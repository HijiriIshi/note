@echo off
cd /d %~dp0
if "%PROCESSOR_ARCHITECTURE%" EQU "x86"   goto :ARCH_X86
if "%PROCESSOR_ARCHITECTURE%" EQU "AMD64" goto :ARCH_X64

:ARCH_X86
echo x86環境
Start bin\caddy32.exe -root docs -host localhost
goto :FIN

:ARCH_X64
echo x64環境
Start bin\caddy.exe -root docs -host localhost
goto :FIN

:FIN
echo HTTPサーバー起動まで10秒ほどお待ちください。
timeout /t 10 /nobreak >nul
start http://localhost:2015/
