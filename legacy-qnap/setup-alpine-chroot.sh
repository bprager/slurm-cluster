#!/bin/bash

# Alpine Linux chroot environment for legacy QNAP
# Alternative method for running Slurm on legacy QNAP systems

set -e

CHROOT_DIR="/share/alpine-chroot"
ALPINE_VERSION="3.18"

echo "=== Setting up Alpine Linux chroot for Slurm ==="

# Create chroot directory
mkdir -p $CHROOT_DIR

# Download Alpine Linux mini root filesystem
cd $CHROOT_DIR
wget https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/releases/armv7/alpine-minirootfs-${ALPINE_VERSION}.0-armv7.tar.gz

# Extract Alpine
tar -xzf alpine-minirootfs-${ALPINE_VERSION}.0-armv7.tar.gz
rm alpine-minirootfs-${ALPINE_VERSION}.0-armv7.tar.gz

# Setup basic chroot environment
cat > enter-chroot.sh << 'EOF'
#!/bin/bash

CHROOT_DIR="/share/alpine-chroot"

# Mount necessary filesystems
mount -t proc proc $CHROOT_DIR/proc
mount -t sysfs sysfs $CHROOT_DIR/sys
mount -o bind /dev $CHROOT_DIR/dev
mount -o bind /dev/pts $CHROOT_DIR/dev/pts

# Copy DNS configuration
cp /etc/resolv.conf $CHROOT_DIR/etc/

# Enter chroot
chroot $CHROOT_DIR /bin/sh
EOF

chmod +x enter-chroot.sh

# Create Slurm installation script for Alpine
cat > $CHROOT_DIR/install-slurm.sh << 'EOF'
#!/bin/sh

# Update Alpine packages
apk update

# Install dependencies
apk add \
    build-base \
    autoconf \
    automake \
    libtool \
    pkgconfig \
    openssl-dev \
    zlib-dev \
    mysql-dev \
    python3 \
    python3-dev \
    wget \
    curl \
    bash \
    shadow

# Install munge
cd /tmp
wget https://github.com/dun/munge/releases/download/munge-0.5.15/munge-0.5.15.tar.xz
tar -xf munge-0.5.15.tar.xz
cd munge-0.5.15
./configure --prefix=/usr
make && make install

# Create munge user
adduser -D -s /bin/sh munge
mkdir -p /etc/munge /var/lib/munge /var/log/munge /var/run/munge
chown munge:munge /etc/munge /var/lib/munge /var/log/munge /var/run/munge
chmod 0700 /etc/munge /var/lib/munge /var/log/munge
chmod 755 /var/run/munge

# Download and build Slurm
cd /tmp
SLURM_VERSION="23.11.7"
wget https://download.schedmd.com/slurm/slurm-${SLURM_VERSION}.tar.bz2
tar -xf slurm-${SLURM_VERSION}.tar.bz2
cd slurm-${SLURM_VERSION}

# Configure and build Slurm
./configure \
    --prefix=/usr \
    --sysconfdir=/etc/slurm \
    --with-munge \
    --with-mysql_config=/usr/bin/mysql_config

make -j$(nproc)
make install

# Create slurm user
adduser -D -s /bin/sh slurm

# Create directories
mkdir -p /var/spool/slurm /var/log/slurm /etc/slurm
chown slurm:slurm /var/spool/slurm /var/log/slurm

echo "Slurm installed in Alpine chroot environment"
EOF

chmod +x $CHROOT_DIR/install-slurm.sh

# Create startup script
cat > start-slurm-chroot.sh << 'EOF'
#!/bin/bash

CHROOT_DIR="/share/alpine-chroot"

# Enter chroot and start services
chroot $CHROOT_DIR /bin/sh -c "
    # Start munge
    /usr/sbin/munged

    # Start slurmd
    /usr/sbin/slurmd -D
"
EOF

chmod +x start-slurm-chroot.sh

echo "=== Alpine chroot setup complete ==="
echo "1. Run ./enter-chroot.sh to enter the Alpine environment"
echo "2. Inside chroot, run /install-slurm.sh to install Slurm"
echo "3. Copy configuration files to /etc/slurm and /etc/munge"
echo "4. Use ./start-slurm-chroot.sh to start Slurm services"
