#!/bin/bash

# Define colors for better output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# --- Help Message ---
display_help() {
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "This script manages Rust installation and uninstallation on Debian/Ubuntu systems."
    echo ""
    echo "Options:"
    echo "  --install    Install Rust, cargo, and wasm-bindgen-cli."
    echo "  --uninstall  Uninstall Rust, cargo, wasm-bindgen-cli, and build-essential."
    echo "  --help       Display this help message."
    echo ""
    echo "If no option is provided, the script will check for existing Rust installation"
    echo "and prompt the user to install or uninstall accordingly."
}

# --- Installation Function ---
install_rust() {
    echo -e "${GREEN}Starting Rust installation...${NC}"
    echo -e "${YELLOW}This is going to take a while... go grab some coffee! ☕${NC}";

    # Install build-essential (includes gcc, g++, make, etc.)
    echo -e "${YELLOW}Installing build-essential for C linker...${NC}"
    sudo apt update
    sudo apt install -y build-essential
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to install build-essential. Exiting. ❌${NC}"
        exit 1
    fi
    echo -e "${GREEN}Build-essential installed successfully. ✅${NC}"

    echo -e "${YELLOW}Starting Rust installation...${NC}"
    # Install Rust using the unattended flag
    curl https://sh.rustup.rs -sSf | sh -s -- -y
    if [ $? -ne 0 ]; then
        echo -e "${RED}Rust installation failed. Exiting. ❌${NC}"
        exit 1
    fi

    # Source the cargo environment to make rustc and cargo available in the current script's shell
    echo -e "${YELLOW}Sourcing Rust environment...${NC}"
    source "$HOME/.cargo/env" || { echo -e "${RED}Failed to source Rust environment. Check ~/.cargo/env exists. Exiting. ❌${NC}"; exit 1; }

    # Verify Rust and Cargo are in the PATH
    echo -e "${YELLOW}Verifying Rust and Cargo versions...${NC}"
    rustc --version &> /dev/null || { echo -e "${RED}rustc not found or failed to execute after sourcing. Exiting. ❌${NC}"; exit 1; }
    cargo --version &> /dev/null || { echo -e "${RED}cargo not found or failed to execute after sourcing. Exiting. ❌${NC}"; exit 1; }
    echo -e "${GREEN}Rust and Cargo verified. ✅${NC}"

    # Install wasm-bindgen-cli
    echo -e "${YELLOW}Installing wasm-bindgen-cli...${NC}"
    cargo install -f wasm-bindgen-cli
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to install wasm-bindgen-cli. Exiting. ❌${NC}"
        exit 1
    fi
    echo -e "${GREEN}wasm-bindgen-cli installed successfully. ✅${NC}"

    # Install wasm-pack
    echo -e "${YELLOW}Installing wasm-pack...${NC}"
    cargo install wasm-pack
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to install wasm-pack. Exiting. ❌${NC}"
        exit 1
    fi
    echo -e "${GREEN}wasm-pack installed successfully. ✅${NC}"

    echo -e "${GREEN}Process complete. ✅✅✅✅${NC}"
}

