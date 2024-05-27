#!/usr/bin/env bash

mkdir build
cd build

# Cross-compile with openmpi
if [[ "${CONDA_BUILD_CROSS_COMPILATION:-0}" == "1" ]]; then
  export OPAL_PREFIX="$PREFIX"
fi

# Openmpi Specific environment setup - Cf. https://github.com/conda-forge/libnetcdf-feedstock/pull/80
export OMPI_MCA_btl=self,tcp
export OMPI_MCA_plm=isolated
export OMPI_MCA_rmaps_base_oversubscribe=yes
export OMPI_MCA_btl_vader_single_copy_mechanism=none
mpiexec="mpiexec --allow-run-as-root"

export CXXFLAGS="$CXXFLAGS -D_LIBCPP_DISABLE_AVAILABILITY"
cmake ${CMAKE_ARGS} \
    -DPython_ROOT_DIR=$PREFIX \
    -DLIBCLANG_LOCATION=$PREFIX/lib \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DBLAS_LIBRARIES=$PREFIX/lib/libblas${SHLIB_EXT} \
    "-DLAPACK_LIBRARIES=$PREFIX/lib/liblapack${SHLIB_EXT};$PREFIX/lib/libblas${SHLIB_EXT}" \
    .. || cat CMakeFiles/CMakeError.log

make -j${CPU_COUNT} VERBOSE=1

if [[ "${CONDA_BUILD_CROSS_COMPILATION}" != "1" ]]; then
  CTEST_OUTPUT_ON_FAILURE=1 ctest
fi

make install

# Set correct paths in various file
py_version=$( python -c "import sys; print('{}.{}'.format(sys.version_info[0], sys.version_info[1]))" )
for file in bin/triqs++ bin/nda++ lib/cmake/triqs/TRIQSConfig.cmake lib/cmake/Cpp2Py/Cpp2PyTargets.cmake \
    lib/cmake/Cpp2Py/Cpp2PyConfig.cmake lib/python${py_version}/site-packages/cpp2py/libclang_config.py \
    lib/cmake/mpi/mpi-config.cmake
do
  sed "s|$BUILD_PREFIX/venv|$PREFIX|g" $PREFIX/$file > tmp_file
  sed "s|$BUILD_PREFIX|$PREFIX|g" tmp_file > $PREFIX/$file
done
