# builder v1.0

**by PhateValleyman (Jonas.Ned@outlook.com)**

`builder.sh` is an interactive, device-aware build script designed to simplify compiling and installing source packages on Termux (Android) and FFP (ZyXEL NSA320) environments.

## Features

- Detects current device and configures toolchain accordingly.
- Supports source archives and plain directories.
- Applies user-specified patches.
- Automatically runs `autoreconf` if necessary.
- Configures with host/build/prefix based on device.
- Compiles using `colormake` with full verbosity.
- Installs to proper device-specific directories.
- Detects and prints compiled binary and version.
- Full colored output and error logging with user prompt.
- CLI and interactive support.
- Built-in usage and version screens.

## Usage

```bash
./builder.sh [--src=SOURCE] [--patch=PATCH] [--configure-options=OPTS] [--install-dir=DIR]
```

### Options

- `--src=...`  
  Source directory or archive to compile. If archive, will be extracted automatically.
- `--patch=...`  
  Patch file to apply (can be specified multiple times).
- `--configure-options=...`  
  Extra arguments to pass to `./configure`.
- `--install-dir=...`  
  Where to install the compiled software (default is device-specific).
- `--help`  
  Show usage screen.
- `--version`  
  Show version and author info.

## Requirements

- bash
- patch
- make
- colormake
- GCC/Clang toolchain (per device)
- unzip/tar for archive extraction

## Example

```bash
./builder.sh --src=nano-7.2.tar.gz --patch=fix-display.patch --configure-options="--enable-utf8"
```

## License

MIT