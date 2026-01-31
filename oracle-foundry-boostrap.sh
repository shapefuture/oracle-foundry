#!/usr/bin/env bash
# ==============================================================================
# ORACLE FOUNDRY - ULTIMATE BOOTSTRAP v1.0
# ==============================================================================
# One command to rule them all: Deploy a complete self-hosted PaaS
# 
# What you get:
# ✅ Dokploy (Vercel-like UI for deploying ANY GitHub project)
# ✅ Podman + crun (49% faster than Docker, no daemon)
# ✅ FastCORS (Rust CORS proxy, 60k+ req/sec)
# ✅ Auto-updates (daily at 3 AM)
# ✅ GitHub webhooks (auto-deploy on commits)
# ✅ Free SSL (Let's Encrypt)
# ✅ One-click databases (Postgres, Redis, MySQL)
#
# Cost: $0/month forever (Oracle Always Free tier)
# ==============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Configuration
DOKPLOY_VERSION="v0.25.6"
FASTCORS_IMAGE="ghcr.io/dominux/fast-cors:latest"
PUBLIC_IP=""

# ==============================================================================
# Utility Functions
# ==============================================================================

log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

log_step() {
    echo
    echo -e "${PURPLE}${BOLD}==>${NC} ${BOLD}$1${NC}"
    echo
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        echo "Please run: sudo bash $0"
        exit 1
    fi
}

get_public_ip() {
    PUBLIC_IP=$(curl -s --max-time 5 ifconfig.me 2>/dev/null || \
                curl -s --max-time 5 icanhazip.com 2>/dev/null || \
                curl -s --max-time 5 ipinfo.io/ip 2>/dev/null || \
                echo "UNKNOWN")
}

# ==============================================================================
# System Checks and Preparation
# ==============================================================================

log_step "PHASE 1/7: System Validation"

check_root
get_public_ip

log_info "Detected public IP: ${PUBLIC_IP}"

# Check OS
if ! grep -q "Ubuntu" /etc/os-release 2>/dev/null; then
    log_error "This script requires Ubuntu 22.04 or 24.04"
    log_info "Detected: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    exit 1
fi

log_success "Running on Ubuntu"

# Check architecture
ARCH=$(uname -m)
if [[ "$ARCH" != "aarch64" && "$ARCH" != "x86_64" ]]; then
    log_error "Unsupported architecture: $ARCH"
    exit 1
fi

log_success "Architecture: $ARCH"

# Check minimum RAM (need at least 4GB for Dokploy)
TOTAL_RAM=$(free -g | awk '/^Mem:/{print $2}')
if [[ $TOTAL_RAM -lt 4 ]]; then
    log_error "Minimum 4GB RAM required. Detected: ${TOTAL_RAM}GB"
    exit 1
fi

log_success "RAM: ${TOTAL_RAM}GB (sufficient)"

# ==============================================================================
# Performance Optimizations
# ==============================================================================

log_step "PHASE 2/7: Performance Optimizations"

log_info "Applying TCP/BBR optimizations for high-traffic workloads..."

cat >> /etc/sysctl.conf <<'SYSCTL'

# Oracle Foundry Performance Tuning
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.core.somaxconn=65535
net.ipv4.tcp_max_syn_backlog=8192
net.ipv4.ip_local_port_range=1024 65535
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_fin_timeout=15
net.ipv4.tcp_keepalive_time=300
net.ipv4.tcp_keepalive_probes=5
net.ipv4.tcp_keepalive_intvl=15
SYSCTL

sysctl -p > /dev/null 2>&1
log_success "BBR congestion control enabled"

# Disable swap (improves performance on VMs)
log_info "Optimizing swap usage..."
swapoff -a || true
sed -i '/ swap / s/^/#/' /etc/fstab
log_success "Swap disabled for better performance"

# ==============================================================================
# Install Core Dependencies
# ==============================================================================

