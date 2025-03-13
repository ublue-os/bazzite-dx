#!/usr/bin/env bash
# TODO: Move this to ublue-os/packages as 'ublue-os-dx-groups'
# See: https://github.com/ublue-os/bluefin/blob/1be5bcabc0b584b16611ecde557027f1f4b292d3/system_files/dx/usr/libexec/bluefin-dx-groups

# SCRIPT VERSION
GROUP_SETUP_VER=1
GROUP_SETUP_VER_FILE="/etc/ublue/dx-groups"
GROUP_SETUP_VER_RAN=$(<"$GROUP_SETUP_VER_FILE")

# Run script if updated
if [[ -f $GROUP_SETUP_VER_FILE && "$GROUP_SETUP_VER" == "$GROUP_SETUP_VER_RAN" ]]; then
  echo "Group setup has already run. Exiting..."
  exit 0
fi

# Function to append a group entry to /etc/group
append_group() {
  local group_name="${1:?}"
  local gline

  grep -qE "^$group_name" /etc/group && return
  while read -r gline; do
    [[ -z ${gline} || ${gline} =~ ^#.* ]] && continue
    if [[ ${gline%%:*} == "$group_name" ]]; then
      echo "Appending $group_name to /etc/group"
      echo "$gline" >> /etc/group
      break
    fi
  done < <(cat /usr/lib/group /usr/etc/group || :)
  # NOTE(@Zeglius Thu Mar 13 2025): Concatenate /usr/lib/group and /usr/etc/group.
  # I'm observing docker being missing at /usr/lib/group.
  # Probably because of rechunk not being used in my custom image and thus groups not being processed.
}

# Setup Groups
append_group docker
append_group incus-admin
append_group lxd
append_group libvirt

IFS=, read -r -a wheelarray < <(getent group wheel | cut -d ":" -f 4)
for user in "${wheelarray[@]}"
do
  usermod -aG docker "$user"
  usermod -aG incus-admin "$user"
  usermod -aG lxd "$user"
  usermod -aG libvirt "$user"
done

# Prevent future executions
echo "Writing state file"
echo "$GROUP_SETUP_VER" > "$GROUP_SETUP_VER_FILE"