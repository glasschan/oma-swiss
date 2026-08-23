# OmaSwiss

[English](README.md) · 繁體中文

![OmaSwiss — 一個 bar icon，四個 Hyprland 工具](preview.png)

**一個 bar icon，四個 Hyprland 工具。**

互換筆電的 Super 與 Alt 鍵、把單一視窗鎖定至任意比例、一鍵切換桌面外觀、快速截圖與螢幕錄影 —— 全部來自同一個彈出面板，閒置時近乎零成本。

## 為何你會一直留著它

- **一個面板，毋須終端機。** 每個工具都是一按即用的開關；右擊 bar icon 可即時切換 Super⇄Alt。
- **閒置成本：一個 icon。** 沒有常駐程序、沒有計時器、沒有輪詢。面板關閉時，插件形同休眠。
- **更新與重新登入後依然生效。** 所有開關只寫入 Omarchy 自身的狀態檔，設定在 reload、重開機與 `omarchy update` 之後原封不動，Omarchy 選單亦照常運作。
- **中／EN。** 整個面板一按切換英文與繁體中文。
- **有新版本自動提示。** GitHub 上有新 release 時，面板會出現升級標示；一按即自動更新（git 安裝），查詢每天最多一次，絕無輪詢。

## 四個工具

- **Super ⇄ Alt 互換** —— 隨時在筆電內置鍵盤上使用 Mac 式修飾鍵；外接鍵盤完全不受影響。
- **單一視窗比例** —— 1:1、4:3、3:2、16:9 預設，或自訂 `W:H`（最高 64）。比例在 reload 與登入後保持不變，原生的 `SUPER+CTRL+BACKSPACE` 綁定亦可同時使用。
- **Opinionated Looks** —— 圓角、半透明 5px 邊框、柔和陰影與 vibrancy blur，一鍵切換；關閉即完全還原 Omarchy 預設。
- **快速擷取** —— 區域／視窗／全螢幕截圖、螢幕取色、OCR（中英）、錄影開始與停止，各一按即發。擷取覆疊需要乾淨畫面，工具啟動時面板會自動關閉讓出螢幕。

## 日常使用

- **左擊** bar icon：開啟工具面板。
- **右擊**：即時切換 Super⇄Alt。
- **固定快捷鍵**（可選）：固定後 `SUPER+CTRL+BACKSPACE` 會在「關閉 ⇄ 上次比例」之間切換，而非原生的固定 1:1 —— 在面板設好 16:9，快捷鍵便跟隨。解除固定即完整還原先前的綁定，Omarchy 選單內建的比例項目亦不受影響。

每個命令亦可直接從 shell 執行，可綁定至任何按鍵：

```bash
omarchy-shell glasschan.oma-swiss toggle         # Super⇄Alt 開／關
omarchy-shell glasschan.oma-swiss aspect 21 10   # 任何自訂比例
omarchy-shell glasschan.oma-swiss aspectOff      # 關閉比例
omarchy-shell glasschan.oma-swiss aspectToggle   # 關閉 <-> 上次比例
omarchy-shell glasschan.oma-swiss pin            # 固定／解除快捷鍵
omarchy-shell glasschan.oma-swiss look           # 外觀開／關
omarchy-shell glasschan.oma-swiss lang           # EN <-> 中
omarchy-shell glasschan.oma-swiss panel          # 開／關面板
omarchy-shell glasschan.oma-swiss status         # 目前狀態
```

## 安裝／移除

```bash
omarchy plugin add <本 repo 的 git URL>     # 安裝
omarchy plugin remove glasschan.oma-swiss   # 移除
```

移除前，請先在面板關閉所有開關。每個開關都會留下一個小型狀態檔，在登入時重新套用設定 —— 關閉開關即刪除該檔，插件移除後不會殘留任何東西。

## 依賴

無須額外安裝 —— 一切隨 Omarchy v4 內附：Hyprland 0.56+、`omarchy-capture-screenshot`（slurp）、`omarchy-capture-text`（OCR）、`omarchy-capture-screenrecording`（gpu-screen-recorder）及 `hyprpicker`。

MIT。
