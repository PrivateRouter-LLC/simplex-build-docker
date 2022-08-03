FROM ubuntu:22.04

# ARG is used instead of ENV since these are never used outside of initial build
ARG TARGETARCH
ARG DEBIAN_FRONTEND=noninteractive

# Separate the packages used for install and runtime
ARG PACKAGES="tini libnuma1 openssl ca-certificates"
ARG EXTRA_PACKAGES="curl jq"

# We work from root
WORKDIR /

# Do our magic to install packages, download, and install our smp-server binary - then cleanup
RUN apt update \
    && apt install -y --no-install-recommends ${PACKAGES} ${EXTRA_PACKAGES} \
    && TARBALL_NAME=simplexmq-linux_${TARGETARCH}.tar.gz \
    && DOWNLOAD_URL=$(curl -sL https://api.github.com/repos/PrivateRouter-LLC/simplex-releases/releases/latest \
	    | jq -r '.assets[].browser_download_url' \
        | grep -F -e ${TARBALL_NAME}) \
    && curl -sL ${DOWNLOAD_URL} -o ${TARBALL_NAME} \
    && tar xvfz ${TARBALL_NAME} -C /usr/bin \
    && rm ${TARBALL_NAME} \
    && apt autoremove -y \
    && apt remove --purge -y $EXTRA_PACKAGES \
    && rm -rf /var/lib/apt/lists/*

# Add our entrypoint script to the container and set it executable
COPY ./entrypoint /usr/bin/entrypoint
RUN chmod +x /usr/bin/entrypoint

# Tell Docker we listen on 5223
EXPOSE 5223

# Allows our container to intercept stop requests
STOPSIGNAL SIGINT

# You can (AND SHOULD) use these volumes in your container for persistence
VOLUME [ "/etc/opt/simplex", "/var/opt/simplex" ]

# Our Docker entrypoint script
ENTRYPOINT ["tini", "--", "entrypoint"]


