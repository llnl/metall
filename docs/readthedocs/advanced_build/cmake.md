# Build and Install Metall Using CMake

Metall's C++ API is header-only, and its optional C API is built as a library.
For CMake consumers, the `Metall::Metall` target supplies the include paths,
C++ standard, and Boost dependencies. Metall can also be added directly to a
CMake project with `FetchContent`.

This page explains how to build and install Metall, configure its optional
examples and tests, and use its CMake package. The repository also includes
benchmarks, verification programs, and utilities.

## Build and Install Metall

```bash
git clone https://github.com/LLNL/metall
cd metall
cmake -S . -B build -DBUILD_EXAMPLE=ON
cmake --build build

# Optional: configure and run the tests in a separate build tree
cmake -S . -B build-test -DBUILD_TEST=ON
cmake --build build-test
ctest --test-dir build-test --output-on-failure

# Optional: install headers and package files
cmake --install build

# Optional: configure and build the API documentation
cmake -S . -B build-doc -DBUILD_DOC=ON
cmake --build build-doc --target build_doc
```

## Requirements

- CMake 3.14 or newer.
- A C++17-compatible compiler. GCC 8.1 or newer is the primary tested
  compiler for building the repository.

## Boost C++ Libraries

Metall requires Boost C++ Libraries 1.80 or newer. The normal
`Metall::Metall` target carries Boost's include and link requirements, so a
consumer can link `Metall::Metall` without listing Boost components separately.

Metall can use Boost in three ways:

- Reuse Boost targets already created in the same CMake build, such as by a
  parent project's `FetchContent_MakeAvailable(Boost)` call.
- Find an installed Boost CMake package with `find_package(Boost CONFIG)`.
- When Metall is the top-level project and is building its own targets, fetch
  the default Boost source archive automatically if no targets or installed
  package are available.

When Metall is added with `FetchContent` or `add_subdirectory`, the parent
project must make Boost available first. A full nested Metall build can also be
given an explicit `BOOST_SOURCE_DIR` or `BOOST_FETCH_URL`; Metall will not
automatically download its default Boost in that case.

### Use an Installed Boost

Make the installed Boost targets available before adding Metall:

```cmake
include(FetchContent)

find_package(Boost 1.80 CONFIG REQUIRED COMPONENTS
  json unordered interprocess container property_tree uuid graph)

FetchContent_Declare(Metall
  GIT_REPOSITORY https://github.com/LLNL/metall.git
  GIT_TAG <metall-version>)
FetchContent_MakeAvailable(Metall)

target_link_libraries(my_app PRIVATE Metall::Metall)
```

For an installed Metall package, `find_package(Metall REQUIRED)` reuses Boost
targets already present in the consumer's build or requires an installed Boost
CMake package. It does not fetch Boost automatically; if neither source is
available, `find_package(Metall)` fails with a dependency error.

### Use FetchContent for Boost

Fetch Boost before Metall so the Boost component targets exist when Metall is
added. `BOOST_INCLUDE_LIBRARIES` is Boost's input variable for selecting
components; it is not Metall's output variable.

```cmake
include(FetchContent)

set(BOOST_INCLUDE_LIBRARIES
  json unordered interprocess container property_tree uuid graph)
FetchContent_Declare(Boost
  URL https://github.com/boostorg/boost/releases/download/boost-1.88.0/boost-1.88.0-cmake.tar.gz)
FetchContent_MakeAvailable(Boost)

FetchContent_Declare(Metall
  GIT_REPOSITORY https://github.com/LLNL/metall.git
  GIT_TAG <metall-version>)
FetchContent_MakeAvailable(Metall)

target_link_libraries(my_app PRIVATE Metall::Metall)
```

The Boost target names are propagated by `Metall::Metall`; do not set the
internal `BOOST_COMPONENT_TARGETS` output variable or link the Boost components
to `my_app` separately.

### Use a Local Boost Source

For a full Metall build, these cache options can point to an already available
Boost source. In a nested build, setting `BOOST_SOURCE_DIR` or `BOOST_FETCH_URL`
explicitly opts in to fetching that source:

- `BOOST_SOURCE_DIR`: Path to an existing, unpacked Boost source tree that
  supports CMake.
- `BOOST_FETCH_URL`: URL or local file path to a Boost source archive.
  For example:
  [boost-1.88.0-cmake.tar.gz](https://github.com/boostorg/boost/releases/download/boost-1.88.0/boost-1.88.0-cmake.tar.gz).
  The archive must contain a Boost release that supports CMake.
- `BOOST_INCLUDE_ROOT`: Legacy option to specify the root directory of Boost
  headers. It supplies include paths only and bypasses Boost target discovery.

`JUST_INSTALL_METALL_HEADER` is an exception to the normal target behavior: it
installs Metall's headers and package files without setting up Boost. Consumers
using this option must arrange Boost themselves and link the necessary Boost
targets directly.

With CMake older than 3.26, a build-tree `find_package(Metall)` export is not
generated when Boost targets were fetched locally. Use `FetchContent` or
`add_subdirectory` in the same build, or install Metall and use
`find_package(Metall)` from the install prefix.

## Additional CMake Options

In addition to standard CMake variables, Metall defines several project
options. To list the cached variables after configuration, run:

```bash
cmake -LAH -S . -B build
```

Some commonly used options are:

- `JUST_INSTALL_METALL_HEADER`: Install only Metall headers and package
  configuration files. Boost setup is skipped; consumer projects must provide
  and link Boost themselves. This is a backup option for users who want to
  manage Boost manually or see issues related to Boost detection. Default:
  `OFF`.
- `BUILD_DOC`: Build the API documentation using Doxygen. You can also run
  Doxygen directly with `docs/Doxyfile.in`. Default: `OFF`.
- `BUILD_UTILITY`: Build utility programs under `src/`. Default: `OFF`.
- `BUILD_EXAMPLE`: Build examples under `example/`. Default: `OFF`.
- `BUILD_BENCH`: Build benchmarks under `bench/`. Default: `OFF`.
- `BUILD_TEST`: Build tests under `test/`. Google Test is downloaded
  automatically unless `SKIP_DOWNLOAD_GTEST=ON`. Default: `OFF`.
- `BUILD_VERIFICATION`: Build verification programs under `verification/`.
  Default: `OFF`.
- `BUILD_C`: Build the C interface library and related examples. Default:
  `OFF`.
- `RUN_LARGE_SCALE_TEST`: Enable large-scale test coverage where supported
  by the test suite. Default: `OFF`.

## Build the Test Directory Without Internet Access (Experimental)

This workflow requires access to the internet for the initial Google Test
download.

1. On a machine with internet access, download Google Test into the build
   tree:

   ```bash
   cd metall
   cmake -S . -B build -DBUILD_TEST=ON -DONLY_DOWNLOAD_GTEST=ON
   ```

2. Move the build directory to the offline machine. Remove the CMake cache if
   necessary, then configure and build the tests:

   ```bash
   cd metall
   rm -f build/CMakeCache.txt
   cmake -S . -B build -DBUILD_TEST=ON -DSKIP_DOWNLOAD_GTEST=ON
   cmake --build build
   ```

- `ONLY_DOWNLOAD_GTEST`: Download Google Test without building the other test
  targets. Default: `OFF`. This option has no effect when `BUILD_TEST` is
  `OFF`.
- `SKIP_DOWNLOAD_GTEST`: Skip downloading Google Test. Default: `OFF`. This
  option has no effect when `BUILD_TEST` is `OFF`.
