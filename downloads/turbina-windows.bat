@echo off
chcp 65001 >nul
title Otimizador de Windows - Menu v4
color 0A

:: ==========================================================
::  OTIMIZADOR DE WINDOWS 10/11 - VERSAO 4 (COMPLETA)
::  Funciona em qualquer PC (detecta SSD/HD automaticamente)
:: ==========================================================
:: Execute como Administrador!
:: ==========================================================

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

set LOGFILE=%~dp0log_otimizacao.txt
echo Log de otimizacao - %DATE% %TIME% > "%LOGFILE%"

:MENU
cls
echo ==========================================================
echo             OTIMIZADOR DE WINDOWS - MENU PRINCIPAL v4
echo ==========================================================
echo.
echo   1  - Limpeza completa (temp, lixeira, update cache, prefetch)
echo   2  - Ajustar efeitos visuais para performance
echo   3  - Ativar plano de energia Alto Desempenho
echo   4  - Desativar dicas/sugestoes/anuncios do Windows
echo   5  - Desativar telemetria e rastreamento (privacidade)
echo   6  - Gerenciar servicos desnecessarios
echo   7  - Ver e desativar programas de inicializacao
echo   8  - Otimizar disco (detecta SSD ou HD automaticamente)
echo   9  - Desativar Xbox Game Bar / gravacao em segundo plano
echo   10 - Limpar DNS e resetar rede
echo   11 - Criar ponto de restauracao do sistema
echo   ----------------------------------------------------------
echo   12 - Remover bloatware (apps inuteis da Microsoft)
echo   13 - Otimizar memoria virtual (pagefile)
echo   14 - Desativar hibernacao (libera espaco em disco)
echo   15 - Limpeza avancada (updates antigos, Windows antigo)
echo   16 - Desativar apps em segundo plano
echo   17 - Ajustar SysMain/Superfetch (automatico p/ SSD ou HD)
echo   18 - Desativar tarefas agendadas de telemetria
echo   19 - Dar prioridade ao programa em uso (ajuda CPU fraca)
echo   ----------------------------------------------------------
echo   21 - Turbo de internet (otimizar TCP/IP - jogos/streaming)
echo   22 - Trocar DNS para servidor mais rapido (Cloudflare/Google)
echo   23 - Desativar Delivery Optimization (economiza internet)
echo   24 - Deixar menus e janelas mais rapidos
echo   25 - Reduzir escritas desnecessarias no disco
echo   26 - Limpar logs antigos do Visualizador de Eventos
echo   27 - Verificar/reparar arquivos do sistema (SFC+DISM - demorado)
echo   28 - Agendar verificacao de disco no proximo boot (CHKDSK)
echo   ----------------------------------------------------------
echo   20 - RODAR TUDO SEGURO (recomendado - nao inclui 12,14,22,27,28)
echo   0  - Sair
echo.
echo ==========================================================
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
if "%opc%"=="0" exit /b
goto MENU

:: ==========================================================
:LIMPEZA
echo.
echo [Limpeza] Limpando arquivos temporarios, lixeira, cache...
del /q /f /s "%TEMP%\*" >nul 2>&1
del /q /f /s "C:\Windows\Temp\*" >nul 2>&1
net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1
rd /s /q "C:\Windows\SoftwareDistribution\Download" >nul 2>&1
net start wuauserv >nul 2>&1
net start bits >nul 2>&1
rd /s /q "C:\$Recycle.Bin" >nul 2>&1
del /q /f "C:\Windows\Prefetch\*" >nul 2>&1
echo Concluido!
echo [Limpeza] concluida >> "%LOGFILE%"
pause
exit /b

:: ==========================================================
:VISUAL
echo.
echo [Visual] Ajustando efeitos visuais para melhor performance...
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "VisualFXSetting" /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v "UserPreferencesMask" /t REG_BINARY /d 9012038010000000 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAnimations" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\DWM" /v "EnableAeroPeek" /t REG_DWORD /d 0 /f >nul 2>&1
echo Concluido! (efeito completo apos reiniciar o Explorer/PC)
pause
exit /b

:: ==========================================================
:ENERGIA
echo.
echo [Energia] Ativando plano de Alto Desempenho...
powercfg -duplicatescheme SCHEME_MIN >nul 2>&1
powercfg -setactive SCHEME_MIN >nul 2>&1
echo Concluido!
pause
exit /b

:: ==========================================================
:DICAS
echo.
echo [Dicas] Desativando sugestoes, anuncios e dicas do sistema...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338388Enabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338389Enabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SoftLandingEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SystemPaneSuggestionsEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "RotatingLockScreenOverlayEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
echo Concluido!
pause
exit /b

