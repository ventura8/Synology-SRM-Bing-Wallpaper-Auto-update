FROM debian:bookworm-slim

# Avoid prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies matching SRM environment + Test Tools
RUN apt-get update && apt-get install -y \
    bash \
    curl \
    wget \
    imagemagick \
    cron \
    sudo \
    bats \
    jq \
    dos2unix \
    grep \
    fonts-noto-cjk \
    build-essential \
    cmake \
    git \
    pkg-config \
    libcurl4-openssl-dev \
    libssl-dev \
    libelf-dev \
    libdw-dev \
    binutils-dev \
    libiberty-dev \
    zlib1g-dev \
    python3 \
    shellcheck \
    && rm -rf /var/lib/apt/lists/*

# Build and Install kcov
RUN git clone https://github.com/SimonKagstrom/kcov.git /tmp/kcov \
    && mkdir /tmp/kcov/build \
    && cd /tmp/kcov/build \
    && cmake .. \
    && make \
    && make install \
    && cd / \
    && rm -rf /tmp/kcov

# Fix for ImageMagick policy to allow text rendering
RUN sed -i 's/rights="none" pattern="PDF"/rights="read|write" pattern="PDF"/' /etc/ImageMagick-6/policy.xml \
    && sed -i 's/rights="none" pattern="LABEL"/rights="read|write" pattern="LABEL"/' /etc/ImageMagick-6/policy.xml

# Copy Scripts
COPY . /app/

# Basic fix for Windows Line Endings (CRLF -> LF)
RUN dos2unix /app/*.sh /app/tests/*.bats /app/tests/mocks/*.json && chmod +x /app/*.sh

# --- Mock Synology SRM Filesystem ---

# 1. Login Background Path
RUN mkdir -p /usr/syno/etc/ && touch /usr/syno/etc/login_background.jpg

# 2. Webman Resources (Theme wallpapers)
RUN mkdir -p /usr/syno/synoman/webman/resources/images/default_wallpaper/ \
    && mkdir -p /usr/syno/synoman/webman/resources/images/theme/router/default_wallpaper/ \
    && touch /usr/syno/synoman/webman/resources/images/default_wallpaper/01.jpg \
    && touch /usr/syno/synoman/webman/resources/images/theme/router/default_wallpaper/01.jpg

# 3. HD Pack Resources
RUN mkdir -p /usr/syno/synoman/synohdpack/images/dsm/resources/images/default_wallpaper/ \
    && mkdir -p /usr/syno/synoman/synohdpack/images/dsm/resources/images/theme/router/default_wallpaper/

# 4. Synoinfo Config
RUN echo 'login_background_customize="no"' > /etc/synoinfo.conf

# 5. Crontab
RUN touch /etc/crontab

# 6. Binary Location
RUN mkdir -p /usr/local/bin

# 7. Add Synology sbin to PATH (SRM specific)
ENV PATH="/usr/syno/sbin:${PATH}"

# Mock 'synoservicectl' (SRM 1.3 Service Manager)
RUN mkdir -p /usr/syno/sbin \
    && echo '#!/bin/bash\necho "Mock synoservicectl: $*"' > /usr/syno/sbin/synoservicectl \
    && chmod +x /usr/syno/sbin/synoservicectl

# Mock 'synoservice' (Legacy/DSM) - Fallback
RUN echo '#!/bin/bash\necho "Mock synoservice: $*"' > /usr/bin/synoservice && chmod +x /usr/bin/synoservice

# Set working directory
WORKDIR /app

# Copy Scripts


CMD ["bats", "tests/"]
