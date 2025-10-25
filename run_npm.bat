@echo off
REM Script to run npm commands using the portable Node.js
REM Usage: run_npm.bat <command> [arguments]
REM Example: run_npm.bat install
REM Example: run_npm.bat run dev

setlocal enabledelayedexpansion

REM Check if command is provided
if "%~1"=="" (
    echo [ERROR] No npm command specified
    echo Usage: run_npm.bat ^<command^> [arguments]
    echo Example: run_npm.bat install
    echo Example: run_npm.bat run dev
    pause
    exit /b 1
)

REM Set PATH to include portable Node.js
set "ROOT_DIR=%~dp0"
set "PORTABLE_NODE=%ROOT_DIR%portable_node"
set "FRONTEND_DIR=%ROOT_DIR%frontend"

if exist "%PORTABLE_NODE%\node.exe" (
    echo [INFO] Using portable Node.js
    set "PATH=%PORTABLE_NODE%;%PATH%"
) else (
    echo [INFO] Using system Node.js
)

REM Verify npm is available
npm -v >nul 2>&1
if errorlevel 1 (
    echo [ERROR] npm is not available
    echo [ERROR] Please install Node.js or set up portable Node.js
    pause
    exit /b 1
)

REM Change to frontend directory
cd /d "%FRONTEND_DIR%"

REM Run the npm command with all arguments
echo [INFO] Running: npm %*
echo.
call npm %*

endlocal
