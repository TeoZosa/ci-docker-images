# syntax=docker/dockerfile:experimental

FROM teozosa/docker-images:pyenv-python-3.7.9-3.8.6-3.9.4-poetry_master
LABEL maintainer="Teofilo Zosa <teo@sonosim.com>"
ENV LANG C.UTF-8

# Install executable for pre-commit hook (`hadolint`)
RUN HADOLINT_GIT_REPO="https://github.com/hadolint/hadolint" && \
    HADOLINT_BINARIES="${HADOLINT_GIT_REPO}/releases/download/v2.0.0" && \
    curl -sSL "${HADOLINT_BINARIES}/hadolint-Linux-x86_64" -o /bin/hadolint && \
    chmod +x /bin/hadolint

# Install Go for pre-commit hook (`shfmt`)
ENV GO111MODULE=on \
    CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=amd64 \
    PATH="${PATH}:/usr/local/go/bin"
# hadolint ignore=DL4006,SC2039
RUN GO_TAR=go1.16.3.linux-amd64.tar.gz && \
    set -o pipefail && \
    curl -sSL "https://golang.org/dl/${GO_TAR}" | tar -C /usr/local -xzf -

WORKDIR /app
ENTRYPOINT ["/bin/bash"]
