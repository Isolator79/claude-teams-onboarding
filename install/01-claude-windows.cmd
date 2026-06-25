@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion
title Instalace Claude Code (Windows)

REM ============================================================
REM   Claude Code - instalace na Windows
REM ------------------------------------------------------------
REM   Pro koho: pro tvuj Windows pocitac.
REM   Jak spustit: dvojklik na tento soubor.
REM   Funguje i na starsich / zakladnich edicich Windows
REM   (kdyz neni moderni Terminal ani winget, pouzije se
REM   nahradni zpusob pres PowerShell).
REM   Bezpecne poustet opakovane (idempotentni).
REM ============================================================

echo.
echo === Instalace Claude Code (Windows) ===
echo.

REM --- 1) Uz nainstalovano? (idempotence) ---------------------
where claude >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Claude Code uz je nainstalovany.
    echo     Aktualizaci si Claude resi sam.
    echo.
    echo Spustis ho prikazem:  claude
    echo.
    pause
    exit /b 0
)

set "DONE="

REM --- 2) Pokus c.1: winget (moderni Windows 10/11) -----------
where winget >nul 2>&1
if %errorlevel% equ 0 (
    echo Zkousim instalaci pres winget...
    winget install --id Anthropic.ClaudeCode --accept-source-agreements --accept-package-agreements -h
    where claude >nul 2>&1
    if !errorlevel! equ 0 set "DONE=1"
)

REM --- 3) Pokus c.2: oficialni installer pres PowerShell ------
REM Tohle funguje i tam, kde winget neni (starsi / zakladni Windows).
if not defined DONE (
    echo.
    echo Zkousim oficialni installer (PowerShell)...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://claude.ai/install.ps1 | iex"
    where claude >nul 2>&1
    if !errorlevel! equ 0 set "DONE=1"
)

REM --- 4) Vyhodnoceni -----------------------------------------
echo.
if defined DONE (
    echo [OK] Hotovo - Claude Code je nainstalovany.
) else (
    where claude >nul 2>&1
    if !errorlevel! equ 0 (
        echo [OK] Hotovo - Claude Code je nainstalovany.
    ) else (
        echo [POZOR] Instalaci se nepodarilo dokoncit automaticky.
        echo   - Zkontroluj pripojeni k internetu.
        echo   - Zkus skript spustit znovu.
        echo   - Pripadne nam posli, co se vypsalo vyse.
        echo.
        pause
        exit /b 1
    )
)

echo.
echo ================ CO DAL ================
echo 1) Zavri toto okno.
echo 2) Otevri NOVE okno: stiskni klavesu Windows, napis  cmd  a potvrd Enter.
echo    (Nove okno je potreba, aby pocitac nasel novy program.)
echo 3) Napis:  claude
echo 4) Pri prvnim spusteni se vypise webova adresa (URL).
echo    Zkopiruj ji do prohlizece, prihlas se a potvrd.
echo    Pak uz si muzes s Claude psat primo v okne.
echo =======================================
echo.
pause
exit /b 0
