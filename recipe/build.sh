set -ex
# meson-python doesn't quite work automagically for cross-compilation
# and conda-forge (for now) does its ARM MacOS builds from Intel

# Perhaps we would not have embraced meson-python so quickly if we knew that.
# Anyway, this seems to be how Scipy and Scikit-image work around it.

# If linux, do regular meson-python build and exit early
if test $(uname -s) = Linux
then
    ${PYTHON} -m pip install . -vv
    exit 0
fi

# Otherwise, it's a Mac

# Remove problematic vsenv argument from pyproject.toml;
# pip install with meson-python ignores it correctly but build will not
sed -i='.bkp' "s/setup = \[\'--vsenv\'\]/setup = []/" pyproject.toml

# Conda-forge uses cross-compilation for ARM:
# - use pkg-config to find Numpy
# - write a "cross file" (overwriting similar one from compilers)
if [[ $target_platform == "osx-arm64" ]]
then
    NUMPY_PKGCONFIG=$(find $BUILD_PREFIX -d -path '*numpy/_core/lib/pkgconfig')
    ls $NUMPY_PKGCONFIG

    export PKG_CONFIG_PATH=$BUILD_PREFIX/lib/pkgconfig:$NUMPY_PKGCONFIG

    cat <<EOF > ${CONDA_PREFIX}/meson_cross_file.txt
[host_machine]
system = 'darwin'
cpu = 'arm64'
cpu_family = 'aarch64'
endian = 'little'
[binaries]
pkg-config = '$BUILD_PREFIX/bin/pkg-config'
[properties]
python = '$BUILD_PREFIX/bin/python'

EOF

fi

# There are some issues with pip install + meson-python +cross-compilation
# so instead we build a wheel explicitly using the build package
mkdir builddir
${PYTHON} -m build --wheel --no-isolation --skip-dependency-check \
          -Cbuilddir=builddir  -Csetup-args=${MESON_ARGS// / -Csetup-args=} \
    || (cat builddir/meson-logs/meson-log.txt && exit 1)

# This wheel can then be safely installed
${PYTHON} -m pip install dist/euphonic*.whl
