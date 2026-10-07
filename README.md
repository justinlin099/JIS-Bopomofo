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

## 快速開始

### 取得安裝包

在本專案的 **Releases** 頁面下載 `jis-bopomofo-<版本>-windows-x64.zip`。若尚無 Release，可從原始碼在專案根目錄執行以下指令，產生同樣的安裝包：

```powershell
python tools/package.py
```

需要 Python 3.9 或更新版本，不需要額外 Python 套件。產物位於 `dist/`。下載原始碼後，請先打包；`windows/Install.cmd` 不是完整安裝包入口。

### 安裝前確認

| 條件 | 完整修正要求 |
|---|---|
| 系統 | Windows 10 x64，build 19044 或 19045 |
| 輸入法 | 已安裝微軟注音 |
| 鍵盤配置 | `00000404` 的 `Layout File` 已為 `KBD106.DLL` |
| 注音核心 | 原版 `IMTCCORE.DLL` SHA256 必須與[相容性清單](docs/COMPATIBILITY.md)完全相符 |
| 權限 | 系統管理員；安裝完成後重新啟動 |

安裝器會檢查這些條件。不符合時請回報相容性需求；不要刪除版本或雜湊檢查強行安裝。

### 套用與還原

1. 解壓安裝包至可寫入的新資料夾。
2. 右鍵 `Install.cmd`，選擇「以系統管理員身分執行」。
3. 顯示 `Completed` 後儲存工作並重新啟動 Windows。
4. 在記事本驗證注音、Shift 中／英切換、Ctrl 符號與兩側空白鍵；完整清單見包內 `Test-results.txt`。

| 操作 | 執行檔 |
|---|---|
| 完整安裝，包含兩側空白鍵 | `Install.cmd` |
| 只安裝兩側空白鍵 | `Install-Spaces.cmd` |
| 還原兩項功能 | `Restore.cmd` |
| 只還原兩側空白鍵 | `Restore-Spaces.cmd` |
| 檢查安裝及執行狀態 | `Check.cmd` |
| 產生登錄與備份診斷 | `Diagnose.cmd` |

安裝、還原均需管理員權限，完成後重新啟動。檢查腳本不修改系統設定。

## 相容性與限制

已驗證 Windows 10 Enterprise LTSC 2021 VM（19044.6456）及一台 Fujitsu LIFEBOOK U 系列 JIS 筆電（Windows 10 Pro 22H2，19045.6466）。其他品牌若符合相同系統與掃描碼條件，可進行驗證；目前沒有所有 JIS 筆電皆相容的結論。

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
