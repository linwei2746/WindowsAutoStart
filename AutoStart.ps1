# ============================================================
#  起動時自動実行スクリプト
#  1. Chrome で指定したリンクを開く
#  2. StartupPrograms フォルダ内のショートカットを番号順に開く
#  3. Windows Media Player Legacy で動画フォルダをランダム・ループでセカンドモニターに全画面表示
#
#  注意：このファイルは必ず "UTF-8 with BOM" で保存すること。そうしないとパス内の日本語が文字化けする。
# ============================================================

# ------------------------- 設定エリア -------------------------

# このスクリプトがあるフォルダ。
# .ps1 を直接実行したときは $PSScriptRoot が使える。
# Run-AutoStart.cmd 経由（スクリプト実行が禁止された環境向けに中身を読み込んで実行）だと
# $PSScriptRoot は空になるため、その場合は現在の作業フォルダ（.cmd が cd 済み）を使う。
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }

# 起動後、デスクトップ・ネットワーク・モニターが準備できるまで数秒待つ
$StartupDelaySeconds = 15

# Chrome で自動的に開くリンク（1行に1つ。複数指定するとそれぞれ別タブで開く）
# 空の @() にすると Chrome は開かない。
$ChromeUrls = @(
    'https://apo-toolboxes.stransa.co.jp/calendar/',
    'https://www.youtube.com/watch?v=Efu7J9uQMxY'
)

# 自動起動したいプログラムのショートカットを置くフォルダ
# ショートカットは名前の先頭の番号順に開く（例："1. SMARTDent"）。
# Chrome は上の $ChromeUrls で開くため、このフォルダに Chrome のショートカットがあっても
# 二重に開かないよう自動でスキップする。
$ProgramsFolder = Join-Path $ScriptDir 'StartupPrograms'

# プログラムを1つ開いた後、次を開くまで待つ秒数
$DelayBetweenProgramsSeconds = 3

# 動画フォルダ：このフォルダ内の動画をランダムな順番でループ再生する
$VideoFolder = 'C:\Users\ONEUSER\Videos\ExhibitionVideo'

# 動画とみなすファイルの拡張子
$VideoExtensions = @('.mp4', '.m4v', '.mkv', '.avi', '.wmv', '.mov')

# 起動のたびに生成するプレイリスト
$PlaylistPath = Join-Path $ScriptDir 'AutoStart.wpl'

# すべてのプログラムを開いた後、プレーヤーを起動するまで待つ秒数（他のプログラムのウィンドウにフォーカスを奪われて全画面化に失敗するのを防ぐ）
$WaitBeforeVideoSeconds = 10

# ログファイル（問題が起きたときはここを確認）
$LogFile = Join-Path $ScriptDir 'AutoStart.log'

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

# 座標を実ピクセルで扱う。2つのモニターの拡大率が異なる場合にウィンドウが誤った位置に移動するのを防ぐ
try {
    if (-not [Win32]::SetProcessDpiAwarenessContext([IntPtr](-4))) { [void][Win32]::SetProcessDPIAware() }
} catch {
    [void][Win32]::SetProcessDPIAware()
}
Add-Type -AssemblyName System.Windows.Forms

Write-Log '========== 開始 =========='
Start-Sleep -Seconds $StartupDelaySeconds

# ---------- 1. Chrome で指定したリンクを開く ----------
if ($ChromeUrls.Count -gt 0) {
    try {
        $chrome = Find-FirstExisting @(
            "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
            "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
            "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
        )
        if (-not $chrome) { $chrome = 'chrome.exe' }   # 見つからなければ App Paths に任せる
        Start-Process -FilePath $chrome -ArgumentList $ChromeUrls
        Write-Log "Chrome を起動しました: $($ChromeUrls -join ' ')"
    } catch {
        Write-Log "Chrome の起動に失敗しました: $_"
    }
    Start-Sleep -Seconds $DelayBetweenProgramsSeconds
}

# ---------- 2. StartupPrograms フォルダ（Chrome 以外のプログラム）----------
# ショートカット自体に設定された引数と「作業フォルダー」はそのまま有効
if (Test-Path -LiteralPath $ProgramsFolder) {
    $programs = Get-ChildItem -LiteralPath $ProgramsFolder -File |
                Where-Object { $_.Name -ne 'desktop.ini' } |
                Where-Object { $_.Name -notmatch 'chrome' } |   # Chrome は上のステップで開くのでスキップ（二重起動防止）
                Sort-Object @{ Expression = { if ($_.Name -match '^\s*(\d+)') { [int]$Matches[1] } else { [int]::MaxValue } } }, Name   # 数値順にソート。10. は 2. の後ろに来る。番号のないものは最後
    foreach ($item in $programs) {
        try {
            Start-Process -FilePath $item.FullName
            Write-Log "起動しました: $($item.Name)"
        } catch {
            Write-Log "起動失敗: $($item.Name)  $_"
        }
        Start-Sleep -Seconds $DelayBetweenProgramsSeconds
    }
} else {
    Write-Log "プログラムフォルダが見つかりません: $ProgramsFolder"
}

Start-Sleep -Seconds $WaitBeforeVideoSeconds

