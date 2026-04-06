export repo_organization := env("GITHUB_REPOSITORY_OWNER", "ublue-os")
export default_image := env("IMAGE_NAME", "bazzite-deck")
export default_tag := env("DEFAULT_TAG", "latest")
export bib_image := env("BIB_IMAGE", "quay.io/centos-bootc/bootc-image-builder:latest")
export PODMAN := if path_exists("/usr/bin/podman") == "true" { env("PODMAN", "/usr/bin/podman") } else if path_exists("/usr/bin/docker") == "true" { env("PODMAN", "docker") } else { env("PODMAN", "exit 1 ; ") }
export build_driver := if PODMAN =~ "docker" { "docker" } else { "podman" }
export PULL_POLICY := if PODMAN =~ "docker" { "missing" } else { "newer" }

alias build-vm := build-qcow2
alias run-vm := run-vm-qcow2

[private]
default:
    @just --list

# Check development environment and image matrix status
[group('Just')]
status:
    @echo "=== Image Configuration ==="
    @echo "Default:  {{ default_image }}"
    @echo "Registry: {{ repo_organization }}"
    @echo "Tag:      {{ default_tag }}"
    @echo ""
    @echo "=== Matrix Insights (image-versions.yaml) ==="
    @echo "Available variants: $(yq '.images[].name' image-versions.yaml | xargs)"
    @echo ""
    @echo "=== Local DX Images (localhost/bazzite-dx-*) ==="
    @${PODMAN} images --filter "reference=localhost/bazzite-dx*" --format "table {{ '{{.Repository}}' }}\t{{ '{{.Tag}}' }}\t{{ '{{.ID}}' }}\t{{ '{{.CreatedSince}}' }}"
    @echo ""
    @echo "=== Tooling Versions ==="
    @echo "Just:      $(just --version | head -n1)"
    @echo "Podman:    $(${PODMAN} --version)"
    @echo "BlueBuild: $(bluebuild --version 2>/dev/null || echo 'Not installed')"

# Check Just Syntax and BlueBuild Recipe
[group('Just')]
check:
    #!/usr/bin/env bash
    find . -type f -name "*.just" | while read -r file; do
    	echo "Checking syntax: $file"
    	just --unstable --fmt --check -f $file
    done
    echo "Checking syntax: Justfile"
    just --unstable --fmt --check -f Justfile
    if [ -f recipes/recipe.yml ]; then
      echo "Validating BlueBuild recipe..."
      bluebuild validate recipes/recipe.yml
    fi
    echo "Running ShellCheck on Bash scripts..."
    just lint

# Fix Just Syntax and Format scripts
[group('Just')]
fix:
    #!/usr/bin/env bash
    find . -type f -name "*.just" | while read -r file; do
    	echo "Fixing syntax: $file"
    	just --unstable --fmt -f $file
    done
    echo "Fixing syntax: Justfile"
    just --unstable --fmt -f Justfile
    echo "Formatting Bash scripts..."
    just format

# Runs shell check on all Bash scripts (uses Container if local not found)
[group('Utility')]
lint:
    #!/usr/bin/env bash
    set -eoux pipefail
    if ! command -v shellcheck &>/dev/null; then
        echo "shellcheck not found locally. Running via ${PODMAN}..."
        /usr/bin/find . -name "*.sh" -type f -not -path "./.bluebuild*" -exec ${PODMAN} run --rm -v "$PWD:/mnt:Z" docker.io/koalaman/shellcheck-alpine shellcheck /mnt/{} ';'
    else
        /usr/bin/find . -iname "*.sh" -type f -not -path "./.bluebuild*" -exec shellcheck "{}" ';'
    fi

# Runs shfmt on all Bash scripts (uses Container if local not found)
[group('Utility')]
format:
    #!/usr/bin/env bash
    set -eoux pipefail
    if ! command -v shfmt &>/dev/null; then
        echo "shfmt not found locally. Running via ${PODMAN}..."
        /usr/bin/find . -name "*.sh" -type f -not -path "./.bluebuild*" -exec ${PODMAN} run --rm -v "$PWD:/mnt:Z" --entrypoint shfmt docker.io/mvdan/shfmt:latest -w /mnt/{} ';'
    else
        /usr/bin/find . -iname "*.sh" -type f -not -path "./.bluebuild*" -exec shfmt --write "{}" ';'
    fi

# Clean project artifacts
[group('Utility')]
clean:
    #!/usr/bin/env bash
    set -euxo pipefail
    rm -rf _build/
    rm -rf .bluebuild/
    rm -f previous.manifest.json
    rm -f changelog.md
    rm -f output.env
    rm -rf output/

# Rebase the local system to the newly built image (local testing)
[group('Lifecycle')]
rebase-local target_image=default_image:
    #!/usr/bin/env bash
    set -euo pipefail
    rm -f /tmp/{{ target_image }}.tar || true
    {{ PODMAN }} save localhost/{{ target_image }}:latest --format oci-archive -o /tmp/{{ target_image }}.tar
    sudo rpm-ostree rebase ostree-unverified-image:oci-archive:/tmp/{{ target_image }}.tar
    rm -f /tmp/{{ target_image }}.tar
    echo "Rebase complete. Please reboot to test your local image."

