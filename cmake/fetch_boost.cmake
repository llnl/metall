include(FetchContent)
include(CMakeParseArguments)

function(fetch_boost_url boost_url)
    if(${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.25")
        FetchContent_Declare(Boost URL "${boost_url}" SYSTEM)
    else()
        FetchContent_Declare(Boost URL "${boost_url}")
    endif()
    FetchContent_MakeAvailable(Boost)
endfunction()

function(fetch_boost_source boost_source)
    if(${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.25")
        FetchContent_Declare(Boost SOURCE_DIR "${boost_source}" SYSTEM)
    else()
        FetchContent_Declare(Boost SOURCE_DIR "${boost_source}")
    endif()
    FetchContent_MakeAvailable(Boost)
endfunction()

# Fetch Boost libraries using FetchContent.
# Check if Boost is already available using FetchContent first.
# If not, fetch Boost based on the provided SOURCE or URL.
# Arguments:
#   Required:
#       COMPONENTS - List of Boost components to include (e.g., filesystem, system)
#   Optional:
#      SOURCE - Path to Boost libraries directory already uncompressed. Must be a version that supports CMake.
#       URL - URL or file path to an archived Boost source. Must be a version that supports CMake.
# Output:
#   BOOST_COMPONENT_TARGETS - Boost component targets for linking.
function(fetch_boost)
    # Add a prefix ('fetch_boost') to the messages.
    # To show prefix, set CMAKE_MESSAGE_CONTEXT to true.
    if(${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.17")
        list(APPEND CMAKE_MESSAGE_CONTEXT "fetch_boost")
    endif()

    # Unset input variables to avoid interference
    unset(__fetch_boost_COMPONENTS)
    unset(__fetch_boost_SOURCE)
    unset(__fetch_boost_URL)

    cmake_parse_arguments(__fetch_boost "" "URL;SOURCE" "COMPONENTS" ${ARGV})

    if(__fetch_boost_URL AND __fetch_boost_SOURCE)
        message(FATAL_ERROR "Both SOURCE and URL arguments cannot be set at the same time")
    endif()

    # Boost's CMake uses BOOST_INCLUDE_LIBRARIES to specify the components to include.
    set(BOOST_INCLUDE_LIBRARIES ${__fetch_boost_COMPONENTS})

    if(boost_POPULATED)
        # Boost is already available by FetchContent.
        message(VERBOSE "Boost was already populated")
    elseif(__fetch_boost_SOURCE)
        message(VERBOSE "Will fetch Boost source from ${__fetch_boost_SOURCE}")
        fetch_boost_source(${__fetch_boost_SOURCE})
    elseif(__fetch_boost_URL)
        message(VERBOSE "Will fetch Boost from ${__fetch_boost_URL}")
        fetch_boost_url(${__fetch_boost_URL})
    else()
        message(WARNING "Boost was not populated or fetched")
        unset(BOOST_COMPONENT_TARGETS)
        return()
    endif()

    # Boost Components to link
    foreach(lib IN LISTS BOOST_INCLUDE_LIBRARIES)
        list(APPEND BOOST_COMPONENT_TARGETS "Boost::${lib}")
    endforeach()
    set(BOOST_COMPONENT_TARGETS ${BOOST_COMPONENT_TARGETS} PARENT_SCOPE)

endfunction()
