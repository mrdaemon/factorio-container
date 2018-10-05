FROM debian:9-slim

LABEL maintainer="Alexandre Gauthier <alex@lab.underwares.org>" \
    description="Factorio Server"

ARG VERSION="0.16.51"
ARG SHA256="6cb09f5ac87f16f8d5b43cef26c0ae26cc46a57a0382e253dfda032dc5bb367f"
ARG URL="https://www.factorio.com/get-download/${VERSION}/headless/linux64"

ENV FACTORIO_HOME /opt/factorio
ENV FACTORIO_PORT 34197
ENV FACTORIO_RCON_PORT 27015
ENV FACTORIO_SAVESDIR ${FACTORIO_HOME}/saves
ENV FACTORIO_CONFIGDIR ${FACTORIO_HOME}/config
ENV FACTORIO_MODSDIR ${FACTORIO_HOME}/mods

# Create runtime directories
RUN mkdir -p /opt/factorio/{saves,config,mods}

WORKDIR /opt/factorio

# Install runtime dependencies
RUN apt-get update && apt-get install --no-install-recommends -y \
    curl ca-certificates xz-utils pwgen && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && rm -rf /tmp/* && rm -rf /var/tmp/*

# Download, verify and extract headless server archive 
RUN curl -L $URL -o /tmp/archive_${VERSION}.txz && \
    echo "${SHA256}  /tmp/archive_${VERSION}.txz" | sha256sum -c - && \
    tar xvJf /tmp/archive_${VERSION}.txz -C /opt && \
    rm -f /tmp/archive_${VERSION}.txz

COPY scripts/run.sh .
RUN chmod +x ./run.sh

VOLUME [${FACTORIO_SAVESDIR}, ${FACTORIO_MODSDIR}, ${FACTORIO_CONFIGDIR}]

EXPOSE ${FACTORIO_PORT}/udp ${FACTORIO_RCON_PORT}/tcp

ENTRYPOINT [ "/opt/factorio/run.sh" ]
