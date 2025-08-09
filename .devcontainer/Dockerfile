ARG RUBY_VERSION=3.4.4
FROM ruby:${RUBY_VERSION}-slim-bookworm

# Install system dependencies
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
  && apt-get -y install --no-install-recommends \
  apt-utils \
  build-essential \
  ca-certificates \
  curl \
  git \
  gnupg \
  imagemagick \
  iproute2 \
  libpq-dev \
  libyaml-dev \
  libyaml-0-2 \
  openssh-client \
  postgresql-client \
  vim \
  wget \
  zsh \
  # Additional development tools
  htop \
  less \
  jq \
  tree \
  unzip \
  # Required for image processing
  libvips42 \
  # Required for debugging
  gdb \
  strace \
  # Required for OCR processing
  tesseract-ocr \
  tesseract-ocr-eng \
  && rm -rf /var/lib/apt/lists/*

# Install Node.js 20 LTS
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
  && apt-get install -y nodejs \
  && rm -rf /var/lib/apt/lists/*

# Install global npm packages for development
RUN npm install -g npm@latest

# Install Ruby gems globally for development
RUN gem update --system \
  && gem install bundler foreman solargraph rubocop

# Create a non-root user for development
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
  && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME -s /bin/zsh \
  && chown -R $USERNAME:$USERNAME /usr/local

# Install Oh My Zsh for better shell experience
USER $USERNAME
RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
  && echo 'export PATH="/workspace/bin:$PATH"' >> ~/.zshrc \
  && echo 'alias be="bundle exec"' >> ~/.zshrc \
  && echo 'alias rs="bin/rails server"' >> ~/.zshrc \
  && echo 'alias rc="bin/rails console"' >> ~/.zshrc \
  && echo 'alias rt="bin/rails test"' >> ~/.zshrc \
  && echo 'alias dev="bin/dev"' >> ~/.zshrc

USER root

WORKDIR /workspace

# Set the default shell to zsh
ENV SHELL=/bin/zsh
