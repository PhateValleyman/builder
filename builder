#!/data/data/com.termux/files/usr/bin/bash

# =============================================
# builder v1.0 - Interactive Build Tool
# by PhateValleyman <Jonas.Ned@outlook.com>
# =============================================

VERSION="builder v1.0\nby PhateValleyman\nJonas.Ned@outlook.com"

# -------- Color definitions for pretty output --------
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
MAGENTA="\e[35m"
CYAN="\e[36m"
RESET="\e[0m"

# -------- Print version info --------
print_version() {
    echo -e "$VERSION"
    exit 0
}

# -------- Print usage screen --------
print_usage() {
    echo -e "${GREEN}Usage:${RESET} builder.sh [--src=SOURCE] [--patch=PATCH] [--configure-options=OPTIONS] [--install-dir=DIR]"
    echo -e "\n${CYAN}Options:${RESET}"
    echo -e "  ${YELLOW}--src${RESET}                Path to source archive or directory"
    echo -e "  ${YELLOW}--patch${RESET}              Path to patch file (can be used multiple times)"
    echo -e "  ${YELLOW}--configure-options${RESET}  Extra options for ./configure"
    echo -e "  ${YELLOW}--install-dir${RESET}        Installation directory (default based on device)"
    echo -e "  ${YELLOW}--version${RESET}            Show script version"
    echo -e "  ${YELLOW}--help${RESET}               Show this help message"
    exit 0
}

# -------- Initialize default variables --------
PATCH_FILES=()
CONFIGURE_OPTS=""
INSTALL_DIR=""
SRC_INPUT=""

# -------- Parse user command-line arguments --------
for arg in "$@"; do
    case $arg in
        --src=*) SRC_INPUT="${arg#*=}" ;;
        --patch=*) PATCH_FILES+=("${arg#*=}") ;;
        --configure-options=*) CONFIGURE_OPTS="${arg#*=}" ;;
        --install-dir=*) INSTALL_DIR="${arg#*=}" ;;
        --version) print_version ;;
        --help) print_usage ;;
        *) echo -e "${RED}Unknown option: $arg${RESET}" && print_usage ;;
    esac
done

# -------- Detect which device we are running on --------
if [[ -n "$PREFIX" && "$PREFIX" =~ termux ]]; then
    DEVICE="termux"
    HOST="aarch64-linux-android"
    PREFIX="/data/data/com.termux/files/usr"
    TEMPDIR="$PREFIX/tmp"

    # Try to use GCC toolchain, fallback to clang if not found
    export CC="$HOST-gcc"
    export CXX="$HOST-g++"
    export AR="$HOST-ar"
    export AS="$HOST-as"
    export LD="$HOST-ld"
    export RANLIB="$HOST-ranlib"

    if ! command -v $CC &>/dev/null; then
        echo -e "${YELLOW}Falling back to clang toolchain${RESET}"
        export CC=clang
        export CXX=clang++
        export AR=llvm-ar
        export RANLIB=llvm-ranlib
        export STRIP=llvm-strip
    fi

    # Termux recommended flags
    export CFLAGS="-Oz -fstack-protector-strong"
    export LDFLAGS="-Wl,-rpath=$PREFIX/lib -Wl,--enable-new-dtags -Wl,-z,relro -Wl,-z,now"
    export LIBS=""

elif uname -a | grep -q 'NSA320'; then
    DEVICE="ffp"
    HOST="arm-ffp-linux-uclibcgnueabi"
    PREFIX="/ffp"
    TEMPDIR="/ffp/tmp"

    export CC="$HOST-gcc"
    export CXX="$HOST-g++"
    export AR="$HOST-ar"
    export AS="$HOST-as"
    export LD="$HOST-ld"
    export RANLIB="$HOST-ranlib"

    # FFP recommended flags
    export CFLAGS="-I/ffp/include -O2"
    export LDFLAGS="-L/ffp/lib -Wl,-rpath,/ffp/lib"
    export LIBS=""
else
    echo -e "${RED}Unsupported or unknown device. Set toolchain manually.${RESET}"
    exit 1
fi