:: ==========================================================
:TELEMETRIA
echo.
echo [Privacidade] Reduzindo telemetria e coleta de dados...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f >nul 2>&1
sc config DiagTrack start= disabled >nul 2>&1
net stop DiagTrack >nul 2>&1
sc config dmwappushservice start= disabled >nul 2>&1
echo Concluido! (isso NAO remove atualizacoes, so reduz coleta de dados)
pause
exit /b

:: ==========================================================
:SERVICOS
echo.
echo [Servicos] Ajustando servicos pouco usados para "sob demanda"...
sc config Fax start= disabled >nul 2>&1
sc config MapsBroker start= demand >nul 2>&1
sc config WSearch start= demand >nul 2>&1
sc config PrintNotify start= demand >nul 2>&1
sc config RemoteRegistry start= disabled >nul 2>&1
echo Concluido!
pause
exit /b

:: ==========================================================
:INICIALIZACAO
echo.
echo [Inicializacao] Abrindo Gerenciador de Tarefas na aba de
echo programas de inicializacao. Desative ali o que voce nao
echo precisa que abra sozinho (Spotify, Steam, Discord, etc).
echo.
start taskmgr
pause
exit /b

:: ==========================================================
:DISCO
echo.
echo [Disco] Detectando tipo de disco (SSD ou HD)...
for /f "tokens=2 delims==" %%a in ('wmic diskdrive get MediaType /value ^| find "MediaType"') do set TIPO=%%a
echo Tipo detectado: %TIPO%
echo Otimizando disco C: (TRIM para SSD ou desfragmentacao para HD)...
defrag C: /O
echo Concluido!
pause
exit /b

:: ==========================================================
:GAMEBAR
echo.
echo [GameBar] Desativando Xbox Game Bar e gravacao em segundo plano...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /t REG_DWORD /d 0 /f >nul 2>&1
echo Concluido!
pause
exit /b

:: ==========================================================
:REDE
echo.
echo [Rede] Limpando cache DNS e renovando IP...
ipconfig /flushdns >nul 2>&1
ipconfig /release >nul 2>&1
ipconfig /renew >nul 2>&1
netsh winsock reset >nul 2>&1
echo Concluido! (recomenda-se reiniciar o PC para efeito total)
pause
exit /b

:: ==========================================================
:RESTAURACAO
echo.
echo [Restauracao] Criando ponto de restauracao do sistema...
powershell -Command "Checkpoint-Computer -Description 'Antes da otimizacao' -RestorePointType 'MODIFY_SETTINGS'" >nul 2>&1
echo Concluido! Va em "Recuperacao" no Painel de Controle para
echo restaurar o sistema para este ponto, se precisar.
pause
exit /b

:: ==========================================================
:BLOATWARE
echo.
echo [Bloatware] Este passo remove apps pre-instalados que a
echo maioria das pessoas nao usa (jogos, apps de dica, etc).
echo Isso NAO afeta arquivos pessoais, apenas apps da Loja.
echo.
set /p conf="Deseja continuar? (S/N): "
if /i not "%conf%"=="S" (
    echo Operacao cancelada.
    pause
    exit /b
)
echo Removendo bloatware, aguarde...
powershell -Command "Get-AppxPackage *3DBuilder* | Remove-AppxPackage" >nul 2>&1
powershell -Command "Get-AppxPackage *MixedReality* | Remove-AppxPackage" >nul 2>&1
powershell -Command "Get-AppxPackage *BingWeather* | Remove-AppxPackage" >nul 2>&1
powershell -Command "Get-AppxPackage *BingNews* | Remove-AppxPackage" >nul 2>&1
powershell -Command "Get-AppxPackage *GetHelp* | Remove-AppxPackage" >nul 2>&1
powershell -Command "Get-AppxPackage *Getstarted* | Remove-AppxPackage" >nul 2>&1
powershell -Command "Get-AppxPackage *Messaging* | Remove-AppxPackage" >nul 2>&1
powershell -Command "Get-AppxPackage *SkypeApp* | Remove-AppxPackage" >nul 2>&1
powershell -Command "Get-AppxPackage *YourPhone* | Remove-AppxPackage" >nul 2>&1
powershell -Command "Get-AppxPackage *ZuneMusic* | Remove-AppxPackage" >nul 2>&1
powershell -Command "Get-AppxPackage *ZuneVideo* | Remove-AppxPackage" >nul 2>&1
powershell -Command "Get-AppxPackage *CandyCrush* | Remove-AppxPackage" >nul 2>&1
powershell -Command "Get-AppxPackage *Disney* | Remove-AppxPackage" >nul 2>&1
powershell -Command "Get-AppxPackage *Spotify* | Remove-AppxPackage" >nul 2>&1
powershell -Command "Get-AppxPackage *Twitter* | Remove-AppxPackage" >nul 2>&1
powershell -Command "Get-AppxPackage *FeedbackHub* | Remove-AppxPackage" >nul 2>&1
echo Concluido! Apps de utilidade (Calculadora, Fotos, Loja etc)
echo foram mantidos de proposito.
pause
exit /b

