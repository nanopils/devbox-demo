#!/usr/bin/env bash

set -e # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_header() {
  echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║         Dependency Installer             ║${NC}"
  echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
  echo ""
}

print_success() {
  echo -e "${GREEN}✓${NC} $1"
}

print_info() {
  echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
  echo -e "${RED}✗${NC} $1"
}

# Detect OS
detect_os() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "macos"
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if [ -f /etc/os-release ]; then
      . /etc/os-release
      echo "$ID"
    else
      echo "linux"
    fi
  else
    echo "unknown"
  fi
}

# Detect shell
detect_shell() {
  if [ -n "$BASH_VERSION" ]; then
    echo "bash"
  elif [ -n "$ZSH_VERSION" ]; then
    echo "zsh"
  elif [ -n "$FISH_VERSION" ]; then
    echo "fish"
  else
    echo "unknown"
  fi
}

# Get shell config file
get_shell_config() {
  local shell_type="$1"
  case "$shell_type" in
  bash)
    echo "$HOME/.bashrc"
    ;;
  zsh)
    echo "$HOME/.zshrc"
    ;;
  fish)
    echo "$HOME/.config/fish/config.fish"
    ;;
  *)
    echo ""
    ;;
  esac
}

# Check if command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Install devbox
install_devbox() {
  if command_exists devbox; then
    print_success "devbox is already installed ($(devbox version 2>/dev/null || echo 'version unknown'))"
    return 0
  fi

  print_info "Installing devbox..."
  if curl -fsSL https://get.jetify.com/devbox | bash; then
    print_success "devbox installed successfully"
    return 0
  else
    print_error "Failed to install devbox"
    return 1
  fi
}

# Install direnv on macOS
install_direnv_macos() {
  if command_exists direnv; then
    print_success "direnv is already installed ($(direnv version 2>/dev/null || echo 'version unknown'))"
    return 0
  fi

  print_info "Installing direnv using Homebrew..."

  # Check if Homebrew is installed
  if ! command_exists brew; then
    print_warning "Homebrew not found. Installing Homebrew first..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  if brew install direnv; then
    print_success "direnv installed successfully"
    return 0
  else
    print_error "Failed to install direnv"
    return 1
  fi
}

# Install direnv on Ubuntu/Debian
install_direnv_debian() {
  if command_exists direnv; then
    print_success "direnv is already installed ($(direnv version 2>/dev/null || echo 'version unknown'))"
    return 0
  fi

  print_info "Installing direnv using apt..."
  sudo apt update
  if sudo apt install -y direnv; then
    print_success "direnv installed successfully"
    return 0
  else
    print_error "Failed to install direnv"
    return 1
  fi
}

# Install direnv on Fedora/RHEL/CentOS
install_direnv_fedora() {
  if command_exists direnv; then
    print_success "direnv is already installed ($(direnv version 2>/dev/null || echo 'version unknown'))"
    return 0
  fi

  print_info "Installing direnv using dnf..."
  if sudo dnf install -y direnv; then
    print_success "direnv installed successfully"
    return 0
  else
    print_error "Failed to install direnv"
    return 1
  fi
}

# Install direnv on Arch Linux
install_direnv_arch() {
  if command_exists direnv; then
    print_success "direnv is already installed ($(direnv version 2>/dev/null || echo 'version unknown'))"
    return 0
  fi

  print_info "Installing direnv using pacman..."
  if sudo pacman -S --noconfirm direnv; then
    print_success "direnv installed successfully"
    return 0
  else
    print_error "Failed to install direnv"
    return 1
  fi
}

# Configure direnv shell hook
configure_direnv_hook() {
  local shell_type=$(detect_shell)
  local config_file=$(get_shell_config "$shell_type")

  if [ -z "$config_file" ]; then
    print_warning "Could not detect shell type. Please manually add direnv hook to your shell config."
    print_info "Add this to your shell config: eval \"\$(direnv hook <shell>)\""
    return 1
  fi

  # Check if hook already exists
  local hook_line=""
  case "$shell_type" in
  bash | zsh)
    hook_line="eval \"\$(direnv hook $shell_type)\""
    ;;
  fish)
    hook_line="direnv hook fish | source"
    ;;
  esac

  if [ -f "$config_file" ] && grep -q "direnv hook" "$config_file"; then
    print_success "direnv hook already configured in $config_file"
  else
    print_info "Configuring direnv hook for $shell_type..."

    # Create config file if it doesn't exist
    if [ ! -f "$config_file" ]; then
      mkdir -p "$(dirname "$config_file")"
      touch "$config_file"
    fi

    # Add hook (idempotent)
    echo "" >>"$config_file"
    echo "# direnv hook (added by install script)" >>"$config_file"
    echo "$hook_line" >>"$config_file"

    print_success "direnv hook added to $config_file"
  fi

  # Configure devbox global shellenv (idempotent)
  local devbox_line="eval \"\$(devbox global shellenv)\""

  if grep -q "devbox global shellenv" "$config_file"; then
    print_success "devbox global shellenv already configured in $config_file"
  else
    print_info "Configuring devbox global shellenv..."

    # Add devbox global shellenv
    echo "" >>"$config_file"
    echo "# Enable devbox globally (added by install script)" >>"$config_file"
    echo "$devbox_line" >>"$config_file"

    print_success "devbox global shellenv added to $config_file"
  fi

  print_warning "Please restart your shell or run: source $config_file"

  return 0
}

# Main installation function
main() {
  print_header

  # Detect OS
  local os=$(detect_os)
  print_info "Detected OS: $os"

  # Install devbox (same for all OS)
  print_info ""
  print_info "Step 1/3: Installing devbox..."
  install_devbox || exit 1

  # Install direnv (OS-specific)
  print_info ""
  print_info "Step 2/3: Installing direnv..."
  case "$os" in
  macos)
    install_direnv_macos || exit 1
    ;;
  ubuntu | debian | pop | linuxmint)
    install_direnv_debian || exit 1
    ;;
  fedora | rhel | centos | rocky | alma)
    install_direnv_fedora || exit 1
    ;;
  arch | manjaro | endeavouros)
    install_direnv_arch || exit 1
    ;;
  nixos)
    # NixOS users should have direnv in their configuration
    if command_exists direnv; then
      print_success "direnv is already installed ($(direnv version 2>/dev/null || echo 'version unknown'))"
    else
      print_warning "NixOS detected - direnv should be installed via your system configuration"
      print_info "Add to your configuration.nix:"
      print_info "  environment.systemPackages = with pkgs; [ direnv ];"
      print_info "  programs.direnv.enable = true;"
      print_info ""
      print_info "Or install in your user profile: nix-env -iA nixos.direnv"
      exit 1
    fi
    ;;
  *)
    print_error "Unsupported OS: $os"
    print_info "Please install direnv manually: https://direnv.net/docs/installation.html"
    exit 1
    ;;
  esac

  # Configure direnv hook
  print_info ""
  print_info "Step 3/3: Configuring direnv shell hook..."
  configure_direnv_hook

  # Summary
  echo ""
  print_header
  print_success "Installation complete!"
  echo ""
  print_info "Next steps:"
  echo "  1. Restart your shell or run: source $(get_shell_config $(detect_shell))"
  echo "  2. Navigate to the project directory"
  echo "  3. Run: direnv allow"
  echo "     (This allows direnv to automatically load the environment)"
  echo "  4. Edit .env with your credentials"
  echo ""
  print_warning "Note: With direnv configured, you DON'T need to run 'devbox shell'!"
  print_info "      The environment activates automatically when you cd into the directory."
  echo ""
}

# Run main function
main "$@"
