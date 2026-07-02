@echo off
chcp 65001 >nul 2>&1
setlocal enableextensions
title Instalace Claude Code + nastroje (Windows)

REM --- self-elevace na spravce (winget muze pri instalaci potrebovat) ---
REM  Kdyz uz jsme jako spravce, pokracujeme. Jinak se pres UAC znovu
REM  spustime s pravy spravce (jeden dialog na zacatku). Bez PowerShellu.
net session >nul 2>&1
if %errorlevel% neq 0 goto ELEVATE
goto ADMIN_OK

:ELEVATE
echo.
echo Ziskavam prava spravce - potvrd prosim dialog Rizeni uzivatelskych uctu (UAC)...
set "_VBS=%TEMP%\claude_elevate.vbs"
> "%_VBS%" echo Set U = CreateObject("Shell.Application")
>> "%_VBS%" echo U.ShellExecute "%~f0", "", "", "runas", 1
cscript //nologo "%_VBS%" >nul 2>&1
del "%_VBS%" >nul 2>&1
exit /b

:ADMIN_OK

REM ============================================================
REM   Claude Code + nastroje - instalace na Windows (cisty .cmd)
REM ------------------------------------------------------------
REM   Jak spustit: dvojklik na tento soubor.
REM   Co to dela: pres winget nainstaluje Claude Code (terminal),
REM   Claude Desktop (okenni app), VS Code, WinSCP a Windows
REM   Terminal, a napevno zapne RemoteControl + YOLO rezim.
REM   Bez PowerShellu. Bezpecne poustet opakovane (idempotentni) -
REM   co uz je nainstalovane, winget jen preskoci / aktualizuje.
REM ============================================================

echo.
echo === Instalace Claude Code + nastroje (Windows) ===
echo.

REM --- kontrola wingetu ---
where winget >nul 2>&1
if errorlevel 1 goto NOWINGET

REM spolecne parametry (odsouhlaseni licenci, tise)
set "WG=-e --accept-source-agreements --accept-package-agreements --silent"

echo [1/6] Claude Code (terminalovy program)...
winget install --id Anthropic.ClaudeCode %WG%
echo.
echo [2/6] Claude Desktop (okenni aplikace)...
winget install --id Anthropic.Claude %WG%
echo.
echo [3/6] Visual Studio Code (editor kodu)...
winget install --id Microsoft.VisualStudioCode %WG%
echo.
echo [4/6] WinSCP (nahravani souboru na server myssi)...
winget install --id WinSCP.WinSCP %WG%
echo.
echo [5/6] Windows Terminal (kam psat prikazy)...
winget install --id Microsoft.WindowsTerminal %WG%

echo.
echo [6/6] Nastaveni Claude (RemoteControl + YOLO napevno)...
set "CDIR=%USERPROFILE%\.claude"
if not exist "%CDIR%" mkdir "%CDIR%"
REM Zapiseme kanonicky settings.json:
REM   remoteControlAtStartup = ovladani bezici session z aplikace Claude
REM   permissions.defaultMode = bypassPermissions  (YOLO)
REM   skipDangerousModePermissionPrompt = neptat se pri startu YOLO
> "%CDIR%\settings.json" (
  echo {
  echo   "remoteControlAtStartup": true,
  echo   "permissions": {
  echo     "defaultMode": "bypassPermissions"
  echo   },
  echo   "skipDangerousModePermissionPrompt": true
  echo }
)
echo [OK] Nastaveni zapsano: %CDIR%\settings.json
echo      (RemoteControl + YOLO plati pro vsechny sessions)

echo.
echo ================ CO DAL ================
echo 1) Zavri toto okno a otevri NOVE (aby se nacetla cesta k programu).
echo    Stiskni klavesu Windows, napis  terminal  a potvrd Enter.
echo 2) Napis:  claude
echo 3) Pri prvnim spusteni se vypise webova adresa (URL).
echo    Zkopiruj ji do prohlizece, prihlas se a potvrd.
echo    Pak uz si muzes s Claude psat primo v okne.
echo.
echo    Navazat na predchozi konverzaci muzes prikazem:  claude --resume
echo =======================================
goto END

:NOWINGET
echo [POZOR] Nenasel jsem 'winget' (App Installer).
echo   winget je soucasti Windows 10 (verze 1809+) a Windows 11.
echo   Reseni: nainstaluj "App Installer" z Microsoft Store
echo   a spust tento soubor znovu.
echo.

:END
echo.
pause
endlocal
exit /b 0
