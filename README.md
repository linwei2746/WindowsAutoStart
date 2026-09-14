# WindowsAutoStart

Windows 11 開機自動啟動腳本 / Windows 11 起動時自動実行スクリプト

開機（登入）後自動：① 依序啟動指定程式、② 用 Windows Media Player Legacy 在第二螢幕全螢幕、隨機、循環播放指定資料夾裡的影片。
Windows 起動（サインイン）後に自動で：①指定したプログラムを順番に起動、②Windows Media Player Legacy でセカンドモニターに指定フォルダの動画をランダム・ループ・全画面再生します。

---

## 功能 / 機能

- 依編號順序（`1.` `2.` `3.` ...）啟動 `StartupPrograms` 資料夾裡的所有捷徑，不需要把程式路徑寫進程式碼
  `StartupPrograms` フォルダ内のショートカットを番号順（`1.` `2.` `3.` ...）ですべて起動。プログラムのパスをコード内に書く必要はありません
- 用 Windows Media Player Legacy 播放指定資料夾裡的所有影片，每次啟動都重新隨機排序，並開啟「重複」與「隨機播放」讓它持續循環
  Windows Media Player Legacy で指定フォルダ内の全動画を再生。起動のたびにランダムな順番に並べ替え、「リピート」と「シャッフル」をオンにして再生し続けます
- 自動把播放器視窗移到第二螢幕（非主顯示器）並全螢幕播放
  プレーヤーのウィンドウをセカンドモニター（非プライマリディスプレイ）に移動し、全画面表示にします
- 每一步都寫入日誌檔，方便排查問題
  各ステップの実行結果をログファイルに記録するため、問題の切り分けが簡単です

## 檔案結構 / ファイル構成

```
WindowsAutoStart/
├─ AutoStart.ps1              # 主腳本 / メインスクリプト
├─ Install-AutoStart.ps1      # 安裝／解除安裝開機啟動 / 起動登録・解除スクリプト
├─ Run-AutoStart.cmd          # 受限環境用啟動器 / スクリプト禁止環境用のランチャー
├─ Install-AutoStart.cmd      # 受限環境用安裝器 / スクリプト禁止環境用のインストーラー
├─ StartupPrograms/           # 放程式捷徑的資料夾 / プログラムのショートカットを置くフォルダ
│   ├─ 1. Chrome.lnk
│   └─ 2. SMARTDent.lnk
├─ AutoStart.log              # 執行日誌（首次執行後產生）/ 実行ログ（初回実行後に生成）
└─ AutoStart.wpl              # 自動產生的播放清單（首次執行後產生）/ 自動生成されるプレイリスト（初回実行後に生成）
```

## 使用方法 / 使用方法

### 1. 新增要自動啟動的程式 / 自動起動したいプログラムを追加する

把程式的捷徑拖進 `StartupPrograms` 資料夾，並在檔名前加上編號控制啟動順序，例如 `1. Chrome`、`2. SMARTDent`。編號較大的（如 `10.`）會排在個位數編號之後；沒有編號的捷徑會排在最後才啟動。刪掉捷徑就不會再啟動該程式。捷徑本身設定的參數（例如 Chrome 後面接的網址）與「起始位置」都會生效。

プログラムのショートカットを `StartupPrograms` フォルダにドラッグし、ファイル名の先頭に番号を付けて起動順を指定します（例：`1. Chrome`、`2. SMARTDent`）。`10.` のような大きい番号は一桁の番号より後になります。番号のないショートカットは最後に起動されます。ショートカットを削除すればそのプログラムは起動されなくなります。ショートカット自体に設定された引数（Chrome の後ろの URL など）や「作業フォルダー」もそのまま有効です。

### 2. 設定要播放的影片資料夾 / 再生する動画フォルダを設定する

打開 `AutoStart.ps1`，在檔案開頭的設定區修改 `$VideoFolder` 為你的影片資料夾路徑。預設支援的副檔名為 `.mp4 .m4v .mkv .avi .wmv .mov`，可在 `$VideoExtensions` 裡增減。

