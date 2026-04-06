#!/usr/bin/env bash

# Bazzite-DX: Image Information & Variant Adjustment
# Orchestrates metadata and hardware-specific workstation transformations.

set -eoux pipefail

# 1. Metadata Orchestration
IMAGE_VENDOR="${IMAGE_VENDOR:-ublue-os}"
IMAGE_NAME="${IMAGE_NAME:-bazzite-dx}"
IMAGE_REF="ostree-image-signed:docker://ghcr.io/$IMAGE_VENDOR/$IMAGE_NAME"
IMAGE_INFO="/usr/share/ublue-os/image-info.json"

if [[ -f "$IMAGE_INFO" ]]; then
	echo "Updating $IMAGE_INFO..."
	sed -i 's/"image-name": [^,]*/"image-name": "'"$IMAGE_NAME"'"/' "$IMAGE_INFO"
	sed -i 's|"image-ref": [^,]*|"image-ref": "'"$IMAGE_REF"'"|' "$IMAGE_INFO"
fi

echo "Updating /usr/lib/os-release..."
sed -i "s/^VARIANT_ID=.*/VARIANT_ID=$IMAGE_NAME/" /usr/lib/os-release

# 2. KDE Hardware Branding (Conditional)
if [[ "$IMAGE_NAME" != *gnome* ]] && [[ -f "/etc/xdg/kcm-about-distrorc" ]]; then
	echo "Updating KDE About branding..."
	sed -i "s|^Website=.*|Website=https://dev.bazzite.gg|" /etc/xdg/kcm-about-distrorc
	if [[ "$IMAGE_NAME" != *nvidia* ]]; then
		sed -i "s/^Variant=.*/Variant=Developer Experience/" /etc/xdg/kcm-about-distrorc
	else
		sed -i "s/^Variant=.*/Variant=Developer Experience (NVIDIA)/" /etc/xdg/kcm-about-distrorc
	fi
fi

# 3. Workstation Experience Adjustments
# - Enable Update Timers and Input Remapper UI
sed -i 's@^NoDisplay=true@NoDisplay=false@' /usr/share/applications/input-remapper-gtk.desktop
systemctl enable input-remapper.service
systemctl enable uupd.timer

# 4. Handheld-to-Workstation Cleanup (Deck Variants)
if [[ "$IMAGE_NAME" =~ "deck" ]]; then
	echo "Deck variant detected. Applying Workstation conversion..."
	rm -f /etc/sddm.conf.d/steamos.conf
	rm -f /etc/sddm.conf.d/virtualkbd.conf
	rm -f /etc/sddm.conf.d/zz-steamos-autologin.conf
	systemctl disable bazzite-autologin.service
fi

# 5. Desktop Environment Logic (GNOME vs KDE)
if [[ "$IMAGE_NAME" =~ "gnome" ]]; then
	echo "GNOME flavor detected: Enabling GDM..."
	systemctl enable gdm.service
	rm -rf /etc/sddm.conf.d/
else
	echo "KDE flavor detected: Restoring logout and user switching..."
	systemctl enable sddm.service || true
	[ -f /etc/xdg/kdeglobals ] && sed -i -E \
		-e 's/^(action\/switch_user)=false/\1=true/' \
		-e 's/^(action\/start_new_session)=false/\1=true/' \
		-e 's/^(action\/lock_screen)=false/\1=true/' \
		/etc/xdg/kdeglobals
fi
