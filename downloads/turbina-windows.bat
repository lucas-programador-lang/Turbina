@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
title Otimizador de Windows - Menu v5 (Definitiva)
color 0A

:: ==========================================================================
::  OTIMIZADOR DE WINDOWS 10/11 - VERSAO 5 (DEFINITIVA)
::  Deteccao automatica de SSD/HD, logs estruturados, tratamento de erros
::  e checagem de ponto de restauracao antes de operacoes invasivas.
:: ==========================================================================
::  Execute como Administrador!
:: ==========================================================================

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo [ERRO] Este script precisa ser executado como Administrador.
    echo Clique com o botao direito no arquivo e escolha
    echo "Executar como administrador".
    echo.
    pause
    exit /b
)

set "LOGFILE=%~dp0log_otimizacao.txt"
set "RESTOREFLAG=%~dp0.restore_ok"
if not exist "%LOGFILE%" echo ========================================== > "%LOGFILE%"
call :LOG "=== Sessao iniciada (Otimizador v5) ==="

goto MENU

:: ==========================================================================
:: FUNCAO DE LOG - uso: call :LOG "mensagem"
:: ==========================================================================
:LOG
echo [%DATE% %TIME%] %~1>> "%LOGFILE%"
exit /b 0

:: ==========================================================================
:: CHECAGEM DE PONTO DE RESTAURACAO antes de operacoes invasivas
:: uso: call :CHECK_RESTORE  (retorna com "goto MENU" se usuario cancelar)
:: ==========================================================================
:CHECK_RESTORE
if exist "%RESTOREFLAG%" exit /b 0
echo.
echo [AVISO] Nenhum ponto de restauracao foi criado nesta maquina ainda
echo (opcao 11). Esta operacao altera o sistema e e recomendavel ter
echo um ponto de restauracao antes de continuar.
echo.
echo   1 - Criar ponto de restauracao agora e continuar
echo   2 - Continuar mesmo assim, por minha conta e risco
echo   3 - Cancelar esta operacao
set /p rc="Escolha uma opcao: "
if "%rc%"=="1" (
    call :RESTAURACAO_CORE
    exit /b 0
)
if "%rc%"=="2" (
    call :LOG "AVISO: usuario prosseguiu sem ponto de restauracao"
    exit /b 0
)
call :LOG "Operacao cancelada pelo usuario (sem ponto de restauracao)"
echo Operacao cancelada.
pause
exit /b 1

:: ==========================================================================
:MENU
cls
echo +==================================================================+
echo |          OTIMIZADOR DE WINDOWS - MENU PRINCIPAL v5 (Definitiva)     |
echo +==================================================================+
echo |   1  - Limpeza completa (temp, lixeira, update cache, prefetch)    |
echo |   2  - Ajustar efeitos visuais para performance                    |
echo |   3  - Ativar plano de energia Alto Desempenho                     |
echo |   4  - Desativar dicas/sugestoes/anuncios do Windows                |
echo |   5  - Desativar telemetria e rastreamento (privacidade)            |
echo |   6  - Gerenciar servicos desnecessarios                           |
echo |   7  - Ver e desativar programas de inicializacao                   |
echo |   8  - Otimizar disco (detecta SSD ou HD automaticamente)          |
echo |   9  - Desativar Xbox Game Bar / gravacao em segundo plano          |
echo |   10 - Limpar DNS e resetar rede                                   |
echo |   11 - Criar ponto de restauracao do sistema                       |
echo +==================================================================+
echo |   12 - Remover bloatware (apps inuteis da Microsoft)                |
echo |   13 - Otimizar memoria virtual (pagefile)                          |
echo |   14 - Desativar hibernacao (libera espaco em disco)                |
echo |   15 - Limpeza avancada (updates antigos, Windows.old, WinSxS)      |
echo |   16 - Desativar apps em segundo plano                              |
echo |   17 - Ajustar SysMain/Superfetch (automatico p/ SSD ou HD)         |
echo |   18 - Desativar tarefas agendadas de telemetria                    |
echo |   19 - Dar prioridade ao programa em uso (ajuda CPU fraca)          |
echo +==================================================================+
echo |   21 - Turbo de internet (otimizar TCP/IP - jogos/streaming)        |
echo |   22 - Trocar DNS para servidor mais rapido (Cloudflare/Google)     |
echo |   23 - Desativar Delivery Optimization (economiza internet)         |
echo |   24 - Deixar menus e janelas mais rapidos                          |
echo |   25 - Reduzir escritas desnecessarias no disco                     |
echo |   26 - Limpar logs antigos do Visualizador de Eventos               |
echo |   27 - Verificar/reparar arquivos do sistema (SFC+DISM - demorado)  |
echo |   28 - Agendar verificacao de disco no proximo boot (CHKDSK)        |
echo +==================================================================+
echo |   20 - RODAR TUDO SEGURO (nao inclui 12,14,22,27,28)                |
echo |   0  - Sair                                                         |
echo +==================================================================+
echo.
set /p opc="Escolha uma opcao: "

