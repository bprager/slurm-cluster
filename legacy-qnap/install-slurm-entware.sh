#!/bin/bash

# Legacy QNAP Slurm Installation Script
# For QNAP devices running QTS 3.4.6 without Docker support

set -e

echo "=== Legacy QNAP Slurm Setup ==="
echo "This script will install Slurm on legacy QNAP via Entware"

# Check if running on QNAP
if [ ! -f /etc/config/qpkg.conf ]; then
    echo "Error: This script is designed for QNAP systems"
    exit 1
fi

# Install Entware if not present
if [ ! -d /opt ]; then
    echo "Installing Entware..."
    # Download and install Entware
    wget -O - http://bin.entware.net/armv7sf-k3.2/installer/generic.sh | sh
fi

# Update Entware packages
echo "Updating Entware packages..."
/opt/bin/opkg update

# Install required packages
echo "Installing dependencies..."
/opt/bin/opkg install \
    gcc \
    make \
    autoconf \
    automake \
    libtool \
    pkgconf \
    zlib-dev \
    openssl-dev \
    mysql-dev \
    python3 \
    python3-dev \
    wget \
    curl \
    git

# Install munge
echo "Installing munge..."
cd /tmp
wget https://github.com/dun/munge/releases/download/munge-0.5.15/munge-0.5.15.tar.xz
tar -xf munge-0.5.15.tar.xz
cd munge-0.5.15
./configure --prefix=/opt
make && make install

# Create munge user and setup
adduser -D -s /bin/sh munge
mkdir -p /opt/etc/munge /opt/var/lib/munge /opt/var/log/munge /opt/var/run/munge
chown munge:munge /opt/etc/munge /opt/var/lib/munge /opt/var/log/munge /opt/var/run/munge
chmod 0700 /opt/etc/munge /opt/var/lib/munge /opt/var/log/munge
chmod 755 /opt/var/run/munge

# Download and build Slurm
echo "Downloading and building Slurm..."
cd /tmp
SLURM_VERSION="23.11.7"
wget https://download.schedmd.com/slurm/slurm-${SLURM_VERSION}.tar.bz2
tar -xf slurm-${SLURM_VERSION}.tar.bz2
cd slurm-${SLURM_VERSION}

# Configure Slurm build
./configure \
    --prefix=/opt \
    --sysconfdir=/opt/etc/slurm \
    --with-munge=/opt \
    --with-mysql_config=/opt/bin/mysql_config \
    --enable-pam \
    --without-gtk2

# Build and install
make -j$(nproc)
make install

# Create slurm user
adduser -D -s /bin/sh slurm

# Create necessary directories
mkdir -p /opt/var/spool/slurm /opt/var/log/slurm /opt/etc/slurm
chown slurm:slurm /opt/var/spool/slurm /opt/var/log/slurm

# Copy configuration files from shared location
if [ -f /share/slurm/slurm.conf ]; then
    cp /share/slurm/slurm.conf /opt/etc/slurm/
    cp /share/slurm/munge.key /opt/etc/munge/
    chown munge:munge /opt/etc/munge/munge.key
    chmod 400 /opt/etc/munge/munge.key
else
    echo "Warning: Configuration files not found in /share/slurm/"
    echo "Please copy slurm.conf and munge.key manually"
fi

# Create startup scripts
cat > /opt/etc/init.d/S90slurm << 'EOF'
#!/bin/sh

DAEMON="slurmd"
PIDFILE="/opt/var/run/slurmd.pid"

start() {
    echo "Starting munge..."
    /opt/sbin/munged
    sleep 2

    echo "Starting $DAEMON..."
    /opt/sbin/slurmd -D &
    echo $! > $PIDFILE
}

stop() {
    echo "Stopping $DAEMON..."
    if [ -f $PIDFILE ]; then
        kill $(cat $PIDFILE)
        rm -f $PIDFILE
    fi
    killall munged 2>/dev/null || true
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        sleep 1
        start
        ;;
    *)
        echo "Usage: $0 {start|stop|restart}"
        exit 1
esac
EOF

chmod +x /opt/etc/init.d/S90slurm

echo "=== Installation Complete ==="
echo "1. Copy slurm.conf and munge.key to /opt/etc/slurm/ and /opt/etc/munge/"
echo "2. Configure node-specific settings in slurm.conf"
echo "3. Start services: /opt/etc/init.d/S90slurm start"
