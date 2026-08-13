# Adapted from Anthropic's reference devcontainer for Claude Code
# (anthropics/claude-code .devcontainer). Local changes:
#   - decision 015: added bats, ripgrep, shellcheck (this repo's test suite and SI loop)
#   - decision 016: egress profiles baked in; the profile is written root-owned to
#     /etc/cc-egress-profile so an in-container agent cannot widen its own allowlist.
# Keep this file minimal-diff against upstream so refreshes are easy.
# node:22 (bookworm), bumped from node:20 2026-08-13: claude-code >=2.1.231
# declares engines.node >=22, so the baked npm install started warning EBADENGINE
# and a future release may hard-fail on node 20. Same Debian base, so the
# python3.11/no-ensurepip and openjdk-17 notes below are unchanged.
FROM node:22

ARG TZ
ENV TZ="$TZ"

ARG CLAUDE_CODE_VERSION=latest

# Install basic development tools and iptables/ipset
RUN apt-get update && apt-get install -y --no-install-recommends \
  less \
  git \
  procps \
  sudo \
  fzf \
  zsh \
  man-db \
  unzip \
  gnupg2 \
  gh \
  iptables \
  ipset \
  iproute2 \
  dnsutils \
  aggregate \
  jq \
  nano \
  vim \
  bats \
  ripgrep \
  shellcheck \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Ensure default node user has access to /usr/local/share
RUN mkdir -p /usr/local/share/npm-global && \
  chown -R node:node /usr/local/share

ARG USERNAME=node

# Persist bash history.
RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
  && mkdir /commandhistory \
  && touch /commandhistory/.bash_history \
  && chown -R $USERNAME /commandhistory

# Set `DEVCONTAINER` environment variable to help with orientation
ENV DEVCONTAINER=true

# Create workspace and config directories and set permissions
RUN mkdir -p /workspace /home/node/.claude && \
  chown -R node:node /workspace /home/node/.claude

WORKDIR /workspace

ARG GIT_DELTA_VERSION=0.18.2
RUN ARCH=$(dpkg --print-architecture) && \
  wget "https://github.com/dandavison/delta/releases/download/${GIT_DELTA_VERSION}/git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
  sudo dpkg -i "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
  rm "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb"

# uv — the Python toolchain (decision log #18).
#
# The node:22 (bookworm) base ships python3.11 but no pip and, crucially, no `ensurepip`, so
# `python3 -m venv` FAILS outright: there is no installer of any kind in the image.
# The `python` egress profile was therefore opening PyPI to a container that had no
# way to reach it. uv is a single static binary that is both the venv builder and the
# installer, so one tool closes the whole gap (no pip/venv/ensurepip bootstrap chain,
# and the venv sidesteps Debian's PEP 668 EXTERNALLY-MANAGED marker).
#
# Fetched from GitHub releases at a pinned version, mirroring the git-delta block
# above, rather than `curl https://astral.sh/uv/install.sh | sh`: no new trusted
# domain (GitHub is already the source for delta and zsh-in-docker), and a version
# bump shows up in the diff.
#
# Astral publishes a `.sha256` file alongside every release asset; verify against
# it rather than trusting the TLS channel alone (git-delta above does not, but that
# predates this decision — don't skip a free check just to match an older layer).
#
# Installed to /usr/local/bin, which is root-owned. Unlike /usr/local/share (chowned
# to node above for npm), `node` cannot rewrite the toolchain binary it runs.
ARG UV_VERSION=0.11.28
RUN case "$(dpkg --print-architecture)" in \
    amd64) UV_TARGET=x86_64-unknown-linux-gnu ;; \
    arm64) UV_TARGET=aarch64-unknown-linux-gnu ;; \
    *) echo "uv: unsupported architecture $(dpkg --print-architecture)" >&2; exit 1 ;; \
  esac && \
  cd /tmp && \
  UV_ASSET="uv-${UV_TARGET}.tar.gz" && \
  wget -q "https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/${UV_ASSET}" \
    "https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/${UV_ASSET}.sha256" && \
  sha256sum -c "${UV_ASSET}.sha256" && \
  tar xzf "${UV_ASSET}" && \
  install -o root -g root -m 0755 "/tmp/uv-${UV_TARGET}/uv" /usr/local/bin/uv && \
  install -o root -g root -m 0755 "/tmp/uv-${UV_TARGET}/uvx" /usr/local/bin/uvx && \
  rm -rf "/tmp/uv-${UV_TARGET}" "/tmp/${UV_ASSET}" "/tmp/${UV_ASSET}.sha256"

