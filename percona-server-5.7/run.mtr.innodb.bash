mtr_options=

for arg in $* ; do
    if [[ $arg =~ --mtr-option=(.*) ]] ; then
        mtr_options="$mtr_options ${BASH_REMATCH[1]}"
    fi
done

engine=innodb

for suite in $(basename -a suite/innodb*); do
    if [ ! -f $suite.out ] ; then
        rm -rf var $engine.var
        ./mtr --suite=$suite --force --retry=0 --max-test-fail=0 --parallel=auto --no-warnings --testcase-timeout=60 --big-test $mtr_options >$suite.out 2>&1
        mv var $suite.var
    fi
done

for suite in funcs iuds ; do
    if [ ! -f $engine.engines.$suite.out ] ; then
        rm -rf var $engine.engines.$suite.var
        ./mtr --suite=engines/$suite --mysqld=--default-storage-engine=$engine --mysqld=--default-tmp-storage-engine=$engine --parallel=auto --force --retry=0 --max-test-fail=0 --big-test $mtr_options >$engine.engines.$suite.out 2>&1
        mv var $engine.engines.$suite.var
    fi
done
