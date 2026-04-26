export PATH=$PATH:/data/data/com.termux/files/usr/bin:/system/bin
export LD_LIBRARY_PATH=/data/data/com.termux/files/usr/lib
#!/bin/bash

MODPATH="/data/adb/modules/GameHub-PRO-X"
CONFIG="$MODPATH/common/config.cfg"
PROTECTED_FILE="$MODPATH/common/protected.list"
CACHE_FILE="$MODPATH/common/renderer_cache.cfg"
LOG_DIR="/data/local/tmp/logs"
LOG_FILE="$LOG_DIR/gamehub.log"
LOG_ERROR="$LOG_DIR/gamehub_err.log"
CHECK_DP="$MODPATH/common/dps_installed"

_VERSION="5.0"
_SCRIPT_NAME="GameHub-PRO-X" 
_AUTHOR="INRRYOFF"

mkdir -p "$MODPATH/common" "$LOG_DIR"
touch "$CONFIG" "$PROTECTED_FILE" "$CACHE_FILE"
> "$LOG_ERROR"

if [ -t 1 ]; then
    RED='\033[1;31m'
    GREEN='\033[1;32m'
    CYAN='\033[1;36m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
    BOLD='\033[1m'
else
    RED=''; GREEN=''; CYAN=''; YELLOW=''; BLUE=''; NC=''
fi

exec 3>&1
echo "--- SESSÃO MT6769 $(date) ---" > "$LOG_FILE"
exec 1>>"$LOG_FILE"
exec 2>>"$LOG_ERROR"

say() { echo -e "$1" >&3; }
log() { echo "[$(date +%H:%M:%S)] $1" >> "$LOG_FILE"; }

# ============================================================
# DEPENDÊNCIAS
# ============================================================
install_dp() {
    if [ -f "$CHECK_DP" ]; then
        return 0
    fi
    
    say "${CYAN}═══════════════════════════════════════${NC}"
    say "${CYAN}   📦 INSTALANDO DEPENDÊNCIAS${NC}"
    say "${CYAN}═══════════════════════════════════════${NC}"
    say ""
    
    if [ -d "/data/data/com.termux" ]; then
        say "${YELLOW}📱 Ambiente Termux detectado${NC}"
        say ""
        
        say "${CYAN}🔄 Atualizando repositórios...${NC}"
        spinner "pkg update"
        
        if ! command -v lolcat; then
            say "${CYAN}💎 Preparando lolcat (isso pode demorar)...${NC}"
            spinner "pkg install ruby"
            spinner "gem install lolcat"
        fi
        
        if ! command -v figlet; then
            say "${CYAN}🎨 Instalando figlet...${NC}"
            spinner "pkg install figlet"
        fi
        
        if ! command -v tput; then
            say "${CYAN}📟 Instalando ncurses...${NC}"
            spinner "pkg install ncurses-utils"
        fi
        
        say ""
        say "${GREEN}✅ Todas as dependências instaladas!${NC}"
        
    else
        say "${YELLOW}⚠️ Ambiente não-Termux, pulando instalação...${NC}"
    fi
    
    touch "$CHECK_DP"
    say ""
    sleep 1
}

install_dp

# ============================================================
# FUNÇÃO PARA EXTRAIR APENAS O PACOTE
# ============================================================
extrair_pacote() {
    local input=$1
    if [[ "$input" == *"/"* ]]; then
        echo "${input%%/*}"
    else
        echo "$input"
    fi
}

# ============================================================
# FUNÇÃO SPINNER
# ============================================================
_spinner_anim() {
    local pid=$1
    local msg="${2:-Carregando...}"
    local delay=0.07
    local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local cores=(31 91 33 93 32 92 36 96 34 94 35 95)
    local cor_msg=36

    tput civis
    local idx=0
    while kill -0 "$pid" 2>/dev/null; do
        for frame in "${frames[@]}"; do
            local cor="${cores[$idx % ${#cores[@]}]}"
            printf "\r\e[K\e[${cor}m[%s]\e[0m\e[${cor_msg};1m%s\e[0m" "$frame" "$msg"
            idx=$((idx + 1))
            sleep "$delay"
            kill -0 "$pid" 2>/dev/null || break
        done
    done

    wait "$pid" 2>/dev/null
    local exit_code=$?
    tput cnorm

    if [ $exit_code -eq 0 ]; then
        printf "\r\e[K\e[32m[✔] %s Concluído!\e[0m\n" "$msg"
    else
        printf "\r\e[K\e[31m[✘] %s Falhou!\e[0m\n" "$msg"
    fi
} 1>&3

