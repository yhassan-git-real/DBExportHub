@echo off
REM DBExportHub Frontend Build Script
REM This script builds the React frontend for production deployment

setlocal enabledelayedexpansion

REM Set working directory
set "ROOT_DIR=%~dp0"
set "FRONTEND_DIR=%ROOT_DIR%frontend"
set "NODE_MODULES=%FRONTEND_DIR%\node_modules"
set "DIST_DIR=%FRONTEND_DIR%\dist"
set "PORTABLE_NODE=%ROOT_DIR%portable_node"

REM Display startup information
echo.
echo ========================================
echo  Building DBExportHub Frontend
echo ========================================
echo.

REM Check for portable Node.js
if exist "%PORTABLE_NODE%\node.exe" (
    echo [INFO] Using portable Node.js installation
    set "PATH=%PORTABLE_NODE%;%PATH%"
) else (
    echo [INFO] Using system Node.js installation
)

REM Verify Node.js is working
node -v >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Node.js is not installed or not in PATH
    echo [ERROR] Please install Node.js v18+ or set up portable Node.js
    pause
    exit /b 1
)

for /f "delims=" %%i in ('node -v') do set "NODE_VERSION=%%i"
echo [SUCCESS] Node.js %NODE_VERSION% is ready
echo.

REM Check if dependencies are installed
if not exist "%NODE_MODULES%" (
    echo [WARN] Frontend dependencies not found. Installing now...
    cd /d "%FRONTEND_DIR%"
    echo [INFO] Running npm install...
    call npm install
    if errorlevel 1 (
        echo [ERROR] Failed to install dependencies
        pause
        exit /b 1
    )
    echo [SUCCESS] Dependencies installed successfully!
    echo.
) else (
    echo [INFO] Frontend dependencies already installed.
    echo.
)

REM Clean previous build
if exist "%DIST_DIR%" (
    echo [INFO] Cleaning previous build...
    rmdir /s /q "%DIST_DIR%"
    echo [SUCCESS] Previous build cleaned.
    echo.
)

REM Build the frontend
echo [INFO] Building frontend for production...
echo.
cd /d "%FRONTEND_DIR%"
call npm run build

if errorlevel 1 (
    echo.
    echo [ERROR] Build failed!
    pause
    exit /b 1
)

if exist "%DIST_DIR%" (
    echo.
    echo [SUCCESS] Frontend built successfully!
    echo [INFO] Production files are available in: %DIST_DIR%
) else (
    echo.
    echo [ERROR] Build completed but dist directory not found.
    pause
    exit /b 1
)

echo.
pause

endlocal
