FROM debian:bookworm-slim@sha256:88200866dfff7ea7f5cbcb6ec7c8a701889efe6fe859fe64d6990e4b07ea4171

# Avoid prompts
ENV DEBIAN_FRONTEND=noninteractive

# Pin Debian APT metadata to a dated snapshot for deterministic rebuilds.
ARG DEBIAN_SNAPSHOT=20260826T000000Z

# Install dependencies matching SRM environment + Test Tools
RUN printf 'Acquire::Check-Valid-Until "false";\n' > /etc/apt/apt.conf.d/99snapshot \
    && printf 'deb http://snapshot.debian.org/archive/debian/%s bookworm main\n' "$DEBIAN_SNAPSHOT" > /etc/apt/sources.list \
    && printf 'deb http://snapshot.debian.org/archive/debian/%s bookworm-updates main\n' "$DEBIAN_SNAPSHOT" >> /etc/apt/sources.list \
        && printf 'deb http://snapshot.debian.org/archive/debian-security/%s bookworm-security main\n' \
            "$DEBIAN_SNAPSHOT" >> /etc/apt/sources.list \
    && apt-get update \
    && apt-get install -y \
    bash \
    curl \
    wget \
    imagemagick \
    cron \
    sudo \
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
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install bats-core (pinned)
RUN curl --retry 5 --retry-delay 2 --retry-connrefused -fsSL \
    https://github.com/bats-core/bats-core/archive/refs/tags/v1.14.0.tar.gz \
    | tar -xz -C /tmp \
    && /tmp/bats-core-1.14.0/install.sh /usr/local \
    && rm -rf /tmp/bats-core-1.14.0

# Install shellcheck (pinned)
RUN curl --retry 5 --retry-delay 2 --retry-connrefused -fsSL \
    https://github.com/koalaman/shellcheck/releases/download/v0.11.0/shellcheck-v0.11.0.linux.x86_64.tar.xz \
    | tar -xJ -C /tmp \
    && install /tmp/shellcheck-v0.11.0/shellcheck /usr/local/bin/shellcheck \
    && rm -rf /tmp/shellcheck-v0.11.0

# Install shfmt (pinned)
RUN curl --retry 5 --retry-delay 2 --retry-connrefused -fsSL \
    https://github.com/mvdan/sh/releases/download/v3.13.1/shfmt_v3.13.1_linux_amd64 \
      -o /usr/local/bin/shfmt \
    && chmod +x /usr/local/bin/shfmt

# Install python lint tooling (pinned)
RUN python3 -m pip install --no-cache-dir --break-system-packages \
    ruff==0.16.4 \
    yamllint==1.38.0

# Install Node.js 22 (pinned; markdownlint-cli@0.49.1 requires >=22)
ARG NODE_VERSION=22.23.2
RUN curl --retry 5 --retry-delay 2 --retry-connrefused -fsSL \
    "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" \
    | tar -xJ -C /usr/local --strip-components=1

# Install markdown lint tooling (pinned)
RUN npm install --global markdownlint-cli@0.49.1

# Build and Install kcov (pinned)
RUN git clone --branch v43 --depth 1 https://github.com/SimonKagstrom/kcov.git /tmp/kcov \
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

COPY . /app/

# Basic fix for Windows Line Endings (CRLF -> LF)
RUN dos2unix /app/*.sh /app/tools/runners/*.sh /app/tests/*.bats /app/tests/mocks/*.json \
    && chmod +x /app/*.sh /app/tools/runners/*.sh

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

CMD ["bats", "tests/"]
