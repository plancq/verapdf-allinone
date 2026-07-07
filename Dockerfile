# Greenfield Alpine Linux base layer with standard user permissions
FROM alpine:3.20

# Install x11 runtime wrappers, Java 17, and standard supervision daemons
RUN apk update && apk add --no-cache \
    openjdk17-jre \
    wget \
    unzip \
    bash \
    xvfb \
    x11vnc \
    fluxbox \
    novnc \
    supervisor \
    ttf-dejavu

# Download and place the latest standalone version of veraPDF
WORKDIR /opt
RUN wget http://downloads.verapdf.org/rel/verapdf-installer.zip && \
    unzip verapdf-installer.zip && \
    rm verapdf-installer.zip && \
    mv verapdf-installer-* verapdf-source && \
    chmod +x /opt/verapdf-source/verapdf-gui

# Create standard storage target mount paths
RUN mkdir -p /data/pdfs /etc/supervisor.d

# Generate an absolute initialization config to prevent execution race conditions
RUN echo '[supervisord]' > /etc/supervisord.conf && \
    echo 'nodaemon=true' >> /etc/supervisord.conf && \
    echo 'user=root' >> /etc/supervisord.conf && \
    echo '[include]' >> /etc/supervisord.conf && \
    echo 'files = /etc/supervisor.d/*.ini' >> /etc/supervisord.conf

# Script out explicit process blocks for each backend interface stream layer
RUN echo '[program:xvfb]' > /etc/supervisor.d/verapdf.ini && \
    echo 'command=/usr/bin/Xvfb :1 -screen 0 1440x900x24' >> /etc/supervisor.d/verapdf.ini && \
    echo '[program:fluxbox]' >> /etc/supervisor.d/verapdf.ini && \
    echo 'command=/usr/bin/fluxbox' >> /etc/supervisor.d/verapdf.ini && \
    echo 'environment=DISPLAY=":1"' >> /etc/supervisor.d/verapdf.ini && \
    echo '[program:x11vnc]' >> /etc/supervisor.d/verapdf.ini && \
    echo 'command=/usr/bin/x11vnc -display :1 -nopw -forever -shared' >> /etc/supervisor.d/verapdf.ini && \
    echo '[program:novnc]' >> /etc/supervisor.d/verapdf.ini && \
    echo 'command=/usr/bin/novnc_proxy --vnc localhost:5900 --listen 80' >> /etc/supervisor.d/verapdf.ini && \
    echo '[program:verapdf]' >> /etc/supervisor.d/verapdf.ini && \
    echo 'command=/opt/verapdf-source/verapdf-gui' >> /etc/supervisor.d/verapdf.ini && \
    echo 'environment=DISPLAY=":1"' >> /etc/supervisor.d/verapdf.ini

EXPOSE 80

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
