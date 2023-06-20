#!/bin/bash

packages=(
  php
  brew-php-switcher
  mysql
  redis
  node
  nvm
  git
  composer
)

tools=(
  iterm2
  fig
  raycast
)

# Install the Homebrew
if test ! "$(which brew)"; then
  echo "Installing Homebrew..."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# Update Homebrew
echo "Updating Homebrew..."
brew update

# Install Packages
echo "Installing Packages..."

for package in "${packages[@]}"; do
  if brew list "$package" > /dev/null 2>&1; then
    echo "$package already installed... skipping."
  else
    brew install "$package"
  fi
done

# Install Tools
echo "Installing Tools..."

for tool in "${tools[@]}"; do
  if brew list --cask "$tool" > /dev/null 2>&1; then
    echo "$tool already installed... skipping."
  else
    brew install --cask "$tool"
  fi
done