if "%opc%"=="1" call :LIMPEZA & goto MENU
if "%opc%"=="2" call :VISUAL & goto MENU
if "%opc%"=="3" call :ENERGIA & goto MENU
if "%opc%"=="4" call :DICAS & goto MENU
if "%opc%"=="5" call :TELEMETRIA & goto MENU
if "%opc%"=="6" call :SERVICOS & goto MENU
if "%opc%"=="7" call :INICIALIZACAO & goto MENU
if "%opc%"=="8" call :DISCO & goto MENU
if "%opc%"=="9" call :GAMEBAR & goto MENU
if "%opc%"=="10" call :REDE & goto MENU
if "%opc%"=="11" call :RESTAURACAO & goto MENU
if "%opc%"=="12" call :BLOATWARE & goto MENU
if "%opc%"=="13" call :PAGEFILE & goto MENU
if "%opc%"=="14" call :HIBERNACAO & goto MENU
if "%opc%"=="15" call :LIMPEZA_AVANCADA & goto MENU
if "%opc%"=="16" call :BACKGROUND_APPS & goto MENU
if "%opc%"=="17" call :SYSMAIN & goto MENU
if "%opc%"=="18" call :TAREFAS & goto MENU
if "%opc%"=="19" call :PRIORIDADE & goto MENU
if "%opc%"=="20" call :TUDO & goto MENU
if "%opc%"=="21" call :TURBO_NET & goto MENU
if "%opc%"=="22" call :DNS & goto MENU
if "%opc%"=="23" call :DELIVERY & goto MENU
if "%opc%"=="24" call :MENUS_RAPIDOS & goto MENU
if "%opc%"=="25" call :LASTACCESS & goto MENU
if "%opc%"=="26" call :LIMPAR_LOGS & goto MENU
if "%opc%"=="27" call :SFC_DISM & goto MENU
if "%opc%"=="28" call :CHKDSK & goto MENU
if "%opc%"=="0" (call :LOG "=== Sessao encerrada pelo usuario ===" & exit /b)
goto MENU

:: ==========================================================================
:LIMPEZA
echo.
echo [Limpeza] Limpando arquivos temporarios, lixeira, cache...
call :LOG "Iniciando LIMPEZA"
del /q /f /s "%TEMP%\*" >nul 2>&1
if errorlevel 1 (call :LOG "AVISO: falha ao limpar %%TEMP%%") else (call :LOG "OK: %%TEMP%% limpo")
del /q /f /s "C:\Windows\Temp\*" >nul 2>&1
if errorlevel 1 (call :LOG "AVISO: falha ao limpar C:\Windows\Temp") else (call :LOG "OK: C:\Windows\Temp limpo")
net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1
rd /s /q "C:\Windows\SoftwareDistribution\Download" >nul 2>&1
if errorlevel 1 (call :LOG "AVISO: falha ao limpar cache do Windows Update") else (call :LOG "OK: cache do Windows Update limpo")
net start wuauserv >nul 2>&1
net start bits >nul 2>&1
rd /s /q "C:\$Recycle.Bin" >nul 2>&1
if errorlevel 1 (call :LOG "AVISO: falha ao esvaziar a Lixeira") else (call :LOG "OK: Lixeira esvaziada")
del /q /f "C:\Windows\Prefetch\*" >nul 2>&1
if errorlevel 1 (call :LOG "AVISO: falha ao limpar Prefetch") else (call :LOG "OK: Prefetch limpo")
echo Concluido!
call :LOG "LIMPEZA concluida"
pause
exit /b