:: ==========================================================
:PAGEFILE
echo.
echo [Memoria Virtual] Configurando gerenciamento automatico
echo otimizado do arquivo de paginacao (pagefile)...
wmic computersystem set AutomaticManagedPagefile=True >nul 2>&1
echo Concluido! O Windows agora gerencia a memoria virtual
echo de forma automatica e otimizada com base na sua RAM.
pause
exit /b

:: ==========================================================
:HIBERNACAO
echo.
echo [ATENCAO] Desativar a hibernacao libera espaco em disco
echo igual ao tamanho da sua RAM (ex: 8GB livres), mas desativa
echo tambem a Inicializacao Rapida (Fast Startup) do Windows.
echo Isso pode deixar o LIGAR do PC um pouco mais lento, mas
echo o DESLIGAR/USO no dia a dia nao muda.
echo.
set /p conf="Deseja desativar a hibernacao mesmo assim? (S/N): "
if /i not "%conf%"=="S" (
    echo Operacao cancelada.
    pause
    exit /b
)
powercfg -h off
echo Concluido! Espaco em disco liberado.
pause
exit /b

:: ==========================================================
:LIMPEZA_AVANCADA
echo.
echo [Limpeza Avancada] Removendo arquivos de atualizacoes antigas
echo e componentes nao utilizados do sistema (pode demorar alguns
echo minutos)...
Dism /Online /Cleanup-Image /StartComponentCleanup /ResetBase >nul 2>&1
echo Concluido! Espaco de atualizacoes antigas foi liberado.
pause
exit /b

:: ==========================================================
:BACKGROUND_APPS
echo.
echo [Apps em 2o plano] Desativando apps que rodam em segundo
echo plano sem voce estar usando (economiza CPU e RAM)...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v "GlobalUserDisabled" /t REG_DWORD /d 1 /f >nul 2>&1
echo Concluido!
pause
exit /b

:: ==========================================================
:SYSMAIN
echo.
echo [SysMain/Superfetch] Detectando tipo de disco...
for /f "tokens=2 delims==" %%a in ('wmic diskdrive get MediaType /value ^| find "MediaType"') do set TIPODISK=%%a
echo %TIPODISK% | find "SSD" >nul
if %errorlevel%==0 (
    echo Disco SSD detectado. Desativando SysMain
    echo ^(nao traz beneficio real em SSD^)...
    sc config SysMain start= disabled >nul 2>&1
    net stop SysMain >nul 2>&1
) else (
    echo Disco HD tradicional detectado. Mantendo SysMain ATIVO
    echo ^(ele ajuda a acelerar abertura de programas em HDs^)...
    sc config SysMain start= auto >nul 2>&1
    net start SysMain >nul 2>&1
)
echo Concluido!
pause
exit /b

:: ==========================================================
:TAREFAS
echo.
echo [Tarefas] Desativando tarefas agendadas de telemetria...
schtasks /Change /TN "Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Application Experience\ProgramDataUpdater" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Autochk\Proxy" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" /Disable >nul 2>&1
echo Concluido!
pause
exit /b

:: ==========================================================
:PRIORIDADE
echo.
echo [Prioridade] Ajustando o Windows para priorizar o programa
echo que voce esta usando no momento (melhora resposta em CPUs
echo com poucos nucleos, como a sua)...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d 38 /f >nul 2>&1
echo Concluido! (requer reiniciar o PC para valer)
pause
exit /b

:: ==========================================================
:TURBO_NET
echo.
echo [Internet] Otimizando TCP/IP para navegacao, jogos e
echo streaming (reduz latencia e remove limitacao de banda
echo para apps de rede/multimidia)...
netsh int tcp set global autotuninglevel=normal >nul 2>&1
netsh int tcp set global rss=enabled >nul 2>&1
netsh int tcp set global ecncapability=enabled >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "NetworkThrottlingIndex" /t REG_DWORD /d 4294967295 /f >nul 2>&1
echo Concluido! (requer reiniciar o PC para valer 100%%)
pause
exit /b

