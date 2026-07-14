# Adapted from Anthropic's reference devcontainer for Claude Code
# (anthropics/claude-code .devcontainer). Local changes:
#   - decision 015: added bats, ripgrep, shellcheck (this repo's test suite and SI loop)
#   - decision 016: egress profiles baked in; the profile is written root-owned to
#     /etc/cc-egress-profile so an in-container agent cannot widen its own allowlist.
# Keep this file minimal-diff against upstream so refreshes are easy.
FROM node:20

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
# The node:20 base ships python3.11 but no pip and, crucially, no `ensurepip`, so
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
# Installed to /usr/local/bin, which is root-owned. Unlike /usr/local/share (chowned
# to node above for npm), `node` cannot rewrite the toolchain binary it runs.
ARG UV_VERSION=0.11.28
RUN case "$(dpkg --print-architecture)" in \
    amd64) UV_TARGET=x86_64-unknown-linux-gnu ;; \
    arm64) UV_TARGET=aarch64-unknown-linux-gnu ;; \
    *) echo "uv: unsupported architecture $(dpkg --print-architecture)" >&2; exit 1 ;; \
  esac && \
  wget -qO- "https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/uv-${UV_TARGET}.tar.gz" \
    | tar xz -C /tmp && \
  install -o root -g root -m 0755 "/tmp/uv-${UV_TARGET}/uv" /usr/local/bin/uv && \
  install -o root -g root -m 0755 "/tmp/uv-${UV_TARGET}/uvx" /usr/local/bin/uvx && \
  rm -rf "/tmp/uv-${UV_TARGET}"

# UV_PYTHON_DOWNLOADS=never: uv resolves the interpreter itself, and when it dislikes
# the system one it silently downloads a managed CPython from GitHub — which the base
# egress profile happens to allow. Pinning it to `never` keeps the image's python3.11
# the only interpreter, so a version mismatch is a loud error rather than a quiet
# fetch through the firewall.
#
# UV_LINK_MODE=copy: the uv cache lives in the container filesystem while venvs live
# under /workspace, a bind mount. Hardlinking across that device boundary is
# impossible, so the default mode warns on every single install.
ENV UV_PYTHON_DOWNLOADS=never \
    UV_LINK_MODE=copy

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

USER root

# /etc/cc-egress-profile is root-owned and world-read-only. `node` has NOPASSWD sudo
# for init-firewall.sh and nothing else, so it can neither rewrite this file nor pass
# a wider profile through sudo (env_reset strips the environment). Widening a
# project's egress therefore requires a host-side re-register + re-bless + rebuild —
# i.e. a human. This is what keeps H5 (per-project egress) from becoming a
# self-service escape hatch for the agent.
RUN chmod +x /usr/local/bin/init-firewall.sh && \
  chmod 0555 /usr/local/share/cc-egress && \
  chmod 0444 /usr/local/share/cc-egress/*.txt && \
  printf '%s\n' "${CC_EGRESS_PROFILE}" > /etc/cc-egress-profile && \
  chmod 0444 /etc/cc-egress-profile && \
  echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/node-firewall && \
  chmod 0440 /etc/sudoers.d/node-firewall

USER node
