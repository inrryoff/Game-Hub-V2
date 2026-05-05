#!/system/bin/sh

SKIPUNZIP=1

# ============================================================
# FUNÇÃO PARA PERGUNTAR SIM/NÃO
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
    returnui_print "⚙️ Inicializando GameHub Engine..."
sleep 1
ui_print "🧠 Detectando hardware..."
sleep 1
ui_print "🔍 Analisando compatibilidade..."
sleep 1
ui_print "🔍 Verificando sistema..."
ui_print ""
ui_print "📱 Codinome:  $DEVICE"
ui_print "📲 Modelo:    $MODEL"
ui_print "🧠 SoC:       $SOC"
[ -n "$SOC_MODEL" ] && ui_print "🔢 ID SoC:    $SOC_MODEL"
ui_print ""
 1
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
SOC=$(detect_soc)
ARCH=$(getprop ro.product.cpu.abi)
DEVICE=$(getprop ro.product.device)
MODEL=$(getprop ro.product.model)
SOC_MODEL=$(getprop ro.soc.model 2>/dev/null)
TERMUX_PATH="/data/data/com.termux"
TERMUX_FILES="/data/data/com.termux/files"
TERMUX_HOME="$TERMUX_FILES/home"
TERMUX_BASHRC="$TERMUX_HOME/.bashrc"

# ============================================================
# VERIFICAÇÃO DE COMPATIBILIDADE
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
ui_print " "
ui_print "  ██████╗ ██╗  ██╗██╗   ██╗██████╗ "
ui_print " ██╔════╝ ██║  ██║██║   ██║██╔══██╗"
ui_print " ██║  ███╗███████║██║   ██║██████╔╝"
ui_print " ██║   ██║██╔══██║██║   ██║██╔══██╗"
ui_print " ╚██████╔╝██║  ██║╚██████╔╝██████╔╝"
ui_print "  ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═════╝ "
ui_print "        GameHub - PRO - X"
ui_print "         BY: INRRYOFF"
ui_print " "
ui_print "═══════════════════════════════════════"
ui_print "⚙️ Inicializando GameHub Engine..."
sleep 1
ui_print "🧠 Detectando hardware..."
sleep 1
ui_print "🔍 Analisando compatibilidade..."
sleep 1

ui_print " "
ui_print "═══════════════════════════════════════"
ui_print "🔍 Informações do sistema"
ui_print "═══════════════════════════════════════"
ui_print " "
ui_print "📱 Codinome : $DEVICE"
ui_print "📲 Modelo   : $MODEL"
ui_print "🧠 SoC      : $SOC"
[ -n "$SOC_MODEL" ] && ui_print "🔢 ID SoC   : $SOC_MODEL"
ui_print " "

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
set_perm "$MODPATH/system/bin/boost" 0 0 0755
set_perm_recursive "$MODPATH/common" 0 0 0755 0644

# ============================================================
# INSTALAÇÃO DO TERMUX
# ============================================================    
case $ARCH in
    arm64-v8a)
        TERMUX_APK="$MODPATH/termux/termux.apk"
        ;;
    armeabi-v7a|armeabi|armv7l|x86|x86_64)
        TERMUX_APK="$MODPATH/termux/u-termux.apk"
        ;;
    *)
        say "${RED}❌ Arquitetura $ARCH não suportada oficialmente pelo GameHub.${NC}"
        sleep 2
        return 1
        ;;
esac

ui_print "- Verificando Termux..."

if [ -d "$TERMUX_PATH" ]; then
    ui_print "✅ Termux já está instalado"
else
    ask_yes_no "❓ Deseja instalar o Termux automaticamente?"
    if [ $? -eq 0 ]; then
        ui_print "📦 Instalando Termux (offline)..."
        if [ -f "$TERMUX_APK" ]; then
            pm install -r "$TERMUX_APK" >/dev/null 2>&1
            sleep 5
            ui_print "✅ Termux instalado!"
        else
            ui_print "❌ APK do Termux não encontrado"
        fi
    fi
fi

