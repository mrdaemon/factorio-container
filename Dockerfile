# Intermediate staging container
FROM debian:11-slim AS staging

ARG VERSION="1.1.49"
ARG SHA256="3bdfd93d3149a0341257ee9638e6accbb59ce2e4082639d58ba6914ae20e8550"
ARG URL="https://www.factorio.com/get-download/${VERSION}/headless/linux64"

# Create staging directory
RUN mkdir -p /staging

# Install required dependencies for preparation
RUN apt-get update && apt-get install --no-install-recommends -y \
    curl ca-certificates xz-utils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && rm -rf /tmp/* && rm -rf /var/tmp/*

# Download, verify and extract headless server archive 
RUN curl -L $URL -o /tmp/archive_${VERSION}.txz && \
    echo "${SHA256}  /tmp/archive_${VERSION}.txz" | sha256sum -c - && \
    tar xvJf /tmp/archive_${VERSION}.txz -C /staging && \
    rm -f /tmp/archive_${VERSION}.txz

# Runtime image
FROM debian:11-slim

LABEL maintainer="Alexandre Gauthier <alex@lab.underwares.org>" \
    description="Factorio Server"

ENV FACTORIO_HOME /opt/factorio
ENV FACTORIO_VOLUME ${FACTORIO_HOME}/volume
ENV FACTORIO_CONFIGDIR ${FACTORIO_VOLUME}/config
ENV FACTORIO_SAVESDIR ${FACTORIO_VOLUME}/saves
ENV FACTORIO_MODSDIR ${FACTORIO_VOLUME}/mods
ENV FACTORIO_PORT 34197
ENV FACTORIO_RCON_PORT 27015

# Create runtime directories
RUN mkdir -p /opt/factorio/volume && mkdir -p /opt/factorio/config

WORKDIR /opt/factorio

# Install runtime dependencies
RUN apt-get update && apt-get install --no-install-recommends -y \
    pwgen && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && rm -rf /tmp/* && rm -rf /var/tmp/*

# Copy factorio binaries
COPY --from=staging /staging/factorio .

# Copy stock configuration for volume paths
COPY files/config.ini config/config.ini

# Copy wrapper script
COPY files/run.sh .
RUN chmod +x ./run.sh

VOLUME [${FACTORIO_VOLUME}]

EXPOSE ${FACTORIO_PORT}/udp ${FACTORIO_RCON_PORT}/tcp

ENTRYPOINT [ "/opt/factorio/run.sh" ]
