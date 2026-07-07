FROM alpine:3.20

# Install Java, X11 virtual display layers, VNC servers, fonts, and web proxy utilities
RUN apk update && apk add --no-cache \
    openjdk17-jre \
    wget \
    unzip \
    ca-certificates \
    bash \
    xvfb \
    x11vnc \
    novnc \
    websockify \
    openbox \
    fontconfig \
    ttf-dejavu \
    libxi \
    libxtst \
    libxrender

WORKDIR /opt

# 1. Download and extract the official installer wizard bundle
RUN wget https://software.verapdf.org/rel/verapdf-installer.zip && \
    unzip verapdf-installer.zip && \
    rm verapdf-installer.zip

# 2. Generate automated installation profile enabling BOTH the CLI and the GUI engines
RUN echo '<?xml version="1.0" encoding="UTF-8" standalone="no"?> \
<AutomatedInstallation version="1.0"> \
    <com.izforge.izpack.panels.htmlhello.HTMLHelloPanel id="welcome"/> \
    <com.izforge.izpack.panels.target.TargetPanel id="install_dir"> \
        <installpath>/opt/verapdf</installpath> \
    </com.izforge.izpack.panels.target.TargetPanel> \
    <com.izforge.izpack.panels.packs.PacksPanel id="packs_selection"> \
        <pack index="0" name="veraPDF Mac/Linux/Windows CLI" selected="true"/> \
        <pack index="1" name="veraPDF Mac/Linux/Windows GUI" selected="true"/> \
    </com.izforge.izpack.panels.packs.PacksPanel> \
    <com.izforge.izpack.panels.install.InstallPanel id="install"/> \
    <com.izforge.izpack.panels.finish.FinishPanel id="finish"/> \
</AutomatedInstallation>' > auto-install.xml

# 3. Execute the headless setup engine and clear build artifacts
RUN java -jar /opt/verapdf-greenfield-*/verapdf-izpack-installer-*.jar auto-install.xml && \
    rm -rf /opt/verapdf-greenfield-* auto-install.xml && \
    chmod +x /opt/verapdf/verapdf /opt/verapdf/verapdf-gui

# 4. Map global paths for systemic command calls
RUN ln -s /opt/verapdf/verapdf /usr/local/bin/verapdf && \
    ln -s /opt/verapdf/verapdf-gui /usr/local/bin/verapdf-gui

# 5. Standardize noVNC landing dashboard route
RUN ln -s /usr/share/novnc/vnc.html /usr/share/novnc/index.html

# 6. Build the background runtime orchestration engine
RUN echo '#!/bin/bash \n\
echo "1. Spawning Virtual X-Server Display (:1)..." \n\
Xvfb :1 -screen 0 1280x1024x24 & \n\
export DISPLAY=:1 \n\
sleep 1 \n\
\n\
echo "2. Initializing Window Layout Manager..." \n\
openbox & \n\
\n\
echo "3. Initializing Secure VNC Server Interface..." \n\
x11vnc -display :1 -forever -nopw -listen 0.0.0.0 -rfbport 5900 & \n\
\n\
echo "4. Establishing Web-VNC WebSocket Network Bridge on Port 8080..." \n\
websockify --web=/usr/share/novnc 8080 localhost:5900 & \n\
\n\
echo "5. Launching native veraPDF GUI Environment..." \n\
# Executing in the foreground ties the GUI lifecycle to the Docker lifecycle to stay healthy \n\
exec /opt/verapdf/verapdf-gui \n\
' > /usr/local/bin/init-gui.sh && chmod +x /usr/local/bin/init-gui.sh

# Expose HTTP port for the TrueNAS Web Portal integration
EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/init-gui.sh"]