`AutoStart.ps1` を開き、ファイル冒頭の設定エリアにある `$VideoFolder` を再生したい動画フォルダのパスに変更してください。既定でサポートする拡張子は `.mp4 .m4v .mkv .avi .wmv .mov` です。必要に応じて `$VideoExtensions` で追加・削除できます。

> 播放清單只讀取該資料夾這一層的影片，不包含子資料夾。第一次使用 Windows Media Player Legacy 前建議先手動開啟一次，完成初次設定精靈。
> プレイリストにはそのフォルダ直下の動画のみが含まれ、サブフォルダは対象外です。Windows Media Player Legacy を初めて使う場合は、事前に一度手動で起動して初期設定ウィザードを完了させておくことをお勧めします。

### 3. 手動測試 / 手動でテストする

```bash
powershell -ExecutionPolicy Bypass -File "AutoStart.ps1"
```

確認 Chrome、指定程式、影片播放都正常後，再設定開機自動啟動。
Chrome・指定したプログラム・動画再生がすべて正常に動作することを確認してから、次のステップで起動時自動実行を設定してください。

### 4. 設定開機自動啟動 / 起動時自動実行を設定する

```bash
powershell -ExecutionPolicy Bypass -File "Install-AutoStart.ps1"
```

這會在「啟動」資料夾建立一個捷徑，不需要系統管理員權限。
「スタートアップ」フォルダにショートカットが作成されます。管理者権限は不要です。

解除安裝 / 解除する：

```bash
powershell -ExecutionPolicy Bypass -File "Install-AutoStart.ps1" -Uninstall
```

## 電腦禁止腳本執行時 / スクリプト実行が禁止されている場合

若目標電腦被限制執行 PowerShell 腳本（`.ps1`），例如出現「running scripts is disabled on this system」的錯誤，通常是**執行原則（ExecutionPolicy）**被設為 `Restricted`，或被公司／IT 用**群組原則（GPO）**強制鎖定，此時連 `-ExecutionPolicy Bypass` 參數也會被忽略。

不過執行原則只會擋住**載入 `.ps1` 檔案**，而用 `-Command` 直接傳入的指令不受限制。本專案提供的 `.cmd` 啟動器就是利用這一點：它把腳本內容讀進來、用 `Invoke-Expression` 執行，因此**不需要修改任何系統設定、也不需要系統管理員權限**。

目標のパソコンで PowerShell スクリプト（`.ps1`）の実行が制限されている場合（例：「running scripts is disabled on this system」というエラーが出る）、たいていは**実行ポリシー（ExecutionPolicy）**が `Restricted` になっているか、会社・IT が**グループポリシー（GPO）**で強制的にロックしています。この場合は `-ExecutionPolicy Bypass` を付けても無視されます。

ただし実行ポリシーが制限するのは **`.ps1` ファイルの読み込み**だけで、`-Command` で直接渡したコマンドは制限されません。本プロジェクトの `.cmd` ランチャーはこれを利用し、スクリプトの中身を読み込んで `Invoke-Expression` で実行します。そのため**システム設定の変更も管理者権限も不要**です。

**執行方式 / 実行方法：**

- 手動測試（直接雙擊或執行）/ 手動テスト（ダブルクリックまたは実行）：`Run-AutoStart.cmd`
- 設定開機啟動 / 起動時自動実行を設定：`Install-AutoStart.cmd`
- 解除開機啟動 / 起動登録を解除：`Install-AutoStart.cmd -Uninstall`

`Install-AutoStart.cmd` 會在「啟動」資料夾建立指向 `Run-AutoStart.cmd` 的捷徑；開機時就透過這個 `.cmd` 執行腳本，完全繞過執行原則。
`Install-AutoStart.cmd` は「スタートアップ」フォルダに `Run-AutoStart.cmd` を指すショートカットを作成します。起動時はこの `.cmd` を通してスクリプトが実行され、実行ポリシーを完全に回避できます。

