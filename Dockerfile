#   ===========================================================================
#   ---------------------------------------------------------------------------
#                 Image from MiGoller's ShinobiDocker nvidia image
#   ---------------------------------------------------------------------------
#   ===========================================================================

FROM node:lts-alpine

########################################
#               Build                  #
########################################
ARG BUILD_DATE="2021-10-22T22:59:49Z"
ARG VERSION="2.0.0"
########################################

# Basic build-time metadata as defined at http://label-schema.org
LABEL org.label-schema.schema-version="1.0" \
    org.label-schema.build-date=${BUILD_DATE} \
    org.label-schema.docker.dockerfile="/Dockerfile" \
    org.label-schema.license="AGPL-3.0 License" \
    org.label-schema.name="shinobidocker" \
    org.label-schema.vendor="t4skforce" \
    org.label-schema.version="Shinobi v${VERSION}" \
    org.label-schema.description="CCTV and NVR in Node.js" \
    org.label-schema.url="https://github.com/t4skforce/shinobidocker" \
    org.label-schema.vcs-type="Git" \
    org.label-schema.vcs-url="https://github.com/t4skforce/shinobidocker.git" \
    maintainer="t4skforce" \
    Author="t4skforce"

# Update Shinobi on every container start?
#   manual:     Update Shinobi manually. New Docker images will always retrieve the latest version.
#   auto:       Update Shinobi on every container start.
ARG ARG_APP_UPDATE=manual
# ShinobiPro branch, defaults to master
ARG ARG_APP_BRANCH=master

# Additional Node JS packages for Shinobi plugins, addons, etc.
ARG ARG_ADD_NODEJS_PACKAGES="mqtt"

# Persist app-reladted build arguments
ENV APP_UPDATE=$ARG_APP_UPDATE \
    APP_BRANCH=${ARG_APP_BRANCH} \
    # Set environment variables to default values
    # ADMIN_USER : the super user login name
    # ADMIN_PASSWORD : the super user login password
    # PLUGINKEY_MOTION : motion plugin connection key
    # PLUGINKEY_OPENCV : opencv plugin connection key
    # PLUGINKEY_OPENALPR : openalpr plugin connection key
    ADMIN_USER=admin@shinobi.video \
    ADMIN_PASSWORD=admin \
    CRON_KEY=fd6c7849-904d-47ea-922b-5143358ba0de \
    PLUGINKEY_MOTION=b7502fd9-506c-4dda-9b56-8e699a6bc41c \
    PLUGINKEY_OPENCV=f078bcfe-c39a-4eb5-bd52-9382ca828e8a \
    PLUGINKEY_OPENALPR=dbff574e-9d4a-44c1-b578-3dc0f1944a3c \
    # Leave these ENVs alone unless you know what you are doing
    MYSQL_USER=majesticflame \
    MYSQL_PASSWORD=password \
    MYSQL_HOST=localhost \
    MYSQL_PORT=3306 \
    MYSQL_DATABASE=ccio \
    MYSQL_ROOT_PASSWORD=blubsblawoot \
    MYSQL_ROOT_USER=root \
    EMBEDDEDDB=false \
    SUBSCRIPTION_ID= \
    PRODUCT_TYPE= \
    TZ=Europe/Vienna
    
     

WORKDIR /tmp/workdir

RUN set -xe \
    # Create additional directories for: Custom configuration, working directory, database directory, scripts
    mkdir -p \
        /opt/shinobi \
        /opt/dbdata \
        /opt/customize \
    #   Install Nodejs
    && apk add --no-cache \ 
        freetype-dev \ 
        ffmpeg \
        gnutls-dev \ 
        lame-dev \ 
        libass-dev \ 
        libogg-dev \ 
        libtheora-dev \ 
        libvorbis-dev \ 
        libvpx-dev \ 
        libwebp-dev \ 
        libssh2 \ 
        opus-dev \ 
        rtmpdump-dev \ 
        x264-dev \ 
        x265-dev \ 
        yasm-dev \
        # .build-dependencies \ 
        build-base \ 
        bzip2 \ 
        coreutils \ 
        gnutls \ 
        nasm \ 
        tzdata \
        x264 \
        bind-tools \
        # nscd \
        git \
        make \
        mariadb-client \
        openrc \
        pkgconfig \
        python3 \
        py3-pip \
        py3-setuptools \
        socat \
        sqlite \
        sqlite-dev \
        wget \
        tar \
        xz \
    && ln -sf /usr/bin/python3 /usr/bin/python \
    #   Nodejs addons
    && npm install -g npm@latest pm2 \
    # Install Shinobi app including NodeJS dependencies
    && git clone -b ${APP_BRANCH} https://gitlab.com/Shinobi-Systems/Shinobi.git /opt/shinobi \
    && cd /opt/shinobi \
    && sed -i 's/\$.help.e.modal('"'"'show'"'"')//g' ./web/pages/blocks/help.ejs \
    && npm install sqlite3 --unsafe-perm \
    && npm install jsonfile edit-json-file ${ARG_ADD_NODEJS_PACKAGES} \
    && npm install --unsafe-perm \
    && npm audit fix --force || /bin/true \
    # cleanup 
    && npm cache clean --force \
    && rm -rf /tmp/* /var/tmp/* \
       /opt/shinobi/.git \
       /root/.cache \
       /root/.node-gyp \
       /root/.npm
    

# Assign working directory
WORKDIR /opt/shinobi

# Copy file system sources
ADD sources/ / 

VOLUME [ "/opt/dbdata" ]
VOLUME [ "/opt/shinobi/videos" ]

EXPOSE 8080

ENTRYPOINT [ "/opt/shinobi/docker-entrypoint.sh" ]

CMD [ "pm2-docker", "pm2Shinobi.yml" ]
