#!/system/bin/sh

SKIPUNZIP=1

# ============================================================
# FUNÇÃO PARA PERGUNTAR SIM/NÃO (VOLUME BUTTONS)
# ============================================================
wait_volume_key() {
    local key
    local timeout=30
    ui_print "   ⏳ Aguardando 30 segundos..."
    for i in 1 2 3; do
        key=$(getevent -qlc 1 2>/dev/null | awk '{ print $3 }' | grep -E 'KEY_VOLUME(DOWN|UP)')
        if [ "$key" = "KEY_VOLUMEUP" ]; then
            return 0
        elif [ "$key" = "KEY_VOLUMEDOWN" ]; then
            return 1
        fi
        sleep 0.1
    done
    return 1
}

ask_yes_no() {
    local question="$1"
    ui_print ""
    ui_print "═══════════════════════════════════════"
    ui_print "$question"
    ui_print "═══════════════════════════════════════"
    ui_print "   ➕ Volume + = SIM"
    ui_print "   ➖ Volume - = NÃO"
    ui_print "═══════════════════════════════════════"
    wait_volume_key
    return $?
}

# ============================================================
# DETECÇÃO DO SOC
# ============================================================
detect_soc() {
    local soc=""
    if [ -f "/proc/cpuinfo" ]; then
        soc=$(cat /proc/cpuinfo | grep -i "Hardware" | head -1 | cut -d':' -f2 | sed 's/^ //')
        if [ -z "$soc" ] || [ "$soc" = "Unknown" ]; then
            soc=$(cat /proc/cpuinfo | grep -i "MT" | head -1 | cut -d':' -f2 | sed 's/^ //')
        fi
    fi
    [ -z "$soc" ] && soc=$(getprop ro.board.platform)
    [ -z "$soc" ] && soc=$(getprop ro.soc.model)
    echo "${soc:-Desconhecido}"
}

# ============================================================
# COLETA DE INFORMAÇÕES
# ============================================================
DEVICE=$(getprop ro.product.device)
MODEL=$(getprop ro.product.model)
SOC=$(detect_soc)
SOC_MODEL=$(getprop ro.soc.model 2>/dev/null)

# ============================================================
# VERIFICAÇÃO DE COMPATIBILIDADE (3 NÍVEIS)
# ============================================================
COMPATIBLE_DEVICE=0
COMPATIBLE_MODEL=0
COMPATIBLE_SOC=0

echo "$DEVICE" | grep -qi "fogorow*" && COMPATIBLE_DEVICE=1
echo "$MODEL" | grep -qiE "moto g24|XT2423|XT2425" && COMPATIBLE_MODEL=1

SOC_PATTERNS="MT6769|MT6769V/CZ|MT6769Z|mt6769|MT6768|k68v1_64"
echo "$SOC" | grep -qiE "$SOC_PATTERNS" && COMPATIBLE_SOC=1
[ -n "$SOC_MODEL" ] && echo "$SOC_MODEL" | grep -qiE "$SOC_PATTERNS" && COMPATIBLE_SOC=1

# ============================================================
# TELA DE INFORMAÇÕES
# ============================================================
ui_print "═══════════════════════════════════════"
ui_print "🔍 GameHub PRO-X - Verificando sistema"
ui_print "═══════════════════════════════════════"
ui_print ""
ui_print "📱 Codinome:  $DEVICE"
ui_print "📲 Modelo:    $MODEL"
ui_print "🧠 SoC:       $SOC"
[ -n "$SOC_MODEL" ] && ui_print "🔢 ID SoC:    $SOC_MODEL"
ui_print ""

# ============================================================
# DECISÃO
# ============================================================
if [ $COMPATIBLE_DEVICE -eq 1 ] || [ $COMPATIBLE_MODEL -eq 1 ]; then
    ui_print "═══════════════════════════════════════"
    ui_print "✅ DISPOSITIVO 100% COMPATÍVEL"
    ui_print "═══════════════════════════════════════"
    ui_print ""
    ui_print "Instalação automática e segura."
    FORCE_INSTALL=0

elif [ $COMPATIBLE_SOC -eq 1 ]; then
    ui_print "═══════════════════════════════════════"
    ui_print "⚠️  COMPATIBILIDADE PARCIAL"
    ui_print "═══════════════════════════════════════"
    ui_print ""
    ui_print "Seu dispositivo NÃO é um Moto G24,"
    ui_print "mas o SoC ($SOC) é compatível (Helio G85/G80)."
    ui_print "✅ O módulo DEVE funcionar corretamente."
    ui_print ""
    ask_yes_no "❓ Deseja instalar mesmo assim?"
    if [ $? -eq 0 ]; then
        ui_print "🔧 Prosseguindo com a instalação (modo experimental)."
        FORCE_INSTALL=1
    else
        ui_print "❌ Instalação cancelada."
        abort
    fi

