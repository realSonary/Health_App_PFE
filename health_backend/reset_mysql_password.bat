@echo off
REM Run this script as Administrator in Command Prompt
REM It resets the MySQL root password to: HealthAI2026!

echo === Step 1: Creating password reset file ===
echo ALTER USER 'root'@'localhost' IDENTIFIED BY 'HealthAI2026!'; > "%TEMP%\mysql_reset.sql"
echo FLUSH PRIVILEGES; >> "%TEMP%\mysql_reset.sql"

echo === Step 2: Stopping MySQL service ===
net stop MySQL80

echo === Step 3: Starting MySQL with --init-file to reset password ===
"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysqld.exe" --init-file="%TEMP%\mysql_reset.sql" --console --skip-networking &
timeout /t 5 /nobreak

echo === Step 4: Stopping init-mode MySQL ===
taskkill /F /IM mysqld.exe

echo === Step 5: Restarting MySQL service normally ===
net start MySQL80
timeout /t 3 /nobreak

echo === Step 6: Testing connection ===
"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -pHealthAI2026! -e "SELECT 'Password reset successful!' AS result;"

echo.
echo If the test above shows "Password reset successful!", update your .env:
echo DATABASE_URL=mysql+aiomysql://root:HealthAI2026!@localhost:3306/healthai_db
del "%TEMP%\mysql_reset.sql"
pause
