#!/usr/bin/env bash

mkdir build
cd build

export CXXFLAGS="$CXXFLAGS -D_LIBCPP_DISABLE_AVAILABILITY"
cmake ${CMAKE_ARGS} \
    -DPython_ROOT_DIR=$PREFIX \
    -DLIBCLANG_LOCATION=$PREFIX/lib \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DBLAS_LIBRARIES=$PREFIX/lib/libblas${SHLIB_EXT} \
    "-DLAPACK_LIBRARIES=$PREFIX/lib/liblapack${SHLIB_EXT};$PREFIX/lib/libblas${SHLIB_EXT}" \
    .. || cat CMakeFiles/CMakeError.log

make -j1 VERBOSE=1

CTEST_OUTPUT_ON_FAILURE=1 ctest -VV

make install

# Set correct paths in various file
py_version=$( python -c "import sys; print('{}.{}'.format(sys.version_info[0], sys.version_info[1]))" )
for file in lib/cmake/triqs/TRIQSConfig.cmake lib/cmake/Cpp2Py/Cpp2PyTargets.cmake \
    lib/cmake/Cpp2Py/Cpp2PyConfig.cmake lib/python${py_version}/site-packages/cpp2py/libclang_config.py \
    lib/cmake/mpi/mpi-config.cmake
do
  [[ -f "$PREFIX/$file" ]] || continue
  sed "s|$BUILD_PREFIX/venv|$PREFIX|g" $PREFIX/$file > tmp_file
  sed "s|$BUILD_PREFIX|$PREFIX|g" tmp_file > $PREFIX/$file
done
