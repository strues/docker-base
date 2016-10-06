FROM debian:jessie
MAINTAINER Steven Truesdell <steven@strues.io>

ENV TERM="linux" \
    DEBIAN_FRONTEND="noninteractive" \
    APT_SPEEDUP="/etc/dpkg/dpkg.cfg.d/docker-apt-speedup" \
    GOSU_VERSION=1.9 \
    TIME_ZONE="America/Denver"


RUN \
    apt-get update \
    && DEBIAN_FRONTEND=noninteractive \
    && echo "en_US ISO-8859-1" >/etc/locale.gen \
    && echo "en_US.UTF-8 UTF-8" >>/etc/locale.gen \
    && [ -z "$TIME_ZONE" ]  ||  echo "$TIME_ZONE" > /etc/timezone  ||  dpkg-reconfigure -f noninteractive tzdata \
    ## Temporarily disable dpkg fsync to make building faster.
    && [ -z "$APT_SPEEDUP" ]  ||  echo force-unsafe-io > "$APT_SPEEDUP" \
    && apt-get update \
    # So many things require a correct locale, we might as well install it
    && apt-get install -y --no-install-recommends wget ca-certificates locales \
    && dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true \
    && rm -rf /usr/share/doc/* /usr/share/man/man*/* \
    && apt-get clean -y \
    && apt-get purge -y wget ca-certificates \
    && apt-get autoremove -y \
    && rm -rf /var/cache/debconf/*-old \
    && rm -rf /var/lib/apt/lists/*


# Configure executable.
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
