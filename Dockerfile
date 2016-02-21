FROM debian:jessie
MAINTAINER Steven Truesdell <steven@strues.io>

ENV DEBIAN_FRONTEND noninteractive
ENV APT_SPEEDUP /etc/dpkg/dpkg.cfg.d/docker-apt-speedup
ENV APT_PROXY_FILE /etc/apt/apt.conf.d/90_apt-cacher_proxy
ENV TIME_ZONE America/Denver
ENV TERM linux
ENV INITRD no

RUN \
    echo "en_US ISO-8859-1" >/etc/locale.gen \
    && echo "en_US.UTF-8 UTF-8" >>/etc/locale.gen \
    && [ -z "$TIME_ZONE" ]  ||  echo "$TIME_ZONE" > /etc/timezone  ||  dpkg-reconfigure -f noninteractive tzdata \
    ## Temporarily disable dpkg fsync to make building faster.
    && [ -z "$APT_SPEEDUP" ]  ||  echo force-unsafe-io > "$APT_SPEEDUP" \
    ## Proxy when appropriate.
    && [ -z "$APT_PROXY_FILE" ]  ||  [ -z "$APT_PROXY" ]  ||  echo "Acquire::http::Proxy \"$APT_PROXY\";" > "$APT_PROXY_FILE" \
    ## Prevent initramfs updates from trying to run grub and lilo.
    ## https://journal.paul.querna.org/articles/2013/10/15/docker-ubuntu-on-rackspace/
    ## http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=594189
    && mkdir -p /etc/container_environment \
    && echo -n no > /etc/container_environment/INITRD \
    ## Replace the 'ischroot' tool to make it always return true.
    ## Prevent initscripts updates from breaking /dev/shm.
    ## https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=685034
    ## Yes, the bug is old, but part of the problem is broken callers :(
    && dpkg-divert --local --rename --add /usr/bin/ischroot \
    && ln -sf /bin/true /usr/bin/ischroot \
    && apt-get update \
    # So many things require a correct locale, we might as well install it
    && apt-get install locales less \
    && rm -rf /usr/share/doc/* /usr/share/man/man*/* \
    && if [ -z "$SSH_SERVER_DIR" ]; then rm -f /etc/ssh/ssh_host_*; \
    else cp /etc/ssh/sshd_config /etc/sshd_config.dpkg-dist ; rm -rf /etc/ssh ; ln -s "$SSH_SERVER_DIR" /etc/ssh; fi \
    && apt-get clean -y \
    && apt-get autoclean -y \
    && apt-get autoremove -y \
    && rm -rf /var/cache/debconf/*-old \
    && rm -rf /var/lib/apt/lists/*


# Configure executable.
ENTRYPOINT ["/bin/bash"]

# Define default command.
CMD []
