mtr_options=

for arg in $* ; do
    if [[ $arg =~ --mtr-option=(.*) ]] ; then
        mtr_options="$mtr_options ${BASH_REMATCH[1]}"
    fi
done

engine=tokudb

old_ld_library_path=$LD_LIBRARY_PATH
if [ -z "$LD_LIBRARY_PATH" ] ; then LD_LIBRARY_PATH=$PWD/../lib/private; else LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$PWD/../lib/private; fi

for suite in $(basename -a suite/tokudb*); do
    if [ ! -f $suite.out ] ; then
        rm -rf var $suite.var
        if [[ $suite =~ backup ]] ; then
            old_ld_preload=$LD_PRELOAD
            if [ -z "$LD_PRELOAD" ] ; then LD_PRELOAD=$PWD/../lib/libHotBackup.so; else LD_PRELOAD=$LD_PRELOAD:$PWD/../lib/libHotBackup.so; fi
        fi
        ./mtr --suite=$suite --skip-test=fast_up.* --force --retry=0 --max-test-fail=0 --parallel=auto --no-warnings --testcase-timeout=60 --big-test $mtr_options >$suite.out 2>&1
        mv var $suite.var
        if [[ $suite =~ backup ]] ; then LD_PRELOAD=$old_ld_preload; fi
    fi
done

LD_LIBRARY_PATH=$old_ld_library_path

for suite in funcs iuds ; do
    if [ ! -f $engine.engines.$suite.out ] ; then
        rm -rf var $engine.engines.$suite.var
        ./mtr --suite=engines/$suite --mysqld=--default-storage-engine=$engine --mysqld=--default-tmp-storage-engine=$engine --mysqld=--plugin-load=tokudb=ha_tokudb.so --mysqld=--loose-tokudb-check-jemalloc=0 --parallel=auto --force --retry=0 --max-test-fail=0 --big-test $mtr_options >$engine.engines.$suite.out 2>&1
        mv var $engine.engines.$suite.var
    fi
done