# UV_PYTHON_DOWNLOADS=never: uv resolves the interpreter itself, and when it dislikes
# the system one it silently downloads a managed CPython from GitHub — reachable
# because init-firewall.sh always admits GitHub's published IP ranges (from
# api.github.com/meta), for every project, independent of egress profile. Pinning
# UV_PYTHON_DOWNLOADS to `never` keeps the image's python3.11 the only interpreter,
# so a version mismatch is a loud error rather than a quiet fetch through the firewall.
#
# UV_LINK_MODE=copy: the uv cache lives in the container filesystem while venvs live
# under /workspace, a bind mount. Hardlinking across that device boundary is
# impossible, so the default mode warns on every single install.
ENV UV_PYTHON_DOWNLOADS=never \
    UV_LINK_MODE=copy

# shfmt — the shell parser the auto-approve-allowed-commands hook depends on.
#
# WHY IT IS HERE AT ALL: hooks/auto-approve-allowed-commands.sh parses a Bash
# command into its component commands (through pipes, &&, subshells, `bash -c`)
# via `shfmt -tojson` before checking each component against the allowlist.
# Without shfmt the parse fails, the hook takes its `|| exit 0` fallback, and it
# silently never auto-approves anything — a no-op that looks like a wiring bug.
# Now that the hooks are wired by default (decision 023), the dependency has to
# be in the image or the wiring is inert.
#
# WHY A PINNED GITHUB RELEASE, NOT apt: bookworm has no `shfmt` binary package,
# and the mvdan/sh releases are single static Go binaries — the same shape as
# the uv and git-delta layers above.
#
# WHY THE HASHES ARE PINNED AS ARGS (the Android layer's discipline, #19, not
# rustup's): v3.13.1 publishes no sha256sums.txt asset, so there is nothing to
# `sha256sum -c` against at build time. Pinning the per-arch digest here means a
# version bump MUST move the hash in the same diff — a CDN or MITM tamper of the
# binary fails the build rather than being silently baked into the image that
# decides which commands get auto-approved. That last clause is why this layer
# verifies at all: shfmt sits on the permission path.
#
# Root-owned in /usr/local/bin, like uv: `node` runs the parser but cannot
# rewrite it.
ARG SHFMT_VERSION=3.13.1
ARG SHFMT_SHA256_AMD64=fb096c5d1ac6beabbdbaa2874d025badb03ee07929f0c9ff67563ce8c75398b1
ARG SHFMT_SHA256_ARM64=32d92acaa5cd8abb29fc49dac123dc412442d5713967819d8af2c29f1b3857c7
RUN case "$(dpkg --print-architecture)" in \
      amd64) SHFMT_ARCH=amd64; SHFMT_SHA="$SHFMT_SHA256_AMD64" ;; \
      arm64) SHFMT_ARCH=arm64; SHFMT_SHA="$SHFMT_SHA256_ARM64" ;; \
      *) echo "shfmt: unsupported architecture $(dpkg --print-architecture)" >&2; exit 1 ;; \
    esac && \
    cd /tmp && \
    wget -q "https://github.com/mvdan/sh/releases/download/v${SHFMT_VERSION}/shfmt_v${SHFMT_VERSION}_linux_${SHFMT_ARCH}" -O shfmt && \
    echo "${SHFMT_SHA}  shfmt" | sha256sum -c - && \
    install -o root -g root -m 0755 /tmp/shfmt /usr/local/bin/shfmt && \
    rm -f /tmp/shfmt && \
    shfmt --version

# Android toolchain — JDK 17 + a baked SDK (decision log #19).
#
# Unconditional, in the shared base image, exactly like uv above: a toolchain is
# installed for everyone and the egress profile gates only NETWORK (the `android`
# profile opens Google Maven / Maven Central / Gradle). The SDK is ~2GB, but because
# every project builds this identical Dockerfile and only the final CC_EGRESS_PROFILE
# layer varies, this is one content-addressed layer shared across all project images,
# not a per-project cost (decision 016, S2).
#
# WHY JDK 17: it is the JDK the current Android Gradle Plugin targets. Debian bookworm
# (the node:22 base) ships openjdk-17-jdk-headless, so no third-party JDK is needed.
#
# WHY BAKE THE SDK (and not fetch it at runtime): the SDK download happens during
# `docker build`, which runs BEFORE init-firewall.sh exists, so it needs no egress
# profile; a runtime fetch would need dl.google.com open and would re-download per
# project. Baking it also means the SDK dir is root-owned — `node` runs builds against
# it but cannot rewrite the toolchain it runs, mirroring uv's root-owned /usr/local/bin.
#
# A project that needs a platform or build-tools version other than the baked one
# fails loudly (sdkmanager cannot write the root-owned dir) rather than silently
# widening anything — that is a central-image rebuild, like uv needing another Python.
RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-17-jdk-headless \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# cmdline-tools is fetched from dl.google.com at a pinned build number and verified
# against a pinned SHA-256 before extraction — matching the uv layer's verify-before-
# extract discipline (the git-delta block above predates it). Google publishes the
# per-package checksum in its SDK repository manifest (repository2-*.xml); the value is
# pinned here rather than parsed at build time so verification does not depend on the
# manifest still listing this (older) build. Bumping the version REQUIRES bumping the
# hash in lockstep — `sha256sum -c` fails otherwise — so both always move together in
# the diff, and a CDN/MITM tamper of the zip is caught rather than silently baked in.
ARG ANDROID_CMDLINE_TOOLS_VERSION=11076708
ARG ANDROID_CMDLINE_TOOLS_SHA256=2d2d50857e4eb553af5a6dc3ad507a17adf43d115264b1afc116f95c92e5e258
ARG ANDROID_PLATFORM=android-35
ARG ANDROID_BUILD_TOOLS=35.0.0
ENV ANDROID_HOME=/opt/android-sdk \
    ANDROID_SDK_ROOT=/opt/android-sdk
