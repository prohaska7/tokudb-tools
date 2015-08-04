# make a debug build of mysql 5.7 with tokudb
# no patch to mysql 5.7 is required
set -e
#git clone -b 5.7 git@github.com:mysql/mysql-server
tar xzf ~/mysql-5.7.8-rc.tar.gz
git clone -b my577.json git@github.com:prohaska7/tokudb-engine
git clone -b master git@github.com:prohaska7/ft-index
ln -s ../../tokudb-engine/storage/tokudb mysql-5.7.8-rc/storage/tokudb
ln -s ../../../ft-index tokudb-engine/storage/tokudb/ft-index
mkdir build
pushd build install
# may need to tinker with the cmake options
GCC=gcc-4.8 CXX=g++-4.8 cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX=../install -DUSE_VALGRIND=ON -DTOKUDB_NOPATCH_CONFIG=1 -DDOWNLOAD_BOOST=1 -DWITH_BOOST=$HOME/boost -DZLIB_INCLUDE_DIR=/usr/include ../mysql-5.7.8-rc
make -j8 install
popd