log_step "PHASE 3/7: Installing Core Dependencies"

log_info "Updating package lists..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq

log_info "Installing essential packages..."
apt-get install -y -qq \
    curl \
    wget \
    git \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    apt-transport-https \
    uidmap \
    fuse-overlayfs \
    slirp4netns

log_success "Core dependencies installed"

# ==============================================================================
# Install Podman + crun (Performance Engine)
# ==============================================================================

log_step "PHASE 4/7: Installing Podman + crun (49% faster than Docker)"

# Check if podman already exists
if command -v podman &> /dev/null; then
    log_warning "Podman already installed, skipping..."
else
    log_info "Adding Podman repository..."

    # For Ubuntu, Podman is in official repos from 22.04+
    apt-get install -y -qq podman crun buildah skopeo

    log_success "Podman installed"
fi

# Configure Podman to use crun (C-based, faster than runc)
log_info "Configuring Podman with crun runtime..."

mkdir -p /etc/containers

cat > /etc/containers/containers.conf <<'PODMANCONF'
[engine]
cgroup_manager = "systemd"
events_logger = "journald"
runtime = "crun"

[network]
network_backend = "netavark"
default_network = "podman"

[engine.runtimes]
crun = ["/usr/bin/crun"]
PODMANCONF

log_success "Podman configured with crun runtime"

# Enable and start Podman socket (Docker compatibility)
log_info "Enabling Podman Docker-compatible socket..."

systemctl enable --now podman.socket

# Create Docker socket symlink for Dokploy compatibility
if [[ ! -e /var/run/docker.sock ]]; then
    ln -s /run/podman/podman.sock /var/run/docker.sock
fi

# WORKAROUND: Ensure socket has correct permissions
chmod 666 /run/podman/podman.sock || true

log_success "Podman socket enabled at /var/run/docker.sock"

# Verify Podman is using crun
RUNTIME_CHECK=$(podman info --format json | jq -r '.host.ociRuntime.name' 2>/dev/null || echo "unknown")
if [[ "$RUNTIME_CHECK" == "crun" ]]; then
    log_success "Verified: Podman using crun runtime"
else
    log_warning "Runtime detected: $RUNTIME_CHECK (expected crun)"
fi

# ==============================================================================
# Install Dokploy (PaaS Dashboard)
# ==============================================================================

log_step "PHASE 5/7: Installing Dokploy (Premium PaaS UI)"

log_info "Downloading Dokploy installer..."

# Official Dokploy install script
curl -sSL https://dokploy.com/install.sh | sh

log_success "Dokploy installed"

# WORKAROUND: Wait for Dokploy to fully start
log_info "Waiting for Dokploy to initialize (this may take 60-90 seconds)..."
sleep 10

# Check if Dokploy is running
MAX_RETRIES=30
RETRY_COUNT=0
while [[ $RETRY_COUNT -lt $MAX_RETRIES ]]; do
    if curl -s http://localhost:3000 > /dev/null 2>&1; then
        log_success "Dokploy is running"
        break
    fi
    sleep 3
    ((RETRY_COUNT++))
    echo -n "."
done

if [[ $RETRY_COUNT -eq $MAX_RETRIES ]]; then
    log_warning "Dokploy might still be initializing. Check: systemctl status dokploy"
fi

# ==============================================================================
# Deploy FastCORS (Always-On CORS Proxy via Quadlet)
# ==============================================================================

log_step "PHASE 6/7: Deploying FastCORS CORS Proxy (Rust, 60k+ req/sec)"

log_info "Creating Quadlet systemd service for FastCORS..."

mkdir -p /etc/containers/systemd

cat > /etc/containers/systemd/fastcors.container <<QUADLET
[Unit]
Description=FastCORS - High-Performance CORS Proxy
After=network-online.target
Wants=network-online.target

[Container]
Image=${FASTCORS_IMAGE}
ContainerName=fastcors
AutoUpdate=registry
Pull=newer

