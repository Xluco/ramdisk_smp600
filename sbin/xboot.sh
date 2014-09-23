#!/system/bin/sh
BB="/system/xbin/busybox"
LOG="/sdcard/xluco_kernel/log.txt"

PATH=/sbin:/system/sbin:/system/bin:/system/xbin
export PATH

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

# Interactive Tweaks
echo 1400000 > /sys/devices/system/cpu/cpufreq/interactive/hispeed_freq;
echo 95 > /sys/devices/system/cpu/cpufreq/interactive/go_hispeed_load;
echo 20000 > /sys/devices/system/cpu/cpufreq/interactive/timer_rate;
echo 1 > /sys/devices/system/cpu/cpufreq/interactive/io_is_busy;

# Block Tweaks
echo 2 > /sys/block/mmcblk0/queue/nomerges;
echo 2 > /sys/block/mmcblk0/queue/rq_affinity;
echo 1 > /sys/block/mmcblk0/queue/iosched/fifo_batch;
echo 250 > /sys/block/mmcblk0/queue/iosched/read_expire;
echo 2500 > /sys/block/mmcblk0/queue/iosched/write_expire;
echo 1 > /sys/block/mmcblk0/queue/iosched/writes_starved;
echo 1 > /sys/block/mmcblk0/queue/iosched/front_merges;
echo 1024 > /sys/block/mmcblk0/queue/read_ahead_kb;
echo 1024 > /sys/block/mmcblk0/queue/nr_requests;
echo 10 > /proc/sys/fs/lease-break-time;

# VM Tweaks
echo 0 > /proc/sys/vm/swappiness;
echo 40 > /proc/sys/vm/dirty_ratio;
echo 100 > /proc/sys/vm/vfs_cache_pressure;
echo 2500 > /proc/sys/vm/dirty_expire_centisecs;
echo 10 > /proc/sys/vm/dirty_background_ratio;
echo 1250 > /proc/sys/vm/dirty_writeback_centisecs;
echo 0 > /proc/sys/vm/laptop_mode;

# Kernel Tweaks
echo "250 32000 100 128" > /proc/sys/kernel/sem;
echo "512" > /proc/sys/kernel/random/write_wakeup_threshold;
echo "1024" > /proc/sys/kernel/random/read_wakeup_threshold;

# Limit Debugging
echo "N" > /sys/module/kernel/parameters/initcall_debug;
echo "0" > /sys/module/alarm_dev/parameters/debug_mask;
echo "0" > /sys/module/binder/parameters/debug_mask;
echo "0" > /sys/module/xt_qtaguid/parameters/debug_mask;

# Network Tweaks
setprop wifi.supplicant_scan_interval 180;
setprop net.tcp.buffersize.wifi "524288,1048576,5242880,524288,1048576,5242880";
echo 5242880 > /proc/sys/net/core/rmem_max;
echo 5242880 > /proc/sys/net/core/wmem_max;
echo "524288 1048576 5242880" > /proc/sys/net/ipv4/tcp_rmem;
echo "524288 1048576 5242880" > /proc/sys/net/ipv4/tcp_wmem;
echo 2048 > /proc/sys/net/core/netdev_max_backlog;
echo 2 > /proc/sys/net/ipv4/tcp_ecn;
echo 1 > /proc/sys/net/ipv4/tcp_sack;
echo 1 > /proc/sys/net/ipv4/tcp_fack;
echo 1 > /proc/sys/net/ipv4/tcp_dsack;
echo 1 > /proc/sys/net/ipv4/tcp_low_latency;
echo 1 > /proc/sys/net/ipv4/tcp_timestamps;
echo 1 > /proc/sys/net/ipv4/tcp_window_scaling;
echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse;
echo 1 > /proc/sys/net/ipv4/tcp_tw_recycle;
echo 15 > /proc/sys/net/ipv4/tcp_fin_timeout;
echo 300 > /proc/sys/net/ipv4/tcp_keepalive_time;
echo 5 > /proc/sys/net/ipv4/tcp_keepalive_probes;
echo 15 > /proc/sys/net/ipv4/tcp_keepalive_intvl;
echo 1 > /proc/sys/net/ipv4/tcp_no_metrics_save;
echo 1 > /proc/sys/net/ipv4/tcp_moderate_rcvbuf;
echo 0 > /proc/sys/net/ipv4/ip_no_pmtu_disc;
echo 524288 > /proc/sys/net/core/somaxconn;
echo 524288 > /proc/sys/net/core/optmem_max;
echo 1440000 > /proc/sys/net/ipv4/tcp_max_tw_buckets;

# Network Hardening
echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts;
echo 2048 > /proc/sys/net/ipv4/tcp_max_syn_backlog;
echo 0 > /proc/sys/net/ipv4/ip_forward;
echo 1 > /proc/sys/net/ipv4/tcp_rfc1337;
echo 1 > /proc/sys/net/ipv4/tcp_workaround_signed_windows;
echo 1 > /proc/sys/net/ipv4/tcp_mtu_probing;
echo 2 > /proc/sys/net/ipv4/tcp_frto_response;
echo 2 > /proc/sys/net/ipv4/tcp_synack_retries;
echo 1 > /proc/sys/net/ipv4/icmp_ignore_bogus_error_responses;
echo 0 > /proc/sys/net/ipv4/conf/all/accept_redirects;
echo 0 > /proc/sys/net/ipv4/conf/all/send_redirects;
echo 0 > /proc/sys/net/ipv4/conf/all/accept_source_route;
echo 0 > /proc/sys/net/ipv4/conf/all/forwarding;
echo 1 > /proc/sys/net/ipv4/conf/all/rp_filter;
echo 0 > /proc/sys/net/ipv4/conf/all/log_martians;
echo 0 > /proc/sys/net/ipv6/conf/default/router_solicitations;
echo 0 > /proc/sys/net/ipv6/conf/default/accept_ra_rtr_pref;
echo 0 > /proc/sys/net/ipv6/conf/default/accept_ra_pinfo;
echo 0 > /proc/sys/net/ipv6/conf/default/accept_ra_defrtr;
echo 0 > /proc/sys/net/ipv6/conf/default/accept_redirects;
echo 0 > /proc/sys/net/ipv6/conf/default/autoconf;
echo 0 > /proc/sys/net/ipv6/conf/default/dad_transmits;
echo 1 > /proc/sys/net/ipv6/conf/default/max_addresses;
echo 1 > /proc/sys/net/ipv4/route/flush;

# Kernel Hardening
echo 2 > /proc/sys/kernel/kptr_restrict;
echo 1 > /proc/sys/kernel/randomize_va_space;
echo 1 > /proc/sys/kernel/dmesg_restrict;
echo 0 > /proc/sys/kernel/core_uses_pid;

echo "xboot.sh finished" `date` >> $LOG;

mount -o remount,ro /system
exit 0
