#!/bin/bash
# ==============================================================================
#  TURBINA v2 - Enterprise Edition
#  Otimizador profissional de macOS (Intel e Apple Silicon: M1/M2/M3/M4)
# ==============================================================================
#  Como usar:
#    1. Abra o Terminal
#    2. chmod +x turbina-mac-v2.sh
#    3. ./turbina-mac-v2.sh
#
#  Observacao: algumas rotinas usam 'sudo' (cache do sistema, logs, pmset,
#  diskutil). O script pedira sua senha quando necessario.
# ==============================================================================

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# ------------------------------------------------------------------------------
# Cores ANSI
# ------------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

LOGFILE="$HOME/turbina-mac-log.txt"
: > "$LOGFILE"

# ------------------------------------------------------------------------------
# Utilitarios basicos
# ------------------------------------------------------------------------------
log() {
    # Uso: log "mensagem"  -> grava com timestamp no LOGFILE (sem exibir na tela)
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOGFILE"
}

run_logged() {
    # Uso: run_logged "descricao" comando args...
    # Executa o comando, captura stdout+stderr no log, e retorna o status.
    local desc="$1"; shift
    {
        echo "----- $desc -----"
        "$@"
        local status=$?
        echo "----- fim ($desc) status=$status -----"
    } >> "$LOGFILE" 2>&1
    return $status
}

pause() {
    read -rp "Pressione ENTER para continuar..."
}

confirmar() {
    read -rp "$1 (s/N): " resp
    [[ "$resp" =~ ^[Ss]$ ]]
}

check_cmd() {
    # Retorna 0 se o utilitario existir no PATH
    command -v "$1" >/dev/null 2>&1
}

require_cmd_or_warn() {
    local cmd="$1"
    if ! check_cmd "$cmd"; then
        echo -e "${YELLOW}[AVISO]${NC} utilitario '$cmd' nao encontrado no sistema. Pulando etapa relacionada."
        log "AVISO: utilitario '$cmd' nao encontrado, etapa pulada"
        return 1
    fi
    return 0
}

detect_arch() {
    local arch
    arch=$(uname -m)
    if [[ "$arch" == "arm64" ]]; then
        echo "Apple Silicon (M1/M2/M3/M4)"
    else
        echo "Intel (x86_64)"
    fi
}

is_laptop() {
    system_profiler SPPowerDataType 2>/dev/null | grep -qi "Battery Information"
}

get_active_network_service() {
    # Retorna o nome do primeiro servico de rede ativo (Wi-Fi/Ethernet)
    local dev svc prevline
    dev=$(route get default 2>/dev/null | awk '/interface: /{print $2}')
    [[ -z "$dev" ]] && return 1
    svc=""
    while IFS= read -r line; do
        if [[ "$line" == *"Device: $dev)"* ]]; then
            svc=$(echo "$prevline" | sed -E 's/^\([0-9]+\)\s*//')
            break
        fi
        prevline="$line"
    done <<< "$(networksetup -listnetworkserviceorder 2>/dev/null)"
    echo "$svc"
}

section_header() {
    echo ""
    echo -e "${CYAN}${BOLD}== $1 ==${NC}"
}

