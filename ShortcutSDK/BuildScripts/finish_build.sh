# This script copies all files that will be distributed into the project dir

set -e

FRAMEWORK="${BUILT_PRODUCTS_DIR}/${PROJECT_NAME}.framework"
BUNDLE="${BUILT_PRODUCTS_DIR}/${PROJECT_NAME}.bundle"
DOCS="${BUILT_PRODUCTS_DIR}/docs"

rm -rf "${PROJECT_DIR}/build"
mkdir -p "${PROJECT_DIR}/build"

cp -R "${FRAMEWORK}" "${PROJECT_DIR}/build/"
cp -R "${BUNDLE}" "${PROJECT_DIR}/build/"
cp -R "${DOCS}" "${PROJECT_DIR}/build/"

open "${PROJECT_DIR}/build"
