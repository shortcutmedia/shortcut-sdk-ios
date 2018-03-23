# This script copies all files that will be distributed into the project dir

set -e

FRAMEWORK="${BUILT_PRODUCTS_DIR}/${PROJECT_NAME}.framework"
BUNDLE="${BUILT_PRODUCTS_DIR}/${PROJECT_NAME}.bundle"
DOCS="${BUILT_PRODUCTS_DIR}/docs"
FRAMEWORK_DIR="framework"

rm -rf "${PROJECT_DIR}/${FRAMEWORK_DIR}"
mkdir -p "${PROJECT_DIR}/${FRAMEWORK_DIR}"

cp -R "${FRAMEWORK}" "${PROJECT_DIR}/${FRAMEWORK_DIR}/"
cp -R "${BUNDLE}" "${PROJECT_DIR}/${FRAMEWORK_DIR}/"
cp -R "${DOCS}" "${PROJECT_DIR}/${FRAMEWORK_DIR}/"

cp "${PROJECT_DIR}/README.md" "${PROJECT_DIR}/${FRAMEWORK_DIR}/"
cp "${PROJECT_DIR}/LICENSE.txt" "${PROJECT_DIR}/${FRAMEWORK_DIR}/"

open "${PROJECT_DIR}/${FRAMEWORK_DIR}"
