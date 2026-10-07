# JIS Bopomofo

**讓日版 JIS 鍵盤搭配微軟注音，保留注音位置，讓符號跟著鍵帽走。**

JIS 鍵盤與常見的美式鍵盤符號位置不同。在 Windows 使用微軟注音時，可能遇到鍵帽與輸出不一致，例如按下標示 `@` 的位置，卻得到另一個符號。

JIS Bopomofo 提供 Windows 原生修正：繼續使用微軟注音，在注音內的中／英模式依照 JIS 配置輸入符號，並修正 `Ctrl`／`Ctrl+Shift` 全形符號。另提供將空白鍵兩側的「無變換」「變換」映射為空白鍵的功能。

> 目前完整安裝支援 **Windows 10 x64 build 19044／19045、指定微軟注音核心，以及已配置 KBD106 的環境**。沒有品牌限制；Windows 11 與其他核心版本尚待移植及實測。詳見[相容性](docs/COMPATIBILITY.md)。

## 功能

- 保留微軟注音的組字、候選字與標準注音鍵位。
- 在微軟注音內切換中／英模式時，使用 JIS 符號位置。
- 修正 JIS 實體鍵位的全形符號快捷鍵，例如 `Ctrl+;` → `；`、`Ctrl+Shift+;` → `＋`、`Ctrl+@` → `＠`。
- 可單獨安裝「無變換／變換 → 空白鍵」。
- 備份原設定，提供還原腳本。
- 使用原生 DLL 與 Windows 掃描碼映射，沒有常駐熱鍵程式、鍵盤 hook 或背景服務。

中／英模式指微軟注音內的切換；另外的 `ENG / US` 輸入配置不在修正範圍內。

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

編譯完成的 DLL 位於 `build/router/JisCoreRouter64.dll`。使用自行編譯的 DLL 安裝前，需完成驗證並更新雜湊設定，詳細步驟見[開發指南](docs/DEVELOPMENT.md)。

若要使用專案附帶的已驗證 DLL 製作安裝包，安裝 Python 3.9 以上版本後執行：

```powershell
python tools/package.py
```

安裝包會產生在 `dist/` 資料夾。

## 相容性與限制

已驗證 Windows 10 Enterprise LTSC 2021 VM（19044.6456）及一台 Fujitsu LIFEBOOK U 系列 JIS 筆電（Windows 10 Pro 22H2，19045.6466）。歡迎大家測試更多 Windows 版本與電腦型號，並透過 Issues 回報測試結果，幫助我們擴大支援範圍。

- 完整修正依賴特定微軟注音二進位內容。Windows 更新後可能回到原版注音，符號修正不再生效。
- 若 Router 本身遭安全政策封鎖或被移除，可能無法載入注音。詳細限制見[跨版本評估](docs/CROSS-VERSION-REVIEW.md)。
- 空白鍵映射對整台電腦生效，會取代兩顆鍵原本的日文功能。
- 安裝器保留既有 KBD106，不會自動將新的美式注音配置改成 JIS。

## 疑難排解

安裝失敗時，先查看解壓資料夾內的 `Install-*.log.txt`，再執行 `Diagnose.cmd`。若安裝後注音無法切換，可使用 `Restore.cmd` 還原並重啟；外部變更可能使自動還原停止，詳見[安裝與排除問題](docs/INSTALLATION.md)。

保留 `%ProgramData%\Fujitsu-JIS-Core` 與 `%ProgramData%\Fujitsu-JIS-SpaceKeys` 的備份。名稱沿用既有版本以相容還原記錄，並不限制鍵盤品牌。

回報問題請使用 Issues 的錯誤或相容性範本。診斷檔含電腦名稱、帳號及私人路徑，分享前請移除；請勿上傳 Windows 系統 DLL。

## 開發與貢獻

```powershell
python tools/verify.py
powershell -NoProfile -ExecutionPolicy Bypass -File tests/Test-SpaceMap.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests/Test-CompatibilityGuards.ps1
python tools/package.py
```

上述指令不執行安裝或修改系統設定。GitHub Actions 會執行檢查並提供封裝產物；這些檢查不取代 VM 的輸入、登入與重新開機測試。

- [開發、重建與測試](docs/DEVELOPMENT.md)
- [實作架構](docs/ARCHITECTURE.md)
- [驗證紀錄](docs/VALIDATION.md)
- [貢獻指南](CONTRIBUTING.md)
- [發行與 GitHub 推送](docs/PUBLISHING.md)
- [版本紀錄](CHANGELOG.md) · [安全問題回報](SECURITY.md)

## 授權

專案自有程式碼及文件採 **GPL-3.0-or-later**，見 [LICENSE](LICENSE) 與 [COPYRIGHT](COPYRIGHT)。安裝包附有對應專案原始碼及建置說明。

Microsoft Windows 與微軟注音元件維持原有權利，不隨本專案散布。修正副本由使用者本機的原版元件產生；詳見[第三方說明](THIRD_PARTY_NOTICES.md)。本專案與 Microsoft、Fujitsu 無官方關係。
