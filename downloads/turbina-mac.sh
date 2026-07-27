#!/bin/bash
# ==========================================================
#  TURBINA - Otimizador de macOS
#  Funciona em qualquer Mac (Intel ou Apple Silicon)
# ==========================================================
# Como usar:
#   1. Abra o Terminal
#   2. chmod +x turbina-mac.sh
#   3. ./turbina-mac.sh
# ==========================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

LOGFILE="$HOME/turbina-mac-log.txt"
echo "Log Turbina - $(date)" > "$LOGFILE"

pause() {
    read -rp "Pressione ENTER para continuar..."
}

confirmar() {
    read -rp "$1 (s/N): " resp
    [[ "$resp" =~ ^[Ss]$ ]]
}

limpeza() {
    echo -e "${CYAN}[Limpeza] Limpando caches do sistema e de apps...${NC}"
    rm -rf "$HOME/Library/Caches/"* 2>/dev/null
    rm -rf "$HOME/Library/Logs/"* 2>/dev/null
    sudo rm -rf /Library/Caches/* 2>/dev/null
    echo "Concluido!" | tee -a "$LOGFILE"
    pause
}

flush_dns() {
    echo -e "${CYAN}[DNS] Limpando cache de DNS...${NC}"
    sudo dscacheutil -flushcache
    sudo killall -HUP mDNSResponder
    echo "Concluido!" | tee -a "$LOGFILE"
    pause
}

reiniciar_finder_dock() {
    echo -e "${CYAN}[Interface] Reiniciando Finder e Dock...${NC}"
    killall Finder
    killall Dock
    echo "Concluido!" | tee -a "$LOGFILE"
    pause
}

verificar_disco() {
    echo -e "${CYAN}[Disco] Verificando o disco principal...${NC}"
    diskutil verifyVolume /
    echo "Concluido! Se houver erros, use o Disk Utility (modo de recuperacao) para reparar." | tee -a "$LOGFILE"
    pause
}

itens_login() {
    echo -e "${CYAN}[Inicializacao] Abrindo Itens de Login e Extensoes...${NC}"
    open "x-apple.systempreferences:com.apple.LoginItems-Settings.extension"
    echo "Revise ali o que abre sozinho ao ligar o Mac e desative o que nao precisa."
    pause
}

limpar_logs() {
    echo -e "${CYAN}[Logs] Limpando logs antigos do sistema...${NC}"
    sudo rm -rf /private/var/log/asl/*.asl 2>/dev/null
    sudo log erase --all 2>/dev/null
    echo "Concluido!" | tee -a "$LOGFILE"
    pause
}

reindexar_spotlight() {
    echo -e "${YELLOW}[ATENCAO] Isso apaga o indice de busca do Spotlight e refaz do${NC}"
    echo "zero. Pode demorar bastante e a busca fica mais lenta ate terminar."
    if confirmar "Deseja continuar?"; then
        sudo mdutil -E /
        echo "Concluido! O Spotlight vai reindexar em segundo plano." | tee -a "$LOGFILE"
    else
        echo "Operacao cancelada."
    fi
    pause
}

espaco_disco() {
    echo -e "${CYAN}[Espaco] Verificando espaco livre em disco...${NC}"
    df -h /
    echo ""
    echo "Pastas que mais ocupam espaco em Downloads/Documents (top 10):"
    du -sh "$HOME/Downloads/"* 2>/dev/null | sort -rh | head -10
    pause
}

purgar_memoria() {
    echo -e "${CYAN}[Memoria] Liberando memoria inativa (RAM)...${NC}"
    sudo purge
    echo "Concluido!" | tee -a "$LOGFILE"
    pause
}

tudo() {
    echo -e "${GREEN}Rodando otimizacoes seguras automaticamente...${NC}"
    limpeza
    flush_dns
    limpar_logs
    espaco_disco
    purgar_memoria
    reiniciar_finder_dock
    echo -e "${GREEN}Tudo concluido!${NC}"
}

menu() {
    clear
    echo "=========================================================="
    echo "         TURBINA - OTIMIZADOR DE macOS"
    echo "=========================================================="
    echo ""
    echo "  1  - Limpeza de cache (sistema e apps)"
    echo "  2  - Limpar cache de DNS"
    echo "  3  - Reiniciar Finder e Dock"
    echo "  4  - Verificar disco"
    echo "  5  - Gerenciar itens de login (inicializacao)"
    echo "  6  - Limpar logs antigos"
    echo "  7  - Reindexar Spotlight (demorado)"
    echo "  8  - Ver espaco em disco e pastas grandes"
    echo "  9  - Liberar memoria RAM inativa"
    echo "  ----------------------------------------------------------"
    echo "  10 - RODAR TUDO SEGURO (recomendado)"
    echo "  0  - Sair"
    echo ""
    echo "=========================================================="
    read -rp "Escolha uma opcao: " opc

    case $opc in
        1) limpeza ;;
        2) flush_dns ;;
        3) reiniciar_finder_dock ;;
        4) verificar_disco ;;
        5) itens_login ;;
        6) limpar_logs ;;
        7) reindexar_spotlight ;;
        8) espaco_disco ;;
        9) purgar_memoria ;;
        10) tudo ;;
        0) exit 0 ;;
    esac
    menu
}

menu
