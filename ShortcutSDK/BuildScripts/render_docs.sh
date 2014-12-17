# This script generates html files from the in-code documentation

company="Shortcut Media AG";
companyID="com.shortcutmedia";
companyURL="http://shortcutmedia.com";
outputPath="${BUILT_PRODUCTS_DIR}/docs";

rm -rf "${outputPath}"

/usr/local/bin/appledoc \
--project-name "${PROJECT_NAME}" \
--project-company "${company}" \
--company-id "#{companyID}" \
--output "${outputPath}" \
--logformat xcode \
--keep-intermediate-files \
--no-repeat-first-par \
--no-warn-invalid-crossref \
--exit-threshold 2 \
--create-html \
"${PROJECT_DIR}"

rm -rf "${outputPath}/docset"
rm -f "${outputPath}/docset-installed.txt"