# Rollback last transaction (Safety)
[group('Lifecycle')]
rollback:
    sudo rpm-ostree rollback

# Build image using BlueBuild CLI (Matrix aware)
[group('Build')]
build target_image=default_image tag=default_tag: (build-recipe target_image tag)
    #!/usr/bin/env bash
    set -euo pipefail
    DX_NAME=$(echo "{{ target_image }}" | sed 's/^bazzite/bazzite-dx/')
    bluebuild build --build-driver {{ build_driver }} --run-driver {{ build_driver }} .bluebuild/build-recipe.yml
    # Tag precisely from the recipe-generated name
    RECIPE_NAME=$(yq -r .name .bluebuild/build-recipe.yml)
    echo "Tagging localhost/${RECIPE_NAME}:latest as localhost/${DX_NAME}:{{ tag }}"
    ${PODMAN} tag localhost/${RECIPE_NAME}:latest localhost/${DX_NAME}:{{ tag }}

# Build image without using cache
[group('Build')]
build-nocache target_image=default_image tag=default_tag: (build-recipe target_image tag)
    #!/usr/bin/env bash
    set -euo pipefail
    DX_NAME=$(echo "{{ target_image }}" | sed 's/^bazzite/bazzite-dx/')
    bluebuild build --no-cache --build-driver {{ build_driver }} --run-driver {{ build_driver }} .bluebuild/build-recipe.yml
    # Tag precisely from the recipe-generated name
    RECIPE_NAME=$(yq -r .name .bluebuild/build-recipe.yml)
    echo "Tagging localhost/${RECIPE_NAME}:latest as localhost/${DX_NAME}:{{ tag }}"
    ${PODMAN} tag localhost/${RECIPE_NAME}:latest localhost/${DX_NAME}:{{ tag }}

# Generate build recipe with complete OCI metadata (Unified Logic)
[private]
build-recipe target_image tag:
    #!/usr/bin/env bash
    set -euo pipefail
    # Resolve and Patch
    export BASE_IMAGE=$(yq ".images[] | select(.name == \"{{ target_image }}\") | .image" image-versions.yaml)
    export BASE_TAG=$(yq ".images[] | select(.name == \"{{ target_image }}\") | .tag" image-versions.yaml)
    export BASE_DIGEST=$(yq ".images[] | select(.name == \"{{ target_image }}\") | .digest" image-versions.yaml)
    export IMAGE_NAME="bazzite-dx"
    export IMAGE_DESC="Developer Experience (DX) layer for Bazzite. Matrix-ready and Universal."
    export ARTIFACTHUB_LOGO_URL="https://avatars.githubusercontent.com/u/187439889?s=200&v=4"
    export REPO_OWNER=$(git remote get-url origin | sed -E 's/.*[:\/](.*)\/(.*)\.git/\1/')
    export KERNEL_RELEASE=$(uname -r)
    export DATE_CREATED=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
    export VERSION_FULL="${BASE_TAG}.$(date +%Y%m%d)"
    export REVISION=$(git rev-parse HEAD 2>/dev/null || echo 'local')

    if [[ -n "$BASE_DIGEST" && "$BASE_DIGEST" != "null" ]]; then
        export IMAGE_VERSION_VAL="${BASE_TAG}@${BASE_DIGEST}"
    else
        export IMAGE_VERSION_VAL="${BASE_TAG}"
    fi

    if [ -z "${BASE_IMAGE}" ] || [ "${BASE_IMAGE}" == "null" ]; then
        echo "Error: Image '{{ target_image }}' not found in image-versions.yaml"
        exit 1
    fi

    echo "Generating build recipe for {{ target_image }} (Base: ${BASE_IMAGE}:${IMAGE_VERSION_VAL})..."
    mkdir -p .bluebuild
    yq '
      .name = env(IMAGE_NAME) |
      .description = env(IMAGE_DESC) |
      .base-image = env(BASE_IMAGE) |
      .image-version = env(IMAGE_VERSION_VAL)
    ' recipes/recipe.yml > .bluebuild/build-recipe.yml

    yq -i '
      .alt-tags = (["latest", "stable", "{{ tag }}", env(BASE_TAG)] | unique) |
      .labels."io.artifacthub.package.logo-url" = env(ARTIFACTHUB_LOGO_URL) |
      .labels."io.artifacthub.package.readme-url" = "https://raw.githubusercontent.com/" + env(REPO_OWNER) + "/bazzite-dx/main/README.md" |
      .labels."io.artifacthub.package.maintainers" = "[{\"name\": \"nklowns\", \"email\": \"nklowns@users.noreply.github.com\"}]" |
      .labels."io.artifacthub.package.keywords" = "bootc,bazzite,dx,ublue,universal-blue,fedora,gaming,developer" |
      .labels."io.artifacthub.package.deprecated" = "false" |
      .labels."io.artifacthub.package.prerelease" = "false" |
      .labels."containers.bootc" = "1" |
      .labels."ostree.linux" = env(KERNEL_RELEASE) |
      .labels."org.opencontainers.image.vendor" = env(REPO_OWNER) |
      .labels."org.opencontainers.image.licenses" = "Apache-2.0" |
      .labels."org.opencontainers.image.url" = "https://dev.bazzite.gg" |
      .labels."org.opencontainers.image.documentation" = "https://raw.githubusercontent.com/" + env(REPO_OWNER) + "/bazzite-dx/main/README.md" |
      .labels."org.opencontainers.image.version" = env(VERSION_FULL) |
      .labels."org.opencontainers.image.revision" = env(REVISION)
    ' .bluebuild/build-recipe.yml

