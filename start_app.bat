@echo off
REM DBExportHub All-in-One Startup Script
REM This script starts both the frontend and backend applications in separate windows

setlocal enabledelayedexpansion

REM Set working directory
set "ROOT_DIR=%~dp0"
set "BACKEND_DIR=%ROOT_DIR%backend"
set "FRONTEND_DIR=%ROOT_DIR%frontend"
set "BACKEND_ENV=%BACKEND_DIR%\.env"
set "FRONTEND_ENV=%FRONTEND_DIR%\.env"

REM Display startup information
echo.
echo ========================================
echo  Starting DBExportHub Application
echo ========================================
echo.

REM Read backend port from .env file
set "BACKEND_PORT=8000"
if exist "%BACKEND_ENV%" (
    for /f "tokens=1,* delims==" %%a in ('type "%BACKEND_ENV%" ^| findstr /i "^SERVER_PORT="') do set "BACKEND_PORT=%%b"
)

REM Read frontend port from .env file
set "FRONTEND_PORT=3001"
if exist "%FRONTEND_ENV%" (
    for /f "tokens=1,* delims==" %%a in ('type "%FRONTEND_ENV%" ^| findstr /i "^VITE_PORT="') do set "FRONTEND_PORT=%%b"
)

echo [INFO] Backend will be available at: http://localhost:%BACKEND_PORT%
echo [INFO] Frontend will be available at: http://localhost:%FRONTEND_PORT%
echo.

REM Ensure required directories exist
if not exist "%BACKEND_DIR%\temp" mkdir "%BACKEND_DIR%\temp"
if not exist "%BACKEND_DIR%\logs" mkdir "%BACKEND_DIR%\logs"
if not exist "%BACKEND_DIR%\templates" mkdir "%BACKEND_DIR%\templates"

REM Start backend in a new window
echo [INFO] Starting backend in a new window...
start "DBExportHub Backend" cmd /k "%ROOT_DIR%start_backend.bat"

REM Wait for backend to initialize
echo [INFO] Waiting for backend to initialize...
timeout /t 3 /nobreak >nul

REM Start frontend in a new window
echo [INFO] Starting frontend in a new window...
start "DBExportHub Frontend" cmd /k "%ROOT_DIR%start_frontend.bat"

echo.
echo [SUCCESS] Both applications are starting!
echo [INFO] Close this window when you're done.
echo.
pause

endlocal
