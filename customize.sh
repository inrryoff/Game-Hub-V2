#!/system/bin/sh

# ============================================================
# customize.sh - GameHub Pro X
# ============================================================

SKIPUNZIP=1

# Verifica dispositivo
DEVICE=$(getprop ro.product.device)

case "$DEVICE" in
    fogorow)
        ui_print "✔ Moto G24 detectado!"
        ;;
    *)
        ui_print "❌ Apenas Moto G24 suportado!"
        ui_print "   Detectado: $DEVICE"
        abort
        ;;
esac

# Extrai arquivos do ZIP
ui_print "- Extraindo arquivos..."
unzip -o "$ZIPFILE" -d "$MODPATH" >&2

# Cria diretório common se não existir
if [ ! -d "$MODPATH/common" ]; then
    mkdir -p "$MODPATH/common"
fi

# Define permissões
ui_print "- Definindo permissões..."

# Permissões para scripts
set_perm "$MODPATH/booster.sh" 0 0 0755

# Permissões para diretório common
set_perm "$MODPATH/common" 0 0 0755

# Permissões para arquivos do common (se existirem)
[ -f "$MODPATH/system/bin/booster.sh" ] && set_perm "$MODPATH/system/bin/booster.sh" 0 0 0755
[ -f "$MODPATH/common/config.cfg" ] && set_perm "$MODPATH/common/config.cfg" 0 0 0644
[ -f "$MODPATH/common/protected.list" ] && set_perm "$MODPATH/common/protected.list" 0 0 0644
[ -f "$MODPATH/common/renderer_cache.cfg" ] && set_perm "$MODPATH/common/renderer_cache.cfg" 0 0 0644

# Configura alias no Termux (opcional)
ui_print "- Configurando integração com Termux..."

TERMUX_RC="/data/data/com.termux/files/home/.bashrc"
if [ -f "$TERMUX_RC" ]; then
    # Remove alias antigo se existir
    sed -i '/alias play=/d' "$TERMUX_RC"
    
    # Adiciona alias
    echo 'alias play='su -c "/data/data/com.termux/files/usr/bin/bash /data/adb/modules/GameHub-PRO-X/system/bin/booster.sh"'\""' >> "$TERMUX_RC"
    
    # Ajusta dono do arquivo
    T_USER=$(stat -c '%u' /data/data/com.termux 2>/dev/null)
    if [ -n "$T_USER" ]; then
        chown -R "$T_USER" "$TERMUX_RC" 2>/dev/null
    fi
    
    ui_print "✔ Alias 'play' adicionado ao Termux"
fi

# Cria arquivos de configuração padrão se não existirem
if [ ! -f "$MODPATH/common/config.cfg" ]; then
    echo "# Nome do Jogo|pacote.com.do.jogo" > "$MODPATH/common/config.cfg"
    echo "" >> "$MODPATH/common/config.cfg"
    echo "# Exemplo:" >> "$MODPATH/common/config.cfg"
    echo "# Clash Royale|com.supercell.clashroyale" >> "$MODPATH/common/config.cfg"
fi

if [ ! -f "$MODPATH/common/protected.list" ]; then
    echo "# Apps que não serão fechados ao limpar RAM" > "$MODPATH/common/protected.list"
    echo "com.termux" >> "$MODPATH/common/protected.list"
fi

ui_print "═══════════════════════════════════════"
ui_print "✅ GameHub Pro X instalado!"
ui_print "═══════════════════════════════════════"
ui_print ""
ui_print "📱 Para usar:"
ui_print "   Termux: digite 'play'"
ui_print "   Ou: su -c 'sh /data/adb/modules/GameHub-PRO-X/booster.sh'"
ui_print ""
ui_print "🎮 Divirta-se!"
