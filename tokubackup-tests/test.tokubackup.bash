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
    echo CC=$CC CXX=$CXX cmake -DCMAKE_BUILD_TYPE=$t
    CC=$CC CXX=$CXX cmake -DCMAKE_BUILD_TYPE=$t ../tokubackup/backup >cmake.out 2>&1
    echo make -j$np
    make -j$np >make.out 2>&1
    echo ctest -j$np
    ctest -j$np >ctest.out 2>&1
    echo ctest -j$np -D ExperimentalMemCheck
    ctest -j$np -D ExperimentalMemCheck >ctest.memcheck.out 2>&1
}

np=$(egrep -c ^processor /proc/cpuinfo)

for t in Debug RelWithDebInfo ; do
    for c in gcc-14 clang-18 ; do
        if [ -d tokubackup-$t-$c ] ; then
            echo skipping $c $t
        else
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
                mkdir tokubackup-$t-$c
                cd tokubackup-$t-$c
                testit $c $t $CC $CXX
                cd ..
            fi
        fi
    done
done

if [ ! -d tokubackup-asan21 ] ; then
    mkdir tokubackup-asan21
    cd tokubackup-asan21
    echo asan CC=clang CXX=clang++ CXXFLAGS=-fsanitize=address cmake -DCMAKE_BUILD_TYPE=Debug
    CC=clang CXX=clang++ CXXFLAGS=-fsanitize=address cmake -DCMAKE_BUILD_TYPE=Debug ../tokubackup/backup >cmake.out 2>&1
    echo asan make -j$np
    make -j$np >make.out 2>&1
    echo asan ctest --verbose
    ctest --verbose >ctest.out 2>&1
    cd ..
fi

if [ ! -d tokubackup-tsan21 ] ; then
    if [ -f tokubackup.tsan.suppressions ] ; then
        export TSAN_OPTIONS="suppressions=$PWD/tokubackup.tsan.suppressions"
    fi
    mkdir tokubackup-tsan21
    cd tokubackup-tsan21
    echo tsan cmake     CC=clang CXX=clang++ CXXFLAGS=-fsanitize=thread cmake -DCMAKE_BUILD_TYPE=Debug
    CC=clang CXX=clang++ CXXFLAGS=-fsanitize=thread cmake -DCMAKE_BUILD_TYPE=Debug ../tokubackup/backup >cmake.out 2>&1
    echo make -j$np
    make -j$np >make.out 2>&1
    echo ctest --verbose
    ctest --verbose >ctest.out 2>&1
    cd ..
fi

if [ ! -d tokubackup-coverage ] ; then
    mkdir tokubackup-coverage
    cd tokubackup-coverage
    echo coverage cmake -DCMAKE_BUILD_TYPE=Debug -DUSE_GCOV=ON
    cmake -DCMAKE_BUILD_TYPE=Debug -DUSE_GCOV=ON ../tokubackup/backup >cmake.out 2>&1
    echo coverage make -j$np
    make -j$np >make.out 2>&1
    echo coverage ctest --verbose
    ctest --verbose >ctest.out 2>&1
    gcov CMakeFiles/HotBackup*.dir/*.cc.o >gcov.out
    cd ..
fi

echo success

