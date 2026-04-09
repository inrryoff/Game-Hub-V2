DEVICE=$(getprop ro.product.device)

case "$DEVICE" in
    fogorow)
        ui_print "✔ Moto G24 detectado!"
    ;;
    *)
        ui_print "❌ Apenas Moto G24 suportado!"
        abort
    ;;
esac

set_perm $MODPATH/system/bin/booster.sh 0 0 0755

if [ ! -d "$MODPATH/common" ]; then
    mkdir -p "$MODPATH/common"
    set_perm "$MODPATH/common" 0 0 0777
fi

TERMUX_RC="/data/data/com.termux/files/home/.bashrc"
if [ -f "$TERMUX_RC" ]; then
    sed -i '/alias play=/d' "$TERMUX_RC"
    echo "alias play='su -c "PREFIX=/data/data/com.termux/files/usr /data/data/com.termux/files/usr/bin/bash /data/adb/modules/GameHub-PRO-X/system/bin/booster.sh'" >> "$TERMUX_RC"
    
    T_USER=$(stat -c '%u' /data/data/com.termux)
    chown $T_USER:$T_USER "$TERMUX_RC"
fi

ui_print "- Instalação concluída!"
ui_print "- Seus jogos e whitelist foram mantidos."

