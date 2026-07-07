FROM alpine:3.20

# Step 1: Install Java, download utilities, unzip, and SSL certificates
RUN apk update && apk add --no-cache \
    openjdk17-jre \
    wget \
    unzip \
    ca-certificates \
    bash

WORKDIR /opt

# Step 2: Download directly from the final HTTPS source to prevent redirect failures
# Step 3: Use a broader wildcard (verapdf-*) to capture the extracted greenfield folder safely
RUN wget https://software.verapdf.org/rel/verapdf-installer.zip && \
    unzip verapdf-installer.zip && \
    rm verapdf-installer.zip && \
    mv verapdf-* verapdf-source && \
    chmod +x /opt/verapdf-source/verapdf

# Step 4: Create a global symlink so you can run 'verapdf' from anywhere
RUN ln -s /opt/verapdf-source/verapdf /usr/local/bin/verapdf

# Default execution context
ENTRYPOINT ["verapdf"]
CMD ["--help"]