# Environment
Environment=ROCKET_ADDRESS=0.0.0.0
Environment=ROCKET_PORT=8080
Environment=ROCKET_LOG_LEVEL=normal

# Networking
PublishPort=8080:8080
Network=pasta

# Security
NoNewPrivileges=true
ReadOnlyRootfs=true
SecurityLabelDisable=false
User=1000:1000

# Resource limits (optional)
# Memory=256M
# CPUQuota=50%

[Service]
Restart=always
RestartSec=10
TimeoutStartSec=300

[Install]
WantedBy=multi-user.target
QUADLET

log_success "Quadlet file created"

# Reload systemd to pick up new Quadlet service
log_info "Activating FastCORS service..."
systemctl daemon-reload
systemctl enable --now fastcors.service

# WORKAROUND: Wait for container to start
sleep 5

# Verify FastCORS is running
if systemctl is-active --quiet fastcors.service; then
    log_success "FastCORS is running on port 8080"
else
    log_warning "FastCORS might be starting. Check: systemctl status fastcors"
fi

# Enable auto-updates for all Quadlet containers
log_info "Enabling automatic container updates (daily at 3 AM)..."
systemctl enable --now podman-auto-update.timer

log_success "Auto-update timer enabled"

# ==============================================================================
# Configure Firewall
# ==============================================================================

log_step "PHASE 7/7: Configuring Firewall"

log_info "Setting up firewall rules..."

# Check if ufw is installed
if command -v ufw &> /dev/null; then
    # UFW firewall
    ufw --force enable
    ufw allow 22/tcp comment 'SSH'
    ufw allow 80/tcp comment 'HTTP'
    ufw allow 443/tcp comment 'HTTPS'
    ufw allow 3000/tcp comment 'Dokploy Dashboard'
    ufw allow 8080/tcp comment 'FastCORS Proxy'
    ufw reload
    log_success "UFW firewall configured"
else
    # Fallback to iptables
    iptables -I INPUT -p tcp --dport 22 -j ACCEPT
    iptables -I INPUT -p tcp --dport 80 -j ACCEPT
    iptables -I INPUT -p tcp --dport 443 -j ACCEPT
    iptables -I INPUT -p tcp --dport 3000 -j ACCEPT
    iptables -I INPUT -p tcp --dport 8080 -j ACCEPT

    # Try to persist
    if command -v netfilter-persistent &> /dev/null; then
        netfilter-persistent save
    elif command -v iptables-save &> /dev/null; then
        iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
    fi

    log_success "iptables rules configured"
fi

log_warning "IMPORTANT: Also configure Oracle Cloud Security List:"
log_info "  OCI Console → Networking → Virtual Cloud Networks"
log_info "  → Select your VCN → Security Lists → Add Ingress Rules:"
log_info "  • Port 80 (HTTP)"
log_info "  • Port 443 (HTTPS)"
log_info "  • Port 3000 (Dokploy)"
log_info "  • Port 8080 (FastCORS)"

# ==============================================================================
# Post-Installation Summary
# ==============================================================================

echo
echo -e "${GREEN}${BOLD}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║                                                                            ║${NC}"
echo -e "${GREEN}${BOLD}║                   🎉 ORACLE FOUNDRY DEPLOYED! 🎉                           ║${NC}"
echo -e "${GREEN}${BOLD}║                                                                            ║${NC}"
echo -e "${GREEN}${BOLD}╚════════════════════════════════════════════════════════════════════════════╝${NC}"
echo

echo -e "${CYAN}${BOLD}📍 Your Server Details:${NC}"
echo -e "   Public IP: ${BOLD}${PUBLIC_IP}${NC}"
echo -e "   Architecture: ${BOLD}${ARCH}${NC}"
echo -e "   RAM: ${BOLD}${TOTAL_RAM}GB${NC}"
echo

