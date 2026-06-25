@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion
title Krok 02 - Pripojeni Claude k Teams

REM ============================================================
REM   Krok 02 - Pripojeni Claude k tvemu Teams (Windows)
REM ------------------------------------------------------------
REM   Co to udela:
REM    1) Pokud jeste nejsi prihlaseny, prihlasi te do Teams
REM       (zkopirujes kod do prohlizece a prihlasis se svym
REM        uctem tvuj-email@bidli.cz).
REM    2) Spusti "most": v Teams ti vznikne skupinovy chat
REM       "Claude" (jen ty v nem). Co tam napises, Claude
REM       precte a odpovi ti primo do chatu.
REM
REM   Predpoklad: nainstalovany Claude Code (krok 01) a Python 3.
REM   Bezpecne poustet opakovane (idempotentni).
REM ============================================================

cd /d "%~dp0"

REM --- Python 3 ---
set "PY="
where python >nul 2>&1 && set "PY=python"
if not defined PY where py >nul 2>&1 && set "PY=py"
if not defined PY (
    echo [CHYBA] Neni nainstalovany Python 3.
    echo   Nainstaluj ho ze stranky https://www.python.org/downloads/
    echo   Pri instalaci zaskrtni "Add Python to PATH". Pak spust tento skript znovu.
    echo.
    pause
    exit /b 1
)

REM --- Claude Code ---
where claude >nul 2>&1
if not !errorlevel! equ 0 (
    echo [POZOR] Nenasel jsem program 'claude'. Nejdriv projdi krok 01 (instalace Claude Code).
    echo         Prihlaseni do Teams pujde, ale odpovidat bude az s Claude.
)

REM --- 1) Prihlaseni, pokud chybi ---
if not exist "tokens.json" (
    echo Jeste nejsi prihlaseny do Teams. Spustim prihlaseni...
    %PY% claude_teams.py login
    if not !errorlevel! equ 0 (
        echo [CHYBA] Prihlaseni se nezdarilo.
        pause
        exit /b 1
    )
) else (
    echo Uz jsi prihlaseny do Teams (pouzivam ulozene prihlaseni).
)

REM --- 2) Spusteni mostu ---
echo.
echo Spoustim spojeni Teams ^<-^> Claude. Nech toto okno otevrene.
echo.
%PY% claude_teams.py run
pause
