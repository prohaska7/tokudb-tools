set -e

git clone -b 8.0-tokudb git@github.com:prohaska7/mysql-server
git clone -b my800 git@github.com:prohaska7/percona-server
git clone -b my800 git@github.com:prohaska7/tokuft

ln -s ../../percona-server/storage/tokudb mysql-server/storage/tokudb

rmdir percona-server/storage/tokudb/PerconaFT
ln -s ../../../tokuft percona-server/storage/tokudb/PerconaFT

ln -s ../../../percona-server/mysql-test/include/have_tokudb.inc mysql-server/mysql-test/include/have_tokudb.inc
for x in $(ls -d percona-server/mysql-test/suite/tokudb*); do
    ln -s ../../../$x mysql-server/mysql-test/suite/$(basename $x)
done

mkdir build install
pushd build
cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX=../install -DDOWNLOAD_BOOST=1 -DWITH_BOOST=$HOME/boost -DZLIB_INCLUDE_DIR=/usr/include -DINSTALL_SQLBENCHDIR=../install ../mysql-server >cmake.out 2>&1
make -j8 install >make.out 2>&1
popd
