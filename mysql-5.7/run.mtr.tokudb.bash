for suite in tokudb.add_index tokudb.alter_table tokudb tokudb.bugs tokudb.parts tokudb.rpl tokudb.sys_vars ; do
    rm -rf var $suite.var
    ./mtr --suite=$suite --skip-test=fast_up.* --force --retry=0 --max-test-fail=0 --parallel=auto --no-warnings --testcase-timeout=60 --big-test >$suite.out 2>&1
    mv var $suite.var
done

for suite in funcs iuds ; do
    rm -rf var engines.$suite.var
    ./mtr --suite=engines/$suite --mysqld=--default-storage-engine=tokudb --mysqld=--default-tmp-storage-engine=tokudb --mysqld=--plugin-load=tokudb=ha_tokudb.so --mysqld=--loose-tokudb-check-jemalloc=0 --parallel=auto --force --retry=0 --max-test-fail=0 --big-test >engines.$suite.out 2>&1
    mv var engines.$suite.var
done