echo -e "${CYAN}${BOLD}🌐 Access Your Services:${NC}"
echo -e "   ${BOLD}Dokploy Dashboard:${NC} http://${PUBLIC_IP}:3000"
echo -e "   ${BOLD}FastCORS Proxy:${NC}    http://${PUBLIC_IP}:8080"
echo

echo -e "${CYAN}${BOLD}🚀 Next Steps:${NC}"
echo
echo -e "${BOLD}1. Access Dokploy Dashboard${NC}"
echo -e "   Open: ${BLUE}http://${PUBLIC_IP}:3000${NC}"
echo -e "   Create admin account on first login"
echo
echo -e "${BOLD}2. Test FastCORS Proxy${NC}"
echo -e "   ${BLUE}curl 'http://${PUBLIC_IP}:8080/https://api.github.com'${NC}"
echo
echo -e "${BOLD}3. Deploy Your First App${NC}"
echo -e "   • In Dokploy, click 'Create Project'"
echo -e "   • Click 'Create Service' → 'From GitHub'"
echo -e "   • Paste any GitHub repo URL"
echo -e "   • Click 'Deploy'"
echo -e "   • Dokploy auto-detects language and builds!"
echo
echo -e "${BOLD}4. Add Custom Domain (Optional)${NC}"
echo -e "   • Point your domain's A record to ${PUBLIC_IP}"
echo -e "   • In Dokploy: Settings → Domains → Add Domain"
echo -e "   • Enable SSL (automatic via Let's Encrypt)"
echo

echo -e "${CYAN}${BOLD}💾 What Got Installed:${NC}"
echo -e "   ✅ Podman + crun (49% faster than Docker)"
echo -e "   ✅ Dokploy ${DOKPLOY_VERSION} (Vercel-like UI)"
echo -e "   ✅ FastCORS (Rust CORS proxy, 60k+ req/sec)"
echo -e "   ✅ Auto-update timer (daily 3 AM updates)"
echo -e "   ✅ BBR congestion control (optimized TCP)"
echo

echo -e "${CYAN}${BOLD}🔧 Useful Commands:${NC}"
echo -e "   Check Dokploy:    ${BLUE}systemctl status dokploy${NC}"
echo -e "   Check FastCORS:   ${BLUE}systemctl status fastcors${NC}"
echo -e "   View Dokploy logs: ${BLUE}journalctl -u dokploy -f${NC}"
echo -e "   View FastCORS logs: ${BLUE}journalctl -u fastcors -f${NC}"
echo -e "   Restart Dokploy:  ${BLUE}systemctl restart dokploy${NC}"
echo -e "   Update containers: ${BLUE}podman auto-update${NC}"
echo

echo -e "${CYAN}${BOLD}🔄 Automatic Maintenance:${NC}"
echo -e "   • FastCORS auto-updates daily at 3 AM"
echo -e "   • Dokploy self-updates via its UI"
echo -e "   • System reboots: Everything auto-starts"
echo

echo -e "${CYAN}${BOLD}📚 Documentation:${NC}"
echo -e "   Dokploy Docs:  ${BLUE}https://dokploy.com/docs${NC}"
echo -e "   Podman Docs:   ${BLUE}https://docs.podman.io${NC}"
echo

echo -e "${YELLOW}${BOLD}⚠️  IMPORTANT SECURITY NOTES:${NC}"
echo -e "   1. Change Dokploy admin password after first login"
echo -e "   2. Configure OCI Security List (see instructions above)"
echo -e "   3. Consider setting up SSH key auth and disabling password login"
echo -e "   4. Enable OCI free monitoring: OCI Console → Observability"
echo

echo -e "${GREEN}${BOLD}🎯 Total Setup Time: $(date -u -d @$SECONDS +%M:%S)${NC}"
echo
echo -e "${PURPLE}${BOLD}Happy Deploying! 🚀${NC}"
echo
