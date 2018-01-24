for suite in tokudb.add_index tokudb.alter_table tokudb tokudb.bugs tokudb.parts tokudb.rpl tokudb.sys_vars ; do
    ./mtr --suite=$suite --valgrind-mysqld --skip-test=fast_up.*\|rows-32m.*\|hotindex-del-.*\|change_column_char\|change_column_bin\|change_column_all_1000.* --mysqld='--plugin-load=tokudb=ha_tokudb.so;tokudb_trx=ha_tokudb.so;tokudb_locks=ha_tokudb.so;tokudb_lock_waits=ha_tokudb.so;tokudb_fractal_tree_info=ha_tokudb.so;tokudb_background_job_status=ha_tokudb.so' --mysqld=--loose-tokudb-check-jemalloc=0 --force --retry=0 --max-test-fail=0 --parallel=auto --no-warnings --testcase-timeout=60  >valgrind.$suite.out 2>&1
    mv var valgrind.$suite.var
done

for suite in funcs iuds ; do
    ./mtr --suite=engines/$suite --valgrind-mysqld --mysqld=--default-storage-engine=tokudb --mysqld=--default-tmp-storage-engine=tokudb --mysqld=--plugin-load=tokudb=ha_tokudb.so --mysqld=--loose-tokudb-check-jemalloc=0 --parallel=auto --force --retry=0 --max-test-fail=0 >valgrind.engines.$suite.out 2>&1
    mv var valgrind.engines.$suite.var
done