# Set temp environment for building
export TEMP="$TEMPDIR"
export TMPDIR="$TEMPDIR"

# -------- Helper function to ask user for input with default --------
ask_input() {
    local prompt="$1"
    local default="$2"
    local input
    if [[ -n "$default" ]]; then
        read -p "${prompt} [${default}]: " input
        input="${input:-$default}"
    else
        read -p "${prompt}: " input
    fi
    echo "$input"
}

# -------- Ask user for source if not provided --------
if [[ -z "$SRC_INPUT" ]]; then
    SRC_INPUT=$(ask_input "Enter path to source archive or folder" "")
fi

# -------- Ask user for patch files if none provided --------
if [[ ${#PATCH_FILES[@]} -eq 0 ]]; then
    patch_input=$(ask_input "Enter patch file paths (space separated, leave empty if none)" "")
    if [[ -n "$patch_input" ]]; then
        read -r -a PATCH_FILES <<< "$patch_input"
    fi
fi

# -------- Ask user for additional configure options if none provided --------
if [[ -z "$CONFIGURE_OPTS" ]]; then
    CONFIGURE_OPTS=$(ask_input "Enter additional configure options (or leave empty)" "")
fi

# -------- Unpack archive if necessary --------
if [[ -f "$SRC_INPUT" ]]; then
    TMPDIR_REAL="$TEMPDIR/builder-$$"
    mkdir -p "$TMPDIR_REAL"
    echo -e "${BLUE}Extracting archive to temporary directory...${RESET}"

    case "$SRC_INPUT" in
        *.tar.gz|*.tgz) tar -xzf "$SRC_INPUT" -C "$TMPDIR_REAL" ;;
        *.tar.bz2) tar -xjf "$SRC_INPUT" -C "$TMPDIR_REAL" ;;
        *.tar.xz) tar -xJf "$SRC_INPUT" -C "$TMPDIR_REAL" ;;
        *.zip) unzip "$SRC_INPUT" -d "$TMPDIR_REAL" ;;
        *) echo -e "${RED}Unsupported archive type${RESET}"; exit 1 ;;
    esac

    # Get first-level subdirectory
    SRC_DIR=$(find "$TMPDIR_REAL" -mindepth 1 -maxdepth 1 -type d | head -n1)
else
    SRC_DIR="$SRC_INPUT"
fi

# -------- Enter source directory --------
cd "$SRC_DIR" || exit 1

# -------- Apply user patches --------
for patch in "${PATCH_FILES[@]}"; do
    echo -e "${CYAN}Processing patch: $patch${RESET}"

    # Detect if patch file exists
    if [[ ! -f "$patch" ]]; then
        echo -e "${RED}Patch file $patch does not exist!${RESET}"
        exit 1
    fi

    # If running on termux and patch contains @TERMUX_PREFIX@, replace with termux prefix
    if [[ "$DEVICE" == "termux" ]]; then
        if grep -q "@TERMUX_PREFIX@" "$patch"; then
            TMP_PATCH="$TEMPDIR/tmp_patch_$$.patch"
            echo -e "${YELLOW}Replacing @TERMUX_PREFIX@ with $PREFIX in patch${RESET}"
            sed "s|@TERMUX_PREFIX@|$PREFIX|g" "$patch" > "$TMP_PATCH"
            patch -p1 < "$TMP_PATCH"
            rm -f "$TMP_PATCH"
            if [[ $? -ne 0 ]]; then
                echo -e "${RED}Patch application failed!${RESET}"
                exit 1
            fi
            continue
        fi
    fi

    # If running on ZyXEL (ffp) and patch contains @TERMUX_PREFIX@, replace with /ffp
    if [[ "$DEVICE" == "ffp" ]]; then
        if grep -q "@TERMUX_PREFIX@" "$patch"; then
            TMP_PATCH="$TEMPDIR/tmp_patch_$$.patch"
            echo -e "${YELLOW}Replacing @TERMUX_PREFIX@ with /ffp in patch${RESET}"
            sed "s|@TERMUX_PREFIX@|/ffp|g" "$patch" > "$TMP_PATCH"
            patch -p1 < "$TMP_PATCH"
            rm -f "$TMP_PATCH"
            if [[ $? -ne 0 ]]; then
                echo -e "${RED}Patch application failed!${RESET}"
                exit 1
            fi
            continue
        fi
    fi

    # For other cases, apply patch normally
    patch -p1 < "$patch"
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Patch application failed!${RESET}"
        exit 1
    fi
