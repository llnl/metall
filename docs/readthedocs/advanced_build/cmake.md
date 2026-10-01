# Build API Documentation, Examples, Tests, and Utilities

Metall's repository includes examples, tests, benchmarks, verification programs,
and utilities. This page explains how to configure and build them with CMake.

```bash
git clone https://github.com/LLNL/metall
cd metall
cmake -S . -B build -DBUILD_EXAMPLE=ON
cmake --build build # Or, 'make'

# Optional: configure with -DBUILD_TEST=ON, then run the tests
ctest --test-dir build --output-on-failure

# Optional: install headers and package files
cmake --install build # Or, 'make install'

# Optional: configure with -DBUILD_DOC=ON, then build the API documentation
cmake --build build --target build_doc
```

## Requirements

- CMake 3.14 or newer.
- A C++17-compatible compiler. GCC 8.1 or newer is the primary tested
  compiler for building the repository.

## Boost C++ Libraries

Metall depends on Boost C++ Libraries 1.80 or newer.
Metall's CMake configuration looks for a pre-installed Boost by using CMake's `find_package` mechanism first.
If a pre-installed Boost is not found, CMake downloads and installs a proper version of the Boost release automatically.

To use an already downloaded but not installed Boost source code, use one of
the following options:

- `BOOST_INCLUDE_ROOT`: Legacy option for a directory containing Boost
  headers. The directory is added to the build targets' include paths.
- `BOOST_SOURCE_DIR`: Path to an existing, unpacked Boost source tree that
  supports CMake.
- `BOOST_FETCH_URL`: URL or local file path to a Boost source archive.
  For example:
  [boost-1.88.0-cmake.tar.gz](https://github.com/boostorg/boost/releases/download/boost-1.88.0/boost-1.88.0-cmake.tar.gz).
  The archive must contain a Boost release that supports CMake.

## Additional CMake Options

In addition to standard CMake variables, Metall defines several project
options. To list the cached variables after configuration, run:

```bash
cmake -LAH -S . -B build
```

Some commonly used options are:

- `JUST_INSTALL_METALL_HEADER`: Install only Metall headers and package
  configuration files. Default: `OFF`.
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
