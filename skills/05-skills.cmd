@echo off
setlocal enabledelayedexpansion
rem ============================================================
rem  Krok 05 - instalace skillu do Claude (beginner + project)
rem  Spustit v Prikazovem radku (cmd):
rem    curl -fsSL -o "%TEMP%\skills.cmd" https://raw.githubusercontent.com/Isolator79/claude-teams-onboarding/main/skills/05-skills.cmd && "%TEMP%\skills.cmd"
rem ============================================================

set "RAW=https://raw.githubusercontent.com/Isolator79/claude-teams-onboarding/main/skills"
set "DEST=%USERPROFILE%\.claude\skills"

echo.
echo === Krok 05: instalace skillu (beginner + project) ===
echo.

where curl >nul 2>&1
if errorlevel 1 (
    echo [CHYBA] Chybi curl. Na Windows 10/11 byva soucasti systemu.
    pause
    exit /b 1
)

set "FAIL=0"
for %%S in (beginner project) do (
    if not exist "%DEST%\%%S" mkdir "%DEST%\%%S"
    curl -fsSL -o "%DEST%\%%S\SKILL.md" "%RAW%/%%S/SKILL.md"
    if errorlevel 1 (
        echo [CHYBA] Skill %%S se nepodarilo stahnout.
        set "FAIL=1"
    ) else (
        echo [OK] Skill %%S nainstalovan -^> %DEST%\%%S\SKILL.md
    )
)

echo.
if "%FAIL%"=="0" (
    echo Hotovo. V Claude je vyvolas napsanim:
    echo   /beginner - systematizace za tebe ^(temata/slozky automaticky^)
    echo   /project  - vic pomocniku najednou na velky ukol + kontrola
    echo.
    echo Pokud mas Claude prave otevreny, zavri ho a spust znovu.
) else (
    echo [CHYBA] Cast skillu se nestahla - zkus prikaz spustit znovu.
)
echo.
pause
endlocal
