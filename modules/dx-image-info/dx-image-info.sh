#!/usr/bin/env bash

# Bazzite-DX: Image Information & Universal Workstation Polish
# Reflects variant name in metadata and converts handheld/minimal traits into Workstation UX.

set -eoux pipefail

# 1. Metadata Orchestration
IMAGE_VENDOR="${IMAGE_VENDOR:-ublue-os}"
IMAGE_NAME="${IMAGE_NAME:-bazzite-dx}"
IMAGE_REF="ostree-image-signed:docker://ghcr.io/$IMAGE_VENDOR/$IMAGE_NAME"
IMAGE_INFO="/usr/share/ublue-os/image-info.json"
FEDORA_MAJOR_VERSION=$(awk -F= '/VERSION_ID/ {print $2}' /etc/os-release | tr -d '"')

if [[ -d "/usr/share/ublue-os" ]]; then
	echo "Updating $IMAGE_INFO..."
	cat > "$IMAGE_INFO" <<EOF
{
  "image-name": "$IMAGE_NAME",
  "image-vendor": "$IMAGE_VENDOR",
  "image-ref": "$IMAGE_REF",
  "image-tag": "latest",
  "fedora-version": "$FEDORA_MAJOR_VERSION"
}
EOF
fi

echo "Polishing /usr/lib/os-release..."
sed -i "s|^HOME_URL=.*|HOME_URL=\"https://bazzite.gg\"|" /usr/lib/os-release
sed -i "s|^DOCUMENTATION_URL=.*|DOCUMENTATION_URL=\"https://dev.bazzite.gg\"|" /usr/lib/os-release
sed -i "s|^SUPPORT_URL=.*|SUPPORT_URL=\"https://github.com/ublue-os/bazzite/issues\"|" /usr/lib/os-release
sed -i "s|^BUG_REPORT_URL=.*|BUG_REPORT_URL=\"https://github.com/ublue-os/bazzite/issues\"|" /usr/lib/os-release
sed -i "s|^CPE_NAME=\"cpe:/o:fedoraproject:fedora|CPE_NAME=\"cpe:/o:universal-blue:bazzite-dx|" /usr/lib/os-release

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

# 3. Desktop Environment Fixes (Universal for DX)
if [[ "$IMAGE_NAME" =~ "gnome" ]]; then
	echo "GNOME flavor detected: Enabling GDM..."
	systemctl enable --force gdm.service
	rm -rf /etc/sddm.conf.d/
else
	echo "KDE flavor detected: Enabling SDDM and restoring interactive features..."
	systemctl enable --force sddm.service || true
	[ -f /etc/xdg/kdeglobals ] && sed -i -E \
		-e 's/^(action\/switch_user)=false/\1=true/' \
		-e 's/^(action\/start_new_session)=false/\1=true/' \
		-e 's/^(action\/lock_screen)=false/\1=true/' \
		/etc/xdg/kdeglobals
fi

# 4. Workstation Conversion (Cleanup Handheld Artifacts Globally)
# These files/services only exist on Deck variants; removal is safe and silent on Desktop.
echo "Applying Workstation-standard cleanup..."
rm -f /etc/sddm.conf.d/steamos.conf \
      /etc/sddm.conf.d/virtualkbd.conf \
      /etc/sddm.conf.d/zz-steamos-autologin.conf
systemctl disable bazzite-autologin.service || true

# Show interactive tools that are hidden by default upstream
sed -i 's@^NoDisplay=true@NoDisplay=false@' /usr/share/applications/input-remapper-gtk.desktop 2>/dev/null || true