:: ==========================================================================
:VISUAL
echo.
echo [Visual] Ajustando efeitos visuais para melhor performance...
call :LOG "Iniciando VISUAL"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "VisualFXSetting" /t REG_DWORD /d 2 /f >nul 2>&1 || call :LOG "AVISO: falha ao ajustar VisualFXSetting"
reg add "HKCU\Control Panel\Desktop" /v "UserPreferencesMask" /t REG_BINARY /d 9012038010000000 /f >nul 2>&1 || call :LOG "AVISO: falha ao ajustar UserPreferencesMask"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAnimations" /t REG_DWORD /d 0 /f >nul 2>&1 || call :LOG "AVISO: falha ao ajustar TaskbarAnimations"
reg add "HKCU\Software\Microsoft\Windows\DWM" /v "EnableAeroPeek" /t REG_DWORD /d 0 /f >nul 2>&1 || call :LOG "AVISO: falha ao ajustar EnableAeroPeek"
echo Concluido! (efeito completo apos reiniciar o Explorer/PC)
call :LOG "VISUAL concluido"
pause
exit /b

:: ==========================================================================
:ENERGIA
echo.
echo [Energia] Ativando plano de Alto Desempenho...
call :LOG "Iniciando ENERGIA"
powercfg -duplicatescheme SCHEME_MIN >nul 2>&1 || call :LOG "AVISO: falha ao duplicar esquema de energia"
powercfg -setactive SCHEME_MIN >nul 2>&1 || call :LOG "AVISO: falha ao ativar Alto Desempenho"
echo Concluido!
call :LOG "ENERGIA concluida"
pause
exit /b

:: ==========================================================================
:DICAS
echo.
echo [Dicas] Desativando sugestoes, anuncios e dicas do sistema...
call :LOG "Iniciando DICAS"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338388Enabled" /t REG_DWORD /d 0 /f >nul 2>&1 || call :LOG "AVISO: chave 338388 nao encontrada"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338389Enabled" /t REG_DWORD /d 0 /f >nul 2>&1 || call :LOG "AVISO: chave 338389 nao encontrada"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SoftLandingEnabled" /t REG_DWORD /d 0 /f >nul 2>&1 || call :LOG "AVISO: chave SoftLanding nao encontrada"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SystemPaneSuggestionsEnabled" /t REG_DWORD /d 0 /f >nul 2>&1 || call :LOG "AVISO: chave SystemPaneSuggestions nao encontrada"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "RotatingLockScreenOverlayEnabled" /t REG_DWORD /d 0 /f >nul 2>&1 || call :LOG "AVISO: chave RotatingLockScreen nao encontrada"
echo Concluido!
call :LOG "DICAS concluidas"
pause
exit /b

:: ==========================================================================
:TELEMETRIA
call :CHECK_RESTORE
if errorlevel 1 exit /b
echo.
echo [Privacidade] Reduzindo telemetria e coleta de dados...
call :LOG "Iniciando TELEMETRIA"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f >nul 2>&1 || call :LOG "AVISO: falha ao ajustar AllowTelemetry"
sc config DiagTrack start= disabled >nul 2>&1 || call :LOG "AVISO: servico DiagTrack nao encontrado"
net stop DiagTrack >nul 2>&1
sc config dmwappushservice start= disabled >nul 2>&1 || call :LOG "AVISO: servico dmwappushservice nao encontrado"
echo Concluido! (isso NAO remove atualizacoes, so reduz coleta de dados)
call :LOG "TELEMETRIA concluida"
pause
exit /b

:: ==========================================================================
:SERVICOS
echo.
echo [Servicos] Ajustando servicos pouco usados para "sob demanda"...
call :LOG "Iniciando SERVICOS"
sc config Fax start= disabled >nul 2>&1 || call :LOG "AVISO: servico Fax nao encontrado"
sc config MapsBroker start= demand >nul 2>&1 || call :LOG "AVISO: servico MapsBroker nao encontrado"
sc config WSearch start= demand >nul 2>&1 || call :LOG "AVISO: servico WSearch nao encontrado"
sc config PrintNotify start= demand >nul 2>&1 || call :LOG "AVISO: servico PrintNotify nao encontrado"
sc config RemoteRegistry start= disabled >nul 2>&1 || call :LOG "AVISO: servico RemoteRegistry nao encontrado"
echo Concluido!
call :LOG "SERVICOS concluidos"
pause
exit /b

