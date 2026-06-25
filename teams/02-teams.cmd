@echo off
chcp 65001 >nul 2>&1
title Krok 02 - Pripojeni Claude k Teams

REM ============================================================
REM   Krok 02 - Pripojeni Claude k tvemu Teams (Windows)
REM ------------------------------------------------------------
REM   Jak spustit: dvojklik na tento soubor.
REM   Co to dela: stahne z internetu VZDY AKTUALNI verzi skriptu
REM   a spusti ji - prihlasi te do Teams a spusti most, kde si
REM   pises s Claude. Diky tomu mas pri kazdem spusteni nejnovejsi
REM   verzi. Nezavisle na ostatnich skriptech, bezpecne i opakovane.
REM ============================================================

echo.
echo === Krok 02: napojeni Claude na Teams ===
echo Stahuji aktualni verzi z internetu...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/Isolator79/claude-teams-onboarding/main/teams/02-teams.ps1 | iex"

echo.
pause
exit /b 0