# ------------------------------------------------------------------------------
# OPCAO 1 - Limpeza Expandida
# ------------------------------------------------------------------------------
limpeza() {
    section_header "Limpeza Expandida"
    log "Iniciando LIMPEZA"

    echo -e "${CYAN}[Limpeza] Cache de usuario (~/Library/Caches)...${NC}"
    run_logged "cache usuario" rm -rf "$HOME/Library/Caches/"*
    echo -e "${CYAN}[Limpeza] Logs de usuario (~/Library/Logs)...${NC}"
    run_logged "logs usuario" rm -rf "$HOME/Library/Logs/"*
    echo -e "${CYAN}[Limpeza] Cache do sistema (/Library/Caches)...${NC}"
    sudo -v
    sudo bash -c 'rm -rf /Library/Caches/* 2>/dev/null'
    log "OK: cache do sistema processado"

    echo -e "${CYAN}[Limpeza] Arquivos temporarios do sistema (/private/var/folders, /tmp)...${NC}"
    run_logged "tmp usuario" find /tmp -type f -user "$(whoami)" -delete
    sudo bash -c 'find /private/var/folders -type f -atime +7 -delete 2>/dev/null'
    log "OK: temporarios antigos removidos (melhor esforco)"

    echo -e "${CYAN}[Limpeza] Caches de navegadores conhecidos...${NC}"
    if [[ -d "$HOME/Library/Caches/com.apple.Safari" ]]; then
        run_logged "cache Safari" rm -rf "$HOME/Library/Caches/com.apple.Safari/"*
        log "OK: cache do Safari removido"
    else
        log "Safari cache nao encontrado, pulando"
    fi
    if [[ -d "$HOME/Library/Caches/Google/Chrome" ]]; then
        run_logged "cache Chrome" rm -rf "$HOME/Library/Caches/Google/Chrome/"*
        log "OK: cache do Chrome removido"
    else
        log "Chrome cache nao encontrado, pulando"
    fi

    echo -e "${CYAN}[Limpeza] Arquivos orfaos de atualizacoes do macOS (Software Update)...${NC}"
    sudo bash -c 'rm -rf /Library/Updates/* 2>/dev/null'
    log "OK: pasta de updates orfaos processada"

    if [[ -d "$HOME/Library/Developer/Xcode/DerivedData" ]]; then
        echo ""
        echo -e "${YELLOW}[Xcode] Foi encontrada a pasta DerivedData do Xcode, que pode${NC}"
        echo "ocupar varios GB. Remove-la e seguro (sera recriada ao compilar),"
        echo "mas o proximo build de cada projeto sera mais lento."
        if confirmar "Deseja remover o cache DerivedData do Xcode?"; then
            run_logged "Xcode DerivedData" rm -rf "$HOME/Library/Developer/Xcode/DerivedData/"*
            echo "DerivedData removido."
            log "OK: Xcode DerivedData removido (confirmado pelo usuario)"
        else
            echo "Mantido."
            log "Xcode DerivedData mantido (usuario optou por nao remover)"
        fi
    fi

    echo -e "${GREEN}Concluido!${NC}"
    log "LIMPEZA concluida"
    pause
}

# ------------------------------------------------------------------------------
# OPCAO 2 - DNS & Rede
# ------------------------------------------------------------------------------
dns_rede() {
    section_header "DNS & Rede"
    log "Iniciando DNS_REDE"

    echo -e "${CYAN}[DNS] Limpando cache de DNS...${NC}"
    sudo -v
    if run_logged "flush dns" sudo dscacheutil -flushcache; then
        log "OK: cache DNS limpo"
    else
        log "AVISO: dscacheutil -flushcache retornou erro"
    fi

    echo -e "${CYAN}[DNS] Reiniciando mDNSResponder de forma limpa...${NC}"
    if run_logged "restart mDNSResponder" sudo killall -HUP mDNSResponder; then
        log "OK: mDNSResponder reiniciado"
    else
        log "AVISO: falha ao reiniciar mDNSResponder"
    fi
    echo -e "${GREEN}Cache de DNS renovado.${NC}"

    echo ""
    echo "Deseja tambem configurar um servidor DNS mais rapido?"
    echo "  1 - Cloudflare (1.1.1.1 / 1.0.0.1)"
    echo "  2 - Google (8.8.8.8 / 8.8.4.4)"
    echo "  3 - Restaurar DNS automatico (DHCP do roteador/provedor)"
    echo "  0 - Nao, obrigado"
    read -rp "Escolha uma opcao: " dnsopc

    if [[ "$dnsopc" != "0" ]]; then
        if ! require_cmd_or_warn networksetup; then
            pause
            return
        fi
        local svc
        svc=$(get_active_network_service)
        if [[ -z "$svc" ]]; then
            echo -e "${YELLOW}[AVISO]${NC} nao foi possivel detectar automaticamente o servico de"
            echo "rede ativo. Rode 'networksetup -listallnetworkservices' e ajuste manualmente."
            log "AVISO: servico de rede ativo nao detectado para configuracao de DNS"
            pause
            return
        fi
        echo "Servico de rede detectado: $svc"
        case "$dnsopc" in
            1)
                sudo networksetup -setdnsservers "$svc" 1.1.1.1 1.0.0.1
                echo -e "${GREEN}DNS Cloudflare aplicado em '$svc'.${NC}"
                log "OK: DNS Cloudflare aplicado em $svc"
                ;;
            2)
                sudo networksetup -setdnsservers "$svc" 8.8.8.8 8.8.4.4
                echo -e "${GREEN}DNS Google aplicado em '$svc'.${NC}"
                log "OK: DNS Google aplicado em $svc"
                ;;
            3)
                sudo networksetup -setdnsservers "$svc" "Empty"
                echo -e "${GREEN}DNS automatico restaurado em '$svc'.${NC}"
                log "OK: DNS automatico restaurado em $svc"
                ;;
            *)
                echo "Opcao invalida, nada foi alterado."
                log "DNS: opcao invalida informada pelo usuario"
                ;;
        esac
    fi
    pause
}