RUN mkdir -p "$ANDROID_HOME/cmdline-tools" && \
  cd /tmp && \
  wget -q "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_TOOLS_VERSION}_latest.zip" \
    -O cmdline-tools.zip && \
  echo "${ANDROID_CMDLINE_TOOLS_SHA256}  cmdline-tools.zip" | sha256sum -c - && \
  unzip -q cmdline-tools.zip -d "$ANDROID_HOME/cmdline-tools" && \
  mv "$ANDROID_HOME/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest" && \
  rm cmdline-tools.zip && \
  yes | "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --licenses >/dev/null && \
  "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" \
    "platform-tools" \
    "platforms;${ANDROID_PLATFORM}" \
    "build-tools;${ANDROID_BUILD_TOOLS}" >/dev/null && \
  chown -R root:root "$ANDROID_HOME"
ENV PATH=$PATH:/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/platform-tools

# Rust toolchain — rustup + a pinned stable, root-owned (decision log #21).
#
# Third instance of the uv/Android pattern (#18, #19): decision 016 shipped a `rust`
# egress profile (crates.io, index.crates.io, static.crates.io) and suggest_profiles
# detects Cargo.toml, but the image had no cargo/rustc — a Rust project could reach
# crates.io and still not compile, the same "reach the registry, can't use it" gap
# that motivated uv. The toolchain goes in the shared base; the egress profile gates
# only network.
#
# WHY RUSTUP (not `apt-get install rustc cargo`): bookworm ships Rust ~1.63, which
# modern crates reject. rustup installs a pinned current stable and is the upstream-
# blessed installer — mirroring #18's choice of the uv binary over apt's stale Python.
#
# ROOT-OWNED, IMMUTABLE TOOLCHAIN: rustup-init runs at build time (before
# init-firewall.sh exists, so no egress profile is needed) with RUSTUP_HOME/CARGO_HOME
# under /opt, then both are chowned root. `node` runs cargo/rustc but cannot rewrite
# the compiler it runs — the same stance as uv's root-owned /usr/local/bin and the
# root-owned Android SDK. static.rust-lang.org is therefore a BUILD-TIME-ONLY host and
# is deliberately absent from egress/rust.txt; a pinned toolchain never self-updates,
# so a `rustup update` fails loudly against the root-owned RUSTUP_HOME rather than
# fetching — a different toolchain is a central-image rebuild, exactly like uv's
# UV_PYTHON_DOWNLOADS=never and the Android SDK's root-owned dir.
#
# WRITABLE-CACHE SPLIT: cargo must write a registry cache at runtime, but the toolchain
# must stay immutable. So the binaries and rustup proxies stay root-owned under
# /opt/{rustup,cargo} (on PATH), while the FINAL CARGO_HOME points at a node-writable
# /home/node/.cargo for the registry cache, config, and `cargo install` output. cargo
# is resolved via PATH (the immutable proxies); CARGO_HOME only steers where cargo
# WRITES, so repointing it does not weaken toolchain immutability.
#
# rustup-init is fetched at a pinned version and verified against the .sha256 published
# alongside it (via sha256sum -c), matching uv's verify-before-use (#18). This is
# transit-integrity only: the checksum comes from the SAME origin as the binary, so a
# compromised/MITM'd static.rust-lang.org could serve a matching pair. The stronger
# stance is the Android layer's (#19): pin the per-arch hash as a build ARG so a bump
# is diff-visible and a hostile origin is caught. That is the recommended hardening
# here too, deferred only because the authoring environment cannot reach the host to
# obtain the two arch hashes; a host-side bump of RUSTUP_VERSION should pin them. The
# blast radius is bounded: this runs at BUILD time into a root-owned dir, so a bad
# rustup-init cannot widen egress or escape the per-project boundary — it could only
# ship a bad compiler in the shared base, which the pin would close. The toolchain
# rustup then installs is hash-checked by rustup against the channel manifest fetched
# over TLS (not GPG-signed) — same origin, same caveat.
ARG RUSTUP_VERSION=1.27.1
ARG RUST_VERSION=1.83.0
ENV RUSTUP_HOME=/opt/rustup \
    CARGO_HOME=/opt/cargo \
    PATH=/opt/cargo/bin:$PATH
