FROM alpine:3.20

# Define the exact version anchor for predictability and caching
ARG VERAPDF_VERSION=1.30.2

# Install Java, download tools, unzip, and shell requirements
RUN apk update && apk add --no-cache \
    openjdk17-jre \
    wget \
    unzip \
    ca-certificates \
    bash

WORKDIR /opt

# Pull the pre-compiled standalone deployment archive directly, bypassing the installer engine
RUN wget https://github.com/veraPDF/veraPDF-apps/releases/download/v${VERAPDF_VERSION}/verapdf-greenfield-${VERAPDF_VERSION}-apps.zip && \
    unzip verapdf-greenfield-${VERAPDF_VERSION}-apps.zip && \
    rm verapdf-greenfield-${VERAPDF_VERSION}-apps.zip && \
    mv verapdf-greenfield-${VERAPDF_VERSION} verapdf && \
    chmod +x /opt/verapdf/verapdf

# Establish a transparent global execution path
RUN ln -s /opt/verapdf/verapdf /usr/local/bin/verapdf

ENTRYPOINT ["verapdf"]
CMD ["--help"]
