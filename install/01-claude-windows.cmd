@echo off
chcp 65001 >nul 2>&1
title Instalace Claude Code (Windows)

REM ============================================================
REM   Claude Code - instalace na Windows (spousteci soubor)
REM ------------------------------------------------------------
REM   Jak spustit: dvojklik na tento soubor.
REM   Co to dela: stahne z internetu VZDY AKTUALNI verzi
REM   instalacniho skriptu a spusti ji. Diky tomu mas pri
REM   kazdem spusteni nejnovejsi verzi (i kdyz vyjde update).
REM   Nezavisle na ostatnich skriptech, bezpecne i opakovane.
REM ============================================================

echo.
echo === Instalace Claude Code (Windows) ===
echo Stahuji aktualni verzi instalatoru z internetu...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/Isolator79/claude-teams-onboarding/main/install/01-claude-windows.ps1 | iex"

echo.
pause
exit /b 0
