@echo off
REM Script to remove white backgrounds from images using ffmpeg
REM Creates a backup folder and processes all PNG files in the current directory

echo Starting white background removal...
echo.

REM Create backup directory if it doesn't exist
if not exist "backup" mkdir backup

REM Process each PNG file in the current directory
for %%f in (*.png) do (
    echo Processing: %%f
    
    REM Backup original file
    copy "%%f" "backup\%%f" >nul
    
    REM Remove white background using colorkey filter
    REM Adjust similarity (0.3) and blend (0.2) values if needed
    ffmpeg -i "%%f" -vf "colorkey=white:0.3:0.2" -y "temp_%%f" 2>nul
    
    REM Replace original with processed file
    move /y "temp_%%f" "%%f" >nul
    
    echo Completed: %%f
    echo.
)

echo.
echo All images processed!
echo Original images backed up to 'backup' folder
pause