:: ==========================================================================
:INICIALIZACAO
echo.
echo [Inicializacao] Abrindo Gerenciador de Tarefas na aba de
echo programas de inicializacao. Desative ali o que voce nao
echo precisa que abra sozinho (Spotify, Steam, Discord, etc).
call :LOG "Gerenciador de Tarefas aberto (opcao INICIALIZACAO)"
echo.
start taskmgr
pause
exit /b

:: ==========================================================================
:DISCO
echo.
echo [Disco] Detectando tipo de disco (SSD ou HD)...
call :LOG "Iniciando DISCO"
set "TIPO="
for /f "tokens=2 delims==" %%a in ('wmic diskdrive get MediaType /value ^| find "MediaType"') do set "TIPO=%%a"
echo Tipo detectado: %TIPO%
call :LOG "Tipo de disco detectado: %TIPO%"
echo Otimizando disco C: (TRIM para SSD ou desfragmentacao para HD)...
defrag C: /O
if errorlevel 1 (call :LOG "AVISO: defrag/otimizacao retornou erro") else (call :LOG "OK: otimizacao de disco concluida")
echo Concluido!
pause
exit /b

:: ==========================================================================
:GAMEBAR
echo.
echo [GameBar] Desativando Xbox Game Bar e gravacao em segundo plano...
call :LOG "Iniciando GAMEBAR"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 0 /f >nul 2>&1 || call :LOG "AVISO: chave AppCaptureEnabled nao encontrada"
reg add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d 0 /f >nul 2>&1 || call :LOG "AVISO: chave GameDVR_Enabled nao encontrada"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /t REG_DWORD /d 0 /f >nul 2>&1 || call :LOG "AVISO: chave AllowGameDVR nao encontrada"
echo Concluido!
call :LOG "GAMEBAR concluido"
pause
exit /b

:: ==========================================================================
:REDE
echo.
echo [Rede] Limpando cache DNS e renovando IP...
call :LOG "Iniciando REDE"
ipconfig /flushdns >nul 2>&1 || call :LOG "AVISO: falha ao limpar cache DNS"
ipconfig /release >nul 2>&1
ipconfig /renew >nul 2>&1
netsh winsock reset >nul 2>&1 || call :LOG "AVISO: falha ao resetar winsock"
echo Concluido! (recomenda-se reiniciar o PC para efeito total)
call :LOG "REDE concluida"
pause
exit /b

:: ==========================================================================
:RESTAURACAO
call :RESTAURACAO_CORE
pause
exit /b

:RESTAURACAO_CORE
echo.
echo [Restauracao] Criando ponto de restauracao do sistema...
call :LOG "Iniciando RESTAURACAO"
powershell -Command "Checkpoint-Computer -Description 'Antes da otimizacao v5' -RestorePointType 'MODIFY_SETTINGS'" >nul 2>&1
if errorlevel 1 (
    call :LOG "AVISO: falha ao criar ponto de restauracao (pode estar desativado ou limitado por frequencia)"
) else (
    echo. > "%RESTOREFLAG%"
    call :LOG "OK: ponto de restauracao criado"
)
echo Concluido! Va em "Recuperacao" no Painel de Controle para
echo restaurar o sistema para este ponto, se precisar.
exit /b

:: ==========================================================================
:BLOATWARE
call :CHECK_RESTORE
if errorlevel 1 exit /b
echo.
echo [Bloatware] Este passo remove apps pre-instalados que a
echo maioria das pessoas nao usa (jogos, apps de dica, etc).
echo A Microsoft Store e apps essenciais NAO sao removidos.
echo Isso NAO afeta arquivos pessoais, apenas apps da Loja.
echo.
set /p conf="Deseja continuar? (S/N): "
if /i not "%conf%"=="S" (
    call :LOG "BLOATWARE cancelado pelo usuario"
    echo Operacao cancelada.
    pause
    exit /b
)
echo Removendo bloatware, aguarde...
call :LOG "Iniciando BLOATWARE"
for %%P in (
    3DBuilder MixedReality BingWeather BingNews GetHelp Getstarted
    Messaging SkypeApp YourPhone ZuneMusic ZuneVideo CandyCrush
    Disney Twitter FeedbackHub MicrosoftSolitaireCollection
    OneConnect People WindowsMaps Todos MicrosoftOfficeHub
) do (
    powershell -Command "Get-AppxPackage *%%P* | Remove-AppxPackage" >nul 2>&1
    if errorlevel 1 (call :LOG "AVISO: falha ou pacote %%P nao encontrado") else (call :LOG "OK: pacote %%P removido/ausente")
)
echo Concluido! Microsoft Store e apps de utilidade (Calculadora,
echo Fotos, Loja etc) foram mantidos de proposito.
call :LOG "BLOATWARE concluido"
pause
exit /b

