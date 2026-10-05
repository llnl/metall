cmake_minimum_required(VERSION 3.14...3.30)
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
include(FetchContent)

# -------------------------------------------------------------------------------- #
# CMake policy
# -------------------------------------------------------------------------------- #
if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.13")
    cmake_policy(SET CMP0077 NEW)
endif()

# When using the URL download method with the ExternalProject_Add() or
# FetchContent_Declare() commands, sets the timestamps of extracted contents
# to the time of extraction.
if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.24")
    cmake_policy(SET CMP0135 NEW)
endif()

# Accept <PACKAGENAME>_ROOT variables for find_package() command.
if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.27")
    cmake_policy(SET CMP0144 NEW)
endif()

# find_package(Boost) to search for the upstream BoostConfig.cmake.
# Disable CMake's FindBoost module.
if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.30")
    cmake_policy(SET CMP0167 NEW)
endif()

# -------------------------------------------------------------------------------- #
# Metall general configuration
# -------------------------------------------------------------------------------- #
project(Metall
    VERSION 0.35
    DESCRIPTION "A persistent memory allocator for data-centric analytics"
    HOMEPAGE_URL "https://github.com/LLNL/metall")

if(CMAKE_SOURCE_DIR STREQUAL PROJECT_SOURCE_DIR)
    set(METALL_IS_TOP_LEVEL TRUE)
else()
    set(METALL_IS_TOP_LEVEL FALSE)
endif()

# Install only Metall's headers and package files; skip Boost setup and other targets.
# Declare this before generating MetallConfig.cmake, which embeds this option's value.
option(JUST_INSTALL_METALL_HEADER
    "Just install Metall header files (do not build anything)"
    OFF)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)
set(CMAKE_CXX_EXTENSIONS OFF)

# ----- Setting up a INTERFACE library to install header files ----- #
include(GNUInstallDirs)

add_library(${PROJECT_NAME} INTERFACE)
add_library(${PROJECT_NAME}::${PROJECT_NAME} ALIAS ${PROJECT_NAME})
target_include_directories(${PROJECT_NAME}
    INTERFACE $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>)
# Consumers should be able to link only Metall::Metall and inherit the
# language level and compatibility link requirements from the interface target.
target_compile_features(${PROJECT_NAME} INTERFACE cxx_std_17)
target_link_libraries(${PROJECT_NAME}
    INTERFACE
    "$<$<AND:$<CXX_COMPILER_ID:GNU>,$<VERSION_LESS:$<CXX_COMPILER_VERSION>,9.1>>:stdc++fs>")
include(metall_target_helpers)

# List of Boost components Metall depends on. Defined before the package config
# is generated so installed consumers can be required to provide these targets.
set(METALL_BOOST_COMPONENTS
    json
    unordered
    interprocess
    container
    property_tree
    uuid
    graph)
set(METALL_DEFAULT_BOOST_FETCH_URL
    "https://github.com/boostorg/boost/releases/download/boost-1.88.0/boost-1.88.0-cmake.tar.gz")

# Generate MetallTargets.cmake file
install(TARGETS ${PROJECT_NAME}
    EXPORT ${PROJECT_NAME}Targets
    DESTINATION ${CMAKE_INSTALL_LIBDIR})
# install MetallTargets.cmake
install(EXPORT ${PROJECT_NAME}Targets
    FILE ${PROJECT_NAME}Targets.cmake
    NAMESPACE ${PROJECT_NAME}::
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/${PROJECT_NAME})

# Install header files
install(DIRECTORY ${PROJECT_SOURCE_DIR}/include/metall
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})

# -------------------------------------------------------------------------------- #
# Generate and install the package configuration and package version files
# -------------------------------------------------------------------------------- #
include(CMakePackageConfigHelpers)

# Generate config file
configure_package_config_file(
    "${PROJECT_SOURCE_DIR}/cmake/${PROJECT_NAME}Config.cmake.in"
    "${PROJECT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
    INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/${PROJECT_NAME}
    NO_SET_AND_CHECK_MACRO
    NO_CHECK_REQUIRED_COMPONENTS_MACRO)

