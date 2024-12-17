set -ex
# meson-python doesn't quite work automagically for cross-compilation
# and conda-forge (for now) does its ARM MacOS builds from Intel

# Perhaps we would not have embraced meson-python so quickly if we knew that.
# Anyway, this seems to be how Scipy and Scikit-image work around it.
#
# Script is largely "borrowed" from scikit-image as we ran into the same build errors

mkdir builddir

echo $(uname -s)

# Remove problematic vsenv argument from pyproject.toml
sed -i "s/setup = \[\'--vsenv\'\]/setup = []/" pyproject.toml

# If linux, do regular meson-python build and exit early
if test $(uname -s) = Linux
then
    ${PYTHON} -m pip install . -vv
    exit 0
fi

# Otherwise, it's a Mac

# need to run meson first for cross-compilation case
${PYTHON} $(which meson) setup ${MESON_ARGS} \
    builddir || (cat builddir/meson-logs/meson-log.txt && exit 1)

${PYTHON} -m build --wheel --no-isolation --skip-dependency-check -Cbuilddir=builddir
${PYTHON} -m pip install dist/euphonic*.whl