spinner() {
    local cmd=$1 
    local msg="${2:-Executando...}"
    
    set +m
    
    eval "$cmd" > /dev/null 2>&1 &
    local pid=$!
    
    _spinner_anim "$pid" "$msg"
    
    set -m
}

# ============================================================
# DETECTOR INTELIGENTE DE RENDERER
# ============================================================
detectar_suporte_vulkan() {
    local pkg=$1
    
    local cached=$(grep "^$pkg|" "$CACHE_FILE" | cut -d'|' -f2)
    if [ -n "$cached" ]; then
        echo "$cached"
        log "Cache hit para $pkg: $cached"
        return 0
    fi
    
    log "Detectando suporte Vulkan para $pkg..."
    
    local apk_path=$(pm path "$pkg" | cut -d':' -f2)
    if [ -n "$apk_path" ]; then
        local libs=$(unzip -l "$apk_path" | grep -E "lib/.*/libvulkan|lib/.*/libVulkan" | head -1)
        if [ -n "$libs" ]; then
            echo "$pkg|vulkan" >> "$CACHE_FILE"
            log "Detectado: Vulkan (via libs nativas)"
            echo "vulkan"
            return 0
        fi
    fi
    
    local unity_players=$(dumpsys package "$pkg" | grep -i "unity" | head -1)
    if [ -n "$unity_players" ]; then
        echo "$pkg|vulkan" >> "$CACHE_FILE"
        log "Detectado: Vulkan (Unity engine)"
        echo "vulkan"
        return 0
    fi
    
    local renderer=$(dumpsys SurfaceFlinger | grep -i "vulkan" | head -1)
    if [ -n "$renderer" ]; then
        echo "$pkg|vulkan" >> "$CACHE_FILE"
        log "Detectado: Vulkan (via SurfaceFlinger)"
        echo "vulkan"
        return 0
    fi
    
    local vulkan_known=(
        "com.miHoYo.Yuanshen"
        "com.miHoYo.Nap"
        "com.HoYoverse.hkrpgoversea"
        "com.tencent.tmgp.sgame"
        "com.pubg.imobile"
        "com.gryphline.endfield.gp"
        ) 
    
    for known in "${vulkan_known[@]}"; do
        if [ "$pkg" = "$known" ]; then
            echo "$pkg|vulkan" >> "$CACHE_FILE"
            log "Detectado: Vulkan (lista conhecida)"
            echo "vulkan"
            return 0
        fi
    done
    
    echo "$pkg|opengl" >> "$CACHE_FILE"
    log "Detectado: OpenGL (padrão)"
    echo "opengl"
    return 0
}

escolher_melhor_renderer() {
    local pkg=$1
    
    say "${CYAN}🔍 Analisando $pkg...${NC}"
    
    local detected=$(detectar_suporte_vulkan "$pkg")
    
    if [ "$detected" = "vulkan" ]; then
        say "${YELLOW}📱 App detectado com suporte Vulkan${NC}"
        say "${GREEN}🔥 Usando VULKAN para máxima performance${NC}"
        echo "vulkan"
        return 0
    else
        say "${CYAN}🖥️ Usando OpenGL (compatibilidade garantida)${NC}"
        echo "opengl"
        return 0
    fi
}

aplicar_renderer() {
    local renderer=$1
    
    if [ "$renderer" = "vulkan" ]; then
        resetprop debug.hwui.renderer skiavk
        resetprop debug.renderengine.backend skiavkthreaded
        resetprop debug.vulkan.layers.enable 0
        resetprop debug.vulkan.shaders.enable 1
        log "Renderer aplicado: VULKAN"
    else
        resetprop debug.hwui.renderer skiagl
        resetprop debug.renderengine.backend skiaglthreaded
        log "Renderer aplicado: OPENGL"
    fi
}

