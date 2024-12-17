set -ex
# meson-python doesn't quite work automagically for cross-compilation
# and conda-forge (for now) does its ARM MacOS builds from Intel

# Perhaps we would not have embraced meson-python so quickly if we knew that.
# Anyway, this seems to be how Scipy and Scikit-image work around it.
#
# Script is largely "borrowed" from scikit-image as we ran into the same build errors

echo $(uname -s)

# Remove problematic vsenv argument from pyproject.toml
sed -i='.bkp' "s/setup = \[\'--vsenv\'\]/setup = []/" pyproject.toml

# If linux, do regular meson-python build and exit early
if test $(uname -s) = Linux
then
    ${PYTHON} -m pip install . -vv
    exit 0
fi

# Otherwise, it's a Mac

# This variable is _probably_ harmless on Intel, but lets
# avoid messing with that currently-working case
if [[ $target_platform == "osx-arm64" ]]
then
    NUMPY_PKGCONFIG=$(find $PREFIX -d -path '*numpy/_core/lib/pkgconfig')
    ls $NUMPY_PKGCONFIG

    export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig:$NUMPY_PKGCONFIG
    #export PKG_CONFIG_PATH=${BUILD_PREFIX}/lib/pkgconfig  #:$BUILD_PREFIX/lib/python3.{10,11,12}/site-packages/numpy/_core/lib/pkgconfig
    echo $PKG_CONFIG_PATH

    $PREFIX/bin/pkg-config --modversion numpy

cat <<EOF > ${CONDA_PREFIX}/meson_cross_file.txt
[host_machine]
system = 'darwin'
cpu = 'arm64'
cpu_family = 'aarch64'
endian = 'little'
[binaries]
# cmake = '$BUILD_PREFIX/bin/cmake'
pkg-config = '$PREFIX/bin/pkg-config'
[properties]
needs_exe_wrapper = true
python = '$PREFIX/bin/python'

EOF

# Exfiltrate some information about what is going on here
# (Yes, I am getting desperate)

cat ${CONDA_PREFIX}/meson_cross_file.txt
fi


for PREFIX_ENV in $PREFIX $BUILD_PREFIX $CONDA_PREFIX
do
    echo "Searching prefix $PREFIX_ENV"
    ls ${PREFIX_ENV}/bin
    find $PREFIX_ENV -name 'numpy.pc'
    find $PREFIX_ENV -name pkg-config
done

    echo ${PYTHON}
    ${PYTHON} -c "import numpy"

mkdir builddir

${PYTHON} -m build --wheel --no-isolation --skip-dependency-check -Cbuilddir=builddir  -Csetup-args=${MESON_ARGS// / -Csetup-args=} || (cat builddir/meson-logs/meson-log.txt && exit 1)

# # need to run meson first for cross-compilation case
# ${PYTHON} $(which meson) setup ${MESON_ARGS} \
#     builddir || (cat builddir/meson-logs/meson-log.txt && exit 1)

# ${PYTHON} -m build --wheel --no-isolation --skip-dependency-check -Cbuilddir=builddir

${PYTHON} -m pip install dist/euphonic*.whl
