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
    https://github.com/mvdan/sh/releases/download/v3.14.1/shfmt_v3.14.1_linux_amd64 \
      -o /usr/local/bin/shfmt \
    && chmod +x /usr/local/bin/shfmt

# Install python lint tooling (pinned)
RUN python3 -m pip install --no-cache-dir --break-system-packages \
    ruff==0.16.8 \
    yamllint==1.38.0

# Install Node.js 22 (pinned; markdownlint-cli@0.49.1 requires >=22)
ARG NODE_VERSION=22.23.3
RUN curl --retry 5 --retry-delay 2 --retry-connrefused -fsSL \
    "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" \
    | tar -xJ -C /usr/local --strip-components=1

# Install markdown lint tooling (pinned)
RUN npm install --global markdownlint-cli@0.49.1

# Build and Install kcov (pinned)
RUN git clone --branch v43 --depth 1 https://github.com/SimonKagstrom/kcov.git /tmp/kcov \
    && cmake -S /tmp/kcov -B /tmp/kcov/build \
    && cmake --build /tmp/kcov/build \
    && cmake --install /tmp/kcov/build \
    && rm -rf /tmp/kcov

# Fix for ImageMagick policy to allow text rendering
RUN sed -i 's/rights="none" pattern="PDF"/rights="read|write" pattern="PDF"/' /etc/ImageMagick-6/policy.xml \
    && sed -i 's/rights="none" pattern="LABEL"/rights="read|write" pattern="LABEL"/' /etc/ImageMagick-6/policy.xml

COPY . /app/

# Basic fix for Windows Line Endings (CRLF -> LF)
RUN dos2unix /app/*.sh /app/tools/runners/*.sh /app/tests/*.bats /app/tests/mocks/*.json \
    && chmod +x /app/*.sh /app/tools/runners/*.sh

# --- Mock Synology SRM Filesystem ---
# 1. Login background, 2. webman theme wallpapers, 3. HD pack resources,
# 4. synoinfo config, 5. crontab, 6. binary location, 7. service manager mocks
RUN mkdir -p /usr/syno/etc/ \
        /usr/syno/sbin \
        /usr/local/bin \
        /usr/syno/synoman/webman/resources/images/default_wallpaper/ \
        /usr/syno/synoman/webman/resources/images/theme/router/default_wallpaper/ \
        /usr/syno/synoman/synohdpack/images/dsm/resources/images/default_wallpaper/ \
        /usr/syno/synoman/synohdpack/images/dsm/resources/images/theme/router/default_wallpaper/ \
    && touch /usr/syno/etc/login_background.jpg \
        /usr/syno/synoman/webman/resources/images/default_wallpaper/01.jpg \
        /usr/syno/synoman/webman/resources/images/theme/router/default_wallpaper/01.jpg \
        /etc/crontab \
    && printf 'login_background_customize="no"\n' > /etc/synoinfo.conf \
    && printf '#!/bin/bash\necho "Mock synoservicectl: $*"\n' > /usr/syno/sbin/synoservicectl \
    && printf '#!/bin/bash\necho "Mock synoservice: $*"\n' > /usr/bin/synoservice \
    && chmod +x /usr/syno/sbin/synoservicectl /usr/bin/synoservice

# Add Synology sbin to PATH (SRM specific)
ENV PATH="/usr/syno/sbin:${PATH}"

# Set working directory
WORKDIR /app

CMD ["bats", "tests/"]
