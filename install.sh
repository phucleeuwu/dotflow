#!/bin/bash

# Go to home directory
cd ~
git clone https://github.com/phucleeuwu/dotfiles
# Remove existing ~/.config and recreate it
rm -f ~/.zshrc
rm -rf ~/.config
mkdir -p ~/.config

# Link config
cd dotfiles
stow -v .
stow -v zshrc -t ~
rm -rf .gitignore .stow-local-ignore .stowrc README.md archive.tar.gz .git .gitattributes
cd zed rm -rf archive.tar.gz
echo "✅ Installation complete! All files from ~/dotfiles are now symlinked to ~/.config/"