# ------------------------------------------------------------------------------
# OPCAO 3 - Interface Avancada
# ------------------------------------------------------------------------------
interface_avancada() {
    section_header "Interface Avancada"
    log "Iniciando INTERFACE_AVANCADA"

    echo -e "${CYAN}[Interface] Acelerando animacoes do Finder e janelas...${NC}"
    run_logged "NSWindowResizeTime" defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
    run_logged "Finder DisableAllAnimations" defaults write com.apple.finder DisableAllAnimations -bool true

    echo -e "${CYAN}[Interface] Removendo atraso do Dock ao ocultar automaticamente...${NC}"
    run_logged "Dock autohide-delay" defaults write com.apple.dock autohide-delay -float 0
    run_logged "Dock autohide-time-modifier" defaults write com.apple.dock autohide-time-modifier -float 0.4

    echo -e "${CYAN}[Interface] Acelerando renderizacao de paginas no Safari...${NC}"
    run_logged "Safari WebKitInitialTimedLayoutDelay" defaults write com.apple.Safari WebKitInitialTimedLayoutDelay -float 0.25
    run_logged "Safari NSQuitAlwaysKeepsWindows" defaults write com.apple.Safari NSQuitAlwaysKeepsWindows -bool false

    echo -e "${CYAN}[Interface] Reduzindo tempo de animacao de folhas (sheets/janelas)...${NC}"
    run_logged "NSWindowResizeTime2" defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false

    echo -e "${CYAN}[Interface] Reiniciando Finder e Dock para aplicar...${NC}"
    killall Finder >/dev/null 2>&1
    killall Dock >/dev/null 2>&1

    echo -e "${GREEN}Concluido! Interface ajustada para maxima responsividade.${NC}"
    log "INTERFACE_AVANCADA concluida"
    pause
}

# ------------------------------------------------------------------------------
# OPCAO 4 - Manutencao Core de Disco
# ------------------------------------------------------------------------------
manutencao_disco() {
    section_header "Manutencao Core de Disco"
    log "Iniciando MANUTENCAO_DISCO"

    echo -e "${CYAN}[Disco] Verificando volume principal (/)...${NC}"
    run_logged "verifyVolume /" diskutil verifyVolume /
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}Volume principal OK.${NC}"
    else
        echo -e "${YELLOW}Foram reportados problemas. Consulte $LOGFILE para detalhes.${NC}"
    fi

    echo ""
    echo -e "${CYAN}[Disco] Listando containers APFS...${NC}"
    run_logged "apfs list" diskutil apfs list

    echo ""
    echo -e "${CYAN}[Disco] Verificando permissoes do volume do sistema...${NC}"
    # Em macOS moderno (APFS assinado), permissoes de sistema sao read-only
    # e gerenciadas pelo SIP; verifyVolume ja cobre integridade do sistema
    # de arquivos. Aqui rodamos uma checagem adicional no container de dados.
    local data_vol
    data_vol=$(diskutil info / 2>/dev/null | awk -F': ' '/APFS Physical Store/{print $2}' | xargs)
    if [[ -n "$data_vol" ]]; then
        echo "Volume fisico associado: $data_vol"
        log "Container fisico identificado: $data_vol"
    fi
    run_logged "verifyVolume Data" diskutil verifyVolume /System/Volumes/Data 2>/dev/null

    echo ""
    echo -e "${GREEN}Concluido! Relatorio completo em: $LOGFILE${NC}"
    log "MANUTENCAO_DISCO concluida"
    pause
}

