@echo off
cd /d %~dp0
if "%PROCESSOR_ARCHITECTURE%" EQU "x86"   goto :ARCH_X86
if "%PROCESSOR_ARCHITECTURE%" EQU "AMD64" goto :ARCH_X64

:ARCH_X86
echo x86��
Start bin\caddy32.exe -root docs -host localhost
goto :FIN

:ARCH_X64
echo x64��
Start bin\caddy.exe -root docs -host localhost
goto :FIN

:FIN
echo HTTP�T�[�o�[�N���܂�10�b�قǂ��҂����������B
timeout /t 10 /nobreak >nul
start http://localhost:2015/