# ============================================================
# EXTERMINAR APPS
# ============================================================
exterminar_apps() {
    log "=== INICIANDO LIMPEZA DE APPS ==="
    
    VITAIS=(
        "android"
        "com.android.systemui"
        "com.android.settings"
        "com.termux"
        "com.google.android.inputmethod.latin"
        "com.google.android.gms"
    )

    local whitelist=("${VITAIS[@]}")
    if [ -f "$PROTECTED_FILE" ]; then
        while IFS= read -r line; do
            [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
            whitelist+=("$line")
        done < "$PROTECTED_FILE"
    fi

    local all_apps=$(pm list packages | cut -d: -f2)
    local count=0

    for app in $all_apps; do
        local skip=false
        for w in "${whitelist[@]}"; do
            if [ "$app" = "$w" ]; then
                skip=true
                break
            fi
        done
        
        if [ "$skip" = false ]; then
            am force-stop "$app" && {
                ((count++))
                killed_apps="$killed_apps $app"
                log "Fechado: $app"
            }
        fi
    done

    sync && echo 1 > /proc/sys/vm/drop_caches
    pm trim-caches 999G &

    log "Total de apps fechados: $count"
}
 
# ============================================================
# PROTEGER JOGO
# ============================================================
proteger_jogo() {
    local pkg=$1
    log "Protegendo $pkg"
    
    for pid in $(pgrep -f "$pkg"); do
        if [ -n "$pid" ] && [ -d "/proc/$pid" ]; then
            echo -1000 > "/proc/$pid/oom_score_adj"
            renice -n -20 -p "$pid"
            ionice -c 1 -n 0 -p "$pid"
            chrt -f -p 99 "$pid"
            taskset -p 0xFC "$pid"
            
            for thread_dir in /proc/$pid/task/*; do
                local tid=$(basename "$thread_dir")
                taskset -p 0xFC "$tid"
                chrt -f -p 99 "$tid"
            done
            
            local policy=$(chrt -p "$pid" | head -1)
            log "PID $pid: $policy"
            say "${GREEN}🛡️ Jogo protegido (PID: $pid - Máxima Prioridade)${NC}"
        fi
    done
}

# ============================================================
# SELEÇÃO DE RESOLUÇÃO
# ============================================================
selecionar_resolucao() {
    say "${CYAN}--- SELEÇÃO DE RESOLUÇÃO (16:9 Adaptado) ---${NC}"
    say "${GREEN}[1] Nativa (720p - Original)${NC}"
    say "${GREEN}[2] Equilibrado (540p - Recomendado)${NC}"
    say "${YELLOW}[3] Performance (480p)${NC}"
    say "${YELLOW}[4] Modo Batata (360p)${NC}"
    say "${RED}[5] Extremo (240p - Grafico de PS1)${NC}"
    echo -n "➜ " >&3
    read res_op
    
    case $res_op in
        2) wm size 540x1209 && wm density 200; log "Resolução: 540p" ;;
        3) wm size 480x1074 && wm density 180; log "Resolução: 480p" ;;
        4) wm size 360x806 && wm density 140; log "Resolução: 360p" ;;
        5) wm size 240x537 && wm density 100; log "Resolução: 240p" ;;
        *) wm size reset && wm density reset; log "Resolução: Nativa" ;;
    esac
    say "${GREEN}✓ Resolução aplicada!${NC}"
}

# ============================================================
# KILL TERMUX SEGURO
# ============================================================
kill_term() {
    log "Agendando morte do Termux após script finalizar..."
    
    (
        while kill -0 $$; do
            sleep 0.5
        done
        sleep 1
        am force-stop com.termux
        killall -9 com.termux
        pkill -9 -f "com.termux"
    ) >/dev/null &
    
    exit 0
}

# ============================================================
# FUNÇÃO PRINCIPAL JOGAR
# ============================================================
jogar() {
    log "=== MODO JOGO INICIADO ==="
    
    local names=()
    local pkgs=()
    
    if [ -f "$CONFIG" ] && [ -s "$CONFIG" ]; then
        while IFS="|" read -r name pkg; do
            [[ "$name" =~ ^#.*$ || -z "$name" ]] && continue
            names+=("$name")
            pkgs+=("$pkg")
        done < "$CONFIG"
    fi
    
    if [ ${#names[@]} -eq 0 ]; then
        say "${RED}Nenhum jogo cadastrado!${NC}"
        pause
        return
    fi
    
    say "${CYAN}--- JOGOS DISPONÍVEIS ---${NC}"
    for i in "${!names[@]}"; do
        local pkg_check="${pkgs[$i]}"
        local pkg_only=$(extrair_pacote "$pkg_check")
        local detected=$(detectar_suporte_vulkan "$pkg_only")
        local icon="🖥️"
        [ "$detected" = "vulkan" ] && icon="🔥"
        say "${GREEN}[$((i+1))] $icon ${names[$i]}${NC}"
    done
    
    echo -n "Escolha: " >&3
    read escolha
    
    local idx=$((escolha - 1))
    if [ $idx -lt 0 ] || [ $idx -ge ${#names[@]} ]; then
        say "${RED}Inválido!${NC}"
        pause
        return
    fi
    
    local pkg_full="${pkgs[$idx]}"
    local name="${names[$idx]}"
    local pkg_only=$(extrair_pacote "$pkg_full")
    
    say "${CYAN}═══════════════════════════════════════${NC}"
    say "${CYAN}🔍 ANALISANDO $name${NC}"
    say "${CYAN}📦 Pacote: $pkg_only${NC}"
    if [[ "$pkg_full" == *"/"* ]]; then
        say "${CYAN}🎯 Activity: ${pkg_full#*/}${NC}"
    fi
    say "${CYAN}═══════════════════════════════════════${NC}"
    
    local best_renderer=$(escolher_melhor_renderer "$pkg_only")
    
    say ""
    aplicar_renderer "$best_renderer"
    selecionar_resolucao

    if [ "$best_renderer" = "vulkan" ]; then
        say "${GREEN}✅ Vulkan ativado - Performance máxima!${NC}"
    else
        say "${BLUE}✅ OpenGL ativado - Compatibilidade garantida${NC}"
    fi
    
    if [ -f "/data/adb/modules/ZramTG24/ram.sh" ]; then
        sh "/data/adb/modules/ZramTG24/ram.sh"
    fi
    
    resetprop sys.lmk.minfree_levels "6144:0,12288:50,16384:100,20480:150,28672:200,40960:300"
    resetprop lmkd.reinit 1
    
    for proc in system_server surfaceflinger; do
        for pid in $(pgrep -f "$proc"); do
            echo -1000 > "/proc/$pid/oom_score_adj"
        done
    done
    
    for policy in /sys/devices/system/cpu/cpufreq/policy*; do
        echo performance > "$policy/scaling_governor"
        max_freq=$(cat "$policy/scaling_max_freq")
        [ -n "$max_freq" ] && echo $max_freq > "$policy/scaling_min_freq"
    done

    stop logd
    resetprop persist.sys.pinner.enabled false
    log "RAM: Logcat e Pinner desativados"
    
    spinner exterminar_apps " ⚡ Otimizando memória..."
    
    say "${GREEN}✅ Otimizações aplicadas!${NC}"
    say ""
    
    say "${GREEN}🎮 Iniciando $name...${NC}"
    
    if [[ "$pkg_full" == *"/"* ]]; then
        am start -n "$pkg_full" > /dev/null
        log "Iniciando com Activity: $pkg_full"
    else
        ACTIVITY=$(cmd package resolve-activity --brief "$pkg_full" | tail -n 1)
        if [ "$ACTIVITY" != "No activity found" ]; then
            am start -n "$ACTIVITY" > /dev/null
        else
            monkey -p "$pkg_full" -c android.intent.category.LAUNCHER 1 > /dev/null
        fi
    fi
    
    say "${YELLOW}⏳ Aguardando processo do jogo...${NC}"

    MAX_TENTATIVAS=60
    CONTADOR=0
    PID_JOGO=""

    while [ $CONTADOR -lt $MAX_TENTATIVAS ]; do
        PID_JOGO=$(pgrep -f "$pkg_only" | head -n 1)
    
        if [ -n "$PID_JOGO" ]; then
            log "PID detectado: $PID_JOGO em $((CONTADOR/2))s"
            break
        fi
    
        sleep 0.5
        CONTADOR=$((CONTADOR + 1))
    done

    if [ -n "$PID_JOGO" ]; then
        proteger_jogo "$pkg_only"
    else
        log "ERRO: Não foi possível capturar o PID de $pkg_only"
        say "${RED}⚠️ Falha ao proteger processo (não detectado)${NC}"
    fi
    
    say "${GREEN}═══════════════════════════════════════${NC}"
    say "${GREEN}✅ $name rodando com $best_renderer!${NC}"
    say "${GREEN}═══════════════════════════════════════${NC}"
    
    log "=== RESUMO DO MODO JOGO ==="
    log "Jogo: $pkg_full"
    log "Pacote (detecção): $pkg_only"
    log "Renderer: $best_renderer"
    log "=========================="
    
    exec 3>&-
    kill_term
}