:: ==========================================================================
:PAGEFILE
echo.
echo [Memoria Virtual] Configurando gerenciamento automatico
echo otimizado do arquivo de paginacao (pagefile) com base na
echo quantidade de RAM instalada...
call :LOG "Iniciando PAGEFILE"
wmic computersystem set AutomaticManagedPagefile=True >nul 2>&1
if errorlevel 1 (call :LOG "AVISO: falha ao ativar gerenciamento automatico de pagefile") else (call :LOG "OK: pagefile gerenciado automaticamente pelo Windows")
echo Concluido! O Windows agora gerencia a memoria virtual
echo de forma automatica e otimizada com base na sua RAM.
pause
exit /b

:: ==========================================================================
:HIBERNACAO
call :CHECK_RESTORE
if errorlevel 1 exit /b
echo.
echo [ATENCAO] Desativar a hibernacao libera espaco em disco
echo igual ao tamanho da sua RAM (ex: 8GB livres), mas desativa
echo tambem a Inicializacao Rapida (Fast Startup) do Windows.
echo Isso pode deixar o LIGAR do PC um pouco mais lento, mas
echo o DESLIGAR/USO no dia a dia nao muda.
echo.
set /p conf="Deseja desativar a hibernacao mesmo assim? (S/N): "
if /i not "%conf%"=="S" (
    call :LOG "HIBERNACAO cancelada pelo usuario"
    echo Operacao cancelada.
    pause
    exit /b
)
call :LOG "Iniciando HIBERNACAO"
powercfg -h off
if errorlevel 1 (call :LOG "AVISO: falha ao desativar hibernacao") else (call :LOG "OK: hibernacao desativada")
echo Concluido! Espaco em disco liberado.
pause
exit /b

:: ==========================================================================
:LIMPEZA_AVANCADA
call :CHECK_RESTORE
if errorlevel 1 exit /b
echo.
echo [Limpeza Avancada] Removendo arquivos de atualizacoes antigas,
echo expurgando a pasta WinSxS e removendo Windows.old se existir
echo (pode demorar alguns minutos)...
call :LOG "Iniciando LIMPEZA_AVANCADA"
Dism /Online /Cleanup-Image /StartComponentCleanup /ResetBase >nul 2>&1
if errorlevel 1 (call :LOG "AVISO: falha no DISM StartComponentCleanup") else (call :LOG "OK: WinSxS expurgado (ResetBase)")
echo Limpando cache do Windows Update via Cleanmgr (automatizado)...
cleanmgr /sagerun:65535 >nul 2>&1
if errorlevel 1 (call :LOG "AVISO: cleanmgr /sagerun falhou ou nao configurado") else (call :LOG "OK: cleanmgr executado")
if exist "C:\Windows.old" (
    echo Pasta Windows.old encontrada. Removendo...
    takeown /F "C:\Windows.old" /R /A >nul 2>&1
    icacls "C:\Windows.old" /grant administrators:F /T >nul 2>&1
    rd /s /q "C:\Windows.old" >nul 2>&1
    if errorlevel 1 (call :LOG "AVISO: falha ao remover Windows.old") else (call :LOG "OK: Windows.old removida")
) else (
    call :LOG "Windows.old nao encontrada, nada a remover"
)
echo Concluido! Espaco de atualizacoes antigas foi liberado.
call :LOG "LIMPEZA_AVANCADA concluida"
pause
exit /b

:: ==========================================================================
:BACKGROUND_APPS
echo.
echo [Apps em 2o plano] Desativando globalmente apps que rodam em
echo segundo plano sem voce estar usando (economiza CPU e RAM)...
call :LOG "Iniciando BACKGROUND_APPS"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v "GlobalUserDisabled" /t REG_DWORD /d 1 /f >nul 2>&1 || call :LOG "AVISO: falha ao ajustar GlobalUserDisabled"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsRunInBackground" /t REG_DWORD /d 2 /f >nul 2>&1 || call :LOG "AVISO: falha ao ajustar politica LetAppsRunInBackground"
echo Concluido!
call :LOG "BACKGROUND_APPS concluido"
pause
exit /b