# ------------------------------------------------------------------------------
# OPCAO 5 - Otimizacao do Spotlight
# ------------------------------------------------------------------------------
spotlight() {
    section_header "Otimizacao do Spotlight"
    log "Iniciando SPOTLIGHT"

    echo -e "${CYAN}[Spotlight] Status atual do indexador por volume:${NC}"
    run_logged "mdutil status" mdutil -s / 
    mdutil -s / 2>/dev/null

    echo ""
    echo -e "${CYAN}Volumes montados adicionais:${NC}"
    local vols
    vols=$(mount | awk '/\/Volumes\// {print $3}')
    if [[ -n "$vols" ]]; then
        echo "$vols"
    else
        echo "(nenhum volume externo montado alem do principal)"
    fi

    echo ""
    echo -e "${YELLOW}[ATENCAO]${NC} Reindexar apaga o indice de busca e refaz do zero."
    echo "Pode demorar bastante e a busca fica mais lenta ate terminar."
    if confirmar "Deseja reindexar o Spotlight agora (volume principal e volumes externos)?"; then
        sudo -v
        run_logged "mdutil reindex /" sudo mdutil -E /
        log "OK: reindexacao disparada para /"
        if [[ -n "$vols" ]]; then
            while IFS= read -r v; do
                [[ -z "$v" ]] && continue
                echo "Reindexando: $v"
                sudo mdutil -E "$v" >> "$LOGFILE" 2>&1
                log "OK: reindexacao disparada para $v"
            done <<< "$vols"
        fi
        echo -e "${GREEN}Concluido! O Spotlight vai reindexar em segundo plano.${NC}"
    else
        echo "Operacao cancelada. Apenas o status foi exibido acima."
        log "Reindexacao cancelada pelo usuario"
    fi
    pause
}

# ------------------------------------------------------------------------------
# OPCAO 6 - Gerenciamento de Apps/Processos
# ------------------------------------------------------------------------------
apps_processos() {
    section_header "Gerenciamento de Apps/Processos"
    log "Iniciando APPS_PROCESSOS"

    echo -e "${CYAN}[Processos] Top 10 processos por uso de CPU:${NC}"
    ps aux | sort -rk3 | head -11
    log "OK: snapshot de processos por CPU registrado"
    {
        echo "----- Top 10 processos por CPU -----"
        ps aux | sort -rk3 | head -11
    } >> "$LOGFILE"

    echo ""
    echo -e "${CYAN}[Processos] Verificando processos zumbis (estado Z)...${NC}"
    local zumbis
    zumbis=$(ps aux | awk '$8 ~ /Z/ {print}')
    if [[ -n "$zumbis" ]]; then
        echo -e "${YELLOW}Processos zumbis encontrados:${NC}"
        echo "$zumbis"
        log "AVISO: processos zumbis encontrados: $zumbis"
    else
        echo "Nenhum processo zumbi encontrado."
        log "OK: nenhum processo zumbi encontrado"
    fi

    echo ""
    if check_cmd brew; then
        echo -e "${CYAN}[Homebrew] Verificando atualizacoes disponiveis...${NC}"
        run_logged "brew update" brew update
        echo "Pacotes desatualizados:"
        brew outdated
        {
            echo "----- brew outdated -----"
            brew outdated
        } >> "$LOGFILE"

        echo ""
        if confirmar "Deseja rodar 'brew cleanup' para remover pacotes/orfaos antigos?"; then
            run_logged "brew cleanup" brew cleanup
            echo -e "${GREEN}brew cleanup concluido.${NC}"
        fi

        echo ""
        if confirmar "Deseja rodar 'brew doctor' para checar problemas de configuracao?"; then
            echo -e "${CYAN}Resultado do brew doctor:${NC}"
            brew doctor 2>&1 | tee -a "$LOGFILE"
        fi
    else
        echo -e "${DIM}Homebrew nao esta instalado neste sistema. Etapa ignorada.${NC}"
        log "Homebrew nao encontrado, etapas de brew puladas"
    fi

    echo -e "${GREEN}Concluido!${NC}"
    log "APPS_PROCESSOS concluida"
    pause
}