# ============================================================
# DEMAIS FUNÇÕES
# ============================================================
limpar_cache() {
    rm -f "$CACHE_FILE"
    say "${GREEN}✓ Cache de detecção limpo!${NC}"
    log "Cache limpo"
    pause
}

adicionar_jogo_manual() {
    echo -n "Nome do jogo: " >&3
    read nome
    echo -n "Pacote (ex: com.HoYoverse.Nap): " >&3
    read pkg
    echo "$nome|$pkg" >> "$CONFIG"
    say "${GREEN}✓ Jogo adicionado!${NC}"
    rm -f "$CACHE_FILE"
    say "${YELLOW}⚠️ Cache limpo - detecção será refeita na próxima vez${NC}"
    pause
}

adicionar_whitelist() {
    echo -n "Pacote para proteger: " >&3
    read pkg
    echo "$pkg" >> "$PROTECTED_FILE"
    say "${GREEN}✓ App protegido!${NC}"
    pause
}

modo_normal() {
    say "${CYAN}═══════════════════════════════════════${NC}"
    say "${CYAN}   RESTAURANDO SISTEMA${NC}"
    say "${CYAN}═══════════════════════════════════════${NC}"
    echo ""
    
    say "${YELLOW}🎨 Restaurando renderer...${NC}"
    resetprop debug.hwui.renderer skiagl
    resetprop debug.renderengine.backend skiaglthreaded
    say "${GREEN}✓ Renderer restaurado${NC}"
    
    say "${YELLOW}⚙️ Restaurando CPU...${NC}"
    for policy in /sys/devices/system/cpu/cpufreq/policy*; do
        if [ -f "$policy/scaling_governor" ]; then
            if grep -q "schedutil" "$policy/scaling_available_governors"; then
                echo "schedutil" > "$policy/scaling_governor"
            elif grep -q "interactive" "$policy/scaling_available_governors"; then
                echo "interactive" > "$policy/scaling_governor"
            fi
        fi

        if [ -f "$policy/cpuinfo_min_freq" ] && [ -f "$policy/scaling_min_freq" ]; then
            cat "$policy/cpuinfo_min_freq" > "$policy/scaling_min_freq"
        fi
    done
    say "${GREEN}✓ CPU restaurado${NC}"
    
    say "${YELLOW}💾 Restaurando LMK...${NC}"
    resetprop sys.lmk.minfree_levels ""
    say "${GREEN}✓ LMK restaurado${NC}"
    
    say "${YELLOW}📺 Restaurando resolução...${NC}"
    wm size reset
    wm density reset
    say "${GREEN}✓ Resolução restaurada${NC}"
    
    echo ""
    say "${GREEN}═══════════════════════════════════════${NC}"
    say "${GREEN}✅ Sistema restaurado com sucesso!${NC}"
    say "${GREEN}═══════════════════════════════════════${NC}"
    
    log "Sistema restaurado (renderer, CPU, LMK, resolução)"
    pause
}

adicionar_jogo_auto() {
    say "${CYAN}═══════════════════════════════════════${NC}"
    say "${CYAN}   DETECTANDO JOGOS INSTALADOS${NC}"
    say "${CYAN}═══════════════════════════════════════${NC}"
    echo ""
    
    local jogos=$(pm list packages -3 | cut -d: -f2 | grep -iE "carxtech|game|rovio|robtop|roblox|hoyoverse|netease|ea.*game|supercell|chess|juggle|gameloft|tencent|mihoyo|gryphline|endfield" | grep -v "hoyolab\|adobe.reader" | sort)
    
    if [ -z "$jogos" ]; then
        say "${RED}⚠️ Nenhum jogo detectado!${NC}"
        pause
        return
    fi
    
    local i=1
    local pkg_array=()
    
    while IFS= read -r pkg; do
        case $pkg in
            com.raongames.growcastle) nome="🌲 Grow Castle" ;;
            com.rovio.battlebay) nome="⚓ Battle Bay" ;;
            com.robtopx.geometryjump) nome="⬛ Geometry Dash" ;;
            com.roblox.client) nome="🧱 Roblox" ;;
            com.HoYoverse.hkrpgoversea) nome="✨ Honkai: Star Rail" ;;
            com.carxtech.sr) nome="🚗 CarX Street" ;;
            com.gryphline.endfield.gp) nome="🎯 Endfield" ;;
            com.netease.newspike) nome="🔫 Blood Strike" ;;
            com.ea.game.pvz2_row) nome="🌱 Plants vs Zombies 2" ;;
            com.gamovation.chessclubpilot) nome="♟️ Chess Club" ;;
            com.supercell.clashroyale) nome="👑 Clash Royale" ;;
            com.chess) nome="♞ Chess.com" ;;
            com.block.juggle) nome="🧩 Block Blast" ;;
            com.supercell.clashofclans) nome="🏰 Clash of Clans" ;;
            *) nome="🎮 $(echo $pkg | cut -d. -f3)" ;;
        esac
        
        if grep -q "|$pkg$" "$CONFIG"; then
            status="${GREEN}✓${NC}"
        else
            status="${YELLOW}○${NC}"
        fi
        
        say "$status ${GREEN}[$i]${NC} $nome"
        say "    ${CYAN}📦 $pkg${NC}"
        echo ""
        
        pkg_array+=("$pkg")
        i=$((i + 1))
    done <<< "$jogos"
    
    say "${CYAN}═══════════════════════════════════════${NC}"
    say "${YELLOW}[0] Voltar | [T] Adicionar Todos${NC}"
    echo -n "➜ " >&3
    read escolha
    
    [ "$escolha" = "0" ] && return
    
    if [ "$escolha" = "T" ] || [ "$escolha" = "t" ]; then
        for pkg in "${pkg_array[@]}"; do
            if ! grep -q "|$pkg$" "$CONFIG"; then
                nome_app=$(echo "$pkg" | cut -d. -f3)
                echo "$nome_app|$pkg" >> "$CONFIG"
                say "${GREEN}✓ Adicionado: $pkg${NC}"
            fi
        done
        rm -f "$CACHE_FILE"
        say "${GREEN}✅ Todos adicionados!${NC}"
        pause
        return
    fi
    
    if [ "$escolha" -ge 1 ] && [ "$escolha" -le ${#pkg_array[@]} ]; then
          pkg_escolhido="${pkg_array[$((escolha-1))]}"
        
        if grep -q "|$pkg_escolhido$" "$CONFIG"; then
            say "${RED}⚠️ Jogo já cadastrado!${NC}"
        else
            nome_app=$(echo "$pkg_escolhido" | cut -d. -f3)
            echo "$nome_app|$pkg_escolhido" >> "$CONFIG"
            rm -f "$CACHE_FILE"
            say "${GREEN}✅ Jogo adicionado!${NC}"
        fi
    else
        say "${RED}⚠️ Opção inválida!${NC}"
    fi
    
    pause
}

pause() {
    say "\n${YELLOW}Pressione ENTER para continuar...${NC}"
    read _unused
}


# ============================================================
# UPDATE
# ============================================================
update() {
    local version_url="https://raw.githubusercontent.com/inrryoff/GameHub-PRO-X/main/version.txt"
    local script_url="https://raw.githubusercontent.com/inrryoff/GameHub-PRO-X/main/script/boost.sh"    
    local module_path="/data/adb/modules/GameHub-PRO-X/script/boost.sh"
    local tmp_script="/data/local/tmp/boost_new.sh"

    say "Verificando se há atualizações..."

    local remote_version=$(unset LD_LIBRARY_PATH; curl -s "$version_url" | tr -d '\r\n')
    if [ -z "$remote_version" ]; then
        say "Não foi possível verificar a versão. Verifique sua conexão."
        return
    fi

    if [ "$remote_version" != "$_VERSION" ]; then
        echo "Nova versão disponível: v$remote_version (Sua versão: v$_VERSION)"
        echo "Baixando atualização..."

        if (unset LD_LIBRARY_PATH; curl -s -o "$tmp_script" "$script_url"); then
            su -c "mv $tmp_script $module_path && chmod +x $module_path && chown root:root $module_path"
            say "Atualizado para v$remote_version! Reiniciando script..."
            su -c "sh $module_path"
            exit
        else
            say "Falha no download da atualização."
        fi
    else
        say "O script já está na versão mais recente (v$_VERSION)."
        sleep 5
    fi
    install_dp
}

# ============================================================
# MENU PRINCIPAL
# ============================================================
show_banner() {
    command clear
    cat << EOF | lolcat
╔════════════════════════════════════════════════════════════════════════════╗
║  ██████╗░█████╗░██████╗░███████╗      ██████╗░░█████╗░███╗░░░███╗███████╗  ║
║  ██╔═══╝██╔══██╗██╔══██╗██╔════╝      ██╔═══╝ ██╔══██╗████╗░████║██╔════╝  ║
║  ██║░░░░██║░░██║██████╔╝█████╗░░█████╗██║░░██╗███████║██╔████╔██║█████╗░░  ║
║  ██║░░░░██║░░██║██╔══██╗██╔══╝░░╚════╝██║░░██║██╔══██║██║╚██╔╝██║██╔══╝░░  ║
║ ░██████╗╚█████╔╝██║░░██║███████╗     ░██████╔╝██║░░██║██║░╚═╝░██║███████╗  ║
║ ░╚═════╝░╚════╝░╚═╝░░╚═╝╚══════╝     ░╚═════╝░╚═╝░░╚═╝╚═╝░░░░░╚═╝╚══════╝  ║
╚════════════════════════════════════════════════════════════════════════════╝
EOF
    say "                         ${BOLD}${_SCRIPT_NAME} v${_VERSION} by ${_AUTHOR}${NC}"
    say "  ${CYAN}══════════════════════════════════════════════════════════════════════════${NC}"
} 1>&3
        
case "$1" in
    --version|-v)
        echo -e "${GREEN}${_SCRIPT_NAME}${NC} versão ${BOLD}${_VERSION}${NC}" 1>&3
        exit 0
        ;;
    --help|-h)
        echo "Uso: Hub [opções]"
        echo "  -v, --version" 1>&3
        exit 0
        ;;
esac

menu() {
    while true; do
        show_banner
        say ""
        say "${GREEN}[1] 🎮 JOGAR${NC}"
        say "${GREEN}[2] 🧹 Limpar RAM${NC}"
        say "${YELLOW}[3] ➕ Adicionar Jogo Auto${NC}"
        say "${YELLOW}[4] 📝 Adicionar jogo manual${NC}"
        say "${YELLOW}[5] 🛡 Proteger App${NC}"
        say "${BLUE}[6] 🔄 Restaurar Sistema${NC}"
        say "${BLUE}[7] 🗑️ Limpar Cache de Detecção${NC}"
        say "${BLUE}[8] 📲 Atualizar/instalar dependências"
        say "${RED}[9] ❌ Sair${NC}"
        echo -n "➜ " >&3
        read op

        case $op in
            1) jogar ;;
            2) spinner exterminar_apps " 🚀 Otimizando memória...";;
            3) adicionar_jogo_auto ;;
            4) adicionar_jogo_manual ;;
            5) adicionar_whitelist ;;
            6) modo_normal ;;
            7) limpar_cache ;;
            8) update;;
            9) exit 0 ;;
            *) say "${RED}Opção inválida!${NC}" ;;
        esac
    done
}

menu
