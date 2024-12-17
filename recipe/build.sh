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
export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig

# ~~~~ From Numpy build.sh  ~~~~
# HACK: extend $CONDA_PREFIX/meson_cross_file that's created in
# https://github.com/conda-forge/ctng-compiler-activation-feedstock/blob/main/recipe/activate-gcc.sh
# https://github.com/conda-forge/clang-compiler-activation-feedstock/blob/main/recipe/activate-clang.sh
# to use host python; requires that [binaries] section is last in meson_cross_file
echo "python = '${PREFIX}/bin/python'" >> ${CONDA_PREFIX}/meson_cross_file.txt

fi

mkdir builddir

${PYTHON} -m build --wheel --no-isolation --skip-dependency-check -Cbuilddir=builddir  -Csetup-args=${MESON_ARGS// / -Csetup-args=} || (cat builddir/meson-logs/meson-log.txt && exit 1)

# # need to run meson first for cross-compilation case
# ${PYTHON} $(which meson) setup ${MESON_ARGS} \
#     builddir || (cat builddir/meson-logs/meson-log.txt && exit 1)

# ${PYTHON} -m build --wheel --no-isolation --skip-dependency-check -Cbuilddir=builddir

${PYTHON} -m pip install dist/euphonic*.whl
