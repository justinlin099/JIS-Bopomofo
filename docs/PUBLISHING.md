# GitHub 推送與發行

## 第一次推送

在 GitHub 建立空的 `jis-bopomofo` repository；不要預先建立 README 或 LICENSE，避免與本機初始提交衝突。

在專案根目錄執行以下命令，將 `YOUR-ACCOUNT` 改成自己的帳號或組織：

```powershell
git remote add origin https://github.com/YOUR-ACCOUNT/jis-bopomofo.git
git push -u origin main
```

本機交付資料夾已建立 `main` 與初始提交。若使用來源 ZIP 解壓的副本，該 ZIP 不含 `.git`，請先執行：

```powershell
git init -b main
git add .
git commit -m "Initialize JIS Bopomofo project"
```

若已有 origin，用 `git remote -v` 確認，再視需要使用 `git remote set-url origin ...`。Git 身分與 GitHub 登入由使用者自己的環境管理；專案不包含 token 或登入檔。

## Actions

推送、Pull Request 或手動執行 **Repository checks** 會：

1. 使用 Python 3.9／3.13 檢查來源雜湊、配方、文件連結及檔案清單。
2. 在 Windows PowerShell 執行純映射與安裝條件測試。
3. 產生安裝包、完整來源 ZIP 與 SHA256 清單，並檢查封裝。
4. 上傳各 Python 版本的 `release-files-*` artifact。

CI 不以管理員安裝，也不會啟動 VM。Actions 綠燈僅代表上述範圍；實際相容性仍需獨立驗收。

## 發布 Release

1. 完成[開發指南](DEVELOPMENT.md)要求的驗證。若只更新文件／封裝，確認執行檔與安裝來源仍等於既有驗收版。
2. 更新 `VERSION`、`CHANGELOG.md`。新檔案須加入 `tools/repository-files.json`。
3. 執行兩項 PowerShell 測試，以及 `python tools/package.py`、`python tools/check_package.py`。
4. 提交並推送 main，確認 CI 通過。
5. 建立對應 tag，例如目前版本 `v0.2.1`，再推送該 tag。
6. 在 GitHub 建立該 tag 的 Release，貼上版本摘要，附上 `dist/` 的兩份 ZIP 與 SHA256SUMS。

```powershell
git tag -a v0.2.1 -m "JIS Bopomofo 0.2.1"
git push origin v0.2.1
```

tag 推送會跑檢查；本專案不會自動發布 Release。發行時將安裝包與對應來源一起提供。不要上傳本機產生的 Microsoft 修正核心副本、VM 映像或私人診斷檔。

## 建議的 GitHub 設定

- Description：`Native JIS keyboard symbol fixes for Microsoft Bopomofo on Windows 10.`
- Topics：`windows`、`jis-keyboard`、`bopomofo`、`ime`、`traditional-chinese`。
- 預設分支：`main`。啟用 Issues；如需私密安全回報，在 repository 設定中啟用 Private vulnerability reporting。
- 需要分支保護時，可將 `check (3.9)` 與 `check (3.13)` 設為必要檢查。
