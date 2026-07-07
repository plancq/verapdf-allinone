# Use a modern, light, unprivileged VNC/noVNC alpine base
FROM alpine:latest

# Install dependencies, minimal window manager, noVNC, and Java 17
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

# Download and extract the greenfield distribution of veraPDF
WORKDIR /opt
RUN wget http://downloads.verapdf.org/rel/verapdf-installer.zip && \
    unzip verapdf-installer.zip && \
    rm verapdf-installer.zip && \
    mv verapdf-installer-* verapdf-source && \
    chmod +x /opt/verapdf-source/verapdf-gui

# Create standard storage mount paths
RUN mkdir -p /data/pdfs

# Configure Supervisor to run the window manager, VNC server, web interface, and veraPDF without root needs
RUN mkdir -p /etc/supervisor.d
RUN echo -e '[program:xvfb]\ncommand=/usr/bin/Xvfb :1 -screen 0 1440x900x24\nautorestart=true\n\n\
[program:fluxbox]\ncommand=/usr/bin/fluxbox\nenv=DISPLAY=:1\nautorestart=true\n\n\
[program:x11vnc]\ncommand=/usr/bin/x11vnc -display :1 -nopw -forever -shared\nautorestart=true\n\n\
[program:novnc]\ncommand=/usr/share/novnc/utils/launch.sh --vnc localhost:5900 --listen 80\nautorestart=true\n\n\
[program:verapdf]\ncommand=/opt/verapdf-source/verapdf-gui\nenv=DISPLAY=:1\nautorestart=true' > /etc/supervisor.d/verapdf.ini

EXPOSE 80

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]
