#!/system/bin/sh
BB="/system/xbin/busybox"
LOGFILE="/sdcard/xluco_kernel/log.txt"

PATH=/sbin:/system/sbin:/system/bin:/system/xbin
export PATH

mount -o rw,remount /system

echo "Start xboot.sh" `date` >> $LOGFILE;

### REDUNDANCY ### 
### This should have been done by the update-script & init.rc,
### but it's important for stability so lets do it again to be safe

    # make directory for Knox to be moved to
    if [ ! -d /sdcard/xluco_kernel/knox_backup ]; then
        mkdir -p /sdcard/xluco_kernel/knox_backup;
        echo "KNOX backup folder created" >> $LOGFILE;
    fi

    # disable knox & tima 
    pm disable com.sec.knox.seandroid;

    BP="/system/build.prop"
    if grep -q ro.config.knox=1 $BP; then
        $BB sed -i "s/ro.config.knox=1/ro.config.knox=0/g" $BP;
        echo "ro.config.knox=0 set" >> $LOGFILE;
    fi

    if grep -q ro.config.tima=1 $BP; then
        $BB sed -i "s/ro.config.tima=1/ro.config.tima=0/g" $BP;
        echo "ro.config.tima=0 set" >> $LOGFILE;
    fi

    APKS="KNOXAgent.apk KNOXAgent.odex KnoxAttestationAgent.apk KnoxAttestationAgent.odex KNOXStore.apk KNOXStore.odex KNOXStub.apk ContainerAgent.apk ContainerAgent.odex KLMSAgent.apk KLMSAgent.odex ContainerEventsRelayManager.apk ContainerEventsRelayManager.odex KnoxVpnServices.apk KnoxVpnServices.odex"
    for APK in $APKS; do
    if [ -f /system/app/$APK ]; then
        dd if="/system/app/$APK" of="/sdcard/xluco_kernel/knox_backup/$APK";
        echo $APK "moved" >> $LOGFILE;
    fi
    done

    # build.pro WiFi fix
    if grep -q ro.securestorage.support=true $BP; then
        $BB sed -i "s/ro.securestorage.support=true/ro.securestorage.support=false/g" $BP;
        echo "ro.securestorage.support=false set" >> $LOGFILE;
    fi

### 
### END REDUNDANCY ### 
### 

# wait for systemui and increase its priority
while sleep 1; do
	if [ `pidof com.android.systemui` ]; then
		systemui=`pidof com.android.systemui`;
		renice -18 $systemui;
		echo -17 > /proc/$systemui/oom_adj;
		chmod 100 /proc/$systemui/oom_adj;
	exit;
	fi;
done&

# lmk whitelist for common launchers and increase launcher priority
list="com.android.launcher com.google.android.googlequicksearchbox org.adw.launcher org.adwfreak.launcher net.alamoapps.launcher com.anddoes.launcher com.android.lmt com.chrislacy.actionlauncher.pro com.cyanogenmod.trebuchet com.gau.go.launcherex com.gtp.nextlauncher com.miui.mihome2 com.mobint.hololauncher com.mobint.hololauncher.hd com.qihoo360.launcher com.teslacoilsw.launcher com.tsf.shell org.zeam";
while sleep 60; do
for class in $list; do
	if [ `pgrep $class | head -n 1` ]; then
		launcher=`pgrep $class`;
		echo -17 > /proc/$launcher/oom_adj;
		chmod 100 /proc/$launcher/oom_adj;
		renice -18 $launcher;
	fi;
	done;
	exit;
done&

# init.d scripts
if [ ! -d /system/etc/init.d ]; then
    mkdir /system/etc/init.d;
	chown -R root.root /system/etc/init.d
	chmod -R 755 /system/etc/init.d
    echo "init.d folder created" `date` >> $LOGFILE;
fi

# Fast Random Generator (frandom) support at boot
chmod 664 /dev/frandom;
rm -f /dev/random;
rm -f /dev/urandom;
ln /dev/frandom /dev/random;
ln /dev/frandom /dev/urandom;
chmod 664 /dev/random;
chmod 664 /dev/urandom;

# NTFS Support
$BB dd if="/sbin/ntfs-3g" of="/system/xbin/ntfs-3g";
$BB chmod 755 /system/xbin/ntfs-3g;
  
# Limit Debugging
echo "N" > /sys/module/kernel/parameters/initcall_debug;
echo "0" > /sys/module/alarm_dev/parameters/debug_mask;
echo "0" > /sys/module/binder/parameters/debug_mask;
echo "0" > /sys/module/xt_qtaguid/parameters/debug_mask;

# Disable IPV6 for security and battery
#sysctl -w net.ipv6.conf.all.disable_ipv6=1
#sysctl -w net.ipv4.route.flush=1

# Interactive Tweaks
#echo 1400000 > /sys/devices/system/cpu/cpufreq/interactive/hispeed_freq;

echo "xboot.sh done" `date` >> $LOGFILE;

mount -o ro,remount /system
exit 0
