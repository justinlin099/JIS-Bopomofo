# 跨系統版本驗證與風險

檢查日期：2026-09-12。對象：0.2.0 GPL 發行內容。

## 結論

目前可列為實測支援的系統仍只有既有 Windows 10 x64 環境。
不能以「JIS 鍵盤」或「Windows 10」兩個條件就判定可用。
其他版本的正常安裝路徑通常會拒絕；安裝後再更新系統則仍有注音失效風險。
本次沒有移除保護條件，也沒有在主機套用任何設定。

## 證據範圍

- **既有整合測試**：Win10 Enterprise LTSC 2021 19044.6456 VM；v2 安裝、失敗還原、重新開機及輸入。
- **既有使用者實機回報**：Win10 Pro 22H2 19045.6466、Fujitsu JIS 筆電全部正常。
- **本次新測試**：從現有安裝器 AST 抽出四項原始純條件，執行 25 個案例，全部通過；另確認這些條件位於安裝資料夾修改之前。測試不執行整份安裝器、不存取登錄、不載入 DLL。
- **本次程式碼審查**：安裝／還原流程、Router 回退、獨立空白鍵映射、診斷腳本。
- **尚未實測**：新的 Windows 10 修補版本、Windows 11、Windows Server、ARM64、32-bit Windows、企業封鎖政策、跨版本升級。

25 個案例是版本／雜湊等輸入值的測試，**不是在 25 台或 25 種作業系統上安裝過**。
執行方式：`powershell -NoProfile -ExecutionPolicy Bypass -File tests/Test-CompatibilityGuards.ps1`。
結果保存在 `validation/compatibility-guards.json`。

## 安裝到不同系統

| 環境 | 現有安裝器的行為／風險 | 證據 |
|---|---|---|
| Win10 x64 19044／19045，核心 SHA256 完全相符且已用 KBD106 | 通過版本門檻；仍需原版註冊、有效簽章、權限及其他檢查 | 條件測試＋上述有限整合驗收 |
| 同為 19044／19045，但微軟更新了 IMTCCORE | 雜湊不同便拒絕，不修改核心註冊；連 Router 內另有配方的 5856 核心也不會被安裝器接受 | 原始雜湊 guard 測試 |
| Win10 1809／1909／2004／21H1 等其他 build | build 不符而拒絕 | 原始 build guard 測試 |
| Win11 22000／22621／22631／26100／26200 | build 不符而拒絕；不可刪掉 guard 直接安裝 | 原始 build guard 測試 |
| Server 17763／20348／26100 等 | build 不符而拒絕；沒有 Server 驗收 | 原始 build guard 測試 |
| 32-bit Windows／32-bit PowerShell | 程式要求 64-bit PowerShell，現有 DLL 也是 x64 | 靜態審查；非本次 25 案例之一 |
| ARM64 Windows | 不支援；Is64BitProcess 並不能識別 x64／ARM64，不能將其視為完整架構檢查。正常 ARM64 核心應無法符合已釘選 x64 雜湊，Win11 亦會先被 build 擋下 | 靜態審查，未做 ARM 實測 |
| 缺少繁體中文／微軟注音組件 | 登錄或檔案讀取失敗，停在核心設定修改之前；訊息可能是一般 Missing key／File not found | 靜態審查 |
| 一般新機仍是 KBDUS 或其他配置 | 拒絕；此包不會自行建立 KBD106 基礎配置 | 原始 layout guard 測試 |
| Home／Pro／Enterprise 等不同 SKU | 未設 SKU 白名單，並不表示每個 SKU 都驗證過；版本、核心及安全政策仍須符合 | 靜態審查 |

安裝拒絕時仍可能寫入同資料夾的安裝日誌；「未修改核心設定」不等於完全沒有任何檔案輸出。
完整 Install 先執行核心安裝，核心失敗時不會接著套用空白鍵映射。

## 安裝成功後才升級或更新

1. **符號修正可能消失。** Router 在每個新程序首次初始化時比對系統核心。如果更新後雜湊未知，會嘗試載入當前原版核心；這保留的是原版注音能力，不保證 Ctrl 符號修正。既有程序不會每次按鍵重新比對，應重新啟動後驗證。
2. **仍可能發生注音無法載入、切回 ENG。** Router 本身缺失、被隔離或被 App Control 拒絕時，根本無法執行回退。安裝器只核對 Router 檔案雜湊，沒有在實際 ctfmon／目標應用程式政策下做啟用測試。
3. **系統更新可能重設 COM 註冊。** 註冊回到 Microsoft 原版後，修正不再使用；目前不會監控或自動重新註冊。不得為保留功能而阻止安全更新。
4. **回退不是跨版本保證。** 原版核心路徑或 COM 介面若改變，載入可能失敗。Router 只釘選 IMTCCORE 自身，沒有驗證其所有依賴、TSF 與其他系統組件；核心雜湊沒變但依賴更新，仍不能視為已通過相容性驗收。
5. **還原可能需要處理衝突。** 還原不受安裝 build 白名單限制，但若更新或其他工具改動了註冊值、登錄鍵或 ACL，現有還原會拒絕覆寫或回報驗證失敗。不能保證升級後原備份一定可直接套回。

目前方案不把自訂 DLL 設為啟動鍵盤 Layout File，避開先前原型遇到的那條開機載入路徑；這仍不是「任何系統都不可能開機失敗」的保證。

## 安全政策與獨立空白鍵功能

Microsoft 說明 App Control 可以管理使用者模式的二進位檔、DLL 和腳本；
Smart App Control 亦可能阻擋未知、未簽章程式。因此，即使 Windows 版本和雜湊符合，
企業政策、PowerShell 限制或 DLL 載入政策仍可能讓安裝或注音啟用失敗。
不建議為此關閉原有安全政策；這類環境應先做隔離政策測試與正式簽署／允許規則評估。

`Install-Spaces.cmd` 不載入 Router、沒有核心雜湊或 OS build 白名單，故範圍可能較廣，
但不能直接宣稱已支援 Win11／ARM。它仍要求 64-bit PowerShell、管理員權限及標準
0x79／0x7B 掃描碼；映射對整台電腦生效，也會取消兩顆鍵原本的日文功能。
廠商特殊驅動、韌體、遠端桌面及多鍵盤情況須另測。

## 發布建議

- 保持「Win10 x64、精確核心版本、既有 KBD106」的支援範圍；其他品牌只能列條件相符待驗收。
- 新系統先用快照 VM 建立原版注音基線，再測拒絕／安裝、組字、Ctrl 符號、32／64-bit 程式、管理員程式、登入與重啟、還原，以及安裝後 Windows 更新。
- 擴大支援前增加明確的原生架構識別、實際載入檢查與更新後健康檢查。這些是待開發項目，現有 0.2.0 未實作。
- 此次只增加測試與風險文件，沒有改動既有 DLL、安裝條件或系統設定。

## 官方參考

- [App Control 政策規則](https://learn.microsoft.com/en-us/windows/security/threat-protection/windows-defender-application-control/select-types-of-rules-to-create)
- [Smart App Control](https://learn.microsoft.com/en-us/windows/apps/develop/smart-app-control/overview)
- [Windows on Arm 的模擬機制](https://learn.microsoft.com/en-us/windows/arm/apps-on-arm-x86-emulation)

以上文件支持平台限制；本專案具體行為與風險判斷來自程式碼審查，未實測部分已標明。
