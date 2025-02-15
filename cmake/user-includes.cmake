# Check if the file exists
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/user_includes.txt")
    # Read the content of the file into a variable
    file(READ "${CMAKE_CURRENT_SOURCE_DIR}/user_includes.txt" user_includes)

    # Remove carriage returns and newlines
    string(REPLACE "\r" "" user_includes "${user_includes}")
    string(REPLACE "\n" ";" user_includes_list "${user_includes}")

    # Add each directory to the include path
    foreach(dir IN LISTS user_includes_list)
        # Skip empty lines or lines that start with '#'
        if(dir STREQUAL "" OR dir MATCHES "^#")
            continue()
        endif()

        get_filename_component(full_path "${CMAKE_CURRENT_SOURCE_DIR}/${dir}" ABSOLUTE)

        message(STATUS "Adding include directory: ${full_path}")

        # Add the directory to the include path
        include_directories(${full_path})
    endforeach()
else()
    message(STATUS "${CMAKE_CURRENT_SOURCE_DIR}/user_includes.txt does not exist, skipping include directories processing.")
endif()
