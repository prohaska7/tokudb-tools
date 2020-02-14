# valgrind_options="--valgrind-mysqld"
valgrind_options="--valgrind-mysqld --valgrind-option=-s"
# valgrind_options="--valgrind-mysqld --valgrind-option=--leak-check=full --valgrind-option=--show-reachable=yes"
# valgrind_options="--valgrind-mysqld --valgrind-option=--track-origins=yes --valgrind-option=-s"

tokudb_plugins="tokudb=ha_tokudb.so;tokudb_trx=ha_tokudb.so;tokudb_locks=ha_tokudb.so;tokudb_lock_waits=ha_tokudb.so;tokudb_fractal_tree_info=ha_tokudb.so;tokudb_background_job_status=ha_tokudb.so;tokudb_file_map=ha_tokudb.so"

for suite in $(basename -a suite/tokudb*|egrep -v backup) ; do
    if [ ! -f valgrind.$suite.out ] ; then
        ./mtr --suite=$suite $valgrind_options --skip-test=fast_up.*\|rows-32m.*\|hotindex-del-.*\|change_column_char\|change_column_bin\|change_column_all_1000.* --mysqld=--plugin-load=$tokudb_plugins --mysqld=--loose-tokudb-check-jemalloc=0 --force --retry=0 --max-test-fail=0 --parallel=auto --no-warnings --testcase-timeout=60  >valgrind.$suite.out 2>&1
            mv var valgrind.$suite.var
    fi
done

for suite in funcs iuds ; do
    if [ ! -f valgrind.engines.$suite.out ] ; then
        ./mtr --suite=engines/$suite $valgrind_options --mysqld=--default-storage-engine=tokudb --mysqld=--default-tmp-storage-engine=tokudb --mysqld=--plugin-load=tokudb=ha_tokudb.so --mysqld=--loose-tokudb-check-jemalloc=0 --parallel=auto --force --retry=0 --max-test-fail=0 >valgrind.engines.$suite.out 2>&1
        mv var valgrind.engines.$suite.var
    fi
done
