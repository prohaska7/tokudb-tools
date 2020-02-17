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
    CC=$(get_c_compiler $c)
    CXX=$(get_cxx_compiler $c)
    echo c=$c t=$t CC=$CC CXX=$CXX
    CC=$CC CXX=$CXX cmake -DCMAKE_BUILD_TYPE=$t ../tokubackup/backup >cmake.out 2>&1
    make -j8 >make.out 2>&1
    ctest -j8 >ctest.out 2>&1
    ctest -j8 -D ExperimentalMemCheck >ctest.memcheck.out 2>&1
}

for c in gcc-7 gcc-8 gcc-9 clang-9 ; do
    for t in Debug RelWithDebInfo ; do
        if [ ! -d tokubackup-$t-$c ] ; then
            mkdir tokubackup-$t-$c
            cd tokubackup-$t-$c
            testit $c $t
            cd ..
        fi
    done
done

if [ ! -d tokubackup-asan21 ] ; then
    mkdir tokubackup-asan21
    cd tokubackup-asan21
    CC=clang CXX=clang++ CXXFLAGS=-fsanitize=address cmake -DCMAKE_BUILD_TYPE=Debug ../tokubackup/backup >cmake.out 2>&1
    make -j8 >make.out 2>&1
    ctest --verbose >ctest.out 2>&1
    cd ..
fi

if [ ! -d tokubackup-tsan21 ] ; then
    mkdir tokubackup-tsan21
    cd tokubackup-tsan21
    CC=clang CXX=clang++ CXXFLAGS=-fsanitize=thread cmake -DCMAKE_BUILD_TYPE=Debug ../tokubackup/backup >cmake.out 2>&1
    make -j8 >make.out 2>&1
    ctest --verbose >ctest.out 2>&1
    cd ..
fi

