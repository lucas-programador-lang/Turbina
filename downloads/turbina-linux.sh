#!/bin/bash
# ==============================================================================
#  TURBINA v2 - Linux Enterprise Edition
#  Otimizador profissional para distros baseadas em systemd
#  (Ubuntu, Debian, Fedora, Arch Linux, Linux Mint, Pop!_OS, etc.)
# ==============================================================================
#  Como usar:
#    1. Abra o Terminal
#    2. chmod +x turbina-linux-v2.sh
#    3. ./turbina-linux-v2.sh
#
#  Observacao: varias rotinas usam 'sudo' apenas quando realmente necessario
#  (pacotes, logs do systemd, sysctl, I/O scheduler). O script pedira sua
#  senha quando chegar nessas etapas.
# ==============================================================================

export LC_ALL=C.UTF-8 2>/dev/null || export LC_ALL=en_US.UTF-8

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

LOGFILE="$HOME/turbina-linux-log.txt"
: > "$LOGFILE"

# ------------------------------------------------------------------------------
# Utilitarios basicos
# ------------------------------------------------------------------------------
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOGFILE"
}

run_logged() {
    # Uso: run_logged "descricao" comando args...
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
    command -v "$1" >/dev/null 2>&1
}

require_cmd_or_warn() {
    local cmd="$1"
    if ! check_cmd "$cmd"; then
        echo -e "${YELLOW}[AVISO]${NC} utilitario '$cmd' nao encontrado. Pulando etapa relacionada."
        log "AVISO: utilitario '$cmd' nao encontrado, etapa pulada"
        return 1
    fi
    return 0
}

ensure_sudo() {
    # Pede a senha uma vez e cacheia a credencial para as proximas chamadas sudo
    if ! check_cmd sudo; then
        echo -e "${RED}[ERRO]${NC} 'sudo' nao esta disponivel neste sistema. Etapa cancelada."
        log "ERRO: sudo nao disponivel"
        return 1
    fi
    sudo -v 2>/dev/null
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}[ERRO]${NC} nao foi possivel obter privilegios de superusuario."
        log "ERRO: falha ao obter sudo (senha incorreta ou usuario sem permissao)"
        return 1
    fi
    return 0
}

section_header() {
    echo ""
    echo -e "${CYAN}${BOLD}== $1 ==${NC}"
}

detectar_gerenciador() {
    if check_cmd apt; then echo "apt";
    elif check_cmd dnf; then echo "dnf";
    elif check_cmd pacman; then echo "pacman";
    elif check_cmd zypper; then echo "zypper";
    else echo "desconhecido"; fi
}

is_ssd() {
    # Uso: is_ssd nome_do_disco (ex: sda, nvme0n1) -> retorna 0 se SSD
    local disk="$1"
    local rot_file="/sys/block/$disk/queue/rotational"
    [[ -f "$rot_file" ]] || return 1
    [[ "$(cat "$rot_file" 2>/dev/null)" == "0" ]]
}

