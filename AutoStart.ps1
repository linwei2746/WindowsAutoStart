# ============================================================
#  开机自动启动脚本
#  1. 按编号顺序打开 StartupPrograms 文件夹里的所有快捷方式
#  2. 用 Windows Media Player Legacy 在第二块屏幕全屏、随机、循环播放视频目录
#
#  注意：本文件必须以 "UTF-8 with BOM" 编码保存，否则路径里的中日文会乱码。
# ============================================================

# ------------------------- 配置区 -------------------------

# 开机后先等待几秒，让桌面、网络、显示器都就绪
$StartupDelaySeconds = 15

# 存放要自动启动的程序快捷方式的文件夹
# 快捷方式按名字开头的编号顺序逐个打开，如 "1. Chrome"、"2. SMARTDent"
$ProgramsFolder = Join-Path $PSScriptRoot 'StartupPrograms'

# 每打开一个程序后等待几秒再打开下一个
$DelayBetweenProgramsSeconds = 3

# 视频目录：目录下的视频会随机排序，循环播放
$VideoFolder = 'C:\Users\shizu\Videos\4K Video Downloader+'

# 算作视频的文件类型
$VideoExtensions = @('.mp4', '.m4v', '.mkv', '.avi', '.wmv', '.mov')

# 每次启动时生成的播放列表
$PlaylistPath = Join-Path $PSScriptRoot 'AutoStart.wpl'

# 程序都打开后等待几秒再启动播放器，避免其他程序的窗口抢走焦点导致全屏失败
$WaitBeforeVideoSeconds = 10

# 日志文件（出问题时看这里）
$LogFile = Join-Path $PSScriptRoot 'AutoStart.log'

# ----------------------------------------------------------

function Write-Log([string]$Message) {
    $line = '{0}  {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    Add-Content -Path $LogFile -Value $line -Encoding UTF8
}

function Find-FirstExisting([string[]]$Paths) {
    foreach ($p in $Paths) {
        if ($p -and (Test-Path -LiteralPath $p)) { return $p }
    }
    return $null
}

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class Win32
{
    [DllImport("user32.dll")] public static extern bool SetProcessDpiAwarenessContext(IntPtr value);
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern IntPtr FindWindow(string cls, string title);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int cmd);
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr after, int x, int y, int w, int h, uint flags);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);
}
'@

# 让坐标使用真实像素，避免两块屏幕缩放比例不同时窗口放错位置
try {
    if (-not [Win32]::SetProcessDpiAwarenessContext([IntPtr](-4))) { [void][Win32]::SetProcessDPIAware() }
} catch {
    [void][Win32]::SetProcessDPIAware()
}
Add-Type -AssemblyName System.Windows.Forms

Write-Log '========== 开始 =========='
Start-Sleep -Seconds $StartupDelaySeconds

# ---------- 1. StartupPrograms 文件夹 ----------
# 快捷方式自带的参数（如 Chrome 后面的网址）和“起始位置”都会生效
if (Test-Path -LiteralPath $ProgramsFolder) {
    $programs = Get-ChildItem -LiteralPath $ProgramsFolder -File |
                Where-Object { $_.Name -ne 'desktop.ini' } |
                Sort-Object @{ Expression = { if ($_.Name -match '^\s*(\d+)') { [int]$Matches[1] } else { [int]::MaxValue } } }, Name   # 按数字排，10. 排在 2. 后面；没编号的放最后
    foreach ($item in $programs) {
        try {
            Start-Process -FilePath $item.FullName
            Write-Log "已打开: $($item.Name)"
        } catch {
            Write-Log "打开失败: $($item.Name)  $_"
        }
        Start-Sleep -Seconds $DelayBetweenProgramsSeconds
    }
} else {
    Write-Log "找不到程序文件夹: $ProgramsFolder"
}

Start-Sleep -Seconds $WaitBeforeVideoSeconds

