#!/usr/bin/bash
set -xeuo pipefail

IMAGE_NAME="${IMAGE_NAME:-bazzite-dx}"

# 1. Input Remapper and Update Timer Setup
# Ensure UI displays and services are properly enabled for the DX experience
sed -i 's@^NoDisplay=true@NoDisplay=false@' /usr/share/applications/input-remapper-gtk.desktop
systemctl enable input-remapper.service
systemctl enable uupd.timer

# 2. Variant-Based Logic (Deck vs Desktop)
# We use IMAGE_NAME to apply specific adjustments for different hardware/software targets.
if [[ "$IMAGE_NAME" =~ "deck" ]]; then
	echo "Deck variant detected ($IMAGE_NAME). Applying handheld-to-desktop DX cleanup..."
	# Remove -deck specific changes to allow for login screens and session selection in settings
	rm -f /etc/sddm.conf.d/steamos.conf
	rm -f /etc/sddm.conf.d/virtualkbd.conf
	rm -f /etc/sddm.conf.d/zz-steamos-autologin.conf
	rm -f /usr/share/gamescope-session-plus/bootstrap_steam.tar.gz
	systemctl disable bazzite-autologin.service

	# Remove steamos-manager as requested for DX workstation experience
	if rpm -q steamos-manager >/dev/null 2>&1; then
		dnf5 remove -y steamos-manager
	fi
else
	echo "Desktop variant detected ($IMAGE_NAME). Ensuring no handheld-specific components..."
	# Ensure steamos-manager is not present in desktop images
	if rpm -q steamos-manager >/dev/null 2>&1; then
		dnf5 remove -y steamos-manager
	fi
fi

# 3. Desktop Environment Logic (GNOME vs KDE)
if [[ "$IMAGE_NAME" =~ "gnome" ]]; then
	echo "GNOME flavor detected: Enabling GDM and cleaning SDDM..."
	systemctl enable gdm.service
	# Remove sddm configs if they exist to prevent conflicts in GNOME images
	rm -rf /etc/sddm.conf.d/
	if rpm -q sddm >/dev/null 2>&1; then
		dnf5 remove -y sddm
	fi
else
	echo "KDE/Other flavor detected: Restoring logout and user switching features..."
	# Ensure SDDM is ready for KDE if not on GNOME
	systemctl enable sddm.service || true
	# Re-enable logout and switch user functionality in KDE
	sed -i -E \
		-e 's/^(action\/switch_user)=false/\1=true/' \
		-e 's/^(action\/start_new_session)=false/\1=true/' \
		-e 's/^(action\/lock_screen)=false/\1=true/' \
		-e 's/^(kcm_sddm\.desktop)=false/\1=true/' \
		-e 's/^(kcm_plymouth\.desktop)=false/\1=true/' \
		/etc/xdg/kdeglobals
fi
