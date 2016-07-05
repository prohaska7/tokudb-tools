rm -rf var tokudb.var
./mtr --suite='tokudb*' --skip-test='fast_up.*' --force --retry=0 --max-test-fail=0 --parallel=auto --no-warnings --testcase-timeout=60 >tokudb.out 2>&1
mv var tokudb.var

rm -rf var
./mtr --suite='tokudb*' --skip-test='fast_up.*' --force --retry=0 --max-test-fail=0 --parallel=auto --no-warnings --testcase-timeout=60 --big-test >tokudb.bigtest.out 2>&1
mv var tokudb.bigtest.var tokudb.bigtest.var

for suite in funcs iuds ; do
    rm -rf var tokudb.engines.$suite.var
    ./mtr --suite=engines/$suite --mysqld=--default-storage-engine=tokudb --mysqld=--default-tmp-storage-engine=tokudb --mysqld=--plugin-load=ha_tokudb.so  --parallel=auto --force --retry=0 --max-test-fail=0 >tokudb.engines.$suite.out 2>&1
    mv var tokudb.engines.$suite.var
done
