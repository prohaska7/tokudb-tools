# make a debug build of mysql 5.7 with tokudb
# no patch to mysql 5.7 is required
set -e
git clone -b 5.7 git@github.com:mysql/mysql-server
git clone -b my577 git@github.com:prohaska7/tokudb-engine
git clone -b master git@github.com:prohaska7/ft-index
ln -s ../../tokudb-engine/storage/tokudb mysql-server/storage/tokudb
ln -s ../../../ft-index tokudb-engine/storage/tokudb/ft-index
mkdir build install
pushd build
cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX=../install -DTOKUDB_NOPATCH_CONFIG=1 -DWITH_BOOST=$HOME/boost -DZLIB_INCLUDE_DIR=/usr/include ../mysql-server
make -j8 install
popd