# ------------------------------------------------------------------------------
# OPCAO 7 - Hibernacao & Bateria
# ------------------------------------------------------------------------------
hibernacao_bateria() {
    section_header "Hibernacao & Bateria"
    log "Iniciando HIBERNACAO_BATERIA"

    if ! is_laptop; then
        echo -e "${YELLOW}[AVISO]${NC} Este Mac nao parece ter bateria (desktop/Mac mini/Mac Studio)."
        echo "As otimizacoes de hibernacao e energia sao voltadas para notebooks."
        if ! confirmar "Deseja aplicar mesmo assim?"; then
            log "HIBERNACAO_BATERIA: usuario optou por nao aplicar em desktop"
            pause
            return
        fi
    fi

    sudo -v
    echo -e "${CYAN}[Energia] Configurando modo de hibernacao seguro (hibernatemode=3)...${NC}"
    echo "  (mantem a RAM e grava no disco - protege dados mesmo se a bateria acabar)"
    run_logged "pmset hibernatemode" sudo pmset -a hibernatemode 3

    echo -e "${CYAN}[Energia] Reduzindo tempo para desligar a tela quando ocioso (10 min na bateria)...${NC}"
    run_logged "pmset displaysleep battery" sudo pmset -b displaysleep 10

    echo -e "${CYAN}[Energia] Ativando standby profundo na bateria apos periodo ocioso...${NC}"
    run_logged "pmset standby" sudo pmset -b standby 1
    run_logged "pmset standbydelaylow" sudo pmset -b standbydelaylow 600

    echo -e "${CYAN}[Energia] Desativando powernap na bateria (economiza ciclos)...${NC}"
    run_logged "pmset powernap" sudo pmset -b powernap 0

    echo ""
    echo -e "${CYAN}Configuracao atual de energia:${NC}"
    pmset -g custom | tee -a "$LOGFILE"

    echo -e "${GREEN}Concluido!${NC}"
    log "HIBERNACAO_BATERIA concluida"
    pause
}

# ------------------------------------------------------------------------------
# OPCAO 10 - Rodar Tudo Seguro
# ------------------------------------------------------------------------------
tudo() {
    section_header "Rodando Otimizacoes Seguras (TUDO)"
    log "=== Iniciando rotina TUDO ==="
    local inicio
    inicio=$(date +%s)

    echo -e "${GREEN}Isso vai rodar: Limpeza, DNS/Rede (sem trocar DNS), Interface,${NC}"
    echo -e "${GREEN}Verificacao de Disco, Processos/Homebrew (sem prompts) e Bateria.${NC}"
    echo -e "${DIM}(a reindexacao completa do Spotlight fica de fora por ser demorada)${NC}"
    echo ""

    # Limpeza (sem prompt do Xcode - pula automaticamente nesta rotina)
    section_header "1/6 - Limpeza"
    log "TUDO: iniciando limpeza"
    rm -rf "$HOME/Library/Caches/"* 2>/dev/null
    rm -rf "$HOME/Library/Logs/"* 2>/dev/null
    sudo -v
    sudo bash -c 'rm -rf /Library/Caches/* 2>/dev/null'
    [[ -d "$HOME/Library/Caches/com.apple.Safari" ]] && rm -rf "$HOME/Library/Caches/com.apple.Safari/"* 2>/dev/null
    [[ -d "$HOME/Library/Caches/Google/Chrome" ]] && rm -rf "$HOME/Library/Caches/Google/Chrome/"* 2>/dev/null
    echo "Limpeza concluida (DerivedData do Xcode NAO foi tocado nesta rotina)."
    log "TUDO: limpeza concluida (Xcode DerivedData preservado por seguranca)"

    # DNS/Rede - so o flush, sem trocar servidor
    section_header "2/6 - DNS & Rede (flush)"
    sudo dscacheutil -flushcache >> "$LOGFILE" 2>&1
    sudo killall -HUP mDNSResponder >> "$LOGFILE" 2>&1
    echo "Cache de DNS renovado."
    log "TUDO: DNS renovado"

    # Interface
    section_header "3/6 - Interface Avancada"
    defaults write NSGlobalDomain NSWindowResizeTime -float 0.001 >> "$LOGFILE" 2>&1
    defaults write com.apple.finder DisableAllAnimations -bool true >> "$LOGFILE" 2>&1
    defaults write com.apple.dock autohide-delay -float 0 >> "$LOGFILE" 2>&1
    defaults write com.apple.dock autohide-time-modifier -float 0.4 >> "$LOGFILE" 2>&1
    defaults write com.apple.Safari WebKitInitialTimedLayoutDelay -float 0.25 >> "$LOGFILE" 2>&1
    killall Finder >/dev/null 2>&1
    killall Dock >/dev/null 2>&1
    echo "Interface ajustada."
    log "TUDO: interface ajustada"

    # Disco - so verificacao, nao reparo
    section_header "4/6 - Verificacao de Disco"
    diskutil verifyVolume / >> "$LOGFILE" 2>&1
    echo "Verificacao de disco concluida (relatorio no log)."
    log "TUDO: verificacao de disco concluida"

    # Processos/Homebrew - so leitura + cleanup automatico, sem prompts interativos
    section_header "5/6 - Processos e Homebrew"
    {
        echo "----- Top 10 processos por CPU (TUDO) -----"
        ps aux | sort -rk3 | head -11
    } >> "$LOGFILE"
    if check_cmd brew; then
        brew cleanup >> "$LOGFILE" 2>&1
        echo "Homebrew: brew cleanup executado."
        log "TUDO: brew cleanup executado"
    else
        echo "Homebrew nao instalado, etapa ignorada."
        log "TUDO: Homebrew ausente"
    fi

    # Bateria - somente se for notebook, sem prompts
    section_header "6/6 - Energia/Bateria"
    if is_laptop; then
        sudo pmset -a hibernatemode 3 >> "$LOGFILE" 2>&1
        sudo pmset -b displaysleep 10 >> "$LOGFILE" 2>&1
        sudo pmset -b powernap 0 >> "$LOGFILE" 2>&1
        echo "Ajustes de energia aplicados (notebook detectado)."
        log "TUDO: ajustes de energia aplicados"
    else
        echo "Desktop detectado, ajustes de bateria ignorados."
        log "TUDO: desktop detectado, energia ignorada"
    fi

    local fim duracao
    fim=$(date +%s)
    duracao=$(( fim - inicio ))

    echo ""
    echo -e "${GREEN}${BOLD}=============================================================="
    echo "  TUDO CONCLUIDO em ${duracao}s!"
    echo "  Relatorio completo: $LOGFILE"
    echo "==============================================================${NC}"
    log "=== Rotina TUDO concluida em ${duracao}s ==="
    pause
}

