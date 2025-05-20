#!/bin/bash

echo "Starting uninstallation process for Debian/Ubuntu systems..."

# 1. Uninstall wasm-bindgen-cli
# This requires cargo to be in the PATH, so we'll source the env first if it exists.
if [ -f "$HOME/.cargo/env" ]; then
    echo "Sourcing Rust environment to uninstall wasm-bindgen-cli..."
    source "$HOME/.cargo/env"
    if command -v cargo &> /dev/null; then
        echo "Uninstalling wasm-bindgen-cli..."
        cargo uninstall wasm-bindgen-cli
        if [ $? -ne 0 ]; then
            echo "Warning: Failed to uninstall wasm-bindgen-cli (it might not have been installed or cargo had issues)."
        else
            echo "wasm-bindgen-cli uninstalled successfully."
        fi
    else
        echo "Warning: cargo command not found even after sourcing. Skipping wasm-bindgen-cli uninstallation."
    fi
else
    echo "Rust environment file (~/.cargo/env) not found. Skipping wasm-bindgen-cli uninstallation."
fi


# 2. Uninstall Rust and Rustup
echo "Uninstalling Rust (rustup)..."
if command -v rustup &> /dev/null; then
    # Pipe 'y' to rustup self uninstall for automatic confirmation
    yes | rustup self uninstall
    if [ $? -ne 0 ]; then
        echo "Warning: Failed to uninstall Rust (rustup). Manual intervention might be needed."
    else
        echo "Rust (rustup) uninstalled successfully."
    fi
else
    echo "Rustup not found. Rust may not have been installed or was already uninstalled."
fi

# Clean up any remaining .cargo directory if rustup self uninstall didn't get everything
if [ -d "$HOME/.cargo" ]; then
    echo "Removing leftover ~/.cargo directory..."
    rm -rf "$HOME/.cargo"
fi
if [ -d "$HOME/.rustup" ]; then
    echo "Removing leftover ~/.rustup directory..."
    rm -rf "$HOME/.rustup"
fi


# 3. Uninstall build-essential for Debian/Ubuntu-based systems
echo "Uninstalling build-essential (requires sudo)..."
sudo apt remove -y build-essential
if [ $? -ne 0 ]; then
    echo "Warning: Failed to remove build-essential. Manual removal might be needed."
else
    echo "build-essential removed successfully."
fi
sudo apt autoremove -y

echo "Cleaning up your shell..."
cp ~/.bashrc ~/.bashrc.bak_$(date +%Y%m%d%H%M%S)
sed -i '/\. "$HOME\/\.cargo\/env"/d' ~/.bashrc
sed -i '/source "$HOME\/\.cargo\/env"/d' ~/.bashrc
sed -i '/export PATH="$HOME\/\.cargo\/bin:$PATH"/d' ~/.bashrc
echo "Done. If this borks your shell, your previous shell init file is at ~/.bashrc.bak_$(date +%Y%m%d%H%M%S)"


echo "Uninstallation process finished. Please check the output for any warnings."
echo "We are sorry to see you go! And just remember, never touch *rust*y nails!"
echo "Process complete."
