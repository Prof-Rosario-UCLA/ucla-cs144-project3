#!/bin/bash

echo "Starting Rust installation..."

# Install build-essential (includes gcc, g++, make, etc.)
echo "Installing build-essential for C linker..."
sudo apt update
sudo apt install -y build-essential

# Check if build-essential installation was successful
if [ $? -ne 0 ]; then
    echo "Failed to install build-essential. Exiting."
    exit 1
fi

echo "Build-essential installed successfully."

echo "Starting Rust installation..."

# Install Rust using the unattended flag
curl https://sh.rustup.rs -sSf | sh -s -- -y

# Check if rustup installation was successful
if [ $? -ne 0 ]; then
    echo "Rust installation failed. Exiting."
    exit 1
fi

# Source the cargo environment to make rustc and cargo available in the current script's shell
# This is crucial for subsequent cargo commands to work
echo "Sourcing Rust environment..."
source "$HOME/.cargo/env" || { echo "Failed to source Rust environment. Check ~/.cargo/env exists."; exit 1; }

# Verify Rust and Cargo are in the PATH
echo "Verifying Rust and Cargo versions..."
rustc --version || { echo "rustc not found or failed to execute after sourcing. Exiting."; exit 1; }
cargo --version || { echo "cargo not found or failed to execute after sourcing. Exiting."; exit 1; }

echo "Rust and Cargo verified."

# Install wasm-bindgen-cli
echo "Installing wasm-bindgen-cli..."
cargo install -f wasm-bindgen-cli

# Check if wasm-bindgen-cli installation was successful
if [ $? -ne 0 ]; then
    echo "Failed to install wasm-bindgen-cli. Exiting."
    exit 1
fi

echo "wasm-bindgen-cli installed successfully."
echo "Process complete."
