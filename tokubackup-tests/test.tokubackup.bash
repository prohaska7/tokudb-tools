set -e

function get_c_compiler () {
    local c=$1
    echo $c
}

function get_cxx_compiler () {
    local c=$1
    if [[ $c =~ gcc-(.*) ]] ; then
        echo g++-${BASH_REMATCH[1]}
    elif [[ $c =~ clang-(.*) ]] ; then
        echo clang++-${BASH_REMATCH[1]}
    else
        echo $c
    fi
}

function testit() {
    local c=$1
    local t=$2
    local CC=$3
    local CXX=$4
    if [ ! -f cmake.out ] ; then
        echo CC=$CC CXX=$CXX cmake -DCMAKE_BUILD_TYPE=$t -DUSE_VALGRIND=ON
        CC=$CC CXX=$CXX cmake -DCMAKE_BUILD_TYPE=$t -DUSE_VALGRIND=ON ../tokubackup/backup >cmake.out 2>&1
    fi
    if [ ! -f make.out ] ; then
        echo make -j$np
        make -j$np >make.out 2>&1
    fi
    if [ ! -f ctest.out ] ; then
        echo ctest -j$np -E 'helgrind|drd' --output-on-failure
        ctest -j$np -E 'helgrind|drd' --output-on-failure >ctest.out 2>&1
    fi
    if [ $runmemcheck -ne 0 -a ! -f ctest.memcheck.out ] ; then
        echo ctest -j$np -D ExperimentalMemCheck -E 'helgrind|drd' --output-on-failure
        ctest -j$np -D ExperimentalMemCheck -E 'helgrind|drd' --output-on-failure >ctest.memcheck.out 2>&1
    fi
    if [ $runhelgrind -ne 0 -a ! -f ctest.helgrind.out ] ; then
        echo ctest -j$np -R 'helgrind|drd' --timeout 300 --output-on-failure
        ctest -j$np -R 'helgrind|drd' --timeout 300 --output-on-failure >ctest.helgrind.out 2>&1
    fi
}

np=$(egrep -c ^processor /proc/cpuinfo)

runmemcheck=0
runhelgrind=0

for arg in $*; do
    if [[ $arg =~ (.*)=(.*) ]] ; then
        eval "${BASH_REMATCH[1]}=${BASH_REMATCH[2]}"
    fi
done

for t in Debug RelWithDebInfo ; do
    for c in gcc-14 clang-18 ; do
        echo checking $c $t
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
            if [ ! -d tokubackup-$t-$c ] ; then
               mkdir tokubackup-$t-$c
            fi
            pushd tokubackup-$t-$c
            testit $c $t $CC $CXX
            popd
        fi
    done
done

if [ ! -d tokubackup-asan21 ] ; then
    mkdir tokubackup-asan21
    pushd tokubackup-asan21
    echo asan CC=clang CXX=clang++ CXXFLAGS=-fsanitize=address cmake -DCMAKE_BUILD_TYPE=Debug
    CC=clang CXX=clang++ CXXFLAGS=-fsanitize=address cmake -DCMAKE_BUILD_TYPE=Debug ../tokubackup/backup >cmake.out 2>&1
    echo asan make -j$np
    make -j$np >make.out 2>&1
    echo asan ctest -j$np --output-on-failure
    ctest -j$np --output-on-failure >ctest.out 2>&1
    popd
fi

if [ ! -d tokubackup-tsan21 ] ; then
    if [ -f tokubackup.tsan.suppressions ] ; then
        export TSAN_OPTIONS="suppressions=$PWD/tokubackup.tsan.suppressions"
    fi
    mkdir tokubackup-tsan21
    pushd tokubackup-tsan21
    echo tsan cmake     CC=clang CXX=clang++ CXXFLAGS=-fsanitize=thread cmake -DCMAKE_BUILD_TYPE=Debug
    CC=clang CXX=clang++ CXXFLAGS=-fsanitize=thread cmake -DCMAKE_BUILD_TYPE=Debug ../tokubackup/backup >cmake.out 2>&1
    echo make -j$np
    make -j$np >make.out 2>&1
    echo ctest -j$np --output-on-failure
    ctest -j$np --output-on-failure >ctest.out 2>&1
    popd
fi

if [ ! -d tokubackup-coverage ] ; then
    mkdir tokubackup-coverage
    pushd tokubackup-coverage
    echo coverage cmake -DCMAKE_BUILD_TYPE=Debug -DUSE_GCOV=ON
    cmake -DCMAKE_BUILD_TYPE=Debug -DUSE_GCOV=ON ../tokubackup/backup >cmake.out 2>&1
    echo coverage make -j$np
    make -j$np >make.out 2>&1
    echo coverage ctest --verbose
    ctest --verbose >ctest.out 2>&1
    gcov CMakeFiles/HotBackup*.dir/*.cc.o >gcov.out
    popd
fi

echo success

