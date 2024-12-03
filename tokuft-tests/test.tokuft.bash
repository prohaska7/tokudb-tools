set -e

function get_c_compiler () {
    local c=$1
    echo $c
}

function get_cxx_compiler () {
    local c=$1
    if [ $c = gcc ] ; then
        echo g++
    elif [[ $c =~ gcc-(.*) ]] ; then
        echo g++-${BASH_REMATCH[1]}
    elif [ $c = clang ] ; then
        echo clang++
    elif [[ $c =~ clang-(.*) ]] ; then
        echo clang++-${BASH_REMATCH[1]}
    else
        echo $c
    fi
}

function find_compilers() {
    local where=$1
    local compiler=$2
    echo $(find $where -name $compiler-[0-9.]* | sort)
}

function testit() {
    local c=$1
    local t=$2
    if [ ! -f cmake.out ] ; then
        echo CC=$CC CXX=$CXX cmake -DCMAKE_BUILD_TYPE=$t -DBUILD_TESTING=ON -DUSE_VALGRIND=ON -DVALGRIND_FAIR_SCHED=ON ../tokuft
        CC=$CC CXX=$CXX cmake -DCMAKE_BUILD_TYPE=$t -DBUILD_TESTING=ON -DUSE_VALGRIND=ON -DVALGRIND_FAIR_SCHED=ON ../tokuft >cmake.out 2>&1
    fi
    if [ ! -f make.out ] ; then
        echo $c $t make -j$np
        make -j$np >make.out 2>&1
    fi

    if [ $runfastcheck != 0 ] ; then 
        for x in portability util locktree ft ydb ; do
            outfile=ctest.$x.out
            if [ ! -f $outfile ] ; then
                echo $c $t ctest -R $x -E 'valgrind|memcheck|helgrind|drd' -j$np --timeout 3000 --output-on-failure
                ctest -R $x/ -E 'valgrind|memcheck|helgrind|drd' -j$np --timeout 3000 --output-on-failure >$outfile 2>&1
            fi
        done
    fi

    if [ $runmemcheck != 0 ] ; then
        for x in portability util locktree ft ydb ; do
            outfile=ctest.$x.memcheck.out
            if [ ! -f $outfile ] ; then
                echo $c $t ctest -R $x -j$np --timeout 3000 --output-on-failure
                ctest -R $x/ -j$np --timeout 3000 --output-on-failure >$outfile 2>&1
            fi
        done
    fi

    if [ $runexpmemcheck != 0 ] ; then
        for x in portability util locktree ft ydb ; do
            outfile=ctest.$x.expmemcheck.out
            if [ ! -f $outfile ] ; then
                echo $c $t ctest -j$np -R $x/ -E 'try-|\.abortrecover|\.recover|hotindexer-undo-do-test' --timeout 30000 -D ExperimentalMemCheck --output-on-failure
                ctest -j$np -R $x/ -E 'try-|\.abortrecover|\.recover|hotindexer-undo-do-test' --timeout 30000 -D ExperimentalMemCheck --output-on-failure >$outfile 2>&1
            fi
        done
    fi
}

np=$(grep -c ^processor /proc/cpuinfo)
runfastcheck=0
runmemcheck=0
runexpmemcheck=0

for arg in $*; do
    if [[ $arg =~ (.*)=(.*) ]] ; then
        eval "${BASH_REMATCH[1]}=${BASH_REMATCH[2]}"
    fi
done

for t in Debug RelWithDebInfo ; do
    for c in gcc-14 clang-18 ; do
        c=$(basename $c)
        CC=$(get_c_compiler $c)
        CXX=$(get_cxx_compiler $c)
        set +e
        $CC --version >/dev/null 2>&1
        r=$?
        if [ $r = 0 ] ; then
            $CXX --version >/dev/null 2>&1
            r=$?
        fi
        set -e
        if [ $r != 0 ] ; then
            echo missing $c $t
        else
            if [ ! -d tokuft-$t-$c ] ; then
                mkdir tokuft-$t-$c
            fi
            pushd tokuft-$t-$c
            CC=$CC CXX=$CXX testit $c $t
            popd
        fi
    done
done

echo success
