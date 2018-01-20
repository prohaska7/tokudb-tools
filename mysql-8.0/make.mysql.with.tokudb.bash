set -e

git clone -b tokudb-803 git@github.com:prohaska7/mysql-server
git clone -b tokudb-803 git@github.com:prohaska7/percona-server
git clone -b tokudb-803 git@github.com:prohaska7/tokuft

ln -s ../../percona-server/storage/tokudb mysql-server/storage/tokudb

rmdir percona-server/storage/tokudb/PerconaFT
ln -s ../../../tokuft percona-server/storage/tokudb/PerconaFT

ln -s ../../../percona-server/mysql-test/include/have_tokudb.inc mysql-server/mysql-test/include/have_tokudb.inc
for x in $(ls -d percona-server/mysql-test/suite/tokudb*); do
    ln -s ../../../$x mysql-server/mysql-test/suite/$(basename $x)
done

mkdir build install
pushd build
cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX=../install -DMYSQL_MAINTAINER_MODE=ON -DDOWNLOAD_BOOST=1 -DWITH_BOOST=$HOME/projects/boost -DZLIB_INCLUDE_DIR=/usr/include -DINSTALL_SQLBENCHDIR=../install -DTOKUDB_NOPATCH_CONFIG=1 ../mysql-server >cmake.out 2>&1
make -j8 install >make.out 2>&1
popd
