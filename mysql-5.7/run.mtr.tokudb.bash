engine=tokudb

for suite in tokudb.add_index tokudb.alter_table tokudb tokudb.bugs tokudb.parts tokudb.rpl tokudb.sys_vars tokudb.backup ; do
    rm -rf var $suite.var
    ./mtr --suite=$suite --skip-test=fast_up.* --force --retry=0 --max-test-fail=0 --parallel=auto --no-warnings --testcase-timeout=60 --big-test >$suite.out 2>&1
    mv var $suite.var
done

for suite in funcs iuds ; do
    rm -rf var $engine.engines.$suite.var
    ./mtr --suite=engines/$suite --mysqld=--default-storage-engine=$engine --mysqld=--default-tmp-storage-engine=$engine --mysqld=--plugin-load=tokudb=ha_tokudb.so --mysqld=--loose-tokudb-check-jemalloc=0 --parallel=auto --force --retry=0 --max-test-fail=0 --big-test >$engine.engines.$suite.out 2>&1
    mv var $engine.engines.$suite.var
done

engine=innodb
suite=innodb
rm -rf var $engine.var
./mtr --suite=$suite --force --retry=0 --max-test-fail=0 --parallel=auto --no-warnings --testcase-timeout=60 --big-test >$suite.out 2>&1
mv var $suite.var

for suite in funcs iuds ; do
    rm -rf var $engine.engines.$suite.var
    ./mtr --suite=engines/$suite --mysqld=--default-storage-engine=$engine --mysqld=--default-tmp-storage-engine=$engine --parallel=auto --force --retry=0 --max-test-fail=0 --big-test >$engine.engines.$suite.out 2>&1
    mv var $engine.engines.$suite.var
done
