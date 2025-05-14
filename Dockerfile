# Single-container Slurm and ssh container for ci/cd testing of Slurm interface
#
# Copyright (c) 2025  Manuel G. Marciani
# BSC-CNS - Earth Sciences

FROM debian:stable-slim

LABEL org.opencontainers.image.source="https://github.com/manuel-g-castro/slurm-cluster-openssh-docker/" \
      org.opencontainers.image.title="slurm-cluster-openssh-docker" \
      org.opencontainers.image.description="Slurm Docker cluster on Debian Slim with an OpenSSH server" 

# install openssh server 

RUN apt-get update \
    && apt-get --no-install-recommends -y install make \
    automake \ 
    autoconf \
    gcc \
    g++ \
    libcurl4 \
    debianutils \
    libglib2.0-dev \
    libgtk2.0-dev \
    mariadb-server \
    mariadb-client \
    libmariadbd-dev \
    libpam0g-dev \
    gpg \
    gpg-agent \
    git \
    wget \
    bzip2 \
    libtool \
    libncurses-dev \
    libgdm1 \
    zlib1g-dev \
    zlib1g \
    pip \
    locales \
    openssh-server \
    dirmngr \
    munge \
    libmunge2 \
    libmunge-dev \
    && rm -rf /tmp/* $HOME/.cache /var/lib/apt/lists/*

ARG SLURM_TAG

RUN git clone -b ${SLURM_TAG} --single-branch --depth=1 https://github.com/SchedMD/slurm.git \
    && cd slurm \
    && ./configure --enable-debug --prefix=/usr --sysconfdir=/etc/slurm \
        --with-mysql_config=/usr/bin  --libdir=/usr/lib64 \
    && make install \
    && install -D -m644 etc/cgroup.conf.example /etc/slurm/cgroup.conf.example \
    && install -D -m644 etc/slurm.conf.example /etc/slurm/slurm.conf.example \
    && install -D -m644 etc/slurmdbd.conf.example /etc/slurm/slurmdbd.conf.example \
    && install -D -m644 contribs/slurm_completion_help/slurm_completion.sh /etc/profile.d/slurm_completion.sh \
    && cd .. \
    && rm -rf slurm 

# manuel: set the username for the run script
ENV USERNAME root

RUN mkdir -p /etc/sysconfig/slurm \
        /var/spool/slurmd \
        /var/run/slurmd \
        /var/run/slurmdbd \
        /var/lib/slurmd \
        /var/log/slurm \
        /data \
    && touch /var/lib/slurmd/node_state \
        /var/lib/slurmd/front_end_state \
        /var/lib/slurmd/job_state \
        /var/lib/slurmd/resv_state \
        /var/lib/slurmd/trigger_state \
        /var/lib/slurmd/assoc_mgr_state \
        /var/lib/slurmd/assoc_usage \
        /var/lib/slurmd/qos_usage \
        /var/lib/slurmd/fed_mgr_state 

RUN ssh-keygen -q -t rsa -N '' -f /root/.ssh/container_root_pubkey

# setup login to ssh
RUN mkdir -p /root/.ssh/ \
    && cat /root/.ssh/container_root_pubkey.pub >> /root/.ssh/authorized_keys \
    && chmod -R 700 /root/.ssh/ \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/g' /etc/ssh/sshd_config \
    && echo 'Port=2222' >> /etc/ssh/sshd_config \
    && echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config

# ssh setup https://askubuntu.com/questions/1110828/ssh-failed-to-start-missing-privilege-separation-directory-var-run-sshd
RUN mkdir /var/run/sshd \
    && chmod 0755 /var/run/sshd

# Set the locale. Taken from http://jaredmarkell.com/docker-and-locales/

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen \
    && locale-gen

ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  
ENV LC_ALL en_US.UTF-8    

# Add Tini. (manuel: a lightweight init, systemd, etc)

ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

COPY slurm.conf /etc/slurm/slurm.conf
COPY slurmdbd.conf /etc/slurm/slurmdbd.conf
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN chmod 600 /etc/slurm/slurm.conf /etc/slurm/slurmdbd.conf

EXPOSE 2222

CMD ["/tini", "--", "/usr/local/bin/docker-entrypoint.sh"]