:: ==========================================================================
:SYSMAIN
echo.
echo [SysMain/Superfetch] Detectando tipo de disco...
call :LOG "Iniciando SYSMAIN"
set "TIPODISK="
for /f "tokens=2 delims==" %%a in ('wmic diskdrive get MediaType /value ^| find "MediaType"') do set "TIPODISK=%%a"
echo %TIPODISK% | find "SSD" >nul
if %errorlevel%==0 (
    echo Disco SSD detectado. Desativando SysMain
    echo ^(nao traz beneficio real em SSD e evita escritas excessivas^)...
    sc config SysMain start= disabled >nul 2>&1 || call :LOG "AVISO: servico SysMain nao encontrado"
    net stop SysMain >nul 2>&1
    call :LOG "SysMain desativado (SSD detectado)"
) else (
    echo Disco HD tradicional detectado. Mantendo SysMain ATIVO
    echo ^(ele ajuda a acelerar abertura de programas em HDs^)...
    sc config SysMain start= auto >nul 2>&1 || call :LOG "AVISO: servico SysMain nao encontrado"
    net start SysMain >nul 2>&1
    call :LOG "SysMain configurado como automatico (HD detectado)"
)
echo Concluido!
pause
exit /b

:: ==========================================================================
:TAREFAS
call :CHECK_RESTORE
if errorlevel 1 exit /b
echo.
echo [Tarefas] Desativando tarefas agendadas de telemetria e CEIP...
call :LOG "Iniciando TAREFAS"
schtasks /Change /TN "Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /Disable >nul 2>&1 || call :LOG "AVISO: tarefa Consolidator nao encontrada"
schtasks /Change /TN "Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" /Disable >nul 2>&1 || call :LOG "AVISO: tarefa UsbCeip nao encontrada"
schtasks /Change /TN "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /Disable >nul 2>&1 || call :LOG "AVISO: tarefa Compatibility Appraiser nao encontrada"
schtasks /Change /TN "Microsoft\Windows\Application Experience\ProgramDataUpdater" /Disable >nul 2>&1 || call :LOG "AVISO: tarefa ProgramDataUpdater nao encontrada"
schtasks /Change /TN "Microsoft\Windows\Autochk\Proxy" /Disable >nul 2>&1 || call :LOG "AVISO: tarefa Autochk Proxy nao encontrada"
schtasks /Change /TN "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" /Disable >nul 2>&1 || call :LOG "AVISO: tarefa DiskDiagnostic nao encontrada"
echo Concluido!
call :LOG "TAREFAS concluidas"
pause
exit /b

:: ==========================================================================
:PRIORIDADE
call :CHECK_RESTORE
if errorlevel 1 exit /b
echo.
echo [Prioridade] Ajustando o Windows para priorizar o programa
echo que voce esta usando no momento (mais tempo de CPU/Quantum
echo para aplicativos em primeiro plano - jogos e softwares ativos)...
call :LOG "Iniciando PRIORIDADE"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d 38 /f >nul 2>&1 || call :LOG "AVISO: falha ao ajustar Win32PrioritySeparation"
echo Concluido! (requer reiniciar o PC para valer)
call :LOG "PRIORIDADE concluida"
pause
exit /b

:: ==========================================================================
:TURBO_NET
call :CHECK_RESTORE
if errorlevel 1 exit /b
echo.
echo [Internet] Otimizando TCP/IP para navegacao, jogos e
echo streaming (autotuning, RSS, NetDMA, Nagle e limitacao de
echo largura de banda para multimidia)...
call :LOG "Iniciando TURBO_NET"
netsh int tcp set global autotuninglevel=normal >nul 2>&1 || call :LOG "AVISO: falha ao ajustar autotuninglevel"
netsh int tcp set global rss=enabled >nul 2>&1 || call :LOG "AVISO: falha ao ativar RSS"
netsh int tcp set global ecncapability=enabled >nul 2>&1 || call :LOG "AVISO: falha ao ativar ECN"
netsh int tcp set global netdma=enabled >nul 2>&1 || call :LOG "AVISO: falha ao ativar NetDMA (pode nao ser suportado)"
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "NetworkThrottlingIndex" /t REG_DWORD /d 4294967295 /f >nul 2>&1 || call :LOG "AVISO: falha ao ajustar NetworkThrottlingIndex"
for /f "tokens=*" %%i in ('powershell -Command "(Get-NetAdapter | Where-Object {$_.Status -eq 'Up'}).Name" 2^>nul') do (
    powershell -Command "Disable-NetAdapterChecksumOffload -Name '%%i' -TcpIPv4 -ErrorAction SilentlyContinue" >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "TcpAckFrequency" /t REG_DWORD /d 1 /f >nul 2>&1
)
call :LOG "OK: parametros TCP/IP ajustados (Nagle/ACK aplicados via adaptadores ativos)"
echo Concluido! (requer reiniciar o PC para valer 100%%)
pause
exit /b

