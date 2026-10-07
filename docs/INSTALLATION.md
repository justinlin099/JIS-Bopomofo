# 安裝、驗證與還原

## 取得完整安裝包

下載 Release 的 `jis-bopomofo-<版本>-windows-x64.zip`，或在原始碼根目錄執行 `python tools/package.py`。不要從 GitHub 原始碼中的 `windows/` 直接安裝：Router DLL 在 `prebuilt/`，打包工具會將必要檔案放在同一層。

解壓至可寫入的本機資料夾。安裝腳本使用 Windows PowerShell 5.1，CMD 入口會選擇 64-bit PowerShell。

## 完整安裝

先確認[相容性要求](COMPATIBILITY.md)。安裝器不會替新電腦建立 KBD106 配置。

1. 若 Windows 正在更新或等待重新啟動，先完成更新並重啟。
2. 以管理員身分執行 `Install.cmd`。
3. 出現 `Completed` 後重新啟動。
4. 用 `Test-results.txt` 驗證微軟注音與符號；再測日常使用的 32／64-bit、一般與管理員應用程式。

完整安裝已包含兩侧空白鍵。若只需要這項映射，改執行 `Install-Spaces.cmd`；它不需要注音核心配方，但其他 Windows 版本仍未完成實測。

## 確認是否成功

- 微軟注音能組字、選字及輸入「你好」。
- 注音內「英」模式：JIS 數字列 Shift+2 輸出雙引號。
- 使用實體鍵帽位置：Ctrl+; 為 `；`、Ctrl+Shift+; 為 `＋`、Ctrl+@ 為 `＠`。
- 無變換／變換在英文、注音組字及 Shift 組合下，與原空白鍵行為一致。
- `Check.cmd` 可產生安裝狀態及可觀察的載入模組報告。無法觀察模組不等於已證明未載入，仍以實際輸入測試為準。

## 還原

以管理員身分執行 `Restore.cmd`，再重新啟動；只還原空白鍵使用 `Restore-Spaces.cmd`。

以下路徑使用歷史名称，以相容舊版備份，不代表品牌限制：

| 路徑 | 用途 |
|---|---|
| `%ProgramFiles%\Fujitsu-JIS-Core` | Router 與本機修正核心副本 |
| `%ProgramData%\Fujitsu-JIS-Core` | 核心登錄備份與交易狀態 |
| `%ProgramData%\Fujitsu-JIS-SpaceKeys` | 掃描碼映射備份 |

請先還原再移除安裝檔案。Restore 保留副本，避免仍在執行的程序需要它；備份也不會自動刪除。若設定已被其他工具或系統更新修改，還原會停止，避免覆蓋未知狀態。

## 常見問題

| 訊息／現象 | 原因與處理 |
|---|---|
| Requires Windows 10 build19044 or19045 | 安裝器只接受這兩個 build；其他版本屬待移植範圍 |
| Unsupported Microsoft core | 原版核心雜湊不同；需要為該版本建立及驗證新配方 |
| Requires the existing working KBD106 configuration | 目前注音配置不是 KBD106；此包不會自動修改基礎配置 |
| Expected signed original Microsoft components | 簽章檢查未通過；先確認原版系統元件完整性 |
| Existing transaction must be restored | 前次狀態尚未還原；使用相應 Restore 入口處理 |
| Settings changed outside this transaction | 登錄設定已被其他來源修改；保留診斷及備份，不要刪除保護條件 |
| 安裝後注音跳回 ENG／無法輸入 | Router 或核心可能無法載入；先嘗試 Restore、重啟，再查看 Code Integrity 與診斷紀錄 |
| Windows 更新後符號修正消失 | 可能回退原版核心或註冊被重設；執行 Check，參閱跨版本評估 |

`Diagnose.cmd` 與 `Check.cmd` 不修改系統設定，但會在解壓資料夾寫入 JSON。回報時只提供相關錯誤與必要欄位；移除私人資訊，不要附 Windows DLL。
