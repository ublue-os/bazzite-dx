FROM scratch AS ctx

COPY system_files /files
COPY build_files /build_files

FROM ghcr.io/ublue-os/bazzite:testing

RUN --mount=type=tmpfs,dst=/tmp \
  --mount=type=bind,from=ctx,source=/,target=/run/context \
  /run/context/build_files/build.sh