# Generate the version file for the config file
write_basic_package_version_file(
    "${PROJECT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY ExactVersion)

# Install the config and version files
install(FILES
    "${PROJECT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
    "${PROJECT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/${PROJECT_NAME})

# -------------------------------------------------------------------------------- #


# -------------------------------------------------------------------------------- #
# Configuration for building test, benchmark, example, etc.
# ----------
# User configurable options
# -------------------------------------------------------------------------------- #
option(BUILD_UTILITY "Build utility programs" OFF)
option(BUILD_DOC "Build API documentation" OFF)
option(BUILD_C "Build C examples and libraries" OFF)
option(BUILD_SHARED_LIBS "Generate shared libraries" OFF)
option(BUILD_EXAMPLE "Build the examples" OFF)
option(BUILD_TEST "Build the test" OFF)
option(RUN_LARGE_SCALE_TEST "Run large scale tests" OFF)
option(RUN_BUILD_AND_TEST_WITH_CI
    "Perform build and basic test with CI"
    OFF)
option(BUILD_BENCH "Build the benchmark" OFF)
option(BUILD_VERIFICATION "Build verification programs" OFF)
if(METALL_IS_TOP_LEVEL
    AND NOT JUST_INSTALL_METALL_HEADER
    AND NOT INSTALL_HEADER_ONLY)
    set(_metall_fetch_boost_default ON)
else()
    set(_metall_fetch_boost_default OFF)
endif()
option(METALL_FETCH_BOOST
    "Fetch Boost and enable its install rules when no Metall targets are enabled"
    ${_metall_fetch_boost_default})
unset(_metall_fetch_boost_default)
set(COMPILER_DEFS "" CACHE STRING
    "A list of Metall compile definitions to be added to all targets")
# Options for selecting a Boost source. Set at most one of these options.
set(BOOST_SOURCE_DIR CACHE STRING
    "Path to Boost libraries directory already uncompressed. Must be a version that supports CMake.")
set(BOOST_FETCH_URL CACHE STRING
    "URL or file path to an archived Boost source. Must be a version that supports CMake.")
# We keep this option for using old Boost versions. This option will be removed in the future.
set(BOOST_INCLUDE_ROOT "" CACHE STRING
    "Path to Boost include directory. Specified value is passed to target_include_directories().")

# ---------- Experimental options ---------- #
set(UMAP_ROOT "" CACHE PATH "UMap installed root directory")
set(PRIVATEER_ROOT "" CACHE PATH "Privateer installed root directory")

option(ONLY_DOWNLOAD_GTEST "Only downloading Google Test" OFF)
option(SKIP_DOWNLOAD_GTEST "Skip downloading Google Test" OFF)
option(BUILD_NUMA "Build programs that require the NUMA policy library (numa.h)" OFF)
# -------------------------------------------------------------------------------- #

# -------------------------------------------------------------------------------- #
# Exit before building anything
# Metall::Metall interface target is not linked to any dependent libraries at this stage.
# -------------------------------------------------------------------------------- #
if(INSTALL_HEADER_ONLY)
    message(WARNING "INSTALL_HEADER_ONLY option has been replaced with JUST_INSTALL_METALL_HEADER.")
    set(JUST_INSTALL_METALL_HEADER TRUE)
endif()

# Header-only mode skips Boost setup, so it cannot be combined with fetching Boost.
if(METALL_FETCH_BOOST AND JUST_INSTALL_METALL_HEADER)
    message(FATAL_ERROR
        "METALL_FETCH_BOOST cannot be used with JUST_INSTALL_METALL_HEADER or INSTALL_HEADER_ONLY.")
endif()

if(JUST_INSTALL_METALL_HEADER)
    metall_export_build_tree_targets()
    return()
endif()
# -------------------------------------------------------------------------------- #

# -------------------------------------------------------------------------------- #
# Dependency discovery and interface target setup
# This section handles the discovery of Threads,
# and sets up the interface target for the project.
# At this step, no targets have been built; only include directories and
# compile definitions are set up.
# -------------------------------------------------------------------------------- #
find_package(Threads QUIET)
if(TARGET Threads::Threads)
    target_link_libraries(${PROJECT_NAME} INTERFACE Threads::Threads)
endif()

foreach(compile_definition IN LISTS COMPILER_DEFS)
    target_compile_definitions(${PROJECT_NAME} INTERFACE ${compile_definition})
endforeach()

# BOOST_INCLUDE_ROOT is the legacy option for callers that provide a plain
# Boost include directory instead of CMake targets.
if(BOOST_INCLUDE_ROOT)
    metall_add_build_interface_include_dirs(${PROJECT_NAME} ${BOOST_INCLUDE_ROOT})
else()
    # A parent project may already have fetched Boost before adding Metall.
    # Reuse those component targets instead of looking for or fetching Boost again.
    metall_get_boost_targets(metall_boost_component_targets metall_boost_targets)

    # If Boost was not added to this build, look for an installed Boost CMake
    # package that provides Metall's required components.
    if(NOT metall_boost_component_targets)
        find_package(Boost 1.80 QUIET CONFIG
            COMPONENTS ${METALL_BOOST_COMPONENTS})
        metall_get_boost_targets(metall_boost_component_targets metall_boost_targets)
    endif()

    if(METALL_FETCH_BOOST AND NOT metall_boost_component_targets)
        # Boost normally suppresses install rules when embedded as a subproject.
        # This opt-in keeps those rules so Boost can be installed with Metall.
        set(BOOST_SKIP_INSTALL_RULES OFF)
        include(fetch_boost)
        set(BOOST_COMPS ${METALL_BOOST_COMPONENTS})
        set(metall_boost_fetch_args URL ${METALL_DEFAULT_BOOST_FETCH_URL})
        if(BOOST_SOURCE_DIR)
            set(metall_boost_fetch_args SOURCE ${BOOST_SOURCE_DIR})
        elseif(BOOST_FETCH_URL)
            set(metall_boost_fetch_args URL ${BOOST_FETCH_URL})
        endif()
        fetch_boost(${metall_boost_fetch_args}
            COMPONENTS ${BOOST_COMPS})
        metall_get_boost_targets(
            metall_boost_component_targets metall_boost_targets)
        if(NOT metall_boost_component_targets)
            message(FATAL_ERROR
                "METALL_FETCH_BOOST did not provide the required Boost component targets.")
        endif()
    endif()

    # Keep component libraries for Metall's own compiled targets. The headers
    # target is also needed to pass include directories to Metall consumers.
    set(BOOST_COMPONENT_TARGETS ${metall_boost_component_targets})
    if(metall_boost_targets)
        # Link Boost through Metall::Metall so consumers inherit its usage
        # requirements. The helper keeps local Boost targets out of install exports.
        metall_attach_build_tree_boost_usage(
            ${PROJECT_NAME} ${metall_boost_targets})
    endif()
endif()

# -------------------------------------------------------------------------------- #

# -------------------------------------------------------------------------------- #
# Exit if there is nothing to build.
# At this point, Metall::Metall has its dependencies and compile definitions.
# -------------------------------------------------------------------------------- #
if(NOT (BUILD_UTILITY OR BUILD_C OR BUILD_EXAMPLE OR BUILD_BENCH OR BUILD_TEST
         OR BUILD_VERIFICATION OR RUN_BUILD_AND_TEST_WITH_CI OR BUILD_DOC))
    if(NOT METALL_IS_TOP_LEVEL
        AND NOT BOOST_INCLUDE_ROOT
        AND NOT metall_boost_component_targets)
        message(FATAL_ERROR
            "Boost ${METALL_BOOST_COMPONENTS} is required when Metall is added as a subproject. "
            "Make Boost targets available in the parent project before adding Metall.")
    endif()
    metall_export_build_tree_targets()
    return()
endif()
# -------------------------------------------------------------------------------- #

# -------------------------------------------------------------------------------- #
# Only downloading Google Test
# -------------------------------------------------------------------------------- #
if(ONLY_DOWNLOAD_GTEST)
    add_subdirectory(test)
    return()
endif()
# -------------------------------------------------------------------------------- #


# -------------------------------------------------------------------------------- #
# Document (Doxygen)
# -------------------------------------------------------------------------------- #
if(BUILD_DOC)
    include(build_doc)
    build_doc()
endif()
# -------------------------------------------------------------------------------- #


# -------------------------------------------------------------------------------- #
# Set up for building executables in this project
# -------------------------------------------------------------------------------- #

# Requirements for GCC
if(NOT RUN_BUILD_AND_TEST_WITH_CI)
    if(("${CMAKE_C_COMPILER_ID}" STREQUAL "GNU") OR ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU"))
        if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS 8.1)
            message(FATAL_ERROR "GCC version must be at least 8.1")
        endif()
    endif()
endif()
# ---------- Metall Macros ---------- #
foreach(compile_definition IN LISTS COMPILER_DEFS)
    message(STATUS "Metall compile definition: ${compile_definition}")
endforeach()


# ---------- CMAKE_BUILD_TYPE ---------- #
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
    message(STATUS "CMAKE_BUILD_TYPE is set as Release")
endif()


# ---------- Threads ---------- #
find_package(Threads REQUIRED)

# ---------- UMap ---------- #
if(UMAP_ROOT)
    if(UNIX AND NOT APPLE)
        find_library(LIBUMAP NAMES umap PATHS ${UMAP_ROOT}/lib)
    endif()
endif()

# ---------- Privateer ---------- #
if(PRIVATEER_ROOT)
    message(STATUS "Privateer Root is ${PRIVATEER_ROOT}")
    find_library(LIBPRIVATEER NAMES privateer PATHS ${PRIVATEER_ROOT}/lib)
endif()

# ---------- Boost ---------- #
# Check for multiple Boost source options and warn if more than one is specified.
set(metall_boost_source_options "")
foreach(boost_source_option IN ITEMS BOOST_SOURCE_DIR BOOST_FETCH_URL BOOST_INCLUDE_ROOT)
    if(DEFINED ${boost_source_option} AND NOT "${${boost_source_option}}" STREQUAL "")
        list(APPEND metall_boost_source_options ${boost_source_option})
    endif()
endforeach()

list(LENGTH metall_boost_source_options metall_boost_source_option_count)
if(metall_boost_source_option_count GREATER 1)
    list(JOIN metall_boost_source_options ", " metall_boost_source_options_string)
    message(WARNING
        "Specify only one of BOOST_SOURCE_DIR, BOOST_FETCH_URL, or BOOST_INCLUDE_ROOT. "
        "Currently set: ${metall_boost_source_options_string}. Undefined behavior may occur.")
endif()

set(METALL_BOOST_HEADER_INCLUDE_DIRS "")
set(METALL_BOOST_LINK_ITEMS "")
set(METALL_BOOST_LOCAL_TARGET_DEPENDENCIES "")
if(BOOST_INCLUDE_ROOT)
    message(STATUS "Boost include root is ${BOOST_INCLUDE_ROOT}")
else()
    include(fetch_boost)

    # List of boost components Metall depends on
    set(BOOST_COMPS ${METALL_BOOST_COMPONENTS})
    # Link Boost UUID with libatomic fails on LC machines
    option(BOOST_UUID_LINK_LIBATOMIC "Link Boost UUID with libatomic" OFF)

    set(metall_boost_fetch_args URL ${METALL_DEFAULT_BOOST_FETCH_URL})

    if(BOOST_SOURCE_DIR)
        set(metall_boost_fetch_args SOURCE ${BOOST_SOURCE_DIR})
    elseif(BOOST_FETCH_URL)
        set(metall_boost_fetch_args URL ${BOOST_FETCH_URL})
    endif()

    if(NOT BOOST_COMPONENT_TARGETS)
        if(METALL_IS_TOP_LEVEL OR BOOST_SOURCE_DIR OR BOOST_FETCH_URL)
            fetch_boost(${metall_boost_fetch_args} COMPONENTS ${BOOST_COMPS})
        else()
            message(FATAL_ERROR
                "Boost ${BOOST_COMPS} is required to build Metall. When Metall is a subproject, "
                "make Boost available in the parent project or set BOOST_SOURCE_DIR/BOOST_FETCH_URL.")
        endif()
    endif()

    metall_get_boost_targets(metall_boost_component_targets metall_boost_targets)
    if(metall_boost_targets)
        metall_attach_build_tree_boost_usage(${PROJECT_NAME} ${metall_boost_targets})
    endif()

    # Component targets often carry the real include directories and shared-lib
    # compile definitions, while Boost::headers may only be a thin umbrella.
    # Collect those include directories for export-safe library builds.
    metall_collect_target_interface_property(
        boost_component_include_dirs INTERFACE_INCLUDE_DIRECTORIES
        ${BOOST_COMPONENT_TARGETS})
    list(APPEND METALL_BOOST_HEADER_INCLUDE_DIRS ${boost_component_include_dirs})
    list(REMOVE_DUPLICATES METALL_BOOST_HEADER_INCLUDE_DIRS)

    if(NOT METALL_BOOST_HEADER_INCLUDE_DIRS)
        if(Boost_SOURCE_DIR)
            set(METALL_BOOST_HEADER_INCLUDE_DIRS ${Boost_SOURCE_DIR})
        else()
            set(METALL_BOOST_HEADER_INCLUDE_DIRS ${Boost_INCLUDE_DIRS})
        endif()
    endif()

    # Exported build products such as metall_c cannot directly reference local
    # Boost targets in export metadata. Convert those local targets to linker
    # file paths, then add explicit build dependencies so Boost is still built
    # first inside this tree.
    metall_convert_local_targets_to_link_items(METALL_BOOST_LINK_ITEMS ${BOOST_COMPONENT_TARGETS})
    metall_collect_local_target_dependencies(
        METALL_BOOST_LOCAL_TARGET_DEPENDENCIES ${BOOST_COMPONENT_TARGETS})
endif()

# Make this project available from its build directory where the CMake version
# can safely export the current Boost target dependencies.
metall_export_build_tree_targets()

# -------------------------------------------------------------------------------- #
# Add executable functions
# -------------------------------------------------------------------------------- #
include(metall_executable_helpers)

# -------------------------------------------------------------------------------- #
# Build tree
# -------------------------------------------------------------------------------- #
add_subdirectory(src)

if(BUILD_EXAMPLE)
    add_subdirectory(example)
endif()

if(BUILD_BENCH)
    add_subdirectory(bench)
endif()

if(BUILD_TEST)
    enable_testing()
    add_subdirectory(test)
endif()

if(BUILD_VERIFICATION)
    add_subdirectory(verification)
endif()