RUN case "$(dpkg --print-architecture)" in \
      amd64) RUST_TARGET=x86_64-unknown-linux-gnu ;; \
      arm64) RUST_TARGET=aarch64-unknown-linux-gnu ;; \
      *) echo "rust: unsupported architecture $(dpkg --print-architecture)" >&2; exit 1 ;; \
    esac && \
    cd /tmp && \
    RUSTUP_URL="https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/${RUST_TARGET}/rustup-init" && \
    wget -q "$RUSTUP_URL" -O rustup-init && \
    wget -q "${RUSTUP_URL}.sha256" -O rustup-init.sha256 && \
    printf '%s  rustup-init\n' "$(cut -d' ' -f1 rustup-init.sha256)" | sha256sum -c - && \
    chmod +x rustup-init && \
    ./rustup-init -y --no-modify-path --profile minimal \
      --default-toolchain "${RUST_VERSION}" \
      --component clippy --component rustfmt && \
    rm -f rustup-init rustup-init.sha256 && \
    chown -R root:root /opt/rustup /opt/cargo && \
    /opt/cargo/bin/rustc --version && /opt/cargo/bin/cargo --version
# Runtime CARGO_HOME is node-writable (registry cache) while the toolchain under /opt
# stays root-owned; PATH already resolves cargo/rustc to the immutable proxies.
ENV CARGO_HOME=/home/node/.cargo
RUN mkdir -p /home/node/.cargo && chown node:node /home/node/.cargo

# Set up non-root user
USER node

# Install global packages
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin

# Set the default shell to zsh rather than sh
ENV SHELL=/bin/zsh

# Set the default editor and visual
ENV EDITOR=nano
ENV VISUAL=nano

# Default powerline10k theme
ARG ZSH_IN_DOCKER_VERSION=1.2.0
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v${ZSH_IN_DOCKER_VERSION}/zsh-in-docker.sh)" -- \
  -p git \
  -p fzf \
  -a "source /usr/share/doc/fzf/examples/key-bindings.zsh" \
  -a "source /usr/share/doc/fzf/examples/completion.zsh" \
  -a "export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
  -x

# Install Claude
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}

# --- Everything below is per-project. Keep it LAST. -------------------------
# CC_EGRESS_PROFILE is the only build arg that varies between projects, so
# declaring it here means every layer above is shared across all projects'
# images (decision 016, S2: N projects must not mean N full builds — only this
# final layer is rebuilt when a project's egress profile differs).
ARG CC_EGRESS_PROFILE=""

COPY egress/ /usr/local/share/cc-egress/
COPY init-firewall.sh /usr/local/bin/
COPY link-claude-home.sh /usr/local/bin/

# The claude-workflows payload (skills, workflows, guides, patterns, hooks, and
# the global CLAUDE.md). Assembled from the repo by install.sh, so it is part of
# the blessed config the human reviews — not something a session can inject.
#
# Placed OUTSIDE /home/node/.claude on purpose: that path is a per-project
# volume (decision 016 H6) and a volume mount would shadow anything baked at
# that path. link-claude-home.sh symlinks these in at container start instead.
COPY claude-home/ /opt/claude-workflows/

USER root

# /etc/cc-egress-profile is root-owned and world-read-only. `node` has NOPASSWD sudo
# for init-firewall.sh and nothing else, so it can neither rewrite this file nor pass
# a wider profile through sudo (env_reset strips the environment). Widening a
# project's egress therefore requires a host-side re-register + re-bless + rebuild —
# i.e. a human. This is what keeps H5 (per-project egress) from becoming a
# self-service escape hatch for the agent.
RUN chmod +x /usr/local/bin/init-firewall.sh /usr/local/bin/link-claude-home.sh && \
  chown -R root:root /opt/claude-workflows && \
  find /opt/claude-workflows -type d -exec chmod 0555 {} + && \
  find /opt/claude-workflows -type f -exec chmod 0444 {} + && \
  find /opt/claude-workflows -type f \( -name '*.sh' -o -name '*.py' \) -exec chmod 0555 {} + && \
  chmod 0555 /usr/local/share/cc-egress && \
  chmod 0444 /usr/local/share/cc-egress/*.txt && \
  printf '%s\n' "${CC_EGRESS_PROFILE}" > /etc/cc-egress-profile && \
  chmod 0444 /etc/cc-egress-profile && \
  echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/node-firewall && \
  chmod 0440 /etc/sudoers.d/node-firewall

USER node
