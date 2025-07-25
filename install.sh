#!/bin/bash

set -e

# --- Configuration ---
GITHUB_REPO="webwizards-team/Phantom-Tunnel"
ASSET_NAME="phantom"
EXECUTABLE_NAME="phantom"
INSTALL_PATH="/usr/local/bin"
SERVICE_NAME="phantom.service"
WORKING_DIR="/etc/phantom"
VERSION_FILE="${WORKING_DIR}/VERSION"
# ----------------------

print_info() { echo -e "\e[34m[INFO]\e[0m $1"; }
print_success() { echo -e "\e[32m[SUCCESS]\e[0m $1"; }
print_error() { echo -e "\e[31m[ERROR]\e[0m $1" >&2; exit 1; }

print_info "Starting Phantom Tunnel Installation..."

# --- Root Check ---
if [ "$(id -u)" -ne 0 ]; then
  print_error "This script must be run as root. Please use 'sudo'."
fi

# --- Dependency Check ---
print_info "Checking for curl..."
if command -v apt-get &> /dev/null; then
    apt-get update -y > /dev/null && apt-get install -y curl
elif command -v yum &> /dev/null; then
    yum install -y curl
else
    print_error "Unsupported package manager. Please install 'curl' manually."
fi

# --- Architecture Check ---
ARCH=$(uname -m)
case "$ARCH" in
  x86_64|amd64) ARCH_TAG="amd64" ;;
  aarch64|arm64) ARCH_TAG="arm64" ;;
  *) print_error "Unsupported architecture: $ARCH" ;;
esac

# --- Get Latest Version ---
print_info "Fetching latest version info from GitHub..."
LATEST_VERSION=$(curl -s "https://api.github.com/repos/${GITHUB_REPO}/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')
[ -z "$LATEST_VERSION" ] && print_error "Unable to fetch latest version tag."

DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/download/${LATEST_VERSION}/${ASSET_NAME}"

print_info "Latest version detected: ${LATEST_VERSION}"
print_info "Downloading from: ${DOWNLOAD_URL}"

# --- Overwrite Check ---
if [ -f "${INSTALL_PATH}/${EXECUTABLE_NAME}" ]; then
  print_info "Existing installation detected at ${INSTALL_PATH}/${EXECUTABLE_NAME}."
  read -p "Do you want to overwrite it? [y/N]: " confirm
  [[ "$confirm" != "y" && "$confirm" != "Y" ]] && print_info "Installation aborted." && exit 0
fi

# --- Download ---
TMP_DIR=$(mktemp -d); trap 'rm -rf -- "$TMP_DIR"' EXIT; cd "$TMP_DIR"
if ! curl -sSLf -o "$EXECUTABLE_NAME" "$DOWNLOAD_URL"; then
    print_error "Download failed. Please check the GitHub release or asset name."
fi

# --- Install ---
print_info "Installing binary to ${INSTALL_PATH}..."
mkdir -p "$WORKING_DIR"
mv "$EXECUTABLE_NAME" "$INSTALL_PATH/"
chmod +x "$INSTALL_PATH/$EXECUTABLE_NAME"
ln -sf "${INSTALL_PATH}/${EXECUTABLE_NAME}" /usr/local/bin/phantom-panel
echo "$LATEST_VERSION" > "$VERSION_FILE"
print_success "Binary installed and version saved."

# --- Systemd Service ---
print_info "Creating systemd service..."
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}"
cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Phantom Tunnel Panel Service
After=network-online.target
Wants=network-online.target

[Service]
ExecStartPre=/bin/sleep 10
ExecStart=${INSTALL_PATH}/${EXECUTABLE_NAME} --start-panel
WorkingDirectory=${WORKING_DIR}
Restart=always
RestartSec=5
LimitNOFILE=65536
User=root
Group=root
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

if ! systemctl daemon-reload; then
    print_error "Systemd reload failed."
fi

print_success "Service file created at ${SERVICE_FILE}"

# --- Prompt for Panel Port (for firewall) ---
read -p "Enter the panel port you plan to use (e.g. 8080): " PANEL_PORT

# --- Open Firewall Port ---
if command -v firewall-cmd &> /dev/null; then
    print_info "firewalld detected. Adding port ${PANEL_PORT}/tcp..."
    firewall-cmd --permanent --add-port=${PANEL_PORT}/tcp
    firewall-cmd --reload
    print_success "Firewall port ${PANEL_PORT} opened."
fi

# --- Final Instructions ---
echo ""
print_success "Installation complete!"
echo "--------------------------------------------------"
echo -e "\e[31m[IMPORTANT]\e[0m You must now perform the initial setup."
echo ""
print_info "1. Navigate to the working directory:"
echo "   cd ${WORKING_DIR}"
echo ""
print_info "2. Run the interactive setup to create credentials and set the panel port:"
echo "   sudo ${INSTALL_PATH}/${EXECUTABLE_NAME}"
echo ""
print_info "3. After setting the port, you can enable and start the service to run in the background:"
echo "   sudo systemctl enable --now ${SERVICE_NAME}"
echo ""
print_info "After that, you can manage the service with:"
echo "   sudo systemctl status ${SERVICE_NAME}"
echo "   sudo systemctl stop ${SERVICE_NAME}"
echo ""
echo -e "\e[32mYour panel should be accessible at: \e[4mhttp://<your-server-ip>:${PANEL_PORT}\e[0m"
echo "--------------------------------------------------"

exit 0
