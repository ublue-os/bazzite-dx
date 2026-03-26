export repo_organization := env("GITHUB_REPOSITORY_OWNER", "ublue-os")
export image_name := env("IMAGE_NAME", "bazzite-dx")
export default_tag := env("DEFAULT_TAG", "latest")
export bib_image := env("BIB_IMAGE", "quay.io/centos-bootc/bootc-image-builder:latest")
export SUDO_DISPLAY := if `if [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then echo true; fi` == "true" { "true" } else { "false" }
export SUDOIF := if `id -u` == "0" { "" } else if SUDO_DISPLAY == "true" { "sudo --askpass" } else { "sudo" }
export PODMAN := if path_exists("/usr/bin/podman") == "true" { env("PODMAN", "/usr/bin/podman") } else if path_exists("/usr/bin/docker") == "true" { env("PODMAN", "docker") } else { env("PODMAN", "exit 1 ; ") }
export PULL_POLICY := if PODMAN =~ "docker" { "missing" } else { "newer" }

alias build-vm := build-qcow2
alias rebuild-vm := rebuild-qcow2
alias run-vm := run-vm-qcow2

[private]
default:
    @just --list

# Check system and development environment status
[group('Just')]
status:
    @echo "=== Image Configuration ==="
    @echo "Project:  {{ image_name }}"
    @echo "Registry: {{ repo_organization }}"
    @echo "Tag:      {{ default_tag }}"
    @echo ""
    @echo "=== Local Images (localhost/) ==="
    @${PODMAN} images --filter "reference=localhost/{{ image_name }}*" --format "table {{ '{{.Repository}}' }}\t{{ '{{.Tag}}' }}\t{{ '{{.ID}}' }}\t{{ '{{.CreatedSince}}' }}"
    @echo ""
    @echo "=== Tooling Versions ==="
    @echo "Just:    $(just --version | head -n1)"
    @echo "Podman:  $(${PODMAN} --version)"
    @echo ""
    @echo "=== BIB Engine ==="
    @echo "Image:   {{ bib_image }}"

# Check Just Syntax
[group('Just')]
check:
    #!/usr/bin/env bash
    find . -type f -name "*.just" | while read -r file; do
      echo "Checking syntax: $file"
      just --unstable --fmt --check -f $file
    done
    echo "Checking syntax: Justfile"
    just --unstable --fmt --check -f Justfile

# Fix Just Syntax
[group('Just')]
fix:
    #!/usr/bin/env bash
    find . -type f -name "*.just" | while read -r file; do
      echo "Checking syntax: $file"
      just --unstable --fmt -f $file
    done
    echo "Checking syntax: Justfile"
    just --unstable --fmt -f Justfile || { exit 1; }

# Clean Repo
[group('Utility')]
clean:
    #!/usr/bin/env bash
    set -euxo pipefail
    touch _build
    find *_build* -exec rm -rf {} \;
    rm -f previous.manifest.json
    rm -f changelog.md
    rm -f output.env
    rm -rf output/

# Sudo Clean Repo
[group('Utility')]
[private]
sudo-clean:
    ${SUDOIF} just clean

# Build the image using the specified parameters
[group('Build')]
build $target_image=image_name $tag=default_tag:
    #!/usr/bin/env bash

    # Get Version
    ver="${tag}-$(date +%Y%m%d)"

    BUILD_ARGS=()
    BUILD_ARGS+=("--build-arg" "IMAGE_NAME=${image_name}")
    BUILD_ARGS+=("--build-arg" "IMAGE_VENDOR=${repo_organization}")
    if [[ -z "$(git status -s)" ]]; then
      BUILD_ARGS+=("--build-arg" "SHA_HEAD_SHORT=$(git rev-parse --short HEAD)")
    fi

    # Ensure localhost/ prefix for local builds if no registry is specified
    full_image="${target_image}:${tag}"
    if [[ "${full_image}" != */* ]]; then
      full_image="localhost/${full_image}"
    fi

    ${PODMAN} build \
        "${BUILD_ARGS[@]}" \
        --pull=${PULL_POLICY} \
        --tag "${full_image}" \
        .

[private]
_rootful_load_image $target_image=image_name $tag=default_tag:
    #!/usr/bin/env bash
    set -euxo pipefail

    if [[ -n "${SUDO_USER:-}" || "${UID}" -eq "0" ]]; then
      echo "Already root or running under sudo, no need to load image from user ${PODMAN}."
      exit 0
    fi

    # Ensure localhost/ prefix for local images
    full_image="${target_image}:${tag}"
    if [[ "${full_image}" != */* ]]; then
      full_image="localhost/${full_image}"
    fi

    set +e
    resolved_tag=$(${PODMAN} inspect -t image "${full_image}" | jq -r '.[].RepoTags.[0]')
    return_code=$?
    set -e

    USER_IMG_ID=$(${PODMAN} images --filter reference="${full_image}" --format "'{{ '{{.ID}}' }}'")

    if [[ $return_code -eq 0 ]]; then
      # Load into Rootful ${PODMAN}
      ID=$(${SUDOIF} ${PODMAN} images --filter reference="${full_image}" --format "'{{ '{{.ID}}' }}'")
      if [[ "$ID" != "$USER_IMG_ID" ]]; then
        COPYTMP=$(mktemp -p "${PWD}" -d -t _build_podman_scp.XXXXXXXXXX)
        ${SUDOIF} TMPDIR=${COPYTMP} ${PODMAN} image scp ${UID}@localhost::"${full_image}" root@localhost::"${full_image}"
        rm -rf "${COPYTMP}"
      fi
    else
      # Make sure the image is present and/or up to date
      ${SUDOIF} ${PODMAN} pull "${full_image}"
    fi

