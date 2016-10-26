set -e
# get the code
git clone -b 5.7 git@github.com:percona/percona-server
pushd percona-server
git submodule init
git submodule update
popd

# build the code
rm -rf build.debug install.debug
mkdir build.debug install.debug
pushd build.debug
cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX=../install.debug -DDOWNLOAD_BOOST=1 -DWITH_BOOST=$HOME/boost -DENABLE_DOWNLOADS=1 ../percona-server >cmake.out 2>&1
make -j8 install >make.out 2>&1
