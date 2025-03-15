FROM scratch AS ctx

COPY system_files /files
COPY build_files /build_files

FROM ghcr.io/ublue-os/bazzite:testing@sha256:a2125b5ebc4246d3a4d714ddc3f7e3df7fc25c647b31fc2155d8348fa7249526

RUN --mount=type=tmpfs,dst=/tmp \
  --mount=type=bind,from=ctx,source=/,target=/run/context \
  /run/context/build_files/build.sh
