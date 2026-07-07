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

# Download veraPDF installer and run a silent automated installation
WORKDIR /opt
RUN wget --tries=3 --connect-timeout=15 --retry-connrefused \
    https://software.verapdf.org/rel/verapdf-installer.zip && \
    unzip verapdf-installer.zip && \
    rm verapdf-installer.zip && \
    # Create an automated installation script for the IzPack installer
    echo '<?xml version="1.0" encoding="UTF-8" standalone="no"?>' > auto-install.xml && \
    echo '<AutomatedInstallation langpack="eng">' >> auto-install.xml && \
    echo '  <com.izforge.izpack.panels.htmlhello.HTMLHelloPanel id="welcome"/>' >> auto-install.xml && \
    echo '  <com.izforge.izpack.panels.target.TargetPanel id="install_dir">' >> auto-install.xml && \
    echo '    <installpath>/opt/verapdf</installpath>' >> auto-install.xml && \
    echo '  </com.izforge.izpack.panels.target.TargetPanel>' >> auto-install.xml && \
    echo '  <com.izforge.izpack.panels.packs.PacksPanel id="packs">' >> auto-install.xml && \
    echo '    <pack index="0" name="veraPDF Desktop" selected="true"/>' >> auto-install.xml && \
    echo '    <pack index="1" name="veraPDF Documentation" selected="true"/>' >> auto-install.xml && \
    echo '  </com.izforge.izpack.panels.packs.PacksPanel>' >> auto-install.xml && \
    echo '  <com.izforge.izpack.panels.install.InstallPanel id="install"/>' >> auto-install.xml && \
    echo '  <com.izforge.izpack.panels.finish.FinishPanel id="finish"/>' >> auto-install.xml && \
    echo '</AutomatedInstallation>' >> auto-install.xml && \
    # Dynamically locate the installer jar to support changing archive layouts
    INSTALLER_JAR=$(find . -maxdepth 3 -type f -name 'verapdf-izpack-installer-*.jar' | head -n 1) && \
    test -n "${INSTALLER_JAR}" && \
    java -jar "${INSTALLER_JAR}" auto-install.xml && \
    rm -rf verapdf-* auto-install.xml && \
    chmod +x /opt/verapdf/verapdf-gui

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
    echo 'command=/opt/verapdf/verapdf-gui' >> /etc/supervisor.d/verapdf.ini && \
    echo 'environment=DISPLAY=":1"' >> /etc/supervisor.d/verapdf.ini

EXPOSE 80

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
