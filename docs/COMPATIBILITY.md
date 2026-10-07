# 相容性

JIS 是鍵盤排列，不是 Windows、IME 二進位版本或韌體行為的保證。
目前沒有品牌／型號限制程式碼；能否共用主要由下列條件決定。

完整修正要求 Windows x64 Build 19044/19045，原版核心路徑、有效簽章及 SHA256：

```text
System32\IME\IMETC\IMTCCORE.DLL
9c74ca43cb645413fda01f789490c1294b1573446b501d49c23bde90d2f79628
```

已驗證核心檔案版本為 19041.5794。OS 累積更新號和核心檔案版本是不同欄位。
配方內其他雜湊保留自開發研究，不代表目前公開安裝器接受它們。
32-bit 程式已在 x64 Windows 上測試；不等於支援 32-bit Windows。

完整修正要求已在使用 `KBD106.DLL`。它不會變更 i8042prt、ENG/US 配置或
`Keyboard Layouts`，也不會探測並自動改造不符前置條件的電腦。
從一般美式注音配置開始的 JIS 電腦需要先另外確認基礎配置，不能直接宣稱可裝。

兩側空白鍵使用掃描碼 `0x79`、`0x7B` → `0x39`。
其他鍵盤若回報相同掃描碼，理論上可共用這項映射；不同韌體、Fn 層、外接／遠端
輸入路徑仍須測試。它是全機映射，會取代原本的日文轉換功能。

新增機種請使用相容性 Issue 範本，回報品牌／型號、OS Build、核心 SHA256、
KBD106 前置條件、實際鍵帽／掃描碼、Ctrl 符號和還原結果。不要上傳完整系統 DLL。

依據：
- [Microsoft keyboard input overview](https://learn.microsoft.com/en-us/windows/win32/inputdev/about-keyboard-input)
- [Microsoft Japanese 106 layout sample](https://github.com/microsoft/Windows-driver-samples/blob/main/input/layout/fe_kbds/jpn/106/kbd106.c)
