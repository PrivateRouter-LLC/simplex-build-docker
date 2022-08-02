FROM ubuntu:22.04

# ARG is used instead of ENV since these are never used outside of initial build
ARG TARGETARCH
ARG DEBIAN_FRONTEND=noninteractive

# Install the required packages to run SimpleXMQ
RUN apt update \
    && apt install -y libnuma1 openssl ca-certificates curl jq \
    && rm -rf /var/lib/apt/lists/*

# Download the current release from our release repo
WORKDIR /
RUN TARBALL_NAME=simplexmq-linux_${TARGETARCH}.tar.gz \
    && DOWNLOAD_URL=$(curl -sL https://api.github.com/repos/PrivateRouter-LLC/simplex-releases/releases/latest \
	    | jq -r '.assets[].browser_download_url' \
        | grep -F -e ${TARBALL_NAME}) \
    && curl -sL ${DOWNLOAD_URL} -o ${TARBALL_NAME} \
    && tar xvfz ${TARBALL_NAME} -C /usr/bin \
    && rm ${TARBALL_NAME}

# Add our entrypoint script to the container and set it executable
COPY ./entrypoint /entrypoint
RUN chmod +x /entrypoint

# Tell Docker we listen on 5223
EXPOSE 5223

# Support catching the SIGINT signal and shutting down the container
STOPSIGNAL SIGINT

# You can (AND SHOULD) use these volumes in your container for persistence
VOLUME [ "/etc/opt/simplex", "/var/opt/simplex" ]

# Our Docker entrypoint script
ENTRYPOINT [ "/entrypoint" ]


