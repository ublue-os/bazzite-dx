FROM scratch AS ctx

COPY system_files /files
COPY build_files /build_files

FROM ghcr.io/ublue-os/bazzite:testing@sha256:8883ebbace2b6c821804ea7302836aa2e7496390ed7eb8a92fc2de4caefe59ff

RUN --mount=type=tmpfs,dst=/tmp \
  --mount=type=bind,from=ctx,source=/,target=/run/context \
  /run/context/build_files/build.sh