# ------------------------------------------------------------------------------
# OPCAO 1 - Limpeza de Pacotes Avancada
# ------------------------------------------------------------------------------
limpeza_pacotes() {
    section_header "Limpeza de Pacotes Avancada"
    log "Iniciando LIMPEZA_PACOTES"

    if ! ensure_sudo; then pause; return; fi

    local GM
    GM=$(detectar_gerenciador)
    echo -e "${CYAN}[Pacotes] Gerenciador detectado: $GM${NC}"
    log "Gerenciador de pacotes detectado: $GM"

    case $GM in
        apt)
            run_logged "apt clean" sudo apt clean || log "AVISO: apt clean falhou"
            run_logged "apt autoremove" sudo apt autoremove -y || log "AVISO: apt autoremove falhou"
            ;;
        dnf)
            run_logged "dnf clean all" sudo dnf clean all || log "AVISO: dnf clean all falhou"
            run_logged "dnf autoremove" sudo dnf autoremove -y || log "AVISO: dnf autoremove falhou"
            ;;
        pacman)
            run_logged "pacman -Sc" sudo pacman -Sc --noconfirm || log "AVISO: pacman -Sc falhou"
            local orfaos
            orfaos=$(pacman -Qtdq 2>/dev/null)
            if [[ -n "$orfaos" ]]; then
                run_logged "pacman -Rns orfaos" sudo pacman -Rns $orfaos --noconfirm || log "AVISO: remocao de orfaos falhou"
            else
                log "Nenhum pacote orfao encontrado (pacman)"
            fi
            ;;
        zypper)
            run_logged "zypper clean" sudo zypper clean --all || log "AVISO: zypper clean falhou"
            ;;
        *)
            echo -e "${YELLOW}Gerenciador de pacotes nao reconhecido. Pulei esta etapa.${NC}"
            log "AVISO: gerenciador de pacotes desconhecido"
            ;;
    esac

    echo ""
    if check_cmd flatpak; then
        echo -e "${CYAN}[Flatpak] Removendo runtimes/apps nao utilizados...${NC}"
        run_logged "flatpak uninstall unused" flatpak uninstall --unused -y
        if [[ $? -eq 0 ]]; then
            log "OK: flatpak uninstall --unused concluido"
        else
            log "AVISO: flatpak uninstall --unused retornou erro"
        fi
    else
        echo -e "${DIM}Flatpak nao instalado, etapa ignorada.${NC}"
        log "Flatpak nao encontrado, etapa pulada"
    fi

    echo ""
    if check_cmd snap; then
        echo -e "${CYAN}[Snap] Limitando retencao de revisoes antigas para 2...${NC}"
        run_logged "snap set refresh.retain=2" sudo snap set system refresh.retain=2
        echo -e "${CYAN}[Snap] Removendo revisoes desabilitadas antigas...${NC}"
        {
            echo "----- snap list --all (revisoes desabilitadas) -----"
            snap list --all 2>/dev/null | awk '/disabled/{print $1, $3}' | while read -r snapname rev; do
                echo "Removendo $snapname revisao $rev"
                sudo snap remove "$snapname" --revision="$rev" 2>&1
            done
        } >> "$LOGFILE" 2>&1
        log "OK: limpeza de revisoes antigas do snap processada"
    else
        echo -e "${DIM}Snap nao instalado, etapa ignorada.${NC}"
        log "Snap nao encontrado, etapa pulada"
    fi

    echo -e "${GREEN}Concluido!${NC}"
    log "LIMPEZA_PACOTES concluida"
    pause
}

# ------------------------------------------------------------------------------
# OPCAO 2 - Limpeza de Logs e Caches do Usuario
# ------------------------------------------------------------------------------
limpar_logs() {
    section_header "Limpeza de Logs e Caches do Usuario"
    log "Iniciando LIMPAR_LOGS"

    if ensure_sudo; then
        echo -e "${CYAN}[Logs] Reduzindo logs do systemd para os ultimos 7 dias...${NC}"
        run_logged "journalctl vacuum" sudo journalctl --vacuum-time=7d
        if [[ $? -eq 0 ]]; then
            log "OK: journalctl vacuum-time=7d concluido"
        else
            log "AVISO: journalctl --vacuum-time=7d retornou erro"
        fi
    fi

    echo -e "${CYAN}[Cache] Limpando ~/.cache do usuario...${NC}"
    if [[ -d "$HOME/.cache" ]]; then
        run_logged "limpar ~/.cache" find "$HOME/.cache" -mindepth 1 -delete
        [[ $? -eq 0 ]] && log "OK: ~/.cache limpo" || log "AVISO: falha parcial ao limpar ~/.cache"
    else
        log "~/.cache nao existe, nada a fazer"
    fi

    echo -e "${CYAN}[Logs] Limpando logs orfaos em ~/.log (se existir)...${NC}"
    if [[ -d "$HOME/.log" ]]; then
        run_logged "limpar ~/.log" find "$HOME/.log" -mindepth 1 -delete
        [[ $? -eq 0 ]] && log "OK: ~/.log limpo" || log "AVISO: falha parcial ao limpar ~/.log"
    else
        log "~/.log nao existe, nada a fazer (pasta nao-padrao, apenas verificacao de seguranca)"
    fi

    echo -e "${GREEN}Concluido!${NC}"
    log "LIMPAR_LOGS concluida"
    pause
}

