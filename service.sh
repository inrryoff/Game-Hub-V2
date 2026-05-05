#!/system/bin/sh
export PATH=/system/bin:/system/xbin:/vendor/bin:$PATH

until [ "$(getprop sys.boot_completed)" -eq 1 ]; do sleep 5; done
sleep 0.1

resetprop sys.lmk.minfree_levels "18432:0,23040:100,27648:200,32256:250,55296:900,80640:950"
resetprop lmkd.reinit 1

for policy in /sys/devices/system/cpu/cpufreq/policy*; do
    echo schedutil > "$policy/scaling_governor"
    if [ -f "$policy/cpuinfo_min_freq" ] && [ -f "$policy/scaling_min_freq" ]; then
    cat "$policy/cpuinfo_min_freq" > "$policy/scaling_min_freq"
    fi
done

wm size reset 2>/dev/null
wm density reset 2>/dev/null

resetprop debug.hwui.renderer skiagl
resetprop debug.renderengine.backend skiaglthreaded