# JIS Bopomofo

**讓日版 JIS 鍵盤搭配微軟注音，保留注音位置，讓符號跟著鍵帽走。**

JIS 鍵盤與常見的美式鍵盤符號位置不同。在 Windows 使用微軟注音時，可能遇到鍵帽與輸出不一致，例如按下標示 `@` 的位置，卻得到另一個符號。

JIS Bopomofo 讓你繼續使用微軟注音，切換中文或英文時都能按日版鍵帽輸入符號，也能使用 `Ctrl`／`Ctrl+Shift` 輸入全形符號。空白鍵兩側的「無變換」「變換」也可以改成空白鍵。

> 目前支援 Windows 10 64 位元的部分版本，並需要對應的微軟注音版本與日版鍵盤設定。安裝前請查看[支援版本與安裝條件](docs/COMPATIBILITY.md)。Windows 11 尚未完成測試。

## 功能

- 保留微軟注音的組字、候選字與標準注音鍵位。
- 微軟注音切換中文或英文時，符號位置都與日版鍵帽一致。
- 支援全形符號快捷鍵，例如 `Ctrl+;` → `；`、`Ctrl+Shift+;` → `＋`、`Ctrl+@` → `＠`。
- 可單獨安裝「無變換／變換 → 空白鍵」。
- 備份原設定，提供還原腳本。
- 不需要額外執行常駐熱鍵程式。

## 安裝

安裝前請先確認[系統相容性](docs/COMPATIBILITY.md)。

1. 從本專案的 Releases 下載安裝包，解壓縮到新資料夾。
2. 右鍵點選 `Install.cmd`，選擇「以系統管理員身分執行」。
3. 顯示 `Completed` 後重新啟動 Windows。

完整安裝會一併將「無變換」與「變換」改成空白鍵。若只需要這項功能，執行 `Install-Spaces.cmd` 即可。

安裝後可在記事本測試注音、中英切換與符號。詳細測試清單在安裝包的 `Test-results.txt`。

### 還原與檢查

| 操作 | 執行檔 |
|---|---|
| 還原全部設定 | `Restore.cmd` |
| 只還原兩側空白鍵 | `Restore-Spaces.cmd` |
| 檢查安裝狀態 | `Check.cmd` |
| 產生診斷報告 | `Diagnose.cmd` |

還原時也需以管理員身分執行，完成後重新啟動。

## 自行編譯

下載原始碼並準備 Zig 0.14.1。在專案根目錄開啟 PowerShell，執行以下指令；將 Zig 路徑換成自己的安裝位置：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File src/router/Build-Router.ps1 -ZigExecutable C:\Tools\zig\zig.exe -OutputDirectory build/router
```

編譯完成的 DLL 位於 `build/router/JisCoreRouter64.dll`。要將它用於安裝，還需要測試並更新安裝程式的檔案檢查設定，步驟見[開發指南](docs/DEVELOPMENT.md)。

使用專案附帶的 DLL 製作安裝包，只需要 Python 3.9 以上版本：

```powershell
python tools/package.py
```

安裝包會產生在 `dist/` 資料夾。

## 支援系統

目前已測試 Windows 10 Enterprise LTSC 2021，以及搭載 Windows 10 Pro 22H2 的 Fujitsu LIFEBOOK U 系列日版筆電。

歡迎大家測試更多 Windows 版本與電腦型號，並透過 Issues 回報測試結果，幫助我們擴大支援範圍。若安裝程式顯示版本不支援，也歡迎回報你的系統版本。

- Windows 更新若改變微軟注音版本，符號修正可能失效。
- 如果程式檔案被 Windows 安全性設定封鎖或被刪除，微軟注音可能無法使用。
- 將「無變換」「變換」改成空白鍵後，這兩顆鍵原本的日文功能就會被取代，並且所有鍵盤都會套用這項設定。
- 完整安裝需要先設定好日版鍵盤，設定要求見[安裝條件](docs/COMPATIBILITY.md)。

## 疑難排解

安裝失敗時，先查看解壓資料夾內的 `Install-*.log.txt`，再執行 `Diagnose.cmd`。若安裝後注音無法切換，可使用 `Restore.cmd` 還原並重新啟動。其他問題見[安裝與疑難排解](docs/INSTALLATION.md)。

請保留 `%ProgramData%\Fujitsu-JIS-Core` 與 `%ProgramData%\Fujitsu-JIS-SpaceKeys` 資料夾，還原設定時會用到裡面的備份。

回報問題時，請在 Issues 說明系統版本、電腦型號、遇到的問題與操作步驟。若要附上診斷報告，請先移除電腦名稱、帳號等個人資訊；不用上傳 Windows 系統檔案。

## 開發與貢獻

```powershell
python tools/verify.py
powershell -NoProfile -ExecutionPolicy Bypass -File tests/Test-SpaceMap.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests/Test-CompatibilityGuards.ps1
python tools/package.py
```

以上指令用來檢查程式和製作安裝包，不會安裝到你的電腦。GitHub Actions 也會執行相同檢查；實際輸入與開機功能仍需另外測試。

- [開發、重建與測試](docs/DEVELOPMENT.md)
- [實作架構](docs/ARCHITECTURE.md)
- [驗證紀錄](docs/VALIDATION.md)
- [貢獻指南](CONTRIBUTING.md)
- [發行與 GitHub 推送](docs/PUBLISHING.md)
- [版本紀錄](CHANGELOG.md) · [安全問題回報](SECURITY.md)

## 授權

專案自有程式碼及文件採 **GPL-3.0-or-later**，見 [LICENSE](LICENSE) 與 [COPYRIGHT](COPYRIGHT)。安裝包附有對應專案原始碼及建置說明。

安裝包不包含微軟的系統 DLL。安裝時會使用電腦內的原版注音檔案建立修正副本，詳見[第三方說明](THIRD_PARTY_NOTICES.md)。本專案並非 Microsoft 或 Fujitsu 的官方產品。