# ------------------------------------------------------------------------------
# OPCAO 3 - DNS & Rede Turbo
# ------------------------------------------------------------------------------
dns_rede_turbo() {
    section_header "DNS & Rede Turbo"
    log "Iniciando DNS_REDE_TURBO"

    echo -e "${CYAN}[DNS] Limpando cache de DNS...${NC}"
    if check_cmd resolvectl; then
        run_logged "resolvectl flush-caches" sudo resolvectl flush-caches
        [[ $? -eq 0 ]] && log "OK: cache DNS limpo (resolvectl)" || log "AVISO: resolvectl flush-caches falhou"
    elif check_cmd systemd-resolve; then
        run_logged "systemd-resolve flush" sudo systemd-resolve --flush-caches
        [[ $? -eq 0 ]] && log "OK: cache DNS limpo (systemd-resolve)" || log "AVISO: systemd-resolve --flush-caches falhou"
    else
        echo -e "${YELLOW}[AVISO]${NC} systemd-resolved nao detectado. Etapa de flush ignorada."
        log "AVISO: nenhum utilitario de flush de DNS encontrado"
    fi
    echo -e "${GREEN}Cache de DNS renovado (quando aplicavel).${NC}"

    echo ""
    echo "Deseja aplicar tambem otimizacoes de rede para jogos/streaming"
    echo "via sysctl (TCP BBR, keepalive, buffers)? Essas mudancas sao"
    echo "gravadas em /etc/sysctl.d/99-turbina-net.conf e podem ser"
    echo "revertidas apagando esse arquivo e rodando 'sudo sysctl --system'."
    if ! confirmar "Aplicar otimizacoes de rede agora?"; then
        log "DNS_REDE_TURBO: usuario optou por nao aplicar sysctl de rede"
        pause
        return
    fi

    if ! ensure_sudo; then pause; return; fi

    local bbr_disponivel="nao"
    local congestion_avail
    congestion_avail=$(sysctl -n net.ipv4.tcp_available_congestion_control 2>/dev/null)
    if [[ "$congestion_avail" == *bbr* ]]; then
        bbr_disponivel="sim"
    else
        sudo modprobe tcp_bbr 2>/dev/null
        congestion_avail=$(sysctl -n net.ipv4.tcp_available_congestion_control 2>/dev/null)
        [[ "$congestion_avail" == *bbr* ]] && bbr_disponivel="sim"
    fi
    log "TCP BBR disponivel: $bbr_disponivel"

    {
        echo "# Gerado por TURBINA v2 - otimizacoes de rede"
        if [[ "$bbr_disponivel" == "sim" ]]; then
            echo "net.core.default_qdisc=fq"
            echo "net.ipv4.tcp_congestion_control=bbr"
        fi
        echo "net.ipv4.tcp_keepalive_time=120"
        echo "net.ipv4.tcp_keepalive_intvl=30"
        echo "net.ipv4.tcp_keepalive_probes=4"
        echo "net.core.rmem_max=8388608"
        echo "net.core.wmem_max=8388608"
        echo "net.ipv4.tcp_rmem=4096 87380 8388608"
        echo "net.ipv4.tcp_wmem=4096 65536 8388608"
        echo "net.ipv4.tcp_fastopen=3"
    } | sudo tee /etc/sysctl.d/99-turbina-net.conf >/dev/null

    run_logged "sysctl --system" sudo sysctl --system
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}Concluido! Parametros de rede aplicados.${NC}"
        if [[ "$bbr_disponivel" == "sim" ]]; then
            echo "TCP BBR ativado como algoritmo de congestionamento."
        else
            echo -e "${YELLOW}TCP BBR nao esta disponivel no kernel atual, foi ignorado.${NC}"
        fi
        log "OK: otimizacoes de rede aplicadas (BBR: $bbr_disponivel)"
    else
        echo -e "${YELLOW}[AVISO]${NC} alguns parametros podem nao ter sido aplicados. Veja o log."
        log "AVISO: sysctl --system retornou erro ao aplicar parametros de rede"
    fi
    pause
}

