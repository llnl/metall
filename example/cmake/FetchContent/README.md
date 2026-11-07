# Downloading and Linking Metall with `FetchContent`

This example shows how to download, build, and link Metall directly from a
CMake project using CMake's [`FetchContent`](https://cmake.org/cmake/help/latest/module/FetchContent.html)
module — no separate install step required.

To link an *already installed* Metall package instead, see the
[find_package example](../find_package).

The [CMakeLists.txt](CMakeLists.txt) in this directory:

- Fetches Boost before Metall, making Boost's component targets available in
  the same CMake build (Metall does not fetch Boost itself automatically for consumer projects).
- Fetches the Metall source with `FetchContent` and adds it as a subdirectory.
- Links `cpp_example` to `Metall::Metall`, which propagates Metall's and
  Boost's usage requirements.
- Optionally builds `c_example`, which links `Metall::metall_c` (the C API),
  when `BUILD_C` is enabled.

To use `JUST_INSTALL_METALL_HEADER` and provide Boost from a separate CMake
project, see the [header-only FetchContent example](../FetchContentHeaderOnly).
In that mode, the consuming project links the Boost targets directly because
Metall's dependency setup is skipped.

## Build

```bash
mkdir build
cd build

# BUILD_C=ON is required only if you also want to build the C API example.
cmake ../ -DBUILD_C=ON
make
```

This produces `cpp_example` and (with `BUILD_C=ON`) `c_example` in the build
directory. Run either directly, e.g. `./cpp_example`.

Both Metall and Boost are fetched from their upstream repositories. To use a
local Metall checkout, pass `-DFETCHCONTENT_SOURCE_DIR_METALL=/path/to/metall`
when configuring.