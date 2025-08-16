#!/bin/bash

set -e

export PREFIX="$HOME/graniteos_toolchain/cross"
export TARGET=i686-elf
export PATH="$PREFIX/bin:$PATH"

PACKAGES=("build-essential" "bison" "flex" "libgmp3-dev" "libmpc-dev" "libmpfr-dev" "texinfo")

MISSING_PACKAGES=()

echo "Checking dependencies.."

for package in "${PACKAGES[@]}"; do
    if dpkg -s "$package" &>/dev/null; then
        echo "✅ $package is installed."
    else
        echo "❌ $package is NOT installed."
        MISSING_PACKAGES+=("$package")
    fi
done

if [ ${#MISSING_PACKAGES[@]} -ne 0 ]; then
    echo
    echo "Installing missing packages: ${MISSING_PACKAGES[*]}"
    sudo apt update
    sudo apt install -y "${MISSING_PACKAGES[@]}"
else
    echo
    echo "All required packages are installed."
fi

# Versions (you can update these)
BINUTILS_VERSION=2.41
GCC_VERSION=13.2.0

# Download binutils
if [ ! -d "binutils-$BINUTILS_VERSION" ]; then
    echo "Downloading binutils-$BINUTILS_VERSION..."
    wget https://ftp.gnu.org/gnu/binutils/binutils-$BINUTILS_VERSION.tar.gz
    tar -xf binutils-$BINUTILS_VERSION.tar.gz
fi

# Build and install binutils
mkdir -p build-binutils
cd build-binutils
../binutils-$BINUTILS_VERSION/configure --target=$TARGET --prefix="$PREFIX" --with-sysroot --disable-nls --disable-werror
make -j$(nproc)
make install
cd ..

# Download gcc
if [ ! -d "gcc-$GCC_VERSION" ]; then
    echo "Downloading gcc-$GCC_VERSION..."
    wget https://ftp.gnu.org/gnu/gcc/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.gz
    tar -xf gcc-$GCC_VERSION.tar.gz
fi

# Download prerequisites for gcc
cd gcc-$GCC_VERSION
./contrib/download_prerequisites
cd ..

# Build and install gcc (minimal, only C compiler)
mkdir -p build-gcc
cd build-gcc
../gcc-$GCC_VERSION/configure --target=$TARGET --prefix="$PREFIX" --disable-nls --enable-languages=c,c++ --without-headers --disable-hosted-libstdcxx
make all-gcc -j$(nproc)
make all-target-libgcc -j$(nproc)
make all-target-libstdc++-v3 -j$(nproc)
make install-gcc
make install-target-libgcc
make install-target-libstdc++-v3
cd ..

echo "Cross-compiler build completed! Your binaries are in $PREFIX/bin"
