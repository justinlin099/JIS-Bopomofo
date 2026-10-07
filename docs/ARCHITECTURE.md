# 架構

1. Windows 既有 KBD106 處理硬體掃描碼與 JIS 符號。
2. 64-bit 注音核心的 COM 登錄改指向專案自有的 `JisCoreRouter64.dll`。
3. Router 檢查原版核心 SHA256；只載入雜湊相符的私有 Table7 修正副本。
4. 原微軟引擎仍處理組字、候選字與文字插入；32-bit 應用程式相容性已有 VM 測試。
5. 可選的空白鍵功能使用 Windows Scancode Map，不透過 Router。

Router 無鍵盤 hook、常駐執行緒或服務，DllMain 不載入核心。
載入的模組維持至程序結束；這不是宣稱完全不使用記憶體。

安裝器只改一個 64-bit 核心 COM 值，並產生 Program Files 私有副本。
暫時啟用備份／還原權限操作該受保護值，保留 registry ACL/owner；不覆寫 Windows DLL。
Format2 狀態同時保存展開後路徑、原始字串與 String/ExpandString 型別。
Restore 精確恢復原型別／內容；支援舊 Format1 的 String 備份。
設定被外部變更時停止，以避免覆蓋未知狀態。

空白鍵程式合併既有映射，只替換兩個來源碼，備份完整原值；若其後映射被外部修改，
還原會停止。請保留 ProgramData 中的狀態檔。

早期將未簽章自訂 DLL 放到啟動用 Layout File 的方案曾觸發 wininit Code Integrity
3033 並卡開機，已撤回。本專案保留原版 KBD106，沒有採用那個啟動配置。
