@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo AMR转AAC转换工具（兼容修复版）
echo ==============================
echo.

set "output_dir=转换后的AAC"
if not exist "%output_dir%" mkdir "%output_dir%"
set logfile="转换日志.txt"

echo 开始时间: %date% %time% > %logfile%
echo ====================================== >> %logfile%

for %%i in (*.awb) do (
    echo 正在处理: "%%i"
    
    REM 获取文件大小（字节）
    for %%s in ("%%i") do set /a "file_size=%%~zs"
    
    REM 获取文件时长（秒）
    set "duration_sec="
    for /f "tokens=1,2 delims=." %%t in ('ffprobe -v error -show_entries format^=duration -of default^=noprint_wrappers^=1:nokey^=1 "%%i" 2^>nul') do (
        set "duration_sec=%%t"
    )
    
    if not defined duration_sec (
        echo 警告：无法获取时长，使用默认值60秒
        set "duration_sec=60"
    ) else (
        echo 时长: !duration_sec! 秒
    )
    
    REM 计算参考比特率（kbps）
    set /a "bitrate_ref=(file_size * 8) / (duration_sec * 1000)"
    echo 参考比特率: !bitrate_ref! kbps
    
    REM 根据参考比特率选择AAC参数
    if !bitrate_ref! LSS 6 (
        set "aac_bitrate=8k"
        set "ar=8000"
    ) else if !bitrate_ref! LSS 8 (
        set "aac_bitrate=12k"
        set "ar=12000"
    ) else if !bitrate_ref! LSS 12 (
        set "aac_bitrate=16k"
        set "ar=16000"
    ) else (
        set "aac_bitrate=24k"
        set "ar=24000"
    )
    
    echo 使用AAC参数: 比特率=!aac_bitrate!, 采样率=!ar!
    
    REM 记录日志
    echo 文件: "%%i" >> %logfile%
    echo   大小: !file_size! 字节 >> %logfile%
    echo   时长: !duration_sec! 秒 >> %logfile%
    echo   参考比特率: !bitrate_ref! kbps >> %logfile%
    echo   AAC设置: 比特率=!aac_bitrate!, 采样率=!ar! >> %logfile%
    echo. >> %logfile%
    
    REM 主转换命令 - 简化版兼容所有FFmpeg
    ffmpeg -i "%%i" -c:a aac -b:a !aac_bitrate! -ar !ar! -ac 1 "%output_dir%\%%~ni.m4a"
    
    if !errorlevel! equ 0 (
        echo 成功转换: "%%~ni.m4a"
        echo   转换成功 >> %logfile%
    ) else (
        echo 错误: "%%i" 转换失败
        echo   转换失败 >> %logfile%
        
        REM 后备方案1 - 强制使用AMR解码器
        echo 尝试后备方案1...
        ffmpeg -c amr_nb -i "%%i" -c:a aac -b:a 16k -ar 16000 -ac 1 "%output_dir%\%%~ni_BACKUP1.m4a"
        
        if !errorlevel! equ 0 (
            echo 后备方案1成功
            echo   后备方案1成功 >> %logfile%
        ) else (
            REM 后备方案2 - 转换为WAV再转AAC
            echo 尝试后备方案2...
            ffmpeg -i "%%i" -f wav - | ffmpeg -i - -c:a aac -b:a 16k -ar 16000 -ac 1 "%output_dir%\%%~ni_BACKUP2.m4a"
            
            if !errorlevel! equ 0 (
                echo 后备方案2成功
                echo   后备方案2成功 >> %logfile%
            ) else (
                REM 最终后备方案 - 转换为MP3
                echo 尝试最终后备方案...
                ffmpeg -i "%%i" -b:a 16k -ar 8000 -ac 1 "%output_dir%\%%~ni_BACKUP3.mp3"
                
                if !errorlevel! equ 0 (
                    echo MP3转换成功
                    echo   MP3转换成功 >> %logfile%
                ) else (
                    echo 所有转换方案均失败
                    echo   所有方案均失败 >> %logfile%
                )
            )
        )
    )
    echo.
)

echo.
echo 所有文件处理完成！
echo 输出目录: %output_dir%
echo 日志文件: %logfile%
echo.
type %logfile%
pause