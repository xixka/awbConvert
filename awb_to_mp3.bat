@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo AMR转MP3智能转换工具
echo ======================
echo.

set "output_dir=转换后的MP3"
if not exist "%output_dir%" mkdir "%output_dir%"

for %%i in (*.awb) do (
    echo 正在分析: "%%i"
    
    REM 获取AMR文件的比特率信息
    for /f "tokens=2" %%b in ('ffprobe -i "%%i" 2^>^&1 ^| findstr "bitrate"') do (
        set "original_bitrate=%%b"
    )
    
    REM 根据原始比特率设置MP3比特率
    if "!original_bitrate!"=="4.75" (
        set "mp3_bitrate=8k"
    ) else if "!original_bitrate!"=="5.15" (
        set "mp3_bitrate=8k"
    ) else if "!original_bitrate!"=="5.90" (
        set "mp3_bitrate=8k"
    ) else if "!original_bitrate!"=="6.70" (
        set "mp3_bitrate=12k"
    ) else if "!original_bitrate!"=="7.40" (
        set "mp3_bitrate=12k"
    ) else if "!original_bitrate!"=="7.95" (
        set "mp3_bitrate=12k"
    ) else if "!original_bitrate!"=="10.2" (
        set "mp3_bitrate=16k"
    ) else if "!original_bitrate!"=="12.2" (
        set "mp3_bitrate=16k"
    ) else (
        set "mp3_bitrate=16k"
    )
    
    echo 原始比特率: !original_bitrate! kbps → 使用MP3比特率: !mp3_bitrate!
    
    ffmpeg -i "%%i" -c:a libmp3lame -b:a !mp3_bitrate! -ac 1 -ar 8000 -vn "%output_dir%\%%~ni.mp3"
    
    if !errorlevel! equ 0 (
        echo 成功转换: "%%~ni.mp3"
    ) else (
        echo 错误: "%%i" 转换失败
    )
    echo.
)

echo 所有文件处理完成！
pause