[private]
_build-bib $target_image $tag $type $config: (_rootful_load_image target_image tag)
    #!/usr/bin/env bash
    set -euo pipefail

    mkdir -p "output"

    echo "Cleaning up previous build"
    if [[ $type == iso ]]; then
      sudo rm -rf "output/bootiso" || true
    else
      sudo rm -rf "output/${type}" || true
    fi

    args="--type ${type}"
    args+=" --progress verbose"
    args+=" --use-librepo=True"
    args+=" --rootfs=btrfs"

    # Ensure localhost/ prefix for local images
    full_image="${target_image}:${tag}"
    if [[ "${full_image}" != */* ]]; then
      full_image="localhost/${full_image}"
    fi

    if [[ $full_image == localhost/* ]]; then
      args+=" --local"
    fi

    sudo ${PODMAN} run \
      --rm \
      -it \
      --privileged \
      --pull=${PULL_POLICY} \
      --net=host \
      --security-opt label=type:unconfined_t \
      -v $(pwd)/${config}:/config.toml:ro \
      -v $(pwd)/output:/output \
      -v /var/lib/containers/storage:/var/lib/containers/storage \
      "${bib_image}" \
      ${args} \
      "${full_image}"

    sudo chown -R $USER:$USER output/

_rebuild-bib $target_image $tag $type $config: (build target_image tag) && (_build-bib target_image tag type config)

[group('Image Builders (BIB)')]
build-qcow2 $target_image=image_name $tag=default_tag: && (_build-bib target_image tag "qcow2" "disk_config/devel.toml")

[group('Image Builders (BIB)')]
build-raw $target_image=image_name $tag=default_tag: && (_build-bib target_image tag "raw" "disk_config/devel.toml")

[group('Image Builders (BIB)')]
build-iso $target_image=image_name $tag=default_tag: && (_build-bib target_image tag "iso" "disk_config/iso.toml")

[group('Image Builders (BIB)')]
rebuild-qcow2 $target_image=image_name $tag=default_tag: && (_rebuild-bib target_image tag "qcow2" "disk_config/devel.toml")

[group('Image Builders (BIB)')]
rebuild-raw $target_image=image_name $tag=default_tag: && (_rebuild-bib target_image tag "raw" "disk_config/devel.toml")

[group('Image Builders (BIB)')]
rebuild-iso $target_image=image_name $tag=default_tag: && (_rebuild-bib target_image tag "iso" "disk_config/iso.toml")

_run-vm $target_image $tag $type $config:
    #!/usr/bin/env bash
    set -euxo pipefail

    image_file="output/${type}/disk.${type}"

    if [[ $type == iso ]]; then
      image_file="output/bootiso/install.iso"
    fi

    if [[ ! -f "${image_file}" ]]; then
      just "build-${type}" "$target_image" "$tag"
    fi

    # Determine which port to use
    port=8006;
    while grep -q :${port} <<< $(ss -tunalp); do
      port=$(( port + 1 ))
    done
    echo "Using Port: ${port}"
    echo "Connect to http://localhost:${port}"
    run_args=()
    run_args+=(--rm --privileged)
    run_args+=(--pull=newer)
    run_args+=(--publish "127.0.0.1:${port}:8006")
    run_args+=(--publish "127.0.0.1:2222:22")
    run_args+=(--env "CPU_CORES=4")
    run_args+=(--env "RAM_SIZE=8G")
    run_args+=(--env "DISK_SIZE=64G")
    # run_args+=(--env "BOOT_MODE=windows_secure")
    run_args+=(--env "TPM=Y")
    run_args+=(--env "GPU=Y")
    run_args+=(--device=/dev/kvm)
    run_args+=(--volume "${PWD}/${image_file}":"/boot.${type}")
    run_args+=(docker.io/qemux/qemu)
    ${PODMAN} run "${run_args[@]}" &
    xdg-open http://localhost:${port}
    wait $!

[group('VM Runners')]
run-vm-qcow2 $target_image=image_name $tag=default_tag: && (_run-vm target_image tag "qcow2" "disk_config/devel.toml")

[group('VM Runners')]
run-vm-raw $target_image=image_name $tag=default_tag: && (_run-vm target_image tag "raw" "disk_config/devel.toml")

[group('VM Runners')]
run-vm-iso $target_image=image_name $tag=default_tag: && (_run-vm target_image tag "iso" "disk_config/iso.toml")

# Run a virtual machine using systemd-vmspawn
[group('VM Runners')]
spawn-vm rebuild="0" type="qcow2" ram="6G":
    #!/usr/bin/env bash
    set -euo pipefail
    [ "{{ rebuild }}" -eq 1 ] && echo "Rebuilding the image" && just build-{{ type }}
    systemd-vmspawn \
      -M "bootc-image" \
      --console=gui \
      --cpus=2 \
      --ram=$(echo {{ ram }}| /usr/bin/numfmt --from=iec) \
      --network-user-mode \
      --vsock=false --pass-ssh-key=false \
      -i ./output/**/*.{{ type }}