[private]
_rootful_load_image $target_image=default_image $tag=default_tag:
    #!/usr/bin/env bash
    set -euxo pipefail
    if [[ -n "${SUDO_USER:-}" || "${UID}" -eq "0" ]]; then
      echo "Already root or running under sudo, no need to load image from user ${PODMAN}."
      exit 0
    fi
    full_image="localhost/${target_image}:${tag}"
    USER_IMG_ID=$(${PODMAN} images --filter reference="${full_image}" --format "'{{ '{{.ID}}' }}'")
    if [ -n "$USER_IMG_ID" ]; then
      echo "Loading ${full_image} (ID: $USER_IMG_ID) into rootful podman..."
      COPYTMP=$(mktemp -p "${PWD}" -d -t _build_podman_scp.XXXXXXXXXX)
      sudo TMPDIR=${COPYTMP} ${PODMAN} image scp ${UID}@localhost::"${full_image}" root@localhost::"${full_image}"
      rm -rf "${COPYTMP}"
    else
      echo "Image ${full_image} not found in user storage."
      sudo ${PODMAN} pull "${full_image}" || (echo "Failed to pull image. Build it first." && exit 1)
    fi

[private]
_build-bib $target_image $tag $type $config: (_rootful_load_image target_image tag)
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p "output"
    sudo rm -rf "output/${type}" "output/bootiso" || true
    full_image="localhost/${target_image}:${tag}"
    args="--type ${type} --progress verbose --use-librepo=True --rootfs=btrfs --local"
    sudo ${PODMAN} run --rm -it --privileged --pull=${PULL_POLICY} --net=host \
      --security-opt label=type:unconfined_t \
      -v $(pwd)/${config}:/config.toml:ro -v $(pwd)/output:/output \
      -v /var/lib/containers/storage:/var/lib/containers/storage \
      "${bib_image}" ${args} "${full_image}"
    sudo chown -R $USER:$USER output/

[group('Image Builders (BIB)')]
build-qcow2 $target_image=default_image $tag=default_tag: && (_build-bib target_image tag "qcow2" "disk_config/devel.toml")

[group('Image Builders (BIB)')]
build-raw $target_image=default_image $tag=default_tag: && (_build-bib target_image tag "raw" "disk_config/devel.toml")

[group('Image Builders (BIB)')]
build-iso $target_image=default_image $tag=default_tag: && (_build-bib target_image tag "iso" "disk_config/iso.toml")

[private]
_run-vm $target_image $tag $type $config:
    #!/usr/bin/env bash
    set -euxo pipefail
    image_file="output/${type}/disk.${type}"
    if [[ $type == iso ]]; then image_file="output/bootiso/install.iso"; fi
    if [[ ! -f "${image_file}" ]]; then just "build-${type}" "$target_image" "$tag"; fi
    port=8006;
    while grep -q :${port} <<< $(ss -tunalp); do port=$(( port + 1 )); done
    echo "Using Port: ${port}. Connect to http://localhost:${port}"
    ${PODMAN} run --rm --privileged --pull=newer \
      -p 127.0.0.1:${port}:8006 -p 127.0.0.1:2222:22 \
      -e CPU_CORES=4 -e RAM_SIZE=8G -e DISK_SIZE=64G -e TPM=Y -e GPU=Y \
      --device=/dev/kvm -v "${PWD}/${image_file}":"/boot.${type}" \
      docker.io/qemux/qemu &
    xdg-open http://localhost:${port} || true
    wait $!

[group('VM Runners')]
run-vm-qcow2 $target_image=default_image $tag=default_tag: && (_run-vm target_image tag "qcow2" "disk_config/devel.toml")

[group('VM Runners')]
run-vm-raw $target_image=default_image $tag=default_tag: && (_run-vm target_image tag "raw" "disk_config/devel.toml")

[group('VM Runners')]
run-vm-iso $target_image=default_image $tag=default_tag: && (_run-vm target_image tag "iso" "disk_config/iso.toml")

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
