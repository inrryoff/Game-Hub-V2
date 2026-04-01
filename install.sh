# --- BLOQUEIO DE HARDWARE EXCLUSIVO MOTO G24 ---
# Pega o codinome do dispositivo direto da Vendor (Motorola)
DEVICE=$(getprop ro.product.vendor.device)

ui_print "- Verificando compatibilidade..."

if [[ "$DEVICE" != "fogorow"* ]]; then
    ui_print "****************************************"
    ui_print "  ❌ ERRO: DISPOSITIVO INCOMPATÍVEL!  "
    ui_print "                                        "
    ui_print "  Este módulo foi desenvolvido na unha  "
    ui_print "  exclusivamente para o Moto G24.      "
    ui_print "  Codinome detectado: $DEVICE          "
    ui_print "****************************************"
    abort "Abortando instalação para sua segurança."
fi

ui_print "- Moto G24 ($DEVICE) detectado! ✅"
ui_print "- Iniciando instalação do GameHub..."
# -----------------------------------------------
