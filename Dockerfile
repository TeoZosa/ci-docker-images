# syntax=docker/dockerfile:experimental

FROM debian:bullseye-slim@sha256:83e867b8399a53fc5f730a3ac9c8a8bc9cf19f7531ccf96d9a5c1b14f021e433

LABEL maintainer="Teofilo Zosa <teo@sonosim.com>"
ENV LANG C.UTF-8

# Configure `bash` as the default shell
# -  symlinking bash to `/bin/sh` as a hack since Makisu image builder does
#    not support the `SHELL` directive and to ensure a consistent environment
#    for image users.
# hadolint ignore=DL4005
RUN ln -sf /bin/bash /bin/sh
ENV HOME="/root"
ENV ENV="${HOME}/.bashrc"
ENV BASH_ENV="${ENV}"

# Install common functionality for downstream layers/user env
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates=20200601 \
        curl=7.72.0-1 \
        git=1:2.29.2-1 \
        make=4.3-4 && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install `pyenv` for Python version management
ENV PYENV_ROOT="${HOME}/.pyenv"
ENV PATH="${PYENV_ROOT}/bin:${PATH}"
# hadolint ignore=DL4006,SC2016,SC2039
RUN git clone https://github.com/pyenv/pyenv.git "${PYENV_ROOT}" && \
        echo 'export PYENV_ROOT="${PYENV_ROOT}"' >> "${ENV}" && \
        echo -e '\
        if command -v pyenv 1>/dev/null 2>&1 && [ -z "${PYENV_LOADED+x}" ]; \
        then\n \
            export PYENV_LOADED="true"\n \
            eval "$(pyenv init -)"\n \
        fi\n' \
        >> "${ENV}"

# Install `pyenv` Python source build tools and Python Interpreters
# hadolint ignore=DL4006,SC2016,SC2039,SC2046
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential=12.8 \
        libbz2-dev=1.0.8-4 \
        libffi-dev=3.3-5 \
        liblzma-dev=5.2.4-1+b1 \
        libncurses5-dev=6.2+20200918-1 \
        libreadline-dev=8.1~rc2-2 \
        libsqlite3-dev=3.33.0-1 \
        libssl-dev=1.1.1h-1 \
        libxml2-dev=2.9.10+dfsg-6.2 \
        libxmlsec1-dev=1.2.30-1 \
        llvm=1:9.0-49.1 \
        parallel=20161222-1.1 \
        tk-dev=8.6.9+1+b1 \
        xz-utils=5.2.4-1+b1 \
        zlib1g-dev=1:1.2.11.dfsg-2 && \
    PYTHON_VERSIONS=(3.7.9 3.8.6 3.9.0) && \
    parallel -j 0 -k pyenv install {} ::: "${PYTHON_VERSIONS[@]}" && \
    pyenv global $(pyenv versions --bare) && \
    find $PYENV_ROOT/versions -type d \
        '(' -name '__pycache__' -o \
            -name 'test' -o \
            -name 'tests' \
        ')' \
        -exec rm -rfv '{}' + && \
    find $PYENV_ROOT/versions -type f \
        '(' -name '*.py[co]' -o \
            -name '*.exe' \
        ')' \
        -exec rm -fv '{}' + && \
    apt-get purge -y --auto-remove \
        build-essential \
        libbz2-dev \
        libffi-dev \
        liblzma-dev \
        libncurses5-dev \
        libreadline-dev \
        libssl-dev \
        libxml2-dev \
        libxmlsec1-dev \
        llvm \
        parallel \
        tk-dev \
        xz-utils \
        zlib1g-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install `poetry` via `curl` and system `python`
ENV PATH="${HOME}/.poetry/bin:${PATH}"
# hadolint ignore=DL4006,SC2039
RUN . "${ENV}" && \
    set -o pipefail && \
    curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python && \
    poetry --version && \
    poetry config virtualenvs.in-project true && \
    poetry config --list

# Install executable for pre-commit hook (`hadolint`)
RUN HADOLINT_GIT_REPO="https://github.com/hadolint/hadolint" && \
    HADOLINT_BINARIES="${HADOLINT_GIT_REPO}/releases/download/v1.18.0" && \
    curl -sSL "${HADOLINT_BINARIES}/hadolint-Linux-x86_64" -o /bin/hadolint && \
    chmod +x /bin/hadolint

# Install Go for pre-commit hook (`shfmt`)
ENV GO111MODULE=on \
    CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=amd64 \
    PATH="${PATH}:/usr/local/go/bin"
# hadolint ignore=DL4006,SC2039
RUN GO_TAR=go1.15.5.linux-amd64.tar.gz && \
    set -o pipefail && \
    curl -sSL "https://golang.org/dl/${GO_TAR}" | tar -C /usr/local -xzvf -

WORKDIR /app
ENTRYPOINT ["/bin/bash"]
