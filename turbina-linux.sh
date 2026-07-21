#!/bin/bash
# ==========================================================
#  TURBINA - Otimizador de Linux
#  Compatível com distros baseadas em systemd
#  (Ubuntu, Debian, Fedora, Arch, Mint, Pop!_OS, etc.)
# ==========================================================
# Como usar:
#   1. Abra o Terminal
#   2. chmod +x turbina-linux.sh
#   3. ./turbina-linux.sh
# ==========================================================

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

LOGFILE="$HOME/turbina-linux-log.txt"
echo "Log Turbina - $(date)" > "$LOGFILE"

pause() {
    read -rp "Pressione ENTER para continuar..."
}

confirmar() {
    read -rp "$1 (s/N): " resp
    [[ "$resp" =~ ^[Ss]$ ]]
}

detectar_gerenciador() {
    if command -v apt &>/dev/null; then echo "apt";
    elif command -v dnf &>/dev/null; then echo "dnf";
    elif command -v pacman &>/dev/null; then echo "pacman";
    elif command -v zypper &>/dev/null; then echo "zypper";
    else echo "desconhecido"; fi
}

limpeza_pacotes() {
    GM=$(detectar_gerenciador)
    echo -e "${CYAN}[Pacotes] Gerenciador detectado: $GM${NC}"
    case $GM in
        apt)
            sudo apt clean
            sudo apt autoremove -y
            ;;
        dnf)
            sudo dnf clean all
            sudo dnf autoremove -y
            ;;
        pacman)
            sudo pacman -Sc --noconfirm
            sudo pacman -Rns $(pacman -Qtdq) --noconfirm 2>/dev/null
            ;;
        zypper)
            sudo zypper clean --all
            ;;
        *)
            echo "Gerenciador de pacotes nao reconhecido. Pulei esta etapa."
            ;;
    esac
    echo "Concluido!" | tee -a "$LOGFILE"
    pause
}

limpar_logs() {
    echo -e "${CYAN}[Logs] Reduzindo logs do systemd para os ultimos 7 dias...${NC}"
    sudo journalctl --vacuum-time=7d
    echo "Concluido!" | tee -a "$LOGFILE"
    pause
}

flush_dns() {
    echo -e "${CYAN}[DNS] Limpando cache de DNS (systemd-resolved)...${NC}"
    if command -v resolvectl &>/dev/null; then
        sudo resolvectl flush-caches
    else
        sudo systemd-resolve --flush-caches 2>/dev/null
    fi
    echo "Concluido!" | tee -a "$LOGFILE"
    pause
}

trim_ssd() {
    echo -e "${CYAN}[Disco] Rodando TRIM (otimizacao para SSD)...${NC}"
    sudo fstrim -av
    echo "Concluido! (se seu disco for HD tradicional, este comando nao faz nada)" | tee -a "$LOGFILE"
    pause
}

swappiness() {
    valor_atual=$(cat /proc/sys/vm/swappiness)
    echo -e "${CYAN}[Memoria] Valor atual do swappiness: $valor_atual${NC}"
    echo "Valores menores (ex: 10) fazem o sistema preferir usar a RAM"
    echo "e so usar a memoria swap (disco) quando for realmente necessario."
    echo "Isso ajuda bastante em PCs com pouca RAM."
    if confirmar "Deseja ajustar o swappiness para 10?"; then
        echo "vm.swappiness=10" | sudo tee /etc/sysctl.d/99-turbina-swappiness.conf >/dev/null
        sudo sysctl vm.swappiness=10
        echo "Concluido!" | tee -a "$LOGFILE"
    else
        echo "Operacao cancelada."
    fi
    pause
}

servicos_ativos() {
    echo -e "${CYAN}[Servicos] Listando servicos ativados na inicializacao:${NC}"
    systemctl list-unit-files --state=enabled --type=service
    echo ""
    echo "Para desativar um servico que voce nao usa, rode:"
    echo "  sudo systemctl disable nome-do-servico"
    pause
}

cache_fontes() {
    echo -e "${CYAN}[Fontes] Reconstruindo cache de fontes...${NC}"
    fc-cache -f -v >/dev/null 2>&1
    echo "Concluido!" | tee -a "$LOGFILE"
    pause
}

espaco_disco() {
    echo -e "${CYAN}[Espaco] Verificando espaco livre em disco...${NC}"
    df -h /
    echo ""
    echo "Pastas que mais ocupam espaco na home (top 10):"
    du -sh "$HOME"/* 2>/dev/null | sort -rh | head -10
    pause
}

tudo() {
    echo -e "${GREEN}Rodando otimizacoes seguras automaticamente...${NC}"
    limpeza_pacotes
    limpar_logs
    flush_dns
    trim_ssd
    cache_fontes
    espaco_disco
    echo -e "${GREEN}Tudo concluido!${NC}"
}

menu() {
    clear
    echo "=========================================================="
    echo "         TURBINA - OTIMIZADOR DE LINUX"
    echo "=========================================================="
    echo ""
    echo "  1  - Limpar pacotes orfaos e cache do gerenciador"
    echo "  2  - Reduzir logs antigos do sistema (journalctl)"
    echo "  3  - Limpar cache de DNS"
    echo "  4  - Rodar TRIM no SSD"
    echo "  5  - Ajustar swappiness (uso de RAM x swap)"
    echo "  6  - Ver servicos ativos na inicializacao"
    echo "  7  - Reconstruir cache de fontes"
    echo "  8  - Ver espaco em disco e pastas grandes"
    echo "  ----------------------------------------------------------"
    echo "  9  - RODAR TUDO SEGURO (recomendado)"
    echo "  0  - Sair"
    echo ""
    echo "=========================================================="
    read -rp "Escolha uma opcao: " opc

    case $opc in
        1) limpeza_pacotes ;;
        2) limpar_logs ;;
        3) flush_dns ;;
        4) trim_ssd ;;
        5) swappiness ;;
        6) servicos_ativos ;;
        7) cache_fontes ;;
        8) espaco_disco ;;
        9) tudo ;;
        0) exit 0 ;;
    esac
    menu
}

menu