# --- Uninstallation Function ---
uninstall_rust() {
    echo -e "${GREEN}Starting uninstallation process for Debian/Ubuntu systems...${NC}"

    # 1. Uninstall Wasm-Pack
    echo -e "${YELLOW}Uninstalling wasm-pack...${NC}"
    cargo uninstall wasm-pack 
    if [ $? -ne 0 ]; then
         echo -e "${YELLOW}Warning: Failed to uninstall wasm-pack (it might not have been installed or cargo had issues).${NC}"
    else
         echo -e "${GREEN}wasm-pack uninstalled successfully. ✅${NC}"
    fi

    # 2. Uninstall wasm-bindgen-cli
    if [ -f "$HOME/.cargo/env" ]; then
        echo -e "${YELLOW}Sourcing Rust environment to uninstall wasm-bindgen-cli...${NC}"
        source "$HOME/.cargo/env"
        if command -v cargo &> /dev/null; then
            echo -e "${YELLOW}Uninstalling wasm-bindgen-cli...${NC}"
            cargo uninstall wasm-bindgen-cli
            if [ $? -ne 0 ]; then
                echo -e "${YELLOW}Warning: Failed to uninstall wasm-bindgen-cli (it might not have been installed or cargo had issues).${NC}"
            else
                echo -e "${GREEN}wasm-bindgen-cli uninstalled successfully. ✅${NC}"
            fi
        else
            echo -e "${YELLOW}Warning: cargo command not found even after sourcing. Skipping wasm-bindgen-cli uninstallation.${NC}"
        fi
    else
        echo -e "${YELLOW}Rust environment file (~/.cargo/env) not found. Skipping wasm-bindgen-cli uninstallation.${NC}"
    fi

    # 3. Uninstall Rust and Rustup
    echo -e "${YELLOW}Uninstalling Rust (rustup)...${NC}"
    if command -v rustup &> /dev/null; then
        yes | rustup self uninstall
        if [ $? -ne 0 ]; then
            echo -e "${YELLOW}Warning: Failed to uninstall Rust (rustup). Manual intervention might be needed.${NC}"
        else
            echo -e "${GREEN}Rust (rustup) uninstalled successfully. ✅${NC}"
        fi
    else
        echo -e "${YELLOW}Rustup not found. Rust may not have been installed or was already uninstalled.${NC}"
    fi

    # Clean up any remaining .cargo directory if rustup self uninstall didn't get everything
    if [ -d "$HOME/.cargo" ]; then
        echo -e "${YELLOW}Removing leftover ~/.cargo directory...${NC}"
        rm -rf "$HOME/.cargo"
    fi
    if [ -d "$HOME/.rustup" ]; then
        echo -e "${YELLOW}Removing leftover ~/.rustup directory...${NC}"
        rm -rf "$HOME/.rustup"
    fi

    # 4. Uninstall build-essential for Debian/Ubuntu-based systems
    echo -e "${YELLOW}Uninstalling build-essential (requires sudo)...${NC}"
    sudo apt remove -y build-essential
    if [ $? -ne 0 ]; then
        echo -e "${YELLOW}Warning: Failed to remove build-essential. Manual removal might be needed.${NC}"
    else
        echo -e "${GREEN}Build-essential removed successfully. ✅${NC}"
    fi
    sudo apt autoremove -y

    echo -e "${YELLOW}Cleaning up your shell...${NC}"
    # Backup .bashrc before modifying
    cp ~/.bashrc ~/.bashrc.bak_$(date +%Y%m%d%H%M%S)
    sed -i '/\. "$HOME\/\.cargo\/env"/d' ~/.bashrc
    sed -i '/source "$HOME\/\.cargo\/env"/d' ~/.bashrc
    sed -i '/export PATH="$HOME\/\.cargo\/bin:$PATH"/d' ~/.bashrc
    echo -e "${GREEN}Done. If this borks your shell, your previous shell init file is at ~/.bashrc.bak_$(date +%Y%m%d%H%M%S)${NC} ✅"

    echo -e "${GREEN}Uninstallation process finished. Please check the output for any warnings. ✅${NC}"
    echo -e "${YELLOW}We are sorry to see you go! 👋 And just remember, never touch *rust*y nails! 🔩${NC}"
    echo -e "${GREEN}Process complete. ✅✅✅✅${NC}"
}

# --- Main Logic ---

# Check for arguments
case "$1" in
    --install)
        install_rust
        ;;
    --uninstall)
        uninstall_rust
        ;;
    --help)
        display_help
        ;;
    *)
        # No flag provided, check for existing installation and prompt
        if command -v rustc &> /dev/null; then
            read -p "Rust is already installed. Do you wish to uninstall? (Y/n) " choice
            case "$choice" in
                y|Y )
                    uninstall_rust
                    ;;
                n|N )
                    echo -e "${GREEN}Aborting. Rust will remain installed. ✅${NC}"
                    exit 0
                    ;;
                * )
                    echo -e "${RED}Invalid choice. Aborting. 👋${NC}"
                    exit 1
                    ;;
            esac
        else
            read -p "Install Rust? (Y/n) " choice
            case "$choice" in
                y|Y )
                    install_rust
                    ;;
                n|N )
                    echo -e "${GREEN}Aborting. Rust will not be installed. 👋${NC}"
                    exit 0
                    ;;
                * )
                    echo -e "${RED}Invalid choice. Aborting. 👋${NC}"
                    exit 1
                    ;;
            esac
        fi
        ;;
esac
