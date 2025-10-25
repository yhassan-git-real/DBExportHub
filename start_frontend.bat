@echo off
REM DBExportHub Frontend Startup Script
REM This script handles dependency installation and starts the React development server

setlocal enabledelayedexpansion

REM Set working directory
set "ROOT_DIR=%~dp0"
set "FRONTEND_DIR=%ROOT_DIR%frontend"
set "NODE_MODULES=%FRONTEND_DIR%\node_modules"
set "ENV_FILE=%FRONTEND_DIR%\.env"
set "PORTABLE_NODE=%ROOT_DIR%portable_node"

REM Display startup information
echo.
echo ========================================
echo  Starting DBExportHub Frontend
echo ========================================
echo.

REM Read port configuration from .env file
set "FRONTEND_PORT=3001"
if exist "%ENV_FILE%" (
    for /f "tokens=1,* delims==" %%a in ('type "%ENV_FILE%" ^| findstr /i "^VITE_PORT="') do set "FRONTEND_PORT=%%b"
)

REM Read API URL from .env file
set "API_URL=http://localhost:8000"
if exist "%ENV_FILE%" (
    for /f "tokens=1,* delims==" %%a in ('type "%ENV_FILE%" ^| findstr /i "^VITE_API_URL="') do set "API_URL=%%b"
)

echo [INFO] Frontend will be available at: http://localhost:%FRONTEND_PORT%
echo [INFO] API URL configured as: %API_URL%
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

for /f "delims=" %%i in ('npm -v') do set "NPM_VERSION=%%i"
echo [SUCCESS] npm %NPM_VERSION% is ready
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

REM Start the frontend development server
echo [INFO] Starting frontend development server...
echo.
cd /d "%FRONTEND_DIR%"
call npm run dev

REM If we get here, the server has stopped
echo.
echo [INFO] Frontend server has stopped.
pause

endlocal
