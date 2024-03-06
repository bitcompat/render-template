# syntax=docker/dockerfile:1.7
FROM golang:1.21-bullseye AS golang-builder

ARG PACKAGE=render-template
ARG TARGET_DIR=common
# renovate: datasource=github-releases depName=bitnami/render-template
ARG BUILD_VERSION=1.0.3
ARG REF=v${BUILD_VERSION}
ARG CGO_ENABLED=0

RUN mkdir -p /opt/bitnami
RUN <<EOT /bin/bash
    set -ex

    apt-get update -qq && apt-get install -y git make upx patch

    rm -rf ${PACKAGE} || true
    mkdir -p ${PACKAGE}
    git clone -b "${REF}" https://github.com/bitnami/render-template ${PACKAGE}
EOT

COPY --link patches ${PACKAGE}/patches

RUN --mount=type=cache,target=/root/.cache/go-build <<EOT /bin/bash
    set -ex

    pushd ${PACKAGE}
    patch -p1 < patches/0001-fix-make-fix-compatibility-with-golang-1.19.patch
    rm -rf out
    make build
    upx --ultra-brute out/${PACKAGE}

    mkdir -p /opt/bitnami/${TARGET_DIR}/licenses
    mkdir -p /opt/bitnami/${TARGET_DIR}/bin
    cp -f COPYING /opt/bitnami/${TARGET_DIR}/licenses/${PACKAGE}-${BUILD_VERSION}.txt
    cp -f out/${PACKAGE} /opt/bitnami/${TARGET_DIR}/bin/render-template
    popd

    rm -rf ${PACKAGE}
EOT

FROM bitnami/minideb:bullseye as stage-0

COPY --link --from=golang-builder /opt/bitnami /opt/bitnami