# ------------------------------------------------------------------------------
# OPCAO 4 - Otimizacao do Kernel e RAM
# ------------------------------------------------------------------------------
kernel_ram() {
    section_header "Otimizacao do Kernel e RAM"
    log "Iniciando KERNEL_RAM"

    local swap_atual cache_atual
    swap_atual=$(cat /proc/sys/vm/swappiness 2>/dev/null)
    cache_atual=$(cat /proc/sys/vm/vfs_cache_pressure 2>/dev/null)

    echo -e "${CYAN}[Memoria] Valor atual do swappiness: ${swap_atual:-desconhecido}${NC}"
    echo "Valores menores (ex: 10) fazem o sistema preferir usar a RAM e"
    echo "so usar a swap (disco) quando for realmente necessario."
    echo ""
    echo -e "${CYAN}[Memoria] Valor atual do vfs_cache_pressure: ${cache_atual:-desconhecido}${NC}"
    echo "Valores menores (ex: 50) fazem o kernel reter mais cache de"
    echo "metadados de arquivos na memoria, em vez de descarta-los cedo."
    echo ""

    if ! confirmar "Deseja aplicar swappiness=10 e vfs_cache_pressure=50 agora?"; then
        log "KERNEL_RAM: usuario optou por nao aplicar"
        pause
        return
    fi

    if ! ensure_sudo; then pause; return; fi

    {
        echo "# Gerado por TURBINA v2 - otimizacoes de memoria"
        echo "vm.swappiness=10"
        echo "vm.vfs_cache_pressure=50"
    } | sudo tee /etc/sysctl.d/99-turbina-swappiness.conf >/dev/null

    run_logged "sysctl vm.swappiness" sudo sysctl vm.swappiness=10
    run_logged "sysctl vm.vfs_cache_pressure" sudo sysctl vm.vfs_cache_pressure=50

    echo -e "${GREEN}Concluido! Valores aplicados agora e persistidos para o proximo boot.${NC}"
    log "OK: swappiness=10 e vfs_cache_pressure=50 aplicados/persistidos"
    pause
}

