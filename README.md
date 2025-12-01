# BugleOS minirootfs

BugleOS minirootfs is an experimental minimal Linux distribution for WSL. It cross-builds a musl-based toolchain, static BusyBox, and a minimal root filesystem that can be imported with `wsl --import`.

## Prerequisites
Install standard build tools (example for Debian/Ubuntu):

```
sudo apt-get update
sudo apt-get install build-essential wget bison flex texinfo bc git python3 gawk libgmp-dev libmpfr-dev libmpc-dev
```

## Quick start
1. Download sources:
   ```
   make download
   ```
2. Build the full image:
   ```
   make
   ```
3. Run tests:
   ```
   make test
   ```
4. Import into WSL from Windows PowerShell:
   ```
   wsl --import BugleOS C:\\WSL\\BugleOS bugleos-minirootfs-wsl.tar.gz
   ```

## Project layout
- `Makefile` orchestrates the build with targets for toolchain, BusyBox, rootfs, image, and tests.
- `config.mk` stores overridable variables such as `TARGET`, `PREFIX`, `SYSROOT`, `ROOTFS`, and version numbers.
- `scripts/` contains build helpers for each component.
- `tests/` provides verification scripts that operate without executing target binaries.
- `sources/`, `build/`, and `output/` hold downloads, build artifacts, and the final tarball respectively.

## Notes
- Default target is `x86_64-linux-musl`; override by setting `TARGET` when invoking make.
- The toolchain and rootfs are built completely via cross-compilation; no target binaries are executed during the build.
- The BusyBox binary is built statically for maximal portability.
