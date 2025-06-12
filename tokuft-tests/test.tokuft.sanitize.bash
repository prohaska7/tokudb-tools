set -e

np=$(grep -c ^processor /proc/cpuinfo)
timeout=3000
CLANG=clang-18
CLANGPP=clang++-18

for arg in $*; do
    if [[ $arg =~ (.*)=(.*) ]] ; then
        eval "${BASH_REMATCH[1]}=${BASH_REMATCH[2]}"
    fi
done

function testit_sanitize() {
    local t=$1
    if [ ! -d tokuft-$t-$CC ] ; then
        mkdir tokuft-$t-$CC
    fi
    pushd tokuft-$t-$CC
    if [ ! -f cmake.out ] ; then
        echo CC=$CC CXX=$CXX CXXFLAGS=$CXXFLAGS cmake -DCMAKE_BUILD_TYPE=Debug ../tokuft
        CC=$CC CXX=$CXX CXXFLAGS=$CXXFLAGS cmake -DCMAKE_BUILD_TYPE=Debug ../tokuft >cmake.out 2>&1
    fi
    if [ ! -f make.out ] ; then
        echo $t make -j$np
        make -j$np >make.out 2>&1
    fi
    for x in portability util locktree ft ydb ; do
        if [ ! -f ctest.$x.out ] ; then
            echo $t ctest -j$np -R $x/ -E 'valgrind|memcheck|drd|helgrind|try-' --timeout $timeout --output-on-failure
            ctest -j$np -R $x/ -E 'valgrind|memcheck|drd|helgrind|try-' --timeout $timeout --output-on-failure >ctest.$x.out 2>&1
        fi
    done
    popd
}

ASAN_OPTIONS="detect_odr_violation=0" CC=$CLANG CXX=$CLANGPP CXXFLAGS=-fsanitize=address \
    testit_sanitize asan

TSAN_OPTIONS="suppressions=$PWD/tokuft.tsan.suppressions second_deadlock_stack=1" CC=$CLANG CXX=$CLANGPP CXXFLAGS=-fsanitize=thread \
    testit_sanitize tsan

echo success
