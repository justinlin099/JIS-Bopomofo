# 開發與測試

## 環境

- Python 3.9+：驗證與封裝，僅使用標準函式庫。
- Windows PowerShell 5.1：腳本測試及安裝。
- Zig 0.14.1：重建原生 x64 Router；編譯器須自行取得。
- 可丟棄的 Windows VM：驗證安裝、注音與重啟。

## 檢查與封裝

在根目錄執行：

```powershell
python tools/verify.py
powershell -NoProfile -ExecutionPolicy Bypass -File tests/Test-SpaceMap.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests/Test-CompatibilityGuards.ps1
python tools/package.py
python tools/check_package.py
```

驗證與打包不會安裝。PowerShell 測試只抽取純函式／條件；產生的 `*-results.json` 已被 Git 排除。

`tools/repository-files.json` 是可發布檔案的明確清單。新增文件或測試時請同步更新；安裝執行檔只取自已驗證的來源 manifest，避免將日誌或本機檔案誤包進去。

打包產生安裝 ZIP、完整來源 ZIP 與 SHA256 清單。安裝包內的 `source/` 也包含對應的完整專案。`check_package.py` 檢查兩份來源一致、每個 entry 的 SHA256、CRC 與執行檔來源；檢查不以 hash 代替數位簽章。

## 重建 Router

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File src/router/Build-Router.ps1 -ZigExecutable C:\Tools\zig\zig.exe -OutputDirectory build/router
```

重建不會自動替換 prebuilt 或註冊。編譯時戳與 GUID 可能改變整檔雜湊；不同二進位須重新驗收。不要刪掉安裝器的精確雜湊檢查來繞過驗證。

`prebuilt/manifest.json` 記錄已驗收 Router；`validation/source-manifest.json` 釘選該次驗收的安裝程式與 Router 來源。修改這些檔案時，先完成適當的隔離測試，再更新來源與二進位 manifest；同時保留驗證範圍與日期。

## 新核心版本

使用自己合法 Windows 環境的元件，在隔離 VM 分析、產生配方。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File windows/Build-Table7-Copy.ps1 -SourceDll C:\Windows\System32\IME\IMETC\IMTCCORE.DLL -OutputDirectory build/private-core
```

這只建立本機副本。不要提交或散布該 Microsoft DLL。配方有研究用版本，不表示公開安裝器已接受或驗收那些版本。

## 整合驗收

在快照 VM 記錄原版注音基線，然後測試：

- 注音位置、組字／候選字、Shift 中英切換。
- `tests/expected-jis-ctrl-symbols.json` 與 `windows/Test-results.txt` 的符號；包括組字中及 Ctrl／Shift 的按下、放開順序。
- 32／64-bit、一般／管理員應用程式。
- 登入、冷開機、重新啟動與還原。
- 未支援核心、缺少／損壞修正副本、注入安裝失敗與外部設定衝突。
- 系統更新後的核心、註冊與安全政策狀態。

既有結果見 [VALIDATION](VALIDATION.md)；來源一致性檢查或 CI 通過均不能代替這些測試。

發行步驟見 [PUBLISHING](PUBLISHING.md)。
