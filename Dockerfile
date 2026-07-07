FROM alpine:3.20

# Install Java, download tools, unzip, and shell requirements
RUN apk update && apk add --no-cache \
    openjdk17-jre \
    wget \
    unzip \
    ca-certificates \
    bash

WORKDIR /opt

# 1. Download directly via the secure HTTPS link to avoid multiple redirect loops
# 2. Extract into the actual directory structure provided by the archive
RUN wget https://software.verapdf.org/rel/verapdf-installer.zip && \
    unzip verapdf-installer.zip && \
    rm verapdf-installer.zip

# 3. Create an automated, silent installation configuration profile for IzPack
RUN echo '<?xml version="1.0" encoding="UTF-8" standalone="no"?> \
<AutomatedInstallation version="1.0"> \
    <com.izforge.izpack.panels.htmlhello.HTMLHelloPanel id="welcome"/> \
    <com.izforge.izpack.panels.target.TargetPanel id="install_dir"> \
        <installpath>/opt/verapdf</installpath> \
    </com.izforge.izpack.panels.target.TargetPanel> \
    <com.izforge.izpack.panels.packs.PacksPanel id="packs_selection"> \
        <pack index="0" name="veraPDF Mac/Linux/Windows CLI" selected="true"/> \
        <pack index="1" name="veraPDF Mac/Linux/Windows GUI" selected="false"/> \
    </com.izforge.izpack.panels.packs.PacksPanel> \
    <com.izforge.izpack.panels.install.InstallPanel id="install"/> \
    <com.izforge.izpack.panels.finish.FinishPanel id="finish"/> \
</AutomatedInstallation>' > auto-install.xml

# 4. Execute the headless installation using wildcards to handle version variations
RUN java -jar /opt/verapdf-greenfield-*/verapdf-izpack-installer-*.jar auto-install.xml && \
    rm -rf /opt/verapdf-greenfield-* auto-install.xml && \
    chmod +x /opt/verapdf/verapdf

# 5. Global symlink so 'verapdf' works directly from any command line context
RUN ln -s /opt/verapdf/verapdf /usr/local/bin/verapdf

ENTRYPOINT ["verapdf"]
CMD ["--help"]