# ---------- 2. Windows Media Player Legacy，第二屏全屏、随机循环 ----------
try {
    $wmp = Find-FirstExisting @(
        "$env:ProgramFiles\Windows Media Player\wmplayer.exe",
        "${env:ProgramFiles(x86)}\Windows Media Player\wmplayer.exe"
    )
    if (-not $wmp)                                  { throw '找不到 wmplayer.exe，请确认已安装 Windows Media Player Legacy' }
    if (-not (Test-Path -LiteralPath $VideoFolder)) { throw "找不到视频目录: $VideoFolder" }

    # 打乱目录下的视频顺序，写成播放列表（.wpl 是 UTF-8 的 XML，日文文件名不会乱码）
    $videos = @(Get-ChildItem -LiteralPath $VideoFolder -File |
                Where-Object { $VideoExtensions -contains $_.Extension.ToLower() })
    if ($videos.Count -eq 0) { throw "视频目录里没有视频文件: $VideoFolder" }
    $videos = @($videos | Get-Random -Count $videos.Count)

    $items = ($videos | ForEach-Object {
        '      <media src="{0}"/>' -f [System.Security.SecurityElement]::Escape($_.FullName)
    }) -join "`r`n"
    $wpl = @"
<?wpl version="1.0"?>
<smil>
  <head>
    <title>AutoStart</title>
  </head>
  <body>
    <seq>
$items
    </seq>
  </body>
</smil>
"@
    [IO.File]::WriteAllText($PlaylistPath, $wpl, (New-Object System.Text.UTF8Encoding $false))
    Write-Log "播放列表已生成，共 $($videos.Count) 个视频，第一个: $($videos[0].Name)"

    # 播放器正在运行的话先关掉，否则下面的设置不生效，播放列表也会被塞进旧窗口
    Get-Process wmplayer -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 1

    # 打开播放器的“重复”和“无序播放”：列表播完后从头再来，每一轮都重新打乱
    $prefs = 'HKCU:\Software\Microsoft\MediaPlayer\Preferences'
    if (-not (Test-Path $prefs)) { New-Item -Path $prefs | Out-Null }
    Set-ItemProperty -Path $prefs -Name ModeLoop    -Value 1 -Type DWord
    Set-ItemProperty -Path $prefs -Name ModeShuffle -Value 1 -Type DWord

    Start-Process -FilePath $wmp -ArgumentList ('"{0}"' -f $PlaylistPath)
    Write-Log '播放器已启动，等待窗口出现'

    # 等待播放器主窗口出现（窗口类名 WMPlayerApp）
    $hwnd = [IntPtr]::Zero
    for ($i = 0; $i -lt 60; $i++) {
        $hwnd = [Win32]::FindWindow('WMPlayerApp', $null)
        if ($hwnd -ne [IntPtr]::Zero -and [Win32]::IsWindowVisible($hwnd)) { break }
        Start-Sleep -Milliseconds 500
    }
    if ($hwnd -eq [IntPtr]::Zero) { throw '30 秒内没有等到播放器窗口' }

    # 播放器启动后会恢复自己上次的窗口位置，稍等一下再移动，免得被它覆盖
    Start-Sleep -Seconds 2

    $screen = [System.Windows.Forms.Screen]::AllScreens | Where-Object { -not $_.Primary } | Select-Object -First 1
    if ($screen) {
        $area = $screen.WorkingArea
        [void][Win32]::ShowWindow($hwnd, 9)   # SW_RESTORE：先取消最大化，否则移动无效
        [void][Win32]::SetWindowPos($hwnd, [IntPtr]::Zero, $area.X + 50, $area.Y + 50, 960, 600, 0x0044)  # SWP_NOZORDER | SWP_SHOWWINDOW
        Write-Log "播放器已移到第二屏: $($screen.DeviceName) $($screen.Bounds)"
        Start-Sleep -Seconds 1
    } else {
        Write-Log '只检测到一块屏幕，将在主屏全屏播放'
    }

    # 把播放器切到前台后发送 Alt+Enter 进入全屏（全屏会铺满窗口所在的那块屏幕）
    $VK_MENU = 0x12; $VK_RETURN = 0x0D; $KEYUP = 0x2
    for ($i = 0; $i -lt 10 -and [Win32]::GetForegroundWindow() -ne $hwnd; $i++) {
        # 先按一下 Alt，绕过 Windows 对后台进程抢前台的限制
        [Win32]::keybd_event($VK_MENU, 0, 0, [UIntPtr]::Zero)
        [void][Win32]::SetForegroundWindow($hwnd)
        [Win32]::keybd_event($VK_MENU, 0, $KEYUP, [UIntPtr]::Zero)
        Start-Sleep -Milliseconds 500
    }
    if ([Win32]::GetForegroundWindow() -ne $hwnd) { throw '无法把播放器切到前台，未能进入全屏' }

    [Win32]::keybd_event($VK_MENU,   0, 0,      [UIntPtr]::Zero)
    [Win32]::keybd_event($VK_RETURN, 0, 0,      [UIntPtr]::Zero)
    [Win32]::keybd_event($VK_RETURN, 0, $KEYUP, [UIntPtr]::Zero)
    [Win32]::keybd_event($VK_MENU,   0, $KEYUP, [UIntPtr]::Zero)
    Write-Log '已发送全屏指令'
} catch {
    Write-Log "播放器处理失败: $_"
}

Write-Log '========== 结束 =========='
