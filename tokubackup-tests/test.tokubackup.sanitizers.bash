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


np=$(grep -c ^processor /proc/cpuinfo)

runmemcheck=0
runhelgrind=0
CLANG=clang-21

for arg in $*; do
    if [[ $arg =~ (.*)=(.*) ]] ; then
        eval "${BASH_REMATCH[1]}=${BASH_REMATCH[2]}"
    fi
done

CLANGPP=$(get_cxx_compiler $CLANG)

if [ ! -d tokubackup-asan-$CLANG ] ; then
    mkdir tokubackup-asan-$CLANG
    pushd tokubackup-asan-$CLANG
    echo asan CC=$CLANG CXX=$CLANGPP CXXFLAGS=-fsanitize=address cmake -DCMAKE_BUILD_TYPE=Debug
    CC=$CLANG CXX=$CLANGPP CXXFLAGS=-fsanitize=address cmake -DCMAKE_BUILD_TYPE=Debug ../tokubackup/backup >cmake.out 2>&1
    echo asan make -j$np
    make -j$np >make.out 2>&1
    echo asan ctest -j$np --output-on-failure
    ctest -j$np --output-on-failure >ctest.out 2>&1
    popd
fi

if [ ! -d tokubackup-msan-$CLANG ] ; then
    mkdir tokubackup-msan-$CLANG
    pushd tokubackup-msan-$CLANG
    echo msan CC=$CLANG CXX=$CLANGPP CXXFLAGS="-fsanitize=memory -fsanitize-memory-track-origins" cmake -DCMAKE_BUILD_TYPE=Debug
    CC=$CLANG CXX=$CLANGPP CXXFLAGS="-fsanitize=memory -fsanitize-memory-track-origins" cmake -DCMAKE_BUILD_TYPE=Debug ../tokubackup/backup >cmake.out 2>&1
    echo msan make -j$np
    make -j$np >make.out 2>&1
    echo msan ctest -j$np --output-on-failure
    ctest -j$np --output-on-failure >ctest.out 2>&1
    popd
fi

if [ ! -d tokubackup-leak-$CLANG ] ; then
    mkdir tokubackup-leak-$CLANG
    pushd tokubackup-leak-$CLANG
    echo leak CC=$CLANG CXX=$CLANGPP CXXFLAGS="-fsanitize=leak" cmake -DCMAKE_BUILD_TYPE=Debug
    CC=$CLANG CXX=$CLANGPP CXXFLAGS="-fsanitize=leak" cmake -DCMAKE_BUILD_TYPE=Debug ../tokubackup/backup >cmake.out 2>&1
    echo leak make -j$np
    make -j$np >make.out 2>&1
    echo leak ctest -j$np --output-on-failure
    ctest -j$np --output-on-failure >ctest.out 2>&1
    popd
fi

if [ ! -d tokubackup-undefined-$CLANG ] ; then
    mkdir tokubackup-undefined-$CLANG
    pushd tokubackup-undefined-$CLANG
    echo undefined CC=$CLANG CXX=$CLANGPP CXXFLAGS="-fsanitize=undefined" cmake -DCMAKE_BUILD_TYPE=Debug
    CC=$CLANG CXX=$CLANGPP CXXFLAGS="-fsanitize=undefined" cmake -DCMAKE_BUILD_TYPE=Debug ../tokubackup/backup >cmake.out 2>&1
    echo undefined make -j$np
    make -j$np >make.out 2>&1
    echo undefined ctest -j$np --output-on-failure
    ctest -j$np --output-on-failure >ctest.out 2>&1
    popd
fi

if [ ! -d tokubackup-tsan-$CLANG ] ; then
    if [ -f tokubackup.tsan.suppressions ] ; then
        export TSAN_OPTIONS="suppressions=$PWD/tokubackup.tsan.suppressions"
    fi
    mkdir tokubackup-tsan-$CLANG
    pushd tokubackup-tsan-$CLANG
    echo tsan cmake CC=$CLANG CXX=$CLANGPP CXXFLAGS=-fsanitize=thread cmake -DCMAKE_BUILD_TYPE=Debug
    CC=$CLANG CXX=$CLANGPP CXXFLAGS=-fsanitize=thread cmake -DCMAKE_BUILD_TYPE=Debug ../tokubackup/backup >cmake.out 2>&1
    echo make -j$np
    make -j$np >make.out 2>&1
    echo ctest -j$np --output-on-failure
    ctest -j$np --output-on-failure >ctest.out 2>&1
    popd
fi

echo success

