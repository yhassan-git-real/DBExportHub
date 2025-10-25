@echo off
REM DBExportHub Backend Startup Script
REM This script handles environment setup and starts the FastAPI backend

setlocal enabledelayedexpansion

REM Set working directory
set "ROOT_DIR=%~dp0"
set "BACKEND_DIR=%ROOT_DIR%backend"
set "ENV_FILE=%BACKEND_DIR%\.env"
set "PORTABLE_VENV=%BACKEND_DIR%\portable_venv"
set "PORTABLE_PYTHON=%BACKEND_DIR%\portable_python"
set "PYTHON_EXE=%PORTABLE_VENV%\Scripts\python.exe"
set "ACTIVATE_SCRIPT=%PORTABLE_VENV%\Scripts\activate.bat"

REM Display startup information
echo.
echo ========================================
echo  Starting DBExportHub Backend
echo ========================================
echo.

REM Read port configuration from .env file
set "BACKEND_PORT=8000"
if exist "%ENV_FILE%" (
    for /f "tokens=1,* delims==" %%a in ('type "%ENV_FILE%" ^| findstr /i "^SERVER_PORT="') do set "BACKEND_PORT=%%b"
)

echo [INFO] Backend will be available at: http://localhost:%BACKEND_PORT%

REM Read CORS settings
set "CORS_ORIGINS=http://localhost:3001"
if exist "%ENV_FILE%" (
    for /f "tokens=1,* delims==" %%a in ('type "%ENV_FILE%" ^| findstr /i "^BACKEND_CORS_ORIGINS="') do set "CORS_ORIGINS=%%b"
)
echo [INFO] CORS origins configured: %CORS_ORIGINS%
echo.

REM Ensure required directories exist
if not exist "%BACKEND_DIR%\temp" mkdir "%BACKEND_DIR%\temp"
if not exist "%BACKEND_DIR%\logs" mkdir "%BACKEND_DIR%\logs"
if not exist "%BACKEND_DIR%\templates" mkdir "%BACKEND_DIR%\templates"

REM Check if portable Python environment exists
if not exist "%PYTHON_EXE%" (
    echo [WARN] Portable Python environment not found at: %PYTHON_EXE%
    echo [WARN] Please run the setup script first or ensure Python is installed
    echo.
    
    REM Check for system Python
    python --version >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] Python is not installed or not in PATH
        echo [ERROR] Please install Python 3.8+ or set up the portable environment
        pause
        exit /b 1
    )
    
    echo [INFO] Using system Python instead
    set "PYTHON_CMD=python"
) else (
    echo [INFO] Using portable Python environment: %PORTABLE_VENV%
    set "PYTHON_CMD=%PYTHON_EXE%"
)

REM Change to backend directory
cd /d "%BACKEND_DIR%"

REM Activate virtual environment if using portable Python
if exist "%ACTIVATE_SCRIPT%" (
    echo [INFO] Activating virtual environment...
    call "%ACTIVATE_SCRIPT%"
)

REM Start the FastAPI application
echo [INFO] Starting FastAPI server...
echo.
%PYTHON_CMD% -m uvicorn app.main:app --host 0.0.0.0 --port %BACKEND_PORT% --reload

REM If we get here, the server has stopped
echo.
echo [INFO] Backend server has stopped.
pause

endlocal
