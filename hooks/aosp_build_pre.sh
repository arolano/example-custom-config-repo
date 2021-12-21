#!/usr/bin/env bash

cd "${AOSP_BUILD_DIR}"

#Re-adding microg in 12th branch too
echo "applying microg patches"
cd "${AOSP_BUILD_DIR}/packages/modules/Permission"
patch -p1 --no-backup-if-mismatch < "${AOSP_BUILD_DIR}/platform/prebuilts/microg/00001-fake-package-sig.patch"
cd "${AOSP_BUILD_DIR}/frameworks/base"
patch -p1 --no-backup-if-mismatch < "${AOSP_BUILD_DIR}/platform/prebuilts/microg/00002-microg-sigspoof.patch"

patch_mkbootfs(){
  cd "${AOSP_BUILD_DIR}/system/core"
  patch -p1 --no-backup-if-mismatch < "${CUSTOM_DIR}/patches/0001_allow_dotfiles_in_cpio.patch"
}

patch_recovery(){
  cd "${AOSP_BUILD_DIR}/bootable/recovery/"
  patch -p1 --no-backup-if-mismatch < "${CUSTOM_DIR}/patches/0002_recovery_add_mark_successful_option.patch"
}

patch_bitgapps(){
  log_header "${FUNCNAME[0]}"

  rm -rf "${AOSP_BUILD_DIR}/vendor/gapps"
  retry git clone https://github.com/BiTGApps/aosp-build.git "${AOSP_BUILD_DIR}/vendor/gapps"
  cd "${AOSP_BUILD_DIR}/vendor/gapps"
  git lfs pull

  echo -ne "\\nTARGET_ARCH := arm64" >> "${AOSP_BUILD_DIR}/device/google/${DEVICE_FAMILY}/device.mk"
  echo -ne "\\nTARGET_SDK_VERSION := 31" >> "${AOSP_BUILD_DIR}/device/google/${DEVICE_FAMILY}/device.mk"
  echo -ne "\\n\$(call inherit-product, vendor/gapps/gapps.mk)" >> "${AOSP_BUILD_DIR}/device/google/${DEVICE_FAMILY}/device.mk"
}

patch_safetynet(){
 #cd "${AOSP_BUILD_DIR}/system/security/"
 #patch -p1 --no-backup-if-mismatch < "${CUSTOM_DIR}/patches/0003-keystore-Block-key-attestation-for-Google-Play-Servi.patch"

  cd "${AOSP_BUILD_DIR}/frameworks/base/"
  rm -rf "${AOSP_BUILD_DIR}/frameworks/base/core/java/com/android/internal/gmscompat/"
  patch -p1 --no-backup-if-mismatch < "${CUSTOM_DIR}/patches/0004-bypass-safetynet.patch"

  cd "${AOSP_BUILD_DIR}/system/core/"
  patch -p1 --no-backup-if-mismatch < "${CUSTOM_DIR}/patches/0005-init-set-properties-to-make-safetynet-pass.patch"
}

# apply custom hosts file
custom_hosts_file="https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
echo "applying custom hosts file ${custom_hosts_file}"
retry wget -q -O "${AOSP_BUILD_DIR}/system/core/rootdir/etc/hosts" "${custom_hosts_file}"

if [ "${ADD_MAGISK}" == "true" ]; then
    patch_mkbootfs
fi
patch_recovery

if [ "${ADD_BITGAPPS}" == "true" ]; then
  patch_bitgapps
fi

# Use a cool alternative bootanimation
if [ "${USE_CUSTOM_BOOTANIMATION}" == "true" ]; then
  cp -f "${CUSTOM_DIR}/prebuilt/bootanimation.zip" "${AOSP_BUILD_DIR}/system/media/bootanimation.zip"
  echo -ne "\\nPRODUCT_COPY_FILES += \\\\\nsystem/media/bootanimation.zip:system/media/bootanimation.zip" >> "${AOSP_BUILD_DIR}/device/google/${DEVICE_FAMILY}/device.mk"
fi

# Patch Keystore to pass SafetyNet
if [ "${SAFETYNET_BYPASS}" == "true" ]; then
  patch_safetynet
fi
