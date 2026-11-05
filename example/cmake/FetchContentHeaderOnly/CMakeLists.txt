cmake_minimum_required(VERSION 3.14)
include(FetchContent)

project(metall_header_only_example LANGUAGES CXX)

set(METALL_REQUIRED_BOOST_COMPONENTS
  json unordered interprocess container property_tree uuid graph)
set(BOOST_INCLUDE_LIBRARIES ${METALL_REQUIRED_BOOST_COMPONENTS})
FetchContent_Declare(Boost
  URL https://github.com/boostorg/boost/releases/download/boost-1.88.0/boost-1.88.0-cmake.tar.gz)
FetchContent_MakeAvailable(Boost)

set(JUST_INSTALL_METALL_HEADER ON)
FetchContent_Declare(
  Metall
  GIT_REPOSITORY https://github.com/LLNL/metall.git
  GIT_TAG master
)
FetchContent_MakeAvailable(Metall)

add_executable(cpp_example ../src/cpp_example.cpp)
target_link_libraries(cpp_example PRIVATE Metall::Metall Boost::headers)
foreach(boost_component IN LISTS METALL_REQUIRED_BOOST_COMPONENTS)
  target_link_libraries(cpp_example PRIVATE Boost::${boost_component})
endforeach()