# ------------------------------------------------------------------------------
# OPCAO 5 - Limpeza Automatica de Travamentos
# ------------------------------------------------------------------------------
limpeza_travamentos() {
    section_header "Limpeza Automatica de Travamentos"
    log "Iniciando LIMPEZA_TRAVAMENTOS"

    if ! ensure_sudo; then pause; return; fi

    echo -e "${CYAN}[Core Dumps] Procurando arquivos core dump acumulados...${NC}"
    local core_count
    core_count=$(sudo find / -xdev -maxdepth 6 \( -name "core" -o -name "core.*" \) -type f 2>/dev/null | wc -l)
    echo "Encontrados: $core_count arquivo(s) core no volume raiz (busca ate 6 niveis)."
    log "Core dumps encontrados: $core_count"
    if [[ "$core_count" -gt 0 ]]; then
        run_logged "remover core dumps" sudo find / -xdev -maxdepth 6 \( -name "core" -o -name "core.*" \) -type f -delete
        [[ $? -eq 0 ]] && log "OK: core dumps removidos" || log "AVISO: falha ao remover alguns core dumps"
    fi

    if check_cmd coredumpctl; then
        echo -e "${CYAN}[Core Dumps] Limpando armazenamento de coredumpctl (systemd)...${NC}"
        run_logged "coredumpctl cleanup" sudo journalctl --vacuum-time=1s --unit=systemd-coredump 2>/dev/null
        # Remove os arquivos de dump geridos pelo systemd diretamente
        sudo rm -rf /var/lib/systemd/coredump/* 2>/dev/null
        log "OK: coredumps do systemd-coredump processados"
    fi

    echo ""
    echo -e "${CYAN}[/tmp] Removendo temporarios com mais de 48h sem uso...${NC}"
    run_logged "limpar /tmp antigo" sudo find /tmp -mindepth 1 -amin +2880 -delete
    if [[ $? -eq 0 ]]; then
        log "OK: temporarios antigos de /tmp removidos"
    else
        log "AVISO: alguns arquivos de /tmp nao puderam ser removidos (podem estar em uso)"
    fi

    echo -e "${GREEN}Concluido!${NC}"
    log "LIMPEZA_TRAVAMENTOS concluida"
    pause
}

# ------------------------------------------------------------------------------
# OPCAO 6 - Analise de Desempenho e Inicializacao
# ------------------------------------------------------------------------------
analise_boot() {
    section_header "Analise de Desempenho e Inicializacao"
    log "Iniciando ANALISE_BOOT"

    if ! require_cmd_or_warn systemd-analyze; then pause; return; fi

    echo -e "${CYAN}[Boot] Tempo total de inicializacao:${NC}"
    systemd-analyze time 2>/dev/null | tee -a "$LOGFILE"

    echo ""
    echo -e "${CYAN}[Boot] Os 5 servicos que mais atrasam o boot:${NC}"
    systemd-analyze blame 2>/dev/null | head -5 | tee -a "$LOGFILE"
    log "OK: analise de boot (systemd-analyze blame) registrada"

    echo ""
    echo -e "${CYAN}[Servicos] Servicos habilitados na inicializacao:${NC}"
    systemctl list-unit-files --state=enabled --type=service --no-pager 2>/dev/null | tee -a "$LOGFILE"
    echo ""
    echo "Para desativar um servico que voce nao usa, rode:"
    echo "  sudo systemctl disable nome-do-servico"

    log "ANALISE_BOOT concluida"
    pause
}

# ------------------------------------------------------------------------------
# OPCAO 7 - Otimizacao de Leituras de Disco (I/O Scheduler)
# ------------------------------------------------------------------------------
io_scheduler() {
    section_header "Otimizacao de Leituras de Disco (I/O Scheduler)"
    log "Iniciando IO_SCHEDULER"

    if [[ ! -d /sys/block ]]; then
        echo -e "${YELLOW}[AVISO]${NC} /sys/block nao encontrado, nao foi possivel detectar discos."
        log "AVISO: /sys/block ausente"
        pause
        return
    fi

    if ! ensure_sudo; then pause; return; fi

    local discos
    discos=$(lsblk -d -n -o NAME 2>/dev/null | grep -Ev '^(loop|sr|zram)')
    if [[ -z "$discos" ]]; then
        echo -e "${YELLOW}Nenhum disco fisico encontrado.${NC}"
        log "Nenhum disco fisico encontrado para ajuste de I/O scheduler"
        pause
        return
    fi

    while IFS= read -r disco; do
        [[ -z "$disco" ]] && continue
        local sched_path="/sys/block/$disco/queue/scheduler"
        [[ -f "$sched_path" ]] || continue

        local atual disponiveis tipo alvo
        atual=$(cat "$sched_path" 2>/dev/null)
        disponiveis=$(cat "$sched_path" 2>/dev/null | tr -d '[]')

        if is_ssd "$disco"; then
            tipo="SSD"
            if [[ "$disponiveis" == *none* ]]; then
                alvo="none"
            elif [[ "$disponiveis" == *kyber* ]]; then
                alvo="kyber"
            else
                alvo=""
            fi
        else
            tipo="HD"
            if [[ "$disponiveis" == *bfq* ]]; then
                alvo="bfq"
            else
                alvo=""
            fi
        fi

        echo -e "${CYAN}Disco: /dev/$disco  Tipo: $tipo${NC}"
        echo "  Scheduler atual:      $atual"
        echo "  Schedulers disponiveis: $disponiveis"

        if [[ -z "$alvo" ]]; then
            echo -e "  ${YELLOW}Nenhum scheduler ideal disponivel no kernel para este tipo de disco. Mantendo atual.${NC}"
            log "IO_SCHEDULER: $disco ($tipo) sem scheduler ideal disponivel, mantido"
        elif [[ "$atual" == *"[$alvo]"* ]]; then
            echo -e "  ${GREEN}Ja esta configurado com o scheduler ideal ($alvo).${NC}"
            log "IO_SCHEDULER: $disco ja estava em $alvo"
        else
            if confirmar "  Aplicar scheduler '$alvo' em /dev/$disco agora?"; then
                echo "$alvo" | sudo tee "$sched_path" >/dev/null 2>>"$LOGFILE"
                if [[ $? -eq 0 ]]; then
                    echo -e "  ${GREEN}Scheduler alterado para $alvo.${NC}"
                    log "OK: $disco alterado para scheduler $alvo"
                else
                    echo -e "  ${YELLOW}Falha ao alterar o scheduler. Veja o log.${NC}"
                    log "AVISO: falha ao alterar scheduler de $disco para $alvo"
                fi
            else
                log "IO_SCHEDULER: usuario optou por nao alterar $disco"
            fi
        fi
        echo ""
    done <<< "$discos"

    echo -e "${DIM}Nota: esta mudanca vale ate o proximo reinicio. Para torna-la${NC}"
    echo -e "${DIM}permanente, crie uma regra udev (ex: /etc/udev/rules.d/60-scheduler.rules).${NC}"
    log "IO_SCHEDULER concluida"
    pause
}

# ------------------------------------------------------------------------------
# OPCAO 8 - Espaco em Disco
# ------------------------------------------------------------------------------
espaco_disco() {
    section_header "Espaco em Disco"
    log "Iniciando ESPACO_DISCO"
    echo -e "${CYAN}[Espaco] Verificando espaco livre em disco...${NC}"
    df -h / | tee -a "$LOGFILE"
    echo ""
    echo "Pastas que mais ocupam espaco na home (top 10):"
    du -sh "$HOME"/* 2>/dev/null | sort -rh | head -10 | tee -a "$LOGFILE"
    log "ESPACO_DISCO concluida"
    pause
}

# ------------------------------------------------------------------------------
# OPCAO 9 - Rodar Tudo Seguro
# ------------------------------------------------------------------------------
tudo() {
    section_header "Rodando Otimizacoes Seguras (TUDO)"
    log "=== Iniciando rotina TUDO ==="
    local inicio
    inicio=$(date +%s)

    echo -e "${GREEN}Isso vai rodar: limpeza de pacotes, logs/cache do usuario,${NC}"
    echo -e "${GREEN}flush de DNS, limpeza de travamentos, analise de boot e espaco em disco.${NC}"
    echo -e "${DIM}(ajustes de sysctl de rede/kernel e troca de I/O scheduler ficam de${NC}"
    echo -e "${DIM} fora, pois alteram configuracoes estruturais e exigem confirmacao)${NC}"
    echo ""

    if ! ensure_sudo; then
        echo -e "${YELLOW}Sem privilegios de sudo, algumas etapas serao puladas.${NC}"
    fi

    section_header "1/6 - Limpeza de Pacotes"
    local GM
    GM=$(detectar_gerenciador)
    case $GM in
        apt) sudo apt clean >> "$LOGFILE" 2>&1; sudo apt autoremove -y >> "$LOGFILE" 2>&1 ;;
        dnf) sudo dnf clean all >> "$LOGFILE" 2>&1; sudo dnf autoremove -y >> "$LOGFILE" 2>&1 ;;
        pacman) sudo pacman -Sc --noconfirm >> "$LOGFILE" 2>&1 ;;
        zypper) sudo zypper clean --all >> "$LOGFILE" 2>&1 ;;
        *) log "TUDO: gerenciador de pacotes desconhecido" ;;
    esac
    check_cmd flatpak && flatpak uninstall --unused -y >> "$LOGFILE" 2>&1
    echo "Limpeza de pacotes concluida."
    log "TUDO: limpeza de pacotes concluida ($GM)"

    section_header "2/6 - Logs e Cache do Usuario"
    sudo journalctl --vacuum-time=7d >> "$LOGFILE" 2>&1
    [[ -d "$HOME/.cache" ]] && find "$HOME/.cache" -mindepth 1 -delete 2>/dev/null
    echo "Logs e cache do usuario limpos."
    log "TUDO: logs/cache do usuario limpos"

    section_header "3/6 - DNS"
    if check_cmd resolvectl; then
        sudo resolvectl flush-caches >> "$LOGFILE" 2>&1
    elif check_cmd systemd-resolve; then
        sudo systemd-resolve --flush-caches >> "$LOGFILE" 2>&1
    fi
    echo "Cache de DNS renovado."
    log "TUDO: DNS renovado"

    section_header "4/6 - Limpeza de Travamentos"
    sudo find / -xdev -maxdepth 6 \( -name "core" -o -name "core.*" \) -type f -delete 2>/dev/null
    sudo find /tmp -mindepth 1 -amin +2880 -delete 2>/dev/null
    echo "Core dumps e temporarios antigos removidos."
    log "TUDO: limpeza de travamentos concluida"

    section_header "5/6 - Analise de Boot"
    if check_cmd systemd-analyze; then
        {
            echo "----- systemd-analyze time (TUDO) -----"
            systemd-analyze time 2>/dev/null
            echo "----- systemd-analyze blame top 5 (TUDO) -----"
            systemd-analyze blame 2>/dev/null | head -5
        } >> "$LOGFILE"
        echo "Analise de boot registrada no log."
        log "TUDO: analise de boot registrada"
    else
        echo "systemd-analyze indisponivel, etapa ignorada."
        log "TUDO: systemd-analyze ausente"
    fi

    section_header "6/6 - Espaco em Disco"
    {
        echo "----- df -h / (TUDO) -----"
        df -h /
    } >> "$LOGFILE"
    df -h /
    log "TUDO: espaco em disco registrado"

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
    local GM
    GM=$(detectar_gerenciador)
    echo -e "${BOLD}┌──────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BOLD}│         TURBINA v2 - LINUX ENTERPRISE EDITION                   │${NC}"
    echo -e "${BOLD}├──────────────────────────────────────────────────────────────┤${NC}"
    printf "│  Gerenciador de pacotes detectado: %-27s │\n" "$GM"
    echo -e "${BOLD}├──────────────────────────────────────────────────────────────┤${NC}"
    echo "│   1  - Limpeza de pacotes avancada (apt/dnf/pacman/zypper,      │"
    echo "│        Flatpak e Snap)                                          │"
    echo "│   2  - Logs do systemd e caches orfaos da home                 │"
    echo "│   3  - DNS & rede turbo (flush + sysctl TCP BBR/keepalive)      │"
    echo "│   4  - Otimizacao do kernel e RAM (swappiness/cache_pressure)   │"
    echo "│   5  - Limpeza automatica de travamentos (core dumps/tmp)      │"
    echo "│   6  - Analise de desempenho e inicializacao (boot)            │"
    echo "│   7  - Otimizacao de I/O scheduler (SSD/HD)                    │"
    echo "│   8  - Ver espaco em disco e pastas grandes                    │"
    echo -e "${BOLD}├──────────────────────────────────────────────────────────────┤${NC}"
    echo "│   9  - RODAR TUDO SEGURO (recomendado)                          │"
    echo "│   0  - Sair                                                     │"
    echo -e "${BOLD}└──────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    read -rp "Escolha uma opcao: " opc

    case $opc in
        1) limpeza_pacotes ;;
        2) limpar_logs ;;
        3) dns_rede_turbo ;;
        4) kernel_ram ;;
        5) limpeza_travamentos ;;
        6) analise_boot ;;
        7) io_scheduler ;;
        8) espaco_disco ;;
        9) tudo ;;
        0) log "=== Sessao encerrada pelo usuario ==="; exit 0 ;;
        *) echo -e "${RED}Opcao invalida.${NC}"; sleep 1 ;;
    esac
    menu
}

# ------------------------------------------------------------------------------
# INICIO
# ------------------------------------------------------------------------------
log "=== Sessao iniciada (TURBINA v2 Linux Enterprise Edition) ==="
menu