:: ==========================================================================
:DNS
echo.
echo [DNS] Servidores DNS mais rapidos podem deixar sites
echo carregando mais rapido (nao aumenta a velocidade da
echo internet contratada, so a resposta dos sites).
echo.
echo   1 - Cloudflare (1.1.1.1) - focado em privacidade/velocidade
echo   2 - Google (8.8.8.8)
echo   3 - Restaurar DNS automatico (padrao do provedor)
echo   0 - Cancelar
set /p dnsopc="Escolha uma opcao: "
call :LOG "Iniciando DNS (opcao %dnsopc%)"
if "%dnsopc%"=="1" (
    powershell -Command "Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | Set-DnsClientServerAddress -ServerAddresses ('1.1.1.1','1.0.0.1')" >nul 2>&1
    if errorlevel 1 (call :LOG "AVISO: falha ao aplicar DNS Cloudflare") else (call :LOG "OK: DNS Cloudflare aplicado")
    echo Concluido! DNS Cloudflare aplicado.
) else if "%dnsopc%"=="2" (
    powershell -Command "Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | Set-DnsClientServerAddress -ServerAddresses ('8.8.8.8','8.8.4.4')" >nul 2>&1
    if errorlevel 1 (call :LOG "AVISO: falha ao aplicar DNS Google") else (call :LOG "OK: DNS Google aplicado")
    echo Concluido! DNS Google aplicado.
) else if "%dnsopc%"=="3" (
    powershell -Command "Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | Set-DnsClientServerAddress -ResetServerAddresses" >nul 2>&1
    if errorlevel 1 (call :LOG "AVISO: falha ao restaurar DNS automatico") else (call :LOG "OK: DNS automatico restaurado")
    echo Concluido! DNS automatico restaurado.
) else (
    call :LOG "DNS cancelado pelo usuario"
    echo Operacao cancelada.
)
pause
exit /b

:: ==========================================================================
:DELIVERY
echo.
echo [Delivery Optimization] Isso desativa o compartilhamento
echo peer-to-peer de atualizacoes do Windows (as vezes seu PC
echo usa internet/upload para mandar updates para outros PCs
echo na internet ou na sua rede). Desativar economiza banda.
call :LOG "Iniciando DELIVERY"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v "DODownloadMode" /t REG_DWORD /d 0 /f >nul 2>&1 || call :LOG "AVISO: falha ao ajustar DODownloadMode"
echo Concluido!
call :LOG "DELIVERY concluido"
pause
exit /b

:: ==========================================================================
:MENUS_RAPIDOS
echo.
echo [Menus] Reduzindo o atraso ao abrir menus e janelas...
call :LOG "Iniciando MENUS_RAPIDOS"
reg add "HKCU\Control Panel\Desktop" /v "MenuShowDelay" /t REG_SZ /d 0 /f >nul 2>&1 || call :LOG "AVISO: falha ao ajustar MenuShowDelay"
reg add "HKCU\Control Panel\Mouse" /v "MouseHoverTime" /t REG_SZ /d 0 /f >nul 2>&1 || call :LOG "AVISO: falha ao ajustar MouseHoverTime"
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /t REG_SZ /d 0 /f >nul 2>&1 || call :LOG "AVISO: falha ao ajustar MinAnimate"
echo Concluido! (efeito completo apos reiniciar a sessao/PC)
call :LOG "MENUS_RAPIDOS concluido"
pause
exit /b

