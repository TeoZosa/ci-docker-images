# syntax=docker/dockerfile:experimental

FROM debian:bullseye-slim@sha256:697685da31675cd0c04f9d40592055b71d6bfa163be54ff2148dc1967113948b

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
# renovate: datasource=repology depName=debian_testing/ca-certificates versioning=loose
ARG CA_CERTIFICATES_VERSION="20210119"
# renovate: datasource=repology depName=debian_testing/curl versioning=loose
ARG CURL_VERSION="7.74.0-1.2"
# renovate: datasource=repology depName=debian_testing/git versioning=loose
ARG GIT_VERSION="1:2.30.2-1"
# renovate: datasource=repology depName=debian_testing/git-lfs versioning=loose
ARG GIT_LFS_VERSION="2.13.2-1+b2"
# renovate: datasource=repology depName=debian_testing/make versioning=loose
ARG MAKE_VERSION="4.3-4.1"
# renovate: datasource=repology depName=debian_testing/procps versioning=loose
ARG PROCPS_VERSION="2:3.3.17-5"
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates=${CA_CERTIFICATES_VERSION} \
        curl=${CURL_VERSION} \
        git=${GIT_VERSION} \
        git-lfs=${GIT_LFS_VERSION} \
        make=${MAKE_VERSION} \
        procps=${PROCPS_VERSION} && \
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
            eval "$(pyenv init --path)"\n \
        fi\n' \
        >> "${ENV}"

# Install `pyenv` Python source build tools and Python Interpreters
# renovate: datasource=repology depName=debian_testing/build-essential versioning=loose
ARG BUILD_ESSENTIAL_VERSION="12.9"
# renovate: datasource=repology depName=debian_testing/libbz2-dev versioning=loose
ARG LIBBZ2_DEV_VERSION="1.0.8-4"
# renovate: datasource=repology depName=debian_testing/libffi-dev versioning=loose
ARG LIBFFI_DEV_VERSION="3.3-6"
# renovate: datasource=repology depName=debian_testing/liblzma-dev versioning=loose
ARG LIBLZMA_DEV_VERSION="5.2.5-2"
# renovate: datasource=repology depName=debian_testing/libncurses5-dev versioning=loose
ARG LIBNCURSES5_DEV_VERSION="6.2+20201114-2"
# renovate: datasource=repology depName=debian_testing/libreadline-dev versioning=loose
ARG LIBREADLINE_DEV_VERSION="8.1-1"
# renovate: datasource=repology depName=debian_testing/libsqlite3-dev versioning=loose
ARG LIBSQLITE3_DEV_VERSION="3.34.1-3"
# renovate: datasource=repology depName=debian_testing/libssl-dev versioning=loose
ARG LIBSSL_DEV_VERSION="1.1.1k-1"
# renovate: datasource=repology depName=debian_testing/libxml2-dev versioning=loose
ARG LIBXML2_DEV_VERSION="2.9.10+dfsg-6.6"
# renovate: datasource=repology depName=debian_testing/libxmlsec1-dev versioning=loose
ARG LIBXMLSEC1_DEV_VERSION="1.2.31-1"
# renovate: datasource=repology depName=debian_testing/llvm versioning=loose
ARG LLVM_VERSION="1:11.0-51+nmu4"
# renovate: datasource=repology depName=debian_testing/parallel versioning=loose
ARG PARALLEL_VERSION="20161222-1.1"
# renovate: datasource=repology depName=debian_testing/tk-dev versioning=loose
ARG TK_DEV_VERSION="8.6.11+1"
# renovate: datasource=repology depName=debian_testing/xz-utils versioning=loose
ARG XZ_UTILS_VERSION="5.2.5-2"
# renovate: datasource=repology depName=debian_testing/zlib1g-dev versioning=loose
ARG ZLIB1G_DEV_VERSION="1:1.2.11.dfsg-2"
# hadolint ignore=DL4006,SC2016,SC2039,SC2046
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential=${BUILD_ESSENTIAL_VERSION} \
        libbz2-dev=${LIBBZ2_DEV_VERSION} \
        libffi-dev=${LIBFFI_DEV_VERSION} \
        liblzma-dev=${LIBLZMA_DEV_VERSION} \
        libncurses5-dev=${LIBNCURSES5_DEV_VERSION} \
        libreadline-dev=${LIBREADLINE_DEV_VERSION} \
        libsqlite3-dev=${LIBSQLITE3_DEV_VERSION} \
        libssl-dev=${LIBSSL_DEV_VERSION} \
        libxml2-dev=${LIBXML2_DEV_VERSION} \
        libxmlsec1-dev=${LIBXMLSEC1_DEV_VERSION} \
        llvm=${LLVM_VERSION} \
        parallel=${PARALLEL_VERSION} \
        tk-dev=${TK_DEV_VERSION} \
        xz-utils=${XZ_UTILS_VERSION} \
        zlib1g-dev=${ZLIB1G_DEV_VERSION} && \
    PYTHON_VERSIONS=(3.7.9 3.8.6 3.9.4) && \
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
ENV PATH="${HOME}/.local/bin:${PATH}"
# hadolint ignore=DL4006,SC2039
RUN . "${ENV}" && \
    set -o pipefail && \
    curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/install-poetry.py | python && \
    poetry --version && \
    poetry config virtualenvs.in-project true && \
    poetry config --list

# Install MySQL for downstream client images
# renovate: datasource=repology depName=debian_testing/default-libmysqlclient-dev versioning=loose
ARG DEFAULT_LIBMYSQLCLIENT_DEV_VERSION="1.0.7"
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        default-libmysqlclient-dev=${DEFAULT_LIBMYSQLCLIENT_DEV_VERSION} && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /app
ENTRYPOINT ["/bin/bash"]
