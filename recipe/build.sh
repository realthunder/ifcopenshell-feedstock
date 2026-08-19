#!/bin/bash

# IF osx use file lib suffix .dylib
# IF linux use file lib suffix .so
# IF windows use file lib suffix .dll

if [ "$(uname)" == "Darwin" ]; then
    export FSUFFIX=dylib
    export LDFLAGS="$LDFLAGS -Wl,-flat_namespace,-undefined,suppress"
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    export FSUFFIX=so
fi


# CMAKE_POLICY_VERSION_MINIMUM=3.5: the vendored svgfill source declares a
# cmake_minimum_required below 3.5, which CMake 4 refuses outright. Setting
# the policy floor is what CMake itself suggests; pinning cmake <4 instead
# would drag the whole toolchain back to the 2024 stack this recipe just
# stopped depending on.
# IFCXML_SUPPORT=OFF because upstream master deleted ifcXML support outright,
# so OFF is where the project is going. It does NOT drop libxml2: the vendored
# svgfill links it independently of this switch, so libxml2-devel stays in the
# host deps (`libxml2` itself is now only the CLI tools after the split).
# NB: comments cannot go INSIDE the backslash-continued cmake call below --
# a comment line ends the continuation, and cmake then runs with no source
# directory at all.
cmake ${CMAKE_ARGS} -G Ninja \
 -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
 -DSCHEMA_VERSIONS="2x3;4;4x1;4x3_add2" \
 -DCMAKE_BUILD_TYPE=Release \
 -DCMAKE_INSTALL_PREFIX=$PREFIX \
  ${CMAKE_PLATFORM_FLAGS[@]} \
 -DCMAKE_PREFIX_PATH=$PREFIX \
 -DCMAKE_SYSTEM_PREFIX_PATH=$PREFIX \
 -DPYTHON_EXECUTABLE:FILEPATH=$PYTHON \
 -DGMP_LIBRARY_DIR=$PREFIX/lib \
 -DMPFR_LIBRARY_DIR=$PREFIX/lib \
 -DOCC_INCLUDE_DIR=$PREFIX/include/opencascade \
 -DOCC_LIBRARY_DIR=$PREFIX/lib \
 -DHDF5_SUPPORT:BOOL=ON \
 -DHDF5_INCLUDE_DIR=$PREFIX/include \
 -DHDF5_LIBRARY_DIR=$PREFIX/lib \
 -DJSON_INCLUDE_DIR=$PREFIX/include \
 -DCGAL_INCLUDE_DIR=$PREFIX/include \
 -DLIBXML2_INCLUDE_DIR=$PREFIX/include/libxml2 \
 -DLIBXML2_LIBRARIES=$PREFIX/lib/libxml2.$FSUFFIX \
 -DEIGEN_DIR:FILEPATH=$PREFIX/include/eigen3 \
 -DCOLLADA_SUPPORT:BOOL=OFF \
 -DBUILD_EXAMPLES:BOOL=OFF \
 -DIFCXML_SUPPORT:BOOL=OFF \
 -DGLTF_SUPPORT:BOOL=ON \
 -DBUILD_CONVERT:BOOL=ON \
 -DBUILD_IFCPYTHON:BOOL=ON \
 -DBUILD_IFCGEOM:BOOL=ON \
 -DBUILD_GEOMSERVER:BOOL=OFF \
 -DBOOST_USE_STATIC_LIBS:BOOL=OFF \
 -DCITYJSON_SUPPORT:BOOL=OFF \
 ./cmake

# -j ${CPU_COUNT}: bare `ninja` uses cores+2, and the generated Ifc*-schema.cpp
# translation units are memory-hungry enough that 18 of them at once exhaust a
# 30GB box. gcc does not report that as an out-of-memory error -- it dies with
# "internal compiler error: Segmentation fault", which reads like a compiler
# bug in a generated file.
ninja -j ${CPU_COUNT:-4}

ninja install -j 1