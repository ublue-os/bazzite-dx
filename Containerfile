ARG BASE_IMAGE="ghcr.io/ublue-os/bazzite-deck:stable"
ARG COMMON_IMAGE="${COMMON_IMAGE:-ghcr.io/projectbluefin/common:latest}"
ARG BREW_IMAGE="${BREW_IMAGE:-ghcr.io/ublue-os/brew:latest}"

FROM ${COMMON_IMAGE} AS common
FROM ${BREW_IMAGE} AS brew

FROM scratch AS ctx
COPY build_files /build_files
COPY system_files /system_files

# Import common uBlue layers
COPY --from=common /system_files /system_files/shared
COPY --from=brew /system_files /system_files/shared

# Overwrite with Bazzite-DX specific files if necessary
COPY system_files /system_files

FROM ${BASE_IMAGE}

ARG IMAGE_NAME="${IMAGE_NAME:-bazzite-dx}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR:-ublue-os}"

RUN --mount=type=tmpfs,dst=/tmp \
  --mount=type=bind,from=ctx,source=/,target=/run/context \
  mkdir -p /var/roothome && \
  /run/context/build_files/build.sh
