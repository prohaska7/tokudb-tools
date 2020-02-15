#!/usr/bin/env bash

function usage() {
    echo "run the sql bench tests"
    echo "assumes that mysqld is already running"
    echo "--socket=$socket --user=$user --password=$password --database=$database --engine=$engine --mysqlbuild=$mysqlbuild"
}

mysqlbuild=
mysqlserver=$(hostname)
engine=tokudb
socket=/tmp/mysql.sock
user=root
password=''
database=sqlbench

# parse the command line
while [ $# -gt 0 ] ; do
    arg=$1; shift
    if [[ $arg =~ --(.*)=(.*) ]] ; then
        eval ${BASH_REMATCH[1]}=${BASH_REMATCH[2]}
    else
        usage; exit 1
    fi
done

tracefile=sql-bench-$engine-$mysqlbuild-$mysqlserver.trace
if [ -f $tracefile ] ; then exit 1; fi
summaryfile=sql-bench-$engine-$mysqlbuild-$mysqlserver.summary
if [ -f $summaryfile ] ; then exit 1; fi

function mydate() {
    date +"%Y%m%d %H:%M:%S"
}

function runtests() {
    testargs=$*
    for testname in test-* ; do
        echo $(mydate) $testname $testargs
        perl $testname $testargs
        exitcode=$?
        echo $(mydate)
        if [ $exitcode != 0 ] ; then
            # assume that the test failure due to a crash.  allow mysqld to restart.
            sleep 60
        fi
        # check for table leaks
        ../bin/mysql --socket=$socket --user=$user --password=$password -e "show table status from $database"
    done
}

>$tracefile

# setup database
../bin/mysql --socket=$socket --user=$user --password=$password -e "drop database $database"
../bin/mysql --socket=$socket --user=$user --password=$password -e "create database $database"

# run tests
runtests --socket=$socket --user=$user --password=$password --database=$database --create-options=engine=$engine --verbose --small-test         >>$tracefile 2>&1
runtests --socket=$socket --user=$user --password=$password --database=$database --create-options=engine=$engine --verbose --small-test --fast  >>$tracefile 2>&1
runtests --socket=$socket --user=$user --password=$password --database=$database --create-options=engine=$engine --verbose                      >>$tracefile 2>&1
runtests --socket=$socket --user=$user --password=$password --database=$database --create-options=engine=$engine --verbose              --fast  >>$tracefile 2>&1
runtests --socket=$socket --user=$user --password=$password --database=$database --create-options=engine=$engine --verbose              --fast --fast-insert >>$tracefile 2>&1
runtests --socket=$socket --user=$user --password=$password --database=$database --create-options=engine=$engine --verbose              --fast --lock-tables >>$tracefile 2>&1

# summarize the results
tfirst=
tlast=
while read l ; do
    if [[ $l =~ ^([0-9]{8}\ [0-9]{2}:[0-9]{2}:[0-9]{2})(.*)$ ]] ; then
        t=${BASH_REMATCH[1]}
        cmd=${BASH_REMATCH[2]}
        if [ -z "$tfirst" ] ; then tfirst=$t; fi
        if [ -z "$cmd" ] ; then
            let duration=$(date -d "$t" +%s)-$(date -d "$tlast" +%s)
            printf "%4s %s %8d %s\n" "$status" "$tlast" "$duration" "$cmdlast"
        else
            cmdlast=$cmd
            status=PASS
        fi
        tlast=$t
     else
        if [[ $l =~ Got\ error|Died|Test\ skipped ]] ; then
            status=FAIL
        fi
    fi
done <$tracefile >$summaryfile

testresult=""
pf=`mktemp`
egrep "^PASS" $summaryfile >$pf 2>&1
if [ $? -eq 0 ] ; then testresult="PASS=`cat $pf | wc -l` $testresult"; fi
egrep "^FAIL" $summaryfile >$pf 2>&1
if [ $? -eq 0 ] ; then testresult="FAIL=`cat $pf | wc -l` $testresult"; fi
rm $pf
if [ "$testresult" = "" ] ; then testresult="?"; fi

let duration=$(date -d "$tlast" +%s)-$(date -d "$tfirst" +%s)
echo $testresult TOTAL time $duration seconds>>$summaryfile

# cleanup
if [[ $testresult =~ "PASS" ]] ; then ../bin/mysql --socket=$socket --user=$user --password=$password -e"drop database $database"; fi

# compute exit code
if [[ $testresult =~ "PASS" ]] ; then exitcode=0; else exitcode=1; fi
exit $exitcode



