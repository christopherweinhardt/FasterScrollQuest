# Write GIT_VERSION to the version.txt file relative to the CMAKELists.txt file
file(WRITE "${CMAKE_CURRENT_SOURCE_DIR}/version.txt" "${GIT_VERSION}")
