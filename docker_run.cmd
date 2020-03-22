@echo off
setlocal
set mypath=%~dp0
set /p SSH_KEY= <%USERPROFILE%\.ssh\id_rsa.pub
set tag_name=go_sshd
echo ---- Docker -------
echo Building: %tag_name%
echo Workdir : %mypath%
::echo ssh %SSH_KEY%
pause
cd %mypath%
docker build -t %tag_name% .
pause
docker run -d -p 2222:22 -e SSH_KEY="%SSH_KEY%" %tag_name%