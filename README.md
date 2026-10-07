# ⌨️ JIS Bopomofo

[繁體中文](#繁體中文) · [English](#english)

## 繁體中文

**拯救日規鍵盤！讓微軟注音的符號乖乖跟著鍵帽走，盲打注音不再猜謎 🌸**

買了手感極佳的日規鍵盤或日本水貨筆電，切回微軟注音打字卻發現符號位置完全大打架？明明照著鍵帽按 `@`，螢幕上偏偏冒出 `"` 🥲

JIS Bopomofo 就是為了解決這個痛點！讓你繼續用熟悉的微軟注音組字、選字，切換中文或英文模式時，符號也能跟著日版鍵帽走。用 `Ctrl`／`Ctrl+Shift` 打全形符號也沒問題。

更棒的是，空白鍵兩側平常用不到的「無変換」「変換」，也能順手改成超好按的空白鍵 ✨

> 💡 **安裝前小提醒：**目前支援 Windows 10 64 位元的部分版本，並需要對應的微軟注音版本與日規鍵盤設定。動手前請先看一下[相容性與安裝條件](docs/COMPATIBILITY.md)。Windows 11 尚未完成測試。

### ✨ 特色亮點

- 🧩 **熟悉的注音最對味：**保留微軟注音的組字、選字習慣與標準注音鍵位，盲打不用重新練。
- 🎯 **符號跟著鍵帽走：**微軟注音切換中文或英文時，都能按日版鍵帽輸入符號。
- ⚡ **全形符號快捷鍵照常用：**例如 `Ctrl+;` → `；`、`Ctrl+Shift+;` → `＋`、`Ctrl+@` → `＠`。
- ␣ **拯救短空白鍵：**空白鍵太短常按空？可以單獨把兩側的「無変換／変換」改成空白鍵。
- 🛡️ **有備份，也有還原：**修改前自動備份原本的設定，並附上還原腳本。
- 🍃 **不用常駐熱鍵工具：**直接修正輸入元件與按鍵設定，不需要額外執行背景程式。

### 🚀 安裝

安裝前記得先確認[系統相容性](docs/COMPATIBILITY.md)！

1. 前往本專案的 **Releases** 頁面下載安裝包，解壓縮到新資料夾。
2. 對著 `Install.cmd` 按右鍵，選擇「以系統管理員身分執行」。
3. 看到視窗顯示 `Completed` 後，重新啟動電腦 🎉

**📌 只想改空白鍵？**

完整安裝會把「無変換」「変換」一併改成空白鍵。如果只想改這兩顆鍵，以管理員身分執行 `Install-Spaces.cmd` 就可以，不會修改注音元件。

重開機後，可以開記事本測試注音、中英切換與符號。安裝包內附有 `Test-results.txt`，方便逐項核對。

### 🔄 還原與檢查

| 想做的事情 | 執行檔 | 備註 |
|---|---|---|
| 還原所有改動 | `Restore.cmd` | 還原安裝前的注音設定與按鍵映射，需重開機 |
| 只還原兩側空白鍵 | `Restore-Spaces.cmd` | 還原「無変換／変換」的按鍵設定，需重開機 |
| 檢查安裝狀態 | `Check.cmd` | 查看目前的設定與修正狀態 |
| 匯出診斷報告 | `Diagnose.cmd` | 產生排除問題需要的紀錄 |

還原腳本請以管理員身分執行。若遇到還原失敗，請保留備份和錯誤訊息，參考[疑難排解](docs/INSTALLATION.md)或至 Issues 回報。

### 🛠️ 自行編譯

先安裝 **Zig 0.14.1**，在專案根目錄開啟 PowerShell 並執行以下指令。請將 Zig 路徑換成你電腦上的實際位置：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File src/router/Build-Router.ps1 -ZigExecutable C:\Tools\zig\zig.exe -OutputDirectory build/router
```

編譯完成的 DLL 會出現在 `build/router/JisCoreRouter64.dll`。要用它製作安裝包，還需要測試並更新安裝程式的檔案檢查設定，詳細步驟見[開發指南](docs/DEVELOPMENT.md)。

如果只是想用專案附帶的 DLL 製作安裝包，準備 **Python 3.9+** 後執行：

```powershell
python tools/package.py
```

安裝包與原始碼 ZIP 會放在 `dist/` 資料夾。

### 💻 支援系統與注意事項

目前已在 Windows 10 Enterprise LTSC 2021 虛擬機，以及搭載 Windows 10 Pro 22H2 的日版 Fujitsu LIFEBOOK U 系列筆電上完成測試。

非常歡迎大家測試更多 Windows 版本與電腦型號！請到 **Issues** 分享設備型號與測試結果，一起擴大支援範圍 💖 若安裝程式顯示版本不支援，也歡迎回報你的系統版本。

- ⚠️ **Windows 更新：**更新若改變微軟注音版本，符號修正可能失效，需要為新版本提供修正。
- ⚠️ **程式檔案被封鎖或刪除：**如果 Windows 安全性設定或安全軟體阻擋相關檔案，微軟注音可能無法使用。此時可以先嘗試執行還原腳本。
- ⚠️ **兩側空白鍵：**改成空白鍵後，這兩顆鍵原本的日文功能會被取代，並且所有連接的鍵盤都會套用這項設定。
- ⚠️ **日規鍵盤設定：**完整安裝需要先設定好日版鍵盤，具體要求見[安裝條件](docs/COMPATIBILITY.md)。

各系統版本的檢查結果與更新風險見[跨版本評估](docs/CROSS-VERSION-REVIEW.md)。

### 🩺 遇到問題？

- **安裝失敗：**先查看解壓縮資料夾裡的 `Install-*.log.txt`，再執行 `Diagnose.cmd`。
- **注音無法使用：**以管理員身分執行 `Restore.cmd` 並重新啟動。若還原也失敗，請保留錯誤訊息並回報。
- **保留備份：**請不要刪除 `%ProgramData%\Fujitsu-JIS-Core` 與 `%ProgramData%\Fujitsu-JIS-SpaceKeys` 資料夾，還原時會用到裡面的備份。

回報問題時，請附上 Windows 版本、電腦或鍵盤型號、遇到的問題與操作步驟。若要附診斷報告，記得先移除電腦名稱、個人帳號等資訊，不需要上傳 Windows 系統檔案。

更多操作說明見[安裝與疑難排解](docs/INSTALLATION.md)。

### 🧪 開發與測試

在專案根目錄執行：

```powershell
python tools/verify.py
powershell -NoProfile -ExecutionPolicy Bypass -File tests/Test-SpaceMap.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests/Test-CompatibilityGuards.ps1
python tools/package.py
python tools/check_package.py
```

這些指令只會檢查程式、執行測試與製作安裝包，不會修改你的系統設定。GitHub Actions 也會執行相同檢查；實際輸入、登入與重新開機功能仍需另外測試。

- 📖 [開發與測試指南](docs/DEVELOPMENT.md)
- 🏗️ [實作架構](docs/ARCHITECTURE.md)
- 📝 [驗證紀錄](docs/VALIDATION.md)
- 🤝 [貢獻指南](CONTRIBUTING.md)
- 🚀 [發行與 GitHub 推送](docs/PUBLISHING.md)
- 📜 [版本紀錄](CHANGELOG.md) · [安全問題回報](SECURITY.md)

### ⚖️ 授權

本專案的原始碼與文件採 **GPL-3.0-or-later** 授權，詳見 [LICENSE](LICENSE) 與 [COPYRIGHT](COPYRIGHT)。安裝包附有對應的原始碼與編譯說明。

安裝包不包含微軟的系統 DLL。安裝時會使用電腦內的原版注音檔案建立修正副本，詳見[第三方說明](THIRD_PARTY_NOTICES.md)。本專案是開源社群作品，並非 Microsoft 或 Fujitsu 官方產品。

---

## English

**Give your Japanese JIS keyboard a break! Make Microsoft Bopomofo symbols follow your keycaps 🌸**

Love your Japanese keyboard or imported laptop, but find typing symbols with Microsoft Bopomofo frustrating? You press the key labeled `@`, only to see `"` on screen 🥲

JIS Bopomofo helps you keep the Zhuyin typing and candidate selection you're used to, while symbols follow your JIS keycaps in Microsoft Bopomofo's Chinese and English modes. You can keep using `Ctrl` and `Ctrl+Shift` for full-width symbols, too.

And those often-unused **Muhenkan (無変換)** and **Henkan (変換)** keys next to the spacebar? You can turn them into extra space keys ✨

> 💡 **Before you install:** The full fix currently supports specific 64-bit Windows 10 builds and requires a matching Microsoft Bopomofo version and JIS keyboard configuration. Please check the [compatibility requirements](docs/COMPATIBILITY.md) first. Windows 11 testing has not been completed.

### ✨ Features

- 🧩 **Keep your Zhuyin habits:** Retains Microsoft Bopomofo composition, candidate selection, and standard Zhuyin key positions.
- 🎯 **Symbols follow your keycaps:** Use JIS symbol positions in Microsoft Bopomofo's Chinese and English modes.
- ⚡ **Full-width shortcuts:** Includes `Ctrl+;` → `；`, `Ctrl+Shift+;` → `＋`, and `Ctrl+@` → `＠`.
- ␣ **More room for Space:** Remap Muhenkan and Henkan to Space, with a separate installer if that's all you need.
- 🛡️ **Backups and recovery:** Backs up the original settings before changing them and includes restore scripts.
- 🍃 **No background hotkey utility:** Applies changes to the input component and keyboard settings without an extra background program.

### 🚀 Installation

Check the [system requirements](docs/COMPATIBILITY.md) before installing.

1. Download the installer archive from this project's **Releases** page and extract it into a new folder.
2. Right-click `Install.cmd` and select **Run as administrator**.
3. Once the console displays `Completed`, restart your computer 🎉

**📌 Only want the extra space keys?**

The full installer also remaps Muhenkan and Henkan to Space. To change only those two keys, run `Install-Spaces.cmd` as administrator. This leaves the Bopomofo component unchanged.

After restarting, open Notepad to test Zhuyin input, Chinese/English switching, and symbols. The package includes `Test-results.txt` as a checklist.

### 🔄 Recovery and diagnostics

| What you want to do | Script | Notes |
|---|---|---|
| Restore all changes | `Restore.cmd` | Restores pre-installation Bopomofo settings and key mappings; restart required |
| Restore only the extra space keys | `Restore-Spaces.cmd` | Restores the previous Muhenkan/Henkan mappings; restart required |
| Check installation status | `Check.cmd` | Reports current settings and fix status |
| Export a diagnostic report | `Diagnose.cmd` | Collects information for troubleshooting |

Run restore scripts as administrator. If recovery fails, keep the backups and error messages, then check the [troubleshooting guide](docs/INSTALLATION.md) or open an Issue.

### 🛠️ Building from source

Install **Zig 0.14.1**, open PowerShell in the project root, and run the command below. Replace the Zig path with its actual location on your computer:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File src/router/Build-Router.ps1 -ZigExecutable C:\Tools\zig\zig.exe -OutputDirectory build/router
```

The compiled DLL is written to `build/router/JisCoreRouter64.dll`. Before using it in an installer, complete testing and update the installer's file verification settings. See the [development guide](docs/DEVELOPMENT.md) for details.

To create release packages with the included DLL, you only need **Python 3.9+**:

```powershell
python tools/package.py
```

The installer and source ZIPs are written to `dist/`.

### 💻 Supported systems and things to know

Tested in a Windows 10 Enterprise LTSC 2021 virtual machine and on a Japanese Fujitsu LIFEBOOK U-series laptop running Windows 10 Pro 22H2.

Community testing on more Windows versions and computer models is welcome! Share your hardware model and results in **Issues** to help expand support 💖 If the installer reports an unsupported version, you're welcome to report your Windows version, too.

- ⚠️ **Windows updates:** Updates that change Microsoft Bopomofo may stop the symbol fix from working. A fix for the new version may be needed.
- ⚠️ **Blocked or deleted files:** If Windows security settings or security software block the relevant files, Bopomofo may stop working. Try the restore script first.
- ⚠️ **Extra space keys:** Remapping Muhenkan/Henkan replaces their Japanese input functions and applies to all connected keyboards.
- ⚠️ **JIS keyboard configuration:** The full installer requires an existing JIS configuration. See the [installation requirements](docs/COMPATIBILITY.md).

See the [cross-version review](docs/CROSS-VERSION-REVIEW.md) for findings and update-related risks.

### 🩺 Troubleshooting

- **Installation failed:** Check `Install-*.log.txt` in the extracted folder, then run `Diagnose.cmd`.
- **Bopomofo isn't working:** Run `Restore.cmd` as administrator and restart. If recovery also fails, keep the error messages and report the problem.
- **Keep your backups:** Do not delete `%ProgramData%\Fujitsu-JIS-Core` or `%ProgramData%\Fujitsu-JIS-SpaceKeys`. Recovery uses the backups in these folders.

When opening an Issue, include your Windows version, computer or keyboard model, the problem, and steps to reproduce it. Remove computer names, usernames, and other personal information before attaching diagnostic reports. Do not upload Windows system files.

See the [installation and troubleshooting guide](docs/INSTALLATION.md) for more details.

### 🧪 Development and testing

Run these commands in the project root:

```powershell
python tools/verify.py
powershell -NoProfile -ExecutionPolicy Bypass -File tests/Test-SpaceMap.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests/Test-CompatibilityGuards.ps1
python tools/package.py
python tools/check_package.py
```

These commands check files, run tests, and create packages without changing system settings. GitHub Actions runs the same checks. Actual typing, login, and restart behavior still need separate testing.

The detailed guides below are currently written in Traditional Chinese:

- 📖 [Development and testing](docs/DEVELOPMENT.md)
- 🏗️ [Architecture](docs/ARCHITECTURE.md)
- 📝 [Validation records](docs/VALIDATION.md)
- 🤝 [Contributing](CONTRIBUTING.md)
- 🚀 [Releases and GitHub publishing](docs/PUBLISHING.md)
- 📜 [Changelog](CHANGELOG.md) · [Security reporting](SECURITY.md)

### ⚖️ License

Project source code and documentation are released under **GPL-3.0-or-later**. See [LICENSE](LICENSE) and [COPYRIGHT](COPYRIGHT). Installer packages include the corresponding source code and build instructions.

The package does not distribute Microsoft system DLLs. The installer creates a modified copy locally using the original Bopomofo files on your computer. See [Third-party notices](THIRD_PARTY_NOTICES.md). This is an independent open-source project, not an official Microsoft or Fujitsu product.
