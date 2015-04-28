#!/system/bin/sh
BB="/system/xbin/busybox"
LOG="/sdcard/xluco/log.txt"

mount -o remount,rw /system

echo "xboot.sh started" `date` > $LOG;

# make directory for knox to be moved to
if [ ! -d /sdcard/xluco/knox_backup ]; then
	mkdir -p /sdcard/xluco/knox_backup;
fi

# disable knox, tima, securestorage and selinux
pm disable com.sec.knox.seandroid

setprop ro.config.knox 0
setprop ro.config.tima 0
setprop ro.securestorage.support false

BP="/system/build.prop"
if grep -q ro.config.knox=1 $BP; then
	$BB sed -i "s/ro.config.knox=1/ro.config.knox=0/g" $BP;
fi

if grep -q ro.config.tima=1 $BP; then
	$BB sed -i "s/ro.config.tima=1/ro.config.tima=0/g" $BP;
fi

if grep -q ro.securestorage.support=true $BP; then
	$BB sed -i "s/ro.securestorage.support=true/ro.securestorage.support=false/g" $BP;
fi

# move knox apps to backup location
APKS="KNOXAgent.apk KNOXAgent.odex KnoxAttestationAgent.apk KnoxAttestationAgent.odex KNOXStore.apk KNOXStore.odex KNOXStub.apk ContainerAgent.apk ContainerAgent.odex KLMSAgent.apk KLMSAgent.odex ContainerEventsRelayManager.apk ContainerEventsRelayManager.odex KnoxVpnServices.apk KnoxVpnServices.odex"
for APK in $APKS; do
if [ -f /system/app/$APK ]; then
	$BB mv -f "/system/app/$APK" "/sdcard/xluco/knox_backup/$APK";
fi
done

# Fast Random Generator (frandom) support
chmod 664 /dev/frandom;
rm -f /dev/random;
rm -f /dev/urandom;
ln /dev/frandom /dev/random;
ln /dev/frandom /dev/urandom;
chmod 664 /dev/random;
chmod 664 /dev/urandom;

# wait for systemui and increase its priority
while sleep 1; do
	if [ `pidof com.android.systemui` ]; then
		systemui=`pidof com.android.systemui`;
		$BB renice -18 $systemui;
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
		$BB renice -18 $launcher;
	fi;
	done;
	exit;
done&

# Powersaving Tweaks
echo 1400000 > /sys/devices/system/cpu/cpufreq/interactive/hispeed_freq;

# Block Tweaks
echo 2 > /sys/block/mmcblk0/queue/nomerges;
echo 2 > /sys/block/mmcblk0/queue/rq_affinity;
echo 1024 > /sys/block/mmcblk0/queue/nr_requests;
echo 10 > /proc/sys/fs/lease-break-time;

# Limit Debugging
echo "N" > /sys/module/kernel/parameters/initcall_debug;
echo "0" > /sys/module/alarm_dev/parameters/debug_mask;
echo "0" > /sys/module/binder/parameters/debug_mask;
echo "0" > /sys/module/xt_qtaguid/parameters/debug_mask;

# Network Tweaks
setprop wifi.supplicant_scan_interval 180;

echo "xboot.sh finished" `date` >> $LOG;

mount -o remount,ro /system
exit 0
