#!/bin/bash

# Exit immediately if any command fails
set -e

# Function to install Homebrew
install_homebrew() {
    echo "🔍 Homebrew not found. Installing now..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Ensure Homebrew is in the PATH
    if [[ "$(uname -m)" == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    if ! command -v brew &>/dev/null; then
        echo "❌ Homebrew installation failed. Please install it manually from https://brew.sh/"
        exit 1
    fi
}

# Function to get a valid yes/no input
get_yes_no() {
    local prompt="$1"
    local response
    while true; do
        read -p "$prompt (y/n) " response
        case "$response" in
            [Yy]) return 0 ;;  # Yes
            [Nn]) return 1 ;;  # No
            *) echo "❌ Invalid choice. Please enter 'y' for Yes or 'n' for No." ;;
        esac
    done
}

# Check if Homebrew is installed, prompt user to install if missing
if ! command -v brew &> /dev/null; then
    if get_yes_no "🍺 Homebrew is not installed. Do you want to install it now?"; then
        install_homebrew
    else
        echo "❌ Homebrew is required for this script. Exiting."
        exit 1
    fi
fi

# Clone dotfiles repository
DOTFILES_DIR="$HOME/dotfiles"
CONFIG_DIR="$HOME/.config"

echo "🚀 Setting up dotfiles..."
cd ~
rm -rf "$DOTFILES_DIR"
git clone --depth 1 https://github.com/phucleeuwu/dotfiles.git "$DOTFILES_DIR"

# Remove existing .zshrc and .config
rm -f ~/.zshrc
rm -rf "$CONFIG_DIR"
mkdir -p "$CONFIG_DIR"


# Use GNU Stow to manage dotfiles
cd "$DOTFILES_DIR" || exit 1  # Ensure cd succeeds

if get_yes_no "❄️ 'y' to use Nix 'n' for Stow"; then
    mv .stow-local-ignore-nix .stow-local-ignore
    stow .
    mv .stow-local-ignore .stow-local-ignore-nix    
else
    # Check if Stow and Zinit is installed, install it via Homebrew if missing
    if ! command -v stow &>/dev/null; then
        brew install stow
    fi
    if ! command -v zinit &>/dev/null; then
        brew install zinit
    fi
    mv .stow-local-ignore-nonix .stow-local-ignore
    stow .
    stow zsh git -t ~
    mv .stow-local-ignore .stow-local-ignore-nonix
fi

# Symlink personal config file
ln -sf "$HOME/Documents/Personal/github-copilot" "$CONFIG_DIR"
ln -sf "$HOME/Documents/Personal/raycast" "$CONFIG_DIR"
echo "✅ Symlink created for GitHub Copilot and Raycast."

# Ask if user wants to install Brew packages
BREWFILE="$DOTFILES_DIR/brew/Brewfile"
if [[ -f "$BREWFILE" ]]; then
    if get_yes_no "🍺 Do you want to install my Homebrew packages (Optional)?"; then
        brew bundle --file="$BREWFILE"
    else
        echo "⏭ Skipping Homebrew package installation."
    fi
else
    echo "⚠ No Brewfile found in ~/dotfiles. Skipping Homebrew package installation."
fi

# Final notice
echo "🎉 Setup complete! All dotfiles have been symlinked."
echo "🛠 If you make any changes to your dotfiles, remember to apply them using: $ cd ~/dotfiles && stow ."