else
    ui_print "═══════════════════════════════════════"
    ui_print "❌ DISPOSITIVO NÃO COMPATÍVEL"
    ui_print "═══════════════════════════════════════"
    ui_print ""
    ui_print "Nenhum critério de compatibilidade foi atendido."
    ui_print "A instalação pode causar instabilidade."
    ui_print ""
    ui_print "❌ Instalação ABORTADA."
    abort
fi

# ============================================================
# EXTRAÇÃO E PERMISSÕES
# ============================================================
ui_print ""
ui_print "- Extraindo arquivos..."
unzip -o "$ZIPFILE" -d "$MODPATH" >&2

ui_print "- Definindo permissões..."
set_perm "$MODPATH/system/bin/booster.sh" 0 0 0755
set_perm_recursive "$MODPATH/common" 0 0 0755 0644

# ============================================================
# INSTALAÇÃO DO TERMUX
# ============================================================
TERMUX_APK="$MODPATH/termux/termux.apk"
TERMUX_PATH="/data/data/com.termux"

ui_print ""
ui_print "- Verificando Termux..."

if [ -d "$TERMUX_PATH" ]; then
    ui_print "✅ Termux já está instalado"
else
    ask_yes_no "❓ Deseja instalar o Termux automaticamente?"
    if [ $? -eq 0 ]; then
        ui_print "📦 Instalando Termux (offline)..."
        if [ -f "$TERMUX_APK" ]; then
            pm install -r "$TERMUX_APK" >/dev/null 2>&1
            if [ $? -eq 0 ]; then
                ui_print "✅ Termux instalado!"
            else
                ui_print "❌ Falha na instalação do Termux"
            fi
        else
            ui_print "❌ APK do Termux não encontrado,"
            ui_print "verifique a integridade dos arquivos!."
        fi
    else
        ui_print "⚠️ Instalação do Termux ignorada"
        ui_print " "
        ui_print "📜 O comando de configuração foi salvo em:"
        ui_print "📂 /sdcard/Download/GameHub_Termux_Cmd.txt"
        ui_print " "
        ui_print "Basta abrir o arquivo, copiar o comando"
        ui_print "e colar dentro do seu Termux."

        cat <<EOF > /sdcard/Download/GameHub_Termux_Cmd.txt
Comandos para configurar o alias 'play' no Termux:

1. Copie e cole o comando abaixo no termux:
echo "alias play='su -c \"/data/data/com.termux/files/usr/bin/bash /data/adb/modules/GameHub-PRO-X/system/bin/booster.sh\"'" >> ~/.bashrc && source ~/.bashrc

2. Pronto! Agora basta digitar 'play' para rodar o booster.
EOF
        
        chown 1023:1023 /sdcard/Download/GameHub_Termux_Cmd.txt 2>/dev/null
    fi
fi

# ============================================================
# CONFIGURAÇÃO DO ALIAS
# ============================================================
TERMUX_BASHRC="/data/data/com.termux/files/home/.bashrc"
if [ -f "$TERMUX_BASHRC" ]; then
    sed -i '/alias play=/d' "$TERMUX_BASHRC" 2>/dev/null
    echo 'alias play="su -c '\''/data/data/com.termux/files/usr/bin/bash /data/adb/modules/GameHub-PRO-X/system/bin/booster.sh'\''"' >> "$TERMUX_BASHRC"
    ui_print "✅ Alias 'play' configurado"
fi

# ============================================================
# FINALIZAÇÃO
# ============================================================
ui_print ""
ui_print "═══════════════════════════════════════"
if [ $COMPATIBLE_DEVICE -eq 1 ] || [ $COMPATIBLE_MODEL -eq 1 ]; then
    ui_print "✅ GameHub PRO-X instalado com sucesso!"
    ui_print "   Desenvolvido por @Inrryoff para Moto G24."
elif [ $COMPATIBLE_SOC -eq 1 ]; then
    ui_print "✅ GameHub PRO-X instalado!"
    ui_print "   SoC compatível (Helio G85/G80)."
else
    ui_print "⚠️ GameHub PRO-X instalado (MODO EXPERIMENTAL)"
fi
ui_print "═══════════════════════════════════════"
ui_print ""
ui_print "📱 No Termux, digite: play"
ui_print "🎮 Divirta-se!"
if [ $FORCE_INSTALL -eq 1 ]; then
    ui_print ""
    ui_print "⚠️ AVISO: Você instalou em dispositivo não oficial."
    ui_print "   Relate problemas apenas se for Moto G24 ou Helio G85."
fi
ui_print "═══════════════════════════════════════"