# ---------- 3. Windows Media Player Legacy、セカンドモニターで全画面・ランダムループ再生 ----------
try {
    $wmp = Find-FirstExisting @(
        "$env:ProgramFiles\Windows Media Player\wmplayer.exe",
        "${env:ProgramFiles(x86)}\Windows Media Player\wmplayer.exe"
    )
    if (-not $wmp)                                  { throw 'wmplayer.exe が見つかりません。Windows Media Player Legacy がインストールされているか確認してください' }
    if (-not (Test-Path -LiteralPath $VideoFolder)) { throw "動画フォルダが見つかりません: $VideoFolder" }

    # フォルダ内の動画の順番をシャッフルしてプレイリストを作成（.wpl は UTF-8 の XML なので日本語のファイル名も文字化けしない）
    $videos = @(Get-ChildItem -LiteralPath $VideoFolder -File |
                Where-Object { $VideoExtensions -contains $_.Extension.ToLower() })
    if ($videos.Count -eq 0) { throw "動画フォルダに動画ファイルがありません: $VideoFolder" }
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
    Write-Log "プレイリストを生成しました。動画数: $($videos.Count)  最初の1本: $($videos[0].Name)"

    # プレーヤーが起動中なら一旦終了する。そうしないと以下の設定が反映されず、プレイリストも既存のウィンドウに読み込まれてしまう
    Get-Process wmplayer -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 1

    # プレーヤーの「リピート」と「シャッフル」をオンにする：リスト再生後は最初から、毎回シャッフルし直す
    $prefs = 'HKCU:\Software\Microsoft\MediaPlayer\Preferences'
    if (-not (Test-Path $prefs)) { New-Item -Path $prefs | Out-Null }
    Set-ItemProperty -Path $prefs -Name ModeLoop    -Value 1 -Type DWord
    Set-ItemProperty -Path $prefs -Name ModeShuffle -Value 1 -Type DWord

    Start-Process -FilePath $wmp -ArgumentList ('"{0}"' -f $PlaylistPath)
    Write-Log 'プレーヤーを起動しました。ウィンドウの表示を待機中'

    # プレーヤーのメインウィンドウが表示されるのを待つ（ウィンドウクラス名 WMPlayerApp）
    $hwnd = [IntPtr]::Zero
    for ($i = 0; $i -lt 60; $i++) {
        $hwnd = [Win32]::FindWindow('WMPlayerApp', $null)
        if ($hwnd -ne [IntPtr]::Zero -and [Win32]::IsWindowVisible($hwnd)) { break }
        Start-Sleep -Milliseconds 500
    }
    if ($hwnd -eq [IntPtr]::Zero) { throw '30秒待ってもプレーヤーのウィンドウが表示されませんでした' }

    # プレーヤーは起動後に前回のウィンドウ位置を復元するため、少し待ってから移動する（上書きされないように）
    Start-Sleep -Seconds 2

    $screen = [System.Windows.Forms.Screen]::AllScreens | Where-Object { -not $_.Primary } | Select-Object -First 1
    if ($screen) {
        $area = $screen.WorkingArea
        [void][Win32]::ShowWindow($hwnd, 9)   # SW_RESTORE：先に最大化を解除しないと移動できない
        [void][Win32]::SetWindowPos($hwnd, [IntPtr]::Zero, $area.X + 50, $area.Y + 50, 960, 600, 0x0044)  # SWP_NOZORDER | SWP_SHOWWINDOW
        Write-Log "プレーヤーをセカンドモニターに移動しました: $($screen.DeviceName) $($screen.Bounds)"
        Start-Sleep -Seconds 1
    } else {
        Write-Log 'モニターが1台しか検出されませんでした。メインモニターで全画面再生します'
    }

    # プレーヤーを前面に切り替えてから Alt+Enter を送信し全画面化する（全画面はウィンドウがあるモニターいっぱいに表示される）
    $VK_MENU = 0x12; $VK_RETURN = 0x0D; $KEYUP = 0x2
    for ($i = 0; $i -lt 10 -and [Win32]::GetForegroundWindow() -ne $hwnd; $i++) {
        # 先に Alt キーを押すことで、バックグラウンドプロセスが前面を奪うことへの Windows の制限を回避する
        [Win32]::keybd_event($VK_MENU, 0, 0, [UIntPtr]::Zero)
        [void][Win32]::SetForegroundWindow($hwnd)
        [Win32]::keybd_event($VK_MENU, 0, $KEYUP, [UIntPtr]::Zero)
        Start-Sleep -Milliseconds 500
    }
    if ([Win32]::GetForegroundWindow() -ne $hwnd) { throw 'プレーヤーを前面に切り替えられず、全画面化できませんでした' }

    [Win32]::keybd_event($VK_MENU,   0, 0,      [UIntPtr]::Zero)
    [Win32]::keybd_event($VK_RETURN, 0, 0,      [UIntPtr]::Zero)
    [Win32]::keybd_event($VK_RETURN, 0, $KEYUP, [UIntPtr]::Zero)
    [Win32]::keybd_event($VK_MENU,   0, $KEYUP, [UIntPtr]::Zero)
    Write-Log '全画面化コマンドを送信しました'
} catch {
    Write-Log "プレーヤー処理に失敗しました: $_"
}

Write-Log '========== 終了 =========='