if [ -d "$TERMUX_PATH" ]; then
    ui_print "⚙️ Configurando ambiente..."
    
    mkdir -p "$TERMUX_HOME"
    get_real_locale() {
        local loc=""
        loc=$(settings get system system_locales 2>/dev/null | cut -d',' -f1)
        [ -z "$loc" ] || [ "$loc" = "null" ] && loc=$(getprop persist.sys.locale)
        [ -z "$loc" ] || [ "$loc" = "null" ] && loc=$(getprop ro.product.locale)
        [ -z "$loc" ] || [ "$loc" = "null" ] && loc="en-US"
        
        echo "$loc"
    }
    SYS_LOCALE=$(get_real_locale)
    TERMUX_LANG=$(echo "$SYS_LOCALE" | tr '-' '_')".UTF-8"
    [ -f "$TERMUX_BASHRC" ] && sed -i '/export LANG=/d' "$TERMUX_BASHRC"
    [ -f "$TERMUX_BASHRC" ] && sed -i '/alias play=/d' "$TERMUX_BASHRC"
    [ -f "$TERMUX_BASHRC" ] && sed -i '/alias turbo=/d' "$TERMUX_BASHRC"
    echo "export LANG=$TERMUX_LANG" >> "$TERMUX_BASHRC"
    echo "alias play='su -c \"/data/data/com.termux/files/usr/bin/bash /data/adb/modules/GameHub-PRO-X/script/boost.sh\"'" >> "$TERMUX_BASHRC"

    if [ "$ARCH" = "arm64-v8a" ]; then
        echo "alias turbo='mkdir -p ~/.termux && if [ -f ~/.termux/.turbo_mode ]; then rm -f ~/.termux/.turbo_mode; echo \"⚡ Antialiasing DESATIVADO\"; else touch ~/.termux/.turbo_mode; echo \"🚀 Antialiasing ATIVADO\"; fi'" >> "$TERMUX_BASHRC"
        HAS_TURBO=1
    else
        HAS_TURBO=0
    fi
    sleep 3

    TERMUX_UID=$(stat -c '%u' /data/data/com.termux)
    TERMUX_GID=$(stat -c '%g' /data/data/com.termux)
    chown -R $TERMUX_UID:$TERMUX_GID "$TERMUX_FILES"
    chmod -R 700 "$TERMUX_FILES"
    chmod 644 "$TERMUX_BASHRC"
    
    ui_print "✅ Idioma ($TERMUX_LANG) configurado!"
    ui_print "✅ Alias 'play' configurado com sucesso!"
    [ "$HAS_TURBO" = "1" ] && ui_print "✅ Alias 'turbo' (Antialiasing arm64) ativado!"
else
    ui_print "⚠️ Instalação do Termux ignorada."
        ui_print " "
        ui_print "📜 Comando de configuração salvo em:"
        ui_print "📂 /sdcard/Download/GameHub_Termux_Cmd.txt"
        ui_print " "
        ui_print "Basta abrir o arquivo, copiar o comando"
        ui_print "e colar dentro do seu Termux."

    cat <<EOF > /sdcard/Download/GameHub_Termux_Cmd.txt
Comandos para configurar o alias 'play' no Termux:

1. Copie e cole o comando abaixo no termux:
echo 'alias play="su -c \"/data/data/com.termux/files/usr/bin/bash /data/adb/modules/GameHub-PRO-X/script/boost\""' >> ~/.bashrc && source ~/.bashrc

2. Pronto! Agora basta digitar 'play' para rodar o boost.
EOF
        
        chown 1023:1023 /sdcard/Download/GameHub_Termux_Cmd.txt 2>/dev/null
fi

# ============================================================
# FINALIZAÇÃO
# ============================================================
ui_print ""
ui_print "═══════════════════════════════════════"
if [ $COMPATIBLE_DEVICE -eq 1 ] || [ $COMPATIBLE_MODEL -eq 1 ]; then
    ui_print "✅ GameHub PRO-X instalado com sucesso!"
    ui_print "   Desenvolvido por @Inrryoff para o Moto G24."
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