# ------------------------------------------------------------------------------
# MENU PRINCIPAL
# ------------------------------------------------------------------------------
menu() {
    clear
    local arch
    arch=$(detect_arch)
    echo -e "${BOLD}┌──────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BOLD}│         TURBINA v2 - ENTERPRISE EDITION (macOS)                 │${NC}"
    echo -e "${BOLD}├──────────────────────────────────────────────────────────────┤${NC}"
    printf "│  Arquitetura detectada: %-38s │\n" "$arch"
    echo -e "${BOLD}├──────────────────────────────────────────────────────────────┤${NC}"
    echo "│   1  - Limpeza expandida (cache, logs, Xcode, navegadores)      │"
    echo "│   2  - DNS & Rede (flush + trocar servidor DNS)                 │"
    echo "│   3  - Interface avancada (animacoes, Dock, Safari)             │"
    echo "│   4  - Manutencao core de disco (verify + APFS)                │"
    echo "│   5  - Otimizacao do Spotlight (status + reindexar)            │"
    echo "│   6  - Apps/Processos (CPU, zumbis, Homebrew)                  │"
    echo "│   7  - Hibernacao & bateria (pmset, so notebooks)              │"
    echo -e "${BOLD}├──────────────────────────────────────────────────────────────┤${NC}"
    echo "│   10 - RODAR TUDO SEGURO (recomendado)                          │"
    echo "│   0  - Sair                                                     │"
    echo -e "${BOLD}└──────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    read -rp "Escolha uma opcao: " opc

    case $opc in
        1) limpeza ;;
        2) dns_rede ;;
        3) interface_avancada ;;
        4) manutencao_disco ;;
        5) spotlight ;;
        6) apps_processos ;;
        7) hibernacao_bateria ;;
        10) tudo ;;
        0) log "=== Sessao encerrada pelo usuario ==="; exit 0 ;;
        *) echo -e "${RED}Opcao invalida.${NC}"; sleep 1 ;;
    esac
    menu
}

# ------------------------------------------------------------------------------
# INICIO
# ------------------------------------------------------------------------------
log "=== Sessao iniciada (TURBINA v2 - $(detect_arch)) ==="
menu
