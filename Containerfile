ARG BASE_IMAGE

FROM scratch AS ctx

COPY system_files /files
COPY build_files /build_files

FROM ${BASE_IMAGE}

RUN --mount=type=tmpfs,dst=/tmp \
  --mount=type=bind,from=ctx,source=/,target=/run/context \
  mkdir -p /var/roothome && \
  /run/context/build_files/build.sh
