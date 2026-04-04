#!/usr/bin/env bash

# Image Information Orchestration
# Updates the image metadata in /usr/share/ublue-os/image-info.json
# and ensures VARIANT_ID matches the current target.

set -eoux pipefail

# Fallbacks for variables not provided by environment
IMAGE_VENDOR="${IMAGE_VENDOR:-ublue-os}"
IMAGE_NAME="${IMAGE_NAME:-bazzite-dx}"
IMAGE_REF="ostree-image-signed:docker://ghcr.io/$IMAGE_VENDOR/$IMAGE_NAME"

IMAGE_INFO="/usr/share/ublue-os/image-info.json"

# image-info File
if [[ -f "$IMAGE_INFO" ]]; then
	echo "Updating $IMAGE_INFO..."
	sed -i 's/"image-name": [^,]*/"image-name": "'"$IMAGE_NAME"'"/' "$IMAGE_INFO"
	sed -i 's|"image-ref": [^,]*|"image-ref": "'"$IMAGE_REF"'"|' "$IMAGE_INFO"
fi

# OS Release File
echo "Updating /usr/lib/os-release..."
sed -i "s/^VARIANT_ID=.*/VARIANT_ID=$IMAGE_NAME/" /usr/lib/os-release

# KDE About page (Conditional)
# We don't want to edit a non-existing file on gnome variants
if [[ "$IMAGE_NAME" != *gnome* ]] && [[ -f "/etc/xdg/kcm-about-distrorc" ]]; then
	echo "Updating KDE About page..."
	sed -i "s|^Website=.*|Website=https://dev.bazzite.gg|" /etc/xdg/kcm-about-distrorc
	if [[ "$IMAGE_NAME" != *nvidia* ]]; then
		sed -i "s/^Variant=.*/Variant=Developer Experience/" /etc/xdg/kcm-about-distrorc
	else
		sed -i "s/^Variant=.*/Variant=Developer Experience (NVIDIA)/" /etc/xdg/kcm-about-distrorc
	fi
fi
