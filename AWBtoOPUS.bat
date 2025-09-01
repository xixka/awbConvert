@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo AMR转OPUS智能转换工具
echo ======================
echo.

set "output_dir=转换后的OPUS"
if not exist "%output_dir%" mkdir "%output_dir%"

for %%i in (*.awb) do (
    echo 正在处理: "%%i"
    
    REM 获取原始AMR比特率
    for /f "tokens=2" %%b in ('ffprobe -i "%%i" 2^>^&1 ^| findstr "bitrate"') do (
        set "original_bitrate=%%b"
    )
    
    REM 移除单位并保留数字
    set "original_bitrate=!original_bitrate: =!"
    set "original_bitrate=!original_bitrate:k=!"
    set "original_bitrate=!original_bitrate:b/s=!"
    
    REM 根据原始比特率智能选择OPUS比特率
    if defined original_bitrate (
        if "!original_bitrate!"=="4.75" set "opus_bitrate=6k"
        if "!original_bitrate!"=="5.15" set "opus_bitrate=7k"
        if "!original_bitrate!"=="5.90" set "opus_bitrate=8k"
        if "!original_bitrate!"=="6.70" set "opus_bitrate=9k"
        if "!original_bitrate!"=="7.40" set "opus_bitrate=10k"
        if "!original_bitrate!"=="7.95" set "opus_bitrate=11k"
        if "!original_bitrate!"=="10.2" set "opus_bitrate=12k"
        if "!original_bitrate!"=="12.2" set "opus_bitrate=14k"
    )
    
    REM 默认值（如果无法获取比特率）
    if not defined opus_bitrate set "opus_bitrate=10k"
    
    echo 原始比特率: !original_bitrate! kbps → 使用OPUS比特率: !opus_bitrate!
    
    REM 转换命令
    ffmpeg -i "%%i" -c:a libopus -b:a !opus_bitrate! -vbr on -compression_level 10 -ac 1 -ar 16000 -application voip "%output_dir%\%%~ni.opus"
    
    if !errorlevel! equ 0 (
        echo 成功转换: "%%~ni.opus"
    ) else (
        echo 错误: "%%i" 转换失败
    )
    
    REM 重置变量
    set "original_bitrate="
    set "opus_bitrate="
    echo.
)

echo 所有文件处理完成！
echo 输出目录: %output_dir%
echo.
pause