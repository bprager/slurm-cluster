FROM rockylinux:8

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies (matching giovtorres approach)
RUN set -ex \
    && yum makecache \
    && yum -y update \
    && yum -y install dnf-plugins-core \
    && yum config-manager --set-enabled powertools \
    && yum -y install \
       wget \
       bzip2 \
       perl \
       gcc \
       gcc-c++\
       git \
       gnupg \
       make \
       munge \
       munge-devel \
       python3-devel \
       python3-pip \
       python3 \
       mariadb-server \
       mariadb-devel \
       psmisc \
       bash-completion \
       vim-enhanced \
       http-parser-devel \
       json-c-devel \
       hwloc-devel \
       rrdtool-devel \
       freeipmi-devel \
       lua-devel \
       readline-devel \
       openssl-devel \
       yaml-cpp-devel \
    && yum clean all \
    && rm -rf /var/cache/yum

RUN alternatives --set python /usr/bin/python3

RUN pip3 install Cython pytest

# Download and install Slurm
ARG SLURM_VERSION=22.05.9
RUN cd /tmp && \
    wget https://download.schedmd.com/slurm/slurm-${SLURM_VERSION}.tar.bz2 && \
    tar xjf slurm-${SLURM_VERSION}.tar.bz2 && \
    cd slurm-${SLURM_VERSION} && \
    ./configure \
        --enable-debug \
        --prefix=/usr \
        --sysconfdir=/etc/slurm \
        --with-mysql_config=/usr/bin \
        --libdir=/usr/lib64 && \
    make install && \
    install -D -m644 etc/cgroup.conf.example /etc/slurm/cgroup.conf.example && \
    install -D -m644 etc/slurm.conf.example /etc/slurm/slurm.conf.example && \
    install -D -m644 etc/slurmdbd.conf.example /etc/slurm/slurmdbd.conf.example && \
    cd / && rm -rf /tmp/slurm-${SLURM_VERSION}*

# Debug: Check if cgroup plugins were built and installed
RUN echo "=== Checking Slurm plugin installation ===" && \
    find /usr/local -name "*cgroup*" -type f && \
    echo "=== Checking plugin directories ===" && \
    ls -la /usr/local/lib/slurm/ || echo "No /usr/local/lib/slurm/ directory" && \
    echo "=== Checking for specific cgroup plugins ===" && \
    find /usr/local -name "proctrack_cgroup*" && \
    find /usr/local -name "task_cgroup*" && \
    find /usr/local -name "jobacct_gather_cgroup*" && \
    echo "=== Plugin installation complete ==="

# Create slurm user and directories
RUN groupadd -r --gid=990 slurm && \
    useradd -r -g slurm --uid=990 slurm && \
    mkdir /etc/sysconfig/slurm \
        /var/spool/slurmd \
        /var/run/slurmd \
        /var/run/slurmdbd \
        /var/lib/slurmd \
        /var/log/slurm \
        /data && \
    touch /var/lib/slurmd/node_state \
        /var/lib/slurmd/front_end_state \
        /var/lib/slurmd/job_state \
        /var/lib/slurmd/resv_state \
        /var/lib/slurmd/trigger_state \
        /var/lib/slurmd/assoc_mgr_state \
        /var/lib/slurmd/assoc_usage \
        /var/lib/slurmd/qos_usage \
        /var/lib/slurmd/fed_mgr_state && \
    chown -R slurm:slurm /var/*/slurm* && \
    /sbin/create-munge-key

# Add Slurm binaries to PATH
ENV PATH="/usr/bin:/usr/sbin:$PATH"
ENV SLURM_PLUGIN_PATH="/usr/lib64/slurm"

# Copy entrypoint script
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose ports
EXPOSE 6817 6818 6819

# Create logs directory
RUN mkdir -p /var/log/slurm && chown slurm:slurm /var/log/slurm

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
