@echo off
chcp 65001
echo Creating RPG Game.exe...

REM Объединяем love.exe + game.love в один файл
copy /b love.exe + game.love "RPG Game.exe"

echo.
echo ====================================
echo SUCCESS! RPG Game.exe created!
echo ====================================
echo File size: 
dir "RPG Game.exe" | find "RPG Game.exe"
echo.
echo You can now send "RPG Game.exe" to friends!
pause