done

# -------- Colored progress bar for autoreconf --------
run_autoreconf() {
    echo -e "${CYAN}Running autoreconf to generate configure script...${RESET}"
    # Run autoreconf and show a simple colored spinner/progress
    autoreconf -vfi 2>&1 | while IFS= read -r line; do
        # Simple progress visualization: print a colored dot per line
        echo -ne "${GREEN}.${RESET}"
    done
    echo -e "\n${GREEN}autoreconf completed.${RESET}"
}

# -------- Run autoreconf if autoconf files exist --------
if [[ -f "configure.ac" || -f "configure.in" ]]; then
    run_autoreconf
fi

# -------- Show all configure and compile environment variables --------
echo -e "${MAGENTA}=== Build environment ===${RESET}"
echo -e "${YELLOW}DEVICE:${RESET} $DEVICE"
echo -e "${YELLOW}HOST:${RESET} $HOST"
echo -e "${YELLOW}PREFIX:${RESET} $PREFIX"
echo -e "${YELLOW}CC:${RESET} $CC"
echo -e "${YELLOW}CXX:${RESET} $CXX"
echo -e "${YELLOW}AR:${RESET} $AR"
echo -e "${YELLOW}AS:${RESET} $AS"
echo -e "${YELLOW}LD:${RESET} $LD"
echo -e "${YELLOW}RANLIB:${RESET} $RANLIB"
echo -e "${YELLOW}CFLAGS:${RESET} $CFLAGS"
echo -e "${YELLOW}LDFLAGS:${RESET} $LDFLAGS"
echo -e "${YELLOW}LIBS:${RESET} $LIBS"
echo -e "${YELLOW}CONFIGURE OPTIONS:${RESET} $CONFIGURE_OPTS"
echo -e "${MAGENTA}=========================${RESET}"

# -------- Run ./configure with environment --------
echo -e "${MAGENTA}Running configure script for $DEVICE target...${RESET}"
./configure --build=$HOST --host=$HOST --prefix=$PREFIX $CONFIGURE_OPTS 2> error.log
if [[ $? -ne 0 ]]; then
    echo -e "${RED}Configure script failed!${RESET}"
    read -p "Show error.log? (y/n): " answer
    [[ "$answer" == "y" ]] && cat error.log
    exit 1
fi

# -------- Build the project --------
echo -e "${GREEN}Starting build process with colormake...${RESET}"
colormake all V=2 2>> error.log || {
    echo -e "${RED}Build failed!${RESET}"
    read -p "Show error.log? (y/n): " answer
    [[ "$answer" == "y" ]] && cat error.log
    exit 1
}

# -------- Detect and show compiled binary info --------
BIN=$(find . -type f -executable | head -n1)
if [[ -x "$BIN" ]]; then
    echo -e "${YELLOW}Compiled binary: $BIN${RESET}"
    VERSION_OUT=$($BIN --version 2>/dev/null | head -n1)
    echo -e "${YELLOW}Binary version: $VERSION_OUT${RESET}"
fi

# -------- Ask user to install the program --------
read -p "Do you want to install the program? (Y/n): " install_answer
install_answer=${install_answer:-Y}
if [[ "$install_answer" =~ ^[Yy]$ ]]; then
    read -p "Enter installation directory [$PREFIX]: " instdir
    instdir=${instdir:-$PREFIX}
    echo -e "${BLUE}Installing to $instdir...${RESET}"
    colormake install DESTDIR="$instdir" V=2 2>> error.log || {
        echo -e "${RED}Installation failed!${RESET}"
        read -p "Show error.log? (y/n): " answer
        [[ "$answer" == "y" ]] && cat error.log
        exit 1
    }
fi

# -------- Done --------
echo -e "${GREEN}Build and installation complete!${RESET}"
exit 0
