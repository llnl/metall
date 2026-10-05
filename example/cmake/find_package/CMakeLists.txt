cmake_minimum_required(VERSION 3.14)

project(myproject LANGUAGES C CXX)

# Find Metall package
# To configure the search path, see CMake documents.
# MetallConfig.cmake reuses Boost targets already in this build or requires an
# installed Boost package. It does not fetch Boost for the consumer.
find_package(Metall REQUIRED)
message(STATUS "Metall_FOUND = ${Metall_FOUND}")


# ---------------------------------------- #
#  For using Metall CXX API
# ---------------------------------------- #
add_executable(cpp_example ../src/cpp_example.cpp)

# Link Metall.
# Metall::Metall provides Metall's include path, C++17 requirement, and Boost
# usage requirements.
target_link_libraries(cpp_example PRIVATE Metall::Metall)


# ---------------------------------------- #
# For using Metall C API
# ---------------------------------------- #

# Not required to do this.
# Just checking if metall_c exists.
find_library(LIB_METALL_C NAMES metall_c)

if(LIB_METALL_C)
    add_executable(c_example ../src/c_example.c)

    # Link Metall C library (libmetall_c). Use this helper (provided by
    # MetallConfig.cmake) instead of target_link_libraries() directly; it
    # also fixes up build ordering against metall_c's transitive Boost
    # static libraries for parallel builds (make -j).
    metall_target_link_metall_c(c_example)
endif()
