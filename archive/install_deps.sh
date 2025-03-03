#!/bin/bash
# Script to install dependencies for the Presidential Term Progress Bot

echo "Presidential Term Progress Bot - Dependency Installer"
echo "===================================================="
echo ""

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
elif [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    OS=$DISTRIB_ID
elif [ "$(uname)" == "Darwin" ]; then
    OS="macOS"
else
    OS="Unknown"
fi

echo "Detected OS: $OS"
echo ""

# Install dependencies based on OS
case "$OS" in
    *"Ubuntu"*|*"Debian"*|*"Mint"*)
        echo "Installing dependencies for Ubuntu/Debian..."
        sudo apt-get update
        sudo apt-get install -y build-essential libcurl4-openssl-dev liboauth-dev
        ;;
    *"Fedora"*|*"Red Hat"*|*"CentOS"*)
        echo "Installing dependencies for Fedora/RHEL/CentOS..."
        sudo dnf install -y gcc libcurl-devel liboauth-devel
        ;;
    *"Arch"*|*"Manjaro"*)
        echo "Installing dependencies for Arch Linux..."
        sudo pacman -S --needed base-devel curl liboauth
        ;;
    *"macOS"*)
        echo "Installing dependencies for macOS..."
        if ! command -v brew &> /dev/null; then
            echo "Homebrew not found. Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install curl liboauth
        ;;
    *)
        echo "Unsupported OS: $OS"
        echo "Please install the following dependencies manually:"
        echo "- C compiler (gcc or clang)"
        echo "- libcurl development files"
        echo "- liboauth development files"
        exit 1
        ;;
esac

# Check if Zig is installed
if ! command -v zig &> /dev/null; then
    echo ""
    echo "Zig compiler not found. Would you like to install it? (y/n)"
    read -r install_zig
    
    if [ "$install_zig" == "y" ] || [ "$install_zig" == "Y" ]; then
        echo "Installing Zig..."
        
        case "$OS" in
            *"Ubuntu"*|*"Debian"*|*"Mint"*)
                # Download latest Zig for Linux
                wget https://ziglang.org/download/0.11.0/zig-linux-x86_64-0.11.0.tar.xz
                tar -xf zig-linux-x86_64-0.11.0.tar.xz
                sudo mv zig-linux-x86_64-0.11.0 /usr/local/zig
                sudo ln -sf /usr/local/zig/zig /usr/local/bin/zig
                rm zig-linux-x86_64-0.11.0.tar.xz
                ;;
            *"Fedora"*|*"Red Hat"*|*"CentOS"*)
                # Download latest Zig for Linux
                wget https://ziglang.org/download/0.11.0/zig-linux-x86_64-0.11.0.tar.xz
                tar -xf zig-linux-x86_64-0.11.0.tar.xz
                sudo mv zig-linux-x86_64-0.11.0 /usr/local/zig
                sudo ln -sf /usr/local/zig/zig /usr/local/bin/zig
                rm zig-linux-x86_64-0.11.0.tar.xz
                ;;
            *"Arch"*|*"Manjaro"*)
                sudo pacman -S zig
                ;;
            *"macOS"*)
                brew install zig
                ;;
            *)
                echo "Please install Zig manually from https://ziglang.org/download/"
                ;;
        esac
    else
        echo "Please install Zig manually from https://ziglang.org/download/"
    fi
else
    echo "Zig is already installed: $(zig version)"
fi

echo ""
echo "All dependencies installed successfully!"
echo ""
echo "Next steps:"
echo "1. Set up your Twitter API credentials in a .env file"
echo "2. Run the bot with: ./run_bot.sh"
echo ""
echo "For more information, see the README.md file."

# Make run_bot.sh executable
if [ -f run_bot.sh ]; then
    chmod +x run_bot.sh
    echo "Made run_bot.sh executable"
fi

# Make test_twitter_api.sh executable
if [ -f test_twitter_api.sh ]; then
    chmod +x test_twitter_api.sh
    echo "Made test_twitter_api.sh executable"
fi

# Make check_env.sh executable
if [ -f check_env.sh ]; then
    chmod +x check_env.sh
    echo "Made check_env.sh executable"
fi

# Make this script executable
chmod +x "$0" 