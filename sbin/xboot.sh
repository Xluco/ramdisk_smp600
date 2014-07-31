#!/system/bin/sh
BB="/sbin/busybox"

mount -o remount,rw /;
mount -o remount,rw /system /system;

echo "Start xboot.sh" `date` >> /sdcard/xluco_kernel/log.txt;

/system/xbin/daemonsu --auto-daemon &

### REDUNDANCY ### 
### This should have been done by the update-script & init.rc,
### but it's important for stability so lets do it again to be safe

    # make directory for Knox to be moved to
    if [ ! -d /sdcard/xluco_kernel/knox_backup ]; then
        mkdir -p /sdcard/xluco_kernel/knox_backup;
        echo "KNOX backup folder created" >> /sdcard/xluco_kernel/log.txt;
    fi

    # disable knox & tima 
    pm disable com.sec.knox.seandroid;

    BP="/system/build.prop"
    if grep -q ro.config.knox=1 $BP; then
        $BB sed -i "s/ro.config.knox=1/ro.config.knox=0/g" $BP;
        echo "ro.config.knox=0 set" >> /sdcard/xluco_kernel/log.txt;
    fi

    if grep -q ro.config.tima=1 $BP; then
        $BB sed -i "s/ro.config.tima=1/ro.config.tima=0/g" $BP;
        echo "ro.config.tima=0 set" >> /sdcard/xluco_kernel/log.txt;
    fi

    APKS="KNOXAgent.apk KNOXAgent.odex KnoxAttestationAgent.apk KnoxAttestationAgent.odex KNOXStore.apk KNOXStore.odex KNOXStub.apk ContainerAgent.apk ContainerAgent.odex KLMSAgent.apk KLMSAgent.odex ContainerEventsRelayManager.apk ContainerEventsRelayManager.odex KnoxVpnServices.apk KnoxVpnServices.odex"
    for APK in $APKS; do
    if [ -f /system/app/$APK ]; then
        dd if="/system/app/$APK" of="/sdcard/xluco_kernel/knox_backup/$APK";
        echo $APK "moved" >> /sdcard/xluco_kernel/log.txt;
    fi
    done

    # build.pro WiFi fix
    if grep -q ro.securestorage.support=true $BP; then
        $BB sed -i "s/ro.securestorage.support=true/ro.securestorage.support=false/g" $BP;
        echo "ro.securestorage.support=false set" >> /sdcard/xluco_kernel/log.txt;
    fi

### 
### END REDUNDANCY ### 
### 

# USB power saving
local POWER_LEVEL=`ls /sys/bus/usb/devices/*/power/level`;
for i in $POWER_LEVEL; do
    chmod 777 $i;
    echo "auto" > $i;
done&

local POWER_AUTOSUSPEND=`ls /sys/bus/usb/devices/*/power/autosuspend`;
for i in $POWER_AUTOSUSPEND; do
    chmod 777 $i;
    echo "1" > $i;
done&

# BUS power saving - i2c, sdio
buslist="i2c sdio";
for bus in $buslist; do
    PC=`ls /sys/bus/$bus/devices/*/power/control`;
        for i in $PC; do
            chmod 777 $i;
            echo "auto" > $i;
        done;
done&

# BUS power saving - spi
SPI=`ls /sys/bus/spi/devices/*/*/power/control`;
for i in $SPI; do
    chmod 777 $i;
    echo "auto" > $i;
done&

# wait for systemui and increase its priority
while sleep 1; do
  if [ `$BB pidof com.android.systemui` ]; then
    systemui=`$BB pidof com.android.systemui`;
    $BB renice -18 $systemui;
    $BB echo -17 > /proc/$systemui/oom_adj;
    $BB chmod 100 /proc/$systemui/oom_adj;
    exit;
  fi;
done&

# lmk whitelist for common launchers and increase launcher priority
list="com.android.launcher com.google.android.googlequicksearchbox org.adw.launcher org.adwfreak.launcher net.alamoapps.launcher com.anddoes.launcher com.android.lmt com.chrislacy.actionlauncher.pro com.cyanogenmod.trebuchet com.gau.go.launcherex com.gtp.nextlauncher com.miui.mihome2 com.mobint.hololauncher com.mobint.hololauncher.hd com.qihoo360.launcher com.teslacoilsw.launcher com.tsf.shell org.zeam";
while sleep 60; do
  for class in $list; do
    if [ `$BB pgrep $class | head -n 1` ]; then
      launcher=`$BB pgrep $class`;
      $BB echo -17 > /proc/$launcher/oom_adj;
      $BB chmod 100 /proc/$launcher/oom_adj;
      $BB renice -18 $launcher;
    fi;
  done;
  exit;
done&

# init.d scripts
if [ ! -d /system/etc/init.d ]; then
    mkdir /system/etc/init.d;
    chown -R root.root /system/etc/init.d;
    chmod -R 777 /system/etc/init.d;
    echo "init.d folder created" `date` >> /sdcard/xluco_kernel/log.txt;
fi

# Fast Random Generator (frandom) support at boot
chmod 664 /dev/frandom;
rm -f /dev/random;
rm -f /dev/urandom;
ln /dev/frandom /dev/random;
ln /dev/frandom /dev/urandom;
chmod 664 /dev/random;
chmod 664 /dev/urandom;

# Start UKSM
echo 1 > /sys/kernel/mm/uksm/run;

# NTFS Support
if [ ! -e /system/xbin/ntfs-3g ]; then
    $BB dd if="/sbin/ntfs-3g" of="/system/xbin/ntfs-3g";
    chmod 755 /system/xbin/ntfs-3g;
    echo "ntfs-3g binary moved to xbin" >> /sdcard/xluco_kernel/log.txt;
else
    $BB rm -f /sbin/ntfs-3g;
    echo "redundant ntfs-3g binary removed from sbin" >> /sdcard/xluco_kernel/log.txt;
fi
  
# Limit Debugging
echo "N" > /sys/module/kernel/parameters/initcall_debug;
echo "0" > /sys/module/alarm_dev/parameters/debug_mask;
echo "0" > /sys/module/binder/parameters/debug_mask;
echo "0" > /sys/module/xt_qtaguid/parameters/debug_mask;

# Disable IPV6 for security and battery
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv4.route.flush=1

# Interactive Tweaks
echo 1400000 > /sys/devices/system/cpu/cpufreq/interactive/hispeed_freq;

# Spring Cleaning
rm -rf /cache/lost+found/* 2> /dev/null;
rm -rf /data/lost+found/* 2> /dev/null;
rm -rf /data/tombstones/* 2> /dev/null;
rm -rf /data/anr/* 2> /dev/null;

echo "xboot.sh done" `date` >> /sdcard/xluco_kernel/log.txt;

mount -o remount,ro /;
mount -o remount,ro /system /system;
exit 0
