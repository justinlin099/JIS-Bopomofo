# 貢獻指南

歡迎修正、文件改善及其他品牌 JIS 鍵盤的相容性回報。

## 回報

使用 Issues 的 Bug report 或 Keyboard compatibility 範本，提供專案版本、OS build、核心雜湊、KBD106 狀態、應用程式與重現步驟。清楚區分親自測試、未測與推測；不要提供序號、帳密、完整私人日誌或 Windows DLL。

新增系統支援請先討論目標版本及驗收方法。目前的 build 白名單代表驗證範圍，不能以刪除白名單或雜湊保護當成移植完成。

## Pull Request

1. 從 main 建立分支。
2. 依 [DEVELOPMENT](docs/DEVELOPMENT.md)執行適當檢查。
3. 新增可發布檔案時，更新 `tools/repository-files.json`。
4. PR 描述具體問題、修正後行為、測試與限制。

安裝器、Router 或配方變更須在可丟棄 VM 驗證失敗回復與還原；文件更新不需重新執行整套 GUI 測試。來源釘選檔不可單純重算來掩蓋未驗證的修改。

貢獻的自有程式碼與文件依 GPL-3.0-or-later 提供。第三方內容應註明來源與授權，並確認可依專案條件使用。安全問題見 [SECURITY](SECURITY.md)。
