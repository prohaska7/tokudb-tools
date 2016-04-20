for suite in tokudb.add_index tokudb.alter_table tokudb tokudb.bugs tokudb.parts tokudb.rpl tokudb.sys_vars ; do
    ./mtr --suite=$suite --skip-test=fast_up.* --mysqld='--plugin-load=tokudb=ha_tokudb.so;tokudb_trx=ha_tokudb.so;tokudb_locks=ha_tokudb.so;tokudb_lock_waits=ha_tokudb.so;tokudb_fractal_tree_info=ha_tokudb.so;tokudb_background_job_status=ha_tokudb.so' --mysqld=--loose-tokudb-check-jemalloc=0 --force --retry=0 --max-test-fail=0 --parallel=auto --no-warnings --testcase-timeout=60 --big-test >$suite.out 2>&1
    mv var $suite.var
done

for suite in funcs iuds ; do
    ./mtr --suite=engines/$suite --mysqld=--default-storage-engine=tokudb --mysqld=--default-tmp-storage-engine=tokudb --mysqld=--plugin-load=tokudb=ha_tokudb.so --mysqld=--loose-tokudb-check-jemalloc=0 --parallel=auto --force --retry=0 --max-test-fail=0 --big-test >engines.$suite.out 2>&1
    mv var engines.$suite.var
done
