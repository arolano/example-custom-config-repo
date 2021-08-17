#!/usr/bin/env bash

cd "${AOSP_BUILD_DIR}"

#echo "applying microg patches"
#cd "${AOSP_BUILD_DIR}/packages/modules/Permission"
#patch -p1 --no-backup-if-mismatch < "${AOSP_BUILD_DIR}/platform/prebuilts/microg/00001-fake-package-sig.patch"
#cd "${AOSP_BUILD_DIR}/frameworks/base"
#patch -p1 --no-backup-if-mismatch < "${AOSP_BUILD_DIR}/platform/prebuilts/microg/00002-microg-sigspoof.patch"

patch_mkbootfs(){
  cd "${AOSP_BUILD_DIR}/system/core"
  patch -p1 --no-backup-if-mismatch < "${CUSTOM_DIR}/patches/0001_allow_dotfiles_in_cpio.patch"
}

patch_recovery(){
  cd "${AOSP_BUILD_DIR}/bootable/recovery/"
  patch -p1 --no-backup-if-mismatch < "${CUSTOM_DIR}/patches/0002_recovery_add_mark_successful_option.patch"
}

# apply custom hosts file
custom_hosts_file="https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
echo "applying custom hosts file ${custom_hosts_file}"
retry wget -q -O "${AOSP_BUILD_DIR}/system/core/rootdir/etc/hosts" "${custom_hosts_file}"

patch_mkbootfs
patch_recovery
