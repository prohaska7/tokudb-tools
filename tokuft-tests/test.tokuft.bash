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

function testit() {
    local c=$1
    local t=$2
    if [ ! -f cmake.out ] ; then
        echo CC=$CC CXX=$CXX cmake -DCMAKE_BUILD_TYPE=$t ../tokuft
        CC=$CC CXX=$CXX cmake -DCMAKE_BUILD_TYPE=$t ../tokuft >cmake.out 2>&1
    fi
    if [ ! -f make.out ] ; then
        echo $c $t make -j$np
        make -j$np >make.out 2>&1
    fi

    if [ $buildonly != 0 ] ; then
        return
    fi

    for x in portability util locktree ft ydb ; do
        if [ ! -f ctest.$x.out ] ; then
            echo $c $t ctest -j$np -R $x/ --timeout 3000
            ctest -j$np -R $x/ --timeout 3000 >ctest.$x.out 2>&1
        fi
    done

    for x in portability util locktree ft ydb ; do
        if [ ! -f ctest.memcheck.$x.out ] ; then
            echo $c $t ctest -j$np -R $x/ --timeout 30000 -D ExperimentalMemCheck
            ctest -j$np -R $x/ --timeout 30000 -D ExperimentalMemCheck >ctest.memcheck.$x.out 2>&1
        fi
    done
}

np=$(egrep -c ^processor /proc/cpuinfo)
buildonly=0

for arg in $*; do
    if [[ $arg =~ --(.*)=(.*) ]] ; then
        eval ${BASH_REMATCH[1]}=${BASH_REMATCH[2]}
    fi
done

for c in $(for x in $(seq 9 -1 5); do echo gcc-$x; echo clang-$x;done); do
    for t in Debug RelWithDebInfo ; do
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
            cd tokuft-$t-$c
            CC=$CC CXX=$CXX testit $c $t
            cd ..
        fi
    done
done

echo success