> **不需要跑腳本的最簡做法**：按 `Win + R`，輸入 `shell:startup` 開啟「啟動」資料夾，把 `Run-AutoStart.cmd` 的**捷徑**（在檔案上按右鍵→建立捷徑）拖進去即可，一行指令都不用執行。
> **スクリプトを一切実行しない最も簡単な方法**：`Win + R` で `shell:startup` を開き、`Run-AutoStart.cmd` の**ショートカット**（右クリック→ショートカットの作成）をそのフォルダに入れるだけです。コマンドを1つも実行する必要はありません。

> ⚠️ **例外**：若 IT 進一步啟用了 **AppLocker／WDAC** 或把 PowerShell 鎖進 **Constrained Language Mode**（受限語言模式），連 `Add-Type` 等 .NET 呼叫都會被禁止，本腳本無法運作，`.cmd` 也救不了——這種情況只能請 IT 協助（例如改用有權限的排程或加入白名單）。
> ⚠️ **例外**：IT がさらに **AppLocker / WDAC** を有効にしていたり、PowerShell を **制約言語モード（Constrained Language Mode）**に固定している場合は、`Add-Type` などの .NET 呼び出しも禁止され、本スクリプトは動作しません（`.cmd` でも回避できません）。この場合は IT 部門に相談してください。

## 設定項目一覽 / 設定項目一覧（`AutoStart.ps1`）

| 變數 / 変数 | 說明 / 説明 |
|---|---|
| `$StartupDelaySeconds` | 開機後等待幾秒才開始執行 / 起動後、実行を開始するまでの待機秒数 |
| `$ProgramsFolder` | 存放程式捷徑的資料夾 / プログラムのショートカットを置くフォルダ |
| `$DelayBetweenProgramsSeconds` | 每個程式啟動間隔秒數 / プログラムを1つ起動するごとの待機秒数 |
| `$VideoFolder` | 影片資料夾路徑 / 動画フォルダのパス |
| `$VideoExtensions` | 視為影片的副檔名清單 / 動画とみなす拡張子の一覧 |
| `$WaitBeforeVideoSeconds` | 程式都啟動完後、播放器啟動前的等待秒數 / プログラム起動後、プレーヤーを起動するまでの待機秒数 |
| `$LogFile` | 日誌檔路徑 / ログファイルのパス |

## 注意事項 / 注意事項

- **編碼**：`AutoStart.ps1` 與 `Install-AutoStart.ps1` 必須以 **UTF-8 with BOM** 編碼儲存，否則路徑中的中日文會亂碼。用記事本編輯後儲存時請選擇「帶有 BOM 的 UTF-8」。
  **エンコーディング**：`AutoStart.ps1` と `Install-AutoStart.ps1` は必ず **UTF-8（BOM付き）** で保存してください。そうしないとパス内の中国語・日本語が文字化けします。メモ帳で編集・保存する際は「BOM付き UTF-8」を選択してください。
- **雙螢幕**：腳本會把播放器移到「非主顯示器」的螢幕。若只偵測到一個螢幕，會直接在主螢幕全螢幕播放。
  **デュアルモニター**：スクリプトはプレーヤーを「プライマリ以外」のモニターに移動します。モニターが1台しか検出されない場合は、そのままメインモニターで全画面再生します。
- **日誌**：發生問題時請查看 `AutoStart.log`。
  **ログ**：問題が発生した場合は `AutoStart.log` を確認してください。
- **需要系統管理員權限的程式**：若某程式每次都跳出 UAC 確認框，「啟動」資料夾的方式無法繞過，需改用「工作排程器」並勾選「使用最高權限執行」。
  **管理者権限が必要なプログラム**：起動のたびに UAC の確認ダイアログが出るプログラムがある場合、「スタートアップ」フォルダの方式では回避できません。「タスクスケジューラ」を使い、「最上位の特権で実行する」を有効にする必要があります。

## 需求 / 動作要件

- Windows 11
- Windows Media Player Legacy（非新版 Media Player）
  Windows Media Player Legacy（新しい Media Player ではありません）
- Google Chrome（如使用 `StartupPrograms` 開啟網頁）
  Google Chrome（`StartupPrograms` でウェブページを開く場合）
