include_guard()

function(prepare_git_info)
    # find git
    find_program(GIT_EXECUTABLE git)

    # check if git is available and if the directory is a git repository
    if(GIT_EXECUTABLE)
        execute_process(COMMAND ${GIT_EXECUTABLE} rev-parse --is-inside-work-tree OUTPUT_VARIABLE IS_GIT_REPO ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE)
    endif()

    if(NOT GIT_EXECUTABLE OR NOT IS_GIT_REPO STREQUAL "true")
        message(WARNING "Git not found or not a git repository. Setting default values.")
        set(GIT_USER "")
        set(GIT_BRANCH "")
        set(GIT_COMMIT "")
        set(GIT_COMMIT_FULL "")
        set(GIT_TAG "")
        set(GIT_EXACT_TAG "")
        set(GIT_MODIFIED 0)
        set(GIT_VERSION "")
    else()
        # get git info
        execute_process(COMMAND ${GIT_EXECUTABLE} config user.name OUTPUT_VARIABLE GIT_USER ERROR_QUIET)
        execute_process(COMMAND ${GIT_EXECUTABLE} branch --show-current OUTPUT_VARIABLE GIT_BRANCH ERROR_QUIET)
        execute_process(COMMAND ${GIT_EXECUTABLE} rev-parse --short HEAD OUTPUT_VARIABLE GIT_COMMIT ERROR_QUIET)
        execute_process(COMMAND ${GIT_EXECUTABLE} rev-parse HEAD OUTPUT_VARIABLE GIT_COMMIT_FULL ERROR_QUIET)
        execute_process(COMMAND ${GIT_EXECUTABLE} describe --tags --abbrev=0 OUTPUT_VARIABLE GIT_TAG ERROR_QUIET)
        execute_process(COMMAND ${GIT_EXECUTABLE} describe --tags --exact --abbrev=0 OUTPUT_VARIABLE GIT_EXACT_TAG ERROR_QUIET)

        if("$ENV{GITHUB_WORKFLOW_RUN}" STREQUAL "true")
            execute_process(COMMAND ${GIT_EXECUTABLE} diff-index --quiet HEAD -- :!qpm.json :!qpm.shared.json :!mod.template.json RESULT_VARIABLE GIT_MODIFIED ERROR_QUIET)
        else()
            execute_process(COMMAND ${GIT_EXECUTABLE} diff-index --quiet HEAD RESULT_VARIABLE GIT_MODIFIED ERROR_QUIET)
        endif()

        string(STRIP "${GIT_USER}" GIT_USER)
        string(STRIP "${GIT_BRANCH}" GIT_BRANCH)
        string(STRIP "${GIT_COMMIT}" GIT_COMMIT)
        string(STRIP "${GIT_COMMIT_FULL}" GIT_COMMIT_FULL)
        string(STRIP "${GIT_TAG}" GIT_TAG)
        string(STRIP "${GIT_EXACT_TAG}" GIT_EXACT_TAG)
    endif()

    set(VERSION_SEPARATOR "+")

    # compute GIT_VERSION
    if(GIT_TAG STREQUAL "")
        set(GIT_VERSION "${PACKAGE_VERSION}")
    else()
        string(REGEX REPLACE "^[^0-9]+" "" GIT_TAG_CLEANED "${GIT_TAG}")
        string(REGEX MATCH "^[^+-]*" GIT_VERSION "${GIT_TAG_CLEANED}")
    endif()

    if(GIT_EXACT_TAG STREQUAL "")
        set(GIT_VERSION "${GIT_VERSION}${VERSION_SEPARATOR}${GIT_COMMIT}")
        set(VERSION_SEPARATOR "-")
    endif()

    if(GIT_MODIFIED)
        set(GIT_VERSION "${GIT_VERSION}${VERSION_SEPARATOR}dirty")
    endif()

    set(GIT_USER "${GIT_USER}" PARENT_SCOPE)
    set(GIT_BRANCH "${GIT_BRANCH}" PARENT_SCOPE)
    set(GIT_COMMIT "${GIT_COMMIT}" PARENT_SCOPE)
    set(GIT_COMMIT_FULL "${GIT_COMMIT_FULL}" PARENT_SCOPE)
    set(GIT_TAG "${GIT_TAG}" PARENT_SCOPE)
    set(GIT_EXACT_TAG "${GIT_EXACT_TAG}" PARENT_SCOPE)
    set(GIT_MODIFIED ${GIT_MODIFIED} PARENT_SCOPE)
    set(GIT_VERSION "${GIT_VERSION}" PARENT_SCOPE)

    message(STATUS "GIT_USER: ${GIT_USER}")
    message(STATUS "GIT_BRANCH: ${GIT_BRANCH}")
    message(STATUS "GIT_COMMIT: ${GIT_COMMIT}")
    message(STATUS "GIT_COMMIT_FULL: ${GIT_COMMIT_FULL}")
    message(STATUS "GIT_TAG: ${GIT_TAG}")
    message(STATUS "GIT_EXACT_TAG: ${GIT_EXACT_TAG}")
    message(STATUS "GIT_MODIFIED: ${GIT_MODIFIED}")
    message(STATUS "GIT_VERSION: ${GIT_VERSION}")

    if(DEFINED GIT_HEADER_FILE)
        # set git defines in header file
        set(GIT_HEADER_CONTENT "#pragma once
#define GIT_USER \"${GIT_USER}\"
#define GIT_BRANCH \"${GIT_BRANCH}\"
#define GIT_COMMIT \"${GIT_COMMIT}\"
#define GIT_COMMIT_FULL \"${GIT_COMMIT_FULL}\"
#define GIT_TAG \"${GIT_TAG}\"
#define GIT_EXACT_TAG \"${GIT_EXACT_TAG}\"
#define GIT_MODIFIED ${GIT_MODIFIED}
#define GIT_VERSION \"${GIT_VERSION}\"
")

        # only update the header file if the contents have changed
        if(EXISTS ${GIT_HEADER_FILE})
            file(READ ${GIT_HEADER_FILE} CURRENT_GIT_HEADER_CONTENT)
        else()
            set(CURRENT_GIT_HEADER_CONTENT "")
        endif()

        file(RELATIVE_PATH REL_GIT_HEADER_FILE ${CMAKE_SOURCE_DIR} ${GIT_HEADER_FILE})

        if(NOT "${GIT_HEADER_CONTENT}" STREQUAL "${CURRENT_GIT_HEADER_CONTENT}")
            message(STATUS "${REL_GIT_HEADER_FILE} needs to be updated.")
            file(WRITE ${GIT_HEADER_FILE} "${GIT_HEADER_CONTENT}")
        else()
            message(STATUS "${REL_GIT_HEADER_FILE} is up to date.")
        endif()
    else()
        message(WARNING "CMake variable GIT_HEADER_FILE not defined, using compile definitions. This is not recommended.")

        # set git defines globally
        add_compile_definitions(
            GIT_USER="${GIT_USER}"
            GIT_BRANCH="${GIT_BRANCH}"
            GIT_COMMIT="${GIT_COMMIT}"
            GIT_COMMIT_FULL="${GIT_COMMIT_FULL}"
            GIT_TAG="${GIT_TAG}"
            GIT_EXACT_TAG="${GIT_EXACT_TAG}"
            GIT_MODIFIED=${GIT_MODIFIED}
            GIT_VERSION="${GIT_VERSION}"
        )
    endif()
endfunction()

prepare_git_info()