:: ==========================================================================
:LASTACCESS
echo.
echo [Disco] Desativando registro de "ultimo acesso" em arquivos
echo (reduz escritas desnecessarias no disco e processamento,
echo util em HDs e tambem ajuda a vida util de SSDs)...
call :LOG "Iniciando LASTACCESS"
fsutil behavior set disablelastaccess 1 >nul 2>&1 || call :LOG "AVISO: falha ao ajustar disablelastaccess"
echo Concluido!
call :LOG "LASTACCESS concluido"
pause
exit /b

:: ==========================================================================
:LIMPAR_LOGS
echo.
echo [Logs] Limpando logs antigos do Visualizador de Eventos...
call :LOG "Iniciando LIMPAR_LOGS"
for /F "tokens=*" %%G in ('wevtutil el') do (
    wevtutil cl "%%G" >nul 2>&1
    if errorlevel 1 call :LOG "AVISO: falha ao limpar log %%G"
)
echo Concluido!
call :LOG "LIMPAR_LOGS concluido"
pause
exit /b

:: ==========================================================================
:SFC_DISM
call :CHECK_RESTORE
if errorlevel 1 exit /b
echo.
echo [ATENCAO] Este processo verifica e repara arquivos do
echo sistema corrompidos. Pode demorar de 10 a 30 minutos.
echo NAO desligue o PC durante o processo.
echo.
set /p conf="Deseja continuar? (S/N): "
if /i not "%conf%"=="S" (
    call :LOG "SFC_DISM cancelado pelo usuario"
    echo Operacao cancelada.
    pause
    exit /b
)
call :LOG "Iniciando SFC_DISM"
echo.
echo Etapa 1/2: Reparando a imagem do Windows (DISM)...
Dism /Online /Cleanup-Image /RestoreHealth
if errorlevel 1 (call :LOG "AVISO: DISM RestoreHealth retornou erro") else (call :LOG "OK: DISM RestoreHealth concluido")
echo.
echo Etapa 2/2: Verificando arquivos do sistema (SFC)...
sfc /scannow
if errorlevel 1 (call :LOG "AVISO: SFC /scannow retornou erro ou encontrou problemas") else (call :LOG "OK: SFC /scannow concluido sem erros")
echo.
echo Concluido! Se algum erro foi corrigido, reinicie o PC.
pause
exit /b

:: ==========================================================================
:CHKDSK
call :CHECK_RESTORE
if errorlevel 1 exit /b
echo.
echo [ATENCAO] Isso agenda uma verificacao completa do disco C:
echo que roda ANTES do Windows abrir no proximo reinicio, e
echo pode demorar bastante dependendo do tamanho do disco.
echo Salve seus arquivos e feche programas antes de reiniciar.
echo.
set /p conf="Deseja agendar a verificacao? (S/N): "
if /i not "%conf%"=="S" (
    call :LOG "CHKDSK cancelado pelo usuario"
    echo Operacao cancelada.
    pause
    exit /b
)
call :LOG "Iniciando CHKDSK (agendamento)"
echo Y| chkdsk C: /f /r >nul 2>&1
if errorlevel 1 (call :LOG "AVISO: falha ao agendar CHKDSK") else (call :LOG "OK: CHKDSK agendado para o proximo boot")
echo Concluido! A verificacao vai rodar no proximo reinicio do PC.
pause
exit /b

:: ==========================================================================
:TUDO
echo.
echo ==============================================================
echo   Rodando otimizacoes seguras automaticamente...
echo   (bloatware, hibernacao, troca de DNS, SFC/DISM e CHKDSK
echo    ficam de fora - use as opcoes 12, 14, 22, 27, 28
echo    manualmente se quiser)
echo ==============================================================
call :LOG "=== Iniciando rotina TUDO (opcao 20) ==="
call :RESTAURACAO_CORE
call :LIMPEZA
call :VISUAL
call :ENERGIA
call :DICAS
call :TELEMETRIA
call :SERVICOS
call :GAMEBAR
call :REDE
call :PAGEFILE
call :LIMPEZA_AVANCADA
call :BACKGROUND_APPS
call :SYSMAIN
call :TAREFAS
call :PRIORIDADE
call :TURBO_NET
call :DELIVERY
call :MENUS_RAPIDOS
call :LASTACCESS
call :LIMPAR_LOGS
call :DISCO
echo.
echo ==============================================================
echo   TUDO CONCLUIDO! Reinicie o computador para aplicar
echo   todas as mudancas por completo.
echo ==============================================================
call :LOG "=== Rotina TUDO concluida ==="
pause
exit /b
