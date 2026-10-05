This directory contains CMake examples that demonstrate how to use Metall library from another CMake project.

If Metall is already installed on the system, one can use the [find_package](./find_package) approach to locate and link it.
Metall can be installed either by using a package manager or by building it from source using the CMake build system.

To **have CMake download, install, and link** Metall, see [FetchContent](./FetchContent).
In this case, Metall expects that required dependencies, such as Boost, are either already installed on the system or are provided through the FetchContent mechanism.
The `Metall::Metall` target carries Boost's usage requirements to consumers.

With `JUST_INSTALL_METALL_HEADER`, Boost setup is skipped; consumers must
provide and link Boost themselves. See the
[header-only FetchContent example](./FetchContentHeaderOnly).
This approach allows users to manage Boost manually while still using Metall's CMake integration.