#!/system/bin/sh

LOG_FILE="/data/local/tmp/logs/gamehub.log"

[ ! -f "$LOG_FILE" ] && echo "Log não encontrado!" && exit 1

# ============================================================
# EXTRAIR INFORMAÇÕES DO LOG
# ============================================================
FECHADOS=$(awk -F': ' '/Total de apps fechados/ {val=$2} END {print val}' "$LOG_FILE")
PROTEGIDOS=$(grep -c "Protegendo" "$LOG_FILE") 

eval $(awk '
/Jogo:/ {jogo=$NF}
/PID.*SCHED_FIFO/ {prio="SCHED_FIFO (tempo real)"}
/PID.*SCHED_OTHER/ {prio="SCHED_OTHER (normal)"}
/PID.*SCHED_RR/ {prio="SCHED_RR (round-robin)"}
END {
    printf "JOGO=\"%s\"\n", jogo
    printf "PRIORIDADE=\"%s\"\n", (prio ? prio : "⛔ Não detectada")
}
' "$LOG_FILE")

JOGO="${JOGO:-⛔ Jogo não detectado}"
FECHADOS="${FECHADOS:-0}"
PROTEGIDOS="${PROTEGIDOS:-0}"

MASK="0xFC (CPUs 2-7)"

echo "════════════════════════════════════════════════"
echo " "
echo "  ██████╗ ██╗  ██╗██╗   ██╗██████╗ "
echo " ██╔════╝ ██║  ██║██║   ██║██╔══██╗"
echo " ██║  ███╗███████║██║   ██║██████╔╝"
echo " ██║   ██║██╔══██║██║   ██║██╔══██╗"
echo " ╚██████╔╝██║  ██║╚██████╔╝██████╔╝"
echo "  ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═════╝ "
echo "            GameHub - PRO  -  X"
echo "               BY: @INRRYOFF"
echo " "
echo "════════════════════════════════════════════════"

echo "======================================================="
echo "Jogo         : $JOGO"
echo "Prioridade   : $PRIORIDADE"
echo "Mask CPU     : $MASK"
echo "Fechados     : $FECHADOS"
echo "Protegidos   : $PROTEGIDOS"
echo "======================================================="

echo " "
echo "=================="
echo "[Vol +] Abrir GitHub"
echo "[Vol -] Sair"
echo "=================="

while true; do
    while read -r line; do
        case "$line" in
            *KEY_VOLUMEUP*DOWN*)
                echo ""
                echo "═══════════════════════════════════════"
                echo "🔗 Abrindo GitHub do desenvolvedor..."
                echo "═══════════════════════════════════════"
                sleep 1
                nohup am start -a android.intent.action.VIEW -d "https://github.com/inrryoff" >/dev/null 2>&1 &
                exit 0
            ;;
            *KEY_VOLUMEDOWN*DOWN*)
                echo "Saindo..."
                exit 0
            ;;
        esac
    done < <(getevent -l 2>/dev/null)
done