:: ==========================================================
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
if "%dnsopc%"=="1" (
    powershell -Command "Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | Set-DnsClientServerAddress -ServerAddresses ('1.1.1.1','1.0.0.1')" >nul 2>&1
    echo Concluido! DNS Cloudflare aplicado.
) else if "%dnsopc%"=="2" (
    powershell -Command "Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | Set-DnsClientServerAddress -ServerAddresses ('8.8.8.8','8.8.4.4')" >nul 2>&1
    echo Concluido! DNS Google aplicado.
) else if "%dnsopc%"=="3" (
    powershell -Command "Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | Set-DnsClientServerAddress -ResetServerAddresses" >nul 2>&1
    echo Concluido! DNS automatico restaurado.
) else (
    echo Operacao cancelada.
)
pause
exit /b

:: ==========================================================
:DELIVERY
echo.
echo [Delivery Optimization] Isso desativa o compartilhamento
echo peer-to-peer de atualizacoes do Windows (as vezes seu PC
echo usa internet/upload para mandar updates para outros PCs
echo na internet ou na sua rede). Desativar economiza banda.
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v "DODownloadMode" /t REG_DWORD /d 0 /f >nul 2>&1
echo Concluido!
pause
exit /b

:: ==========================================================
:MENUS_RAPIDOS
echo.
echo [Menus] Reduzindo o atraso ao abrir menus e janelas...
reg add "HKCU\Control Panel\Desktop" /v "MenuShowDelay" /t REG_SZ /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Mouse" /v "MouseHoverTime" /t REG_SZ /d 0 /f >nul 2>&1
echo Concluido! (efeito completo apos reiniciar a sessao/PC)
pause
exit /b

:: ==========================================================
:LASTACCESS
echo.
echo [Disco] Desativando registro de "ultimo acesso" em arquivos
echo (reduz escritas desnecessarias no disco, util em HDs e
echo tambem ajuda a vida util de SSDs)...
fsutil behavior set disablelastaccess 1 >nul 2>&1
echo Concluido!
pause
exit /b

:: ==========================================================
:LIMPAR_LOGS
echo.
echo [Logs] Limpando logs antigos do Visualizador de Eventos...
for /F "tokens=*" %%G in ('wevtutil el') do (wevtutil cl "%%G" >nul 2>&1)
echo Concluido!
pause
exit /b

:: ==========================================================
:SFC_DISM
echo.
echo [ATENCAO] Este processo verifica e repara arquivos do
echo sistema corrompidos. Pode demorar de 10 a 30 minutos.
echo NAO desligue o PC durante o processo.
echo.
set /p conf="Deseja continuar? (S/N): "
if /i not "%conf%"=="S" (
    echo Operacao cancelada.
    pause
    exit /b
)
echo.
echo Etapa 1/2: Reparando a imagem do Windows (DISM)...
Dism /Online /Cleanup-Image /RestoreHealth
echo.
echo Etapa 2/2: Verificando arquivos do sistema (SFC)...
sfc /scannow
echo.
echo Concluido! Se algum erro foi corrigido, reinicie o PC.
pause
exit /b

:: ==========================================================
:CHKDSK
echo.
echo [ATENCAO] Isso agenda uma verificacao completa do disco C:
echo que roda ANTES do Windows abrir no proximo reinicio, e
echo pode demorar bastante dependendo do tamanho do disco.
echo Salve seus arquivos e feche programas antes de reiniciar.
echo.
set /p conf="Deseja agendar a verificacao? (S/N): "
if /i not "%conf%"=="S" (
    echo Operacao cancelada.
    pause
    exit /b
)
echo Y| chkdsk C: /f /r >nul 2>&1
echo Concluido! A verificacao vai rodar no proximo reinicio do PC.
pause
exit /b

:: ==========================================================
:TUDO
echo.
echo ==========================================================
echo   Rodando otimizacoes seguras automaticamente...
echo   (bloatware, hibernacao, troca de DNS, SFC/DISM e CHKDSK
echo    ficam de fora - use as opcoes 12, 14, 22, 27, 28
echo    manualmente se quiser)
echo ==========================================================
call :RESTAURACAO
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
echo ==========================================================
echo   TUDO CONCLUIDO! Reinicie o computador para aplicar
echo   todas as mudancas por completo.
echo ==========================================================
pause
exit /b
