@echo off
chcp 65001
echo Creating game.love as ZIP file...

REM Удаляем старый файл если есть
if exist game.love del game.love
if exist game.zip del game.zip

REM Создаем ZIP архив с помощью Windows
powershell -command "Compress-Archive -Path 'conf.lua', 'config.lua', 'main.lua', 'NetworkManager.lua', 'server_config.txt', 'src', 'lua-websockets' -DestinationPath 'game.zip' -CompressionLevel Optimal"

REM Переименовываем ZIP в LOVE
ren game.zip game.love

echo.
echo ===============================
echo game.love created successfully!
echo ===============================
dir game.love
echo.
pause