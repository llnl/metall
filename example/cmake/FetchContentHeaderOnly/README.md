# Fetching Metall Headers with `JUST_INSTALL_METALL_HEADER`

This example fetches Metall with `FetchContent` and sets
`JUST_INSTALL_METALL_HEADER` so Metall adds its header target without linking Boost or building its optional libraries and tools.

Header-only mode intentionally skips Boost setup. The consuming project must
make Boost available and link its header and component targets to each target
that uses Metall. This example fetches Boost first and links both
`Metall::Metall` and the required Boost targets to `cpp_example`.

## Build

```bash
mkdir build
cd build
cmake ..
cmake --build .
```

Both Metall and Boost are fetched from their upstream repositories. To use a
local Metall checkout, pass `-DFETCHCONTENT_SOURCE_DIR_METALL=/path/to/metall`
when configuring.
