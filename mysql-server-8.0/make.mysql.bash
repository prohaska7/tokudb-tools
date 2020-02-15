# build Debug: make.mysql.bash
# build RelWithDebInfo: make.mysql.bash --cmake-build-type=RelWithDebInfo
# build with ASAN: make.mysql.bash --with-asan
set -e
build_type=Debug
build_name=$(echo $build_type | tr [:upper:] [:lower:])
build_repo=prohaska7/mysql-server
build_repo_shorthand=ms
build_branch=8.0
cmake_options=

for arg in $*; do
    echo $arg
    if [[ $arg =~ --cmake-build-type=(.*) ]] ; then
        build_type=${BASH_REMATCH[1]}
        build_name=$(echo $build_type | tr [:upper:] [:lower:])
    elif [[ $arg =~ --cmake-option=(.*) ]] ; then
        cmake_options="$cmake_options ${BASH_REMATCH[1]}"
    elif [[ $arg =~ asan ]] ; then
        build_name=asan
        cmake_options="$cmake_options -DWITH_ASAN=ON"
    fi
done

# get the code
if [ ! -d $build_repo_shorthand-$build_branch ] ; then
    git clone -b $build_branch git@github.com:$build_repo $build_repo_shorthand-$build_branch
    pushd $build_repo_shorthand-$build_branch
    git submodule init
    git submodule update
    popd
fi

# build the code
if [ ! -d $build_repo_shorthand-$build_branch-$build_name-build ] ; then
    mkdir $build_repo_shorthand-$build_branch-$build_name-build
    pushd $build_repo_shorthand-$build_branch-$build_name-build
    cmake -DCMAKE_BUILD_TYPE=$build_type -DCMAKE_INSTALL_PREFIX=../$build_repo_shorthand-$build_branch-$build_name-install -DDOWNLOAD_BOOST=1 -DWITH_BOOST=$HOME/boost -DENABLE_DOWNLOADS=1 $cmake_options ../$build_repo_shorthand-$build_branch >cmake.out 2>&1
    make -j8 install >make.out 2>&1
    echo "make done=$?"
fi
