#!/bin/bash

# Get CPU information
arch=$(lscpu | awk '/Architecture:/ { print $2 }')
model_name=$(lscpu | awk -F ': +' '/Model name:/ { print $2 }')

# Common compiler flags
common_flags="-Ofast -ffinite-loops -ffast-math -D_REENTRANT -finline-functions -falign-functions=16 -fomit-frame-pointer -fpic -pthread -flto -fuse-ld=lld -fno-stack-protector"

# Set architecture-specific flags
if [[ "$arch" == "aarch64" ]]; then
    if [[ "$model_name" == *"Cortex-A53"* ]]; then
        cpu_flags="-march=armv8-a+crypto -mfpu=crypto-neon-fp-armv8 -mfloat-abi=hard -mtune=cortex-a53 -mfix-cortex-a53-835769" 
    elif [[ "$model_name" == *"Cortex-A73"* ]]; then
        cpu_flags="-march=armv8-a+crypto -mfpu=crypto-neon-fp-armv8 -mfloat-abi=hard -mtune=cortex-a73"
    else
        # Default to ARMv8-A architecture (Cortex-A53) if unknown
        echo "Unknown or unsupported model: $model_name. Defaulting to ARMv8-A."
        cpu_flags="-march=armv8-a+crypto -mtune=cortex-a53"
    fi
else
    # Default to ARMv8-A architecture (Cortex-A53) if unknown architecture
    echo "Unknown or unsupported architecture: $arch. Defaulting to Native Tuning."
    cpu_flags="-mtune=native"
fi

# Set vectorization flags
vectorization_flags="-Rpass-missed=loop-vectorize -Rpass-analysis=loop-vectorize -Wl"

# Combine all flags
all_flags="$common_flags $cpu_flags $vectorization_flags"

# Configure and build
./configure --target=aarch64-linux-gnu --host=x86_64-linux-gnu --build=x86_64-linux-gnu \
            CXXFLAGS="-Wl,-hugetlbfs-align -funroll-loops -finline-functions $all_flags" \
            CFLAGS="-Wl,-hugetlbfs-align -finline-functions $all_flags" \
            CXX=clang++ CC=clang LDFLAGS="-v -flto -Wl,-hugetlbfs-align"
