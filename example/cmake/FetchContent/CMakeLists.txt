cmake_minimum_required(VERSION 3.14)
include(FetchContent)

project(myproject LANGUAGES C CXX)

# To install Boost, FetchContent can be used as shown below.
# If Boost is already installed on the system, this step can be skipped.
FetchContent_Declare(Boost URL "https://github.com/boostorg/boost/releases/download/boost-1.88.0/boost-1.88.0-cmake.tar.gz")
FetchContent_MakeAvailable(Boost)

FetchContent_Declare(
    Metall
    GIT_REPOSITORY https://github.com/LLNL/metall.git
    GIT_TAG master
)
FetchContent_MakeAvailable(Metall)

# ---------------------------------------- #
#  For using Metall CXX API
# ---------------------------------------- #
add_executable(cpp_example ../src/cpp_example.cpp)

# Link Metall. Metall::Metall is an INTERFACE target, so no Metall binary is
# linked. It adds Metall's include path, C++17 requirement, and Boost usage
# requirements.
target_link_libraries(cpp_example PRIVATE Metall::Metall)

# ---------------------------------------- #
# For using Metall C API
# ---------------------------------------- #
if(BUILD_C)
    add_executable(c_example ../src/c_example.c)

    # Link Metall C library (libmetall_c)
    target_link_libraries(c_example PRIVATE Metall::metall_c)
endif()
