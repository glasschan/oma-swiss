# OmaSwiss

[English](README.md) · 繁體中文

![OmaSwiss — 一個 bar icon，六個 Hyprland 工具](preview.png)

**一個 bar icon，六個 Hyprland 工具。**

互換筆電的 Super 與 Alt 鍵、把單一視窗鎖定至任意比例、一鍵切換桌面外觀、遊戲模式調校、輸入法候選視窗主題、快速截圖與螢幕錄影 —— 全部來自同一個彈出面板，閒置時近乎零成本。

## 為何你會一直留著它

- **一個面板，毋須終端機。** 每個工具都是一按即用的開關；右擊 bar icon 可即時切換 Super⇄Alt。
- **閒置成本：一個 icon。** 沒有常駐程序、沒有計時器、沒有輪詢。面板關閉時，插件形同休眠。
- **更新與重新登入後依然生效。** 所有開關只寫入 Omarchy 自身的狀態檔，設定在 reload、重開機與 `omarchy update` 之後原封不動，Omarchy 選單亦照常運作。
- **四種介面語言。** 可從面板右上角的選單切換 English、繁體中文、日本語、한국어。日文與韓文為機器輔助翻譯，歡迎透過 PR 改善。
- **有新版本自動提示。** GitHub 上有新 release 時，面板會出現升級標示，游標停在標示上即可檢視更新說明；一按即自動更新（git 安裝），更新完成後 Omarchy shell 會短暫自行重啟，確保新版本立即生效；查詢每天最多一次，絕無輪詢。

## 六個工具

- **Super ⇄ Alt 互換** —— 隨時互換筆電內置鍵盤的左 Super 與左 Alt；外接鍵盤完全不受影響。
- **單一視窗比例** —— 1:1、4:3、3:2、16:9 預設，或自訂 `W:H`（最高 64）。比例在 reload 與登入後保持不變，原生的 `SUPER+CTRL+BACKSPACE` 綁定亦可同時使用。
- **Opinionated Looks** —— 圓角、半透明 5px 邊框、柔和陰影與 vibrancy blur，一鍵切換；關閉即完全還原 Omarchy 預設。
- **遊戲模式** —— 一鍵啟用 VRR（可變更新率）並允許畫面撕裂，追求最低輸入延遲；關閉即完全還原 Omarchy 預設值。
- **輸入法候選視窗主題** —— fcitx5 候選視窗套用 Omarchy 配色，圓角、半透明邊框與 vibrancy blur，切換主題時自動重新配色；關閉即還原 fcitx5 預設。
- **快速擷取** —— 區域／視窗／全螢幕截圖、螢幕取色、OCR（中英）、QR 碼掃描（解碼內容自動複製到剪貼簿），以及含網路攝影機與否的螢幕錄影開關，各一按即發。擷取覆疊需要乾淨畫面，工具啟動時面板會自動關閉讓出螢幕。

## 日常使用

- **左擊** bar icon：開啟工具面板。
- **右擊**：即時切換 Super⇄Alt。
- **中鍵點擊**：即時區域截圖（按 Esc 取消）。
- **懸停**：兩行提示列出三個滑鼠鍵的功能，語言跟隨面板設定。
- **固定比例快捷鍵**（可選）：固定後 `SUPER+CTRL+BACKSPACE` 會在「關閉 ⇄ 上次比例」之間切換，而非原生的固定 1:1 —— 在面板設好 16:9，快捷鍵便跟隨。解除固定即完整還原先前的綁定，Omarchy 選單內建的比例項目亦不受影響。

每個命令亦可直接從 shell 執行，可綁定至任何按鍵：

```bash
omarchy-shell glasschan.oma-swiss toggle         # Super⇄Alt 開／關
omarchy-shell glasschan.oma-swiss aspect 21 10   # 任何自訂比例
omarchy-shell glasschan.oma-swiss aspectOff      # 關閉比例
omarchy-shell glasschan.oma-swiss aspectToggle   # 關閉 <-> 上次比例
omarchy-shell glasschan.oma-swiss pin            # 固定／解除比例快捷鍵
omarchy-shell glasschan.oma-swiss look           # 外觀開／關
omarchy-shell glasschan.oma-swiss gaming         # 遊戲模式開／關
omarchy-shell glasschan.oma-swiss fcitx          # 輸入法候選視窗主題開／關
omarchy-shell glasschan.oma-swiss lang           # 循環切換介面語言 en→zh→ja→ko→en
omarchy-shell glasschan.oma-swiss panel          # 開／關面板
omarchy-shell glasschan.oma-swiss open           # 開啟面板
omarchy-shell glasschan.oma-swiss close          # 關閉面板
omarchy-shell glasschan.oma-swiss status         # 目前狀態
```

## 專案結構

repo 內所有被追蹤的檔案，以及各自的角色：

```text
.
├── .github/
│   └── workflows/
│       ├── ci.yml                    # CI：校驗 manifest，並執行提交規範與安全強化檢查
│       └── release.yml               # CI：發布 GitHub Release（tag 須與 manifest 版本一致，打包 zip + sha256）
├── design/
│   ├── cover.html                    # preview.png 封面的原始檔（以 headless Chromium 轉譯）
│   └── fcitx5-candidates.png         # 封面內嵌的 fcitx5 主題候選字列截圖（2x 最近鄰放大）
├── docs/
│   ├── agents/                       # 給編碼代理的操作說明：issue 追蹤、分類標籤、領域文件
│   │   ├── domain.md
│   │   ├── issue-tracker.md
│   │   └── triage-labels.md
│   └── fcitx5-candidate-theming.md   # fcitx5 開關的設計簡介與驗證清單
├── scripts/
│   ├── check-hardening.sh            # CI 安全基線 tripwire（引號處理、期限、原子寫入等類別）
│   └── check-submission.sh           # CI 市集提交規範檢查（README 章節、LICENSE、預覽圖上限）
├── AGENTS.md                         # 本 repo 的工作契約：契約、強化規則、E2E 清單
├── BarWidget.qml                     # 進入點：全部狀態與動作、bar icon、IPC 介面
├── EvalQueue.qml                     # 單槽佇列，讓連續的 hyprctl 切換依序落地
├── LICENSE                           # MIT 授權
├── README.md                         # 英文說明文件
├── README.zh-Hant.md                 # 本檔案，與 README.md 保持內容對等
├── ToolPanel.qml                     # 彈出面板：純視圖，由 BarWidget 以 hostWidget 注入
├── fcitx5-theme.sh                   # fcitx5 開關的 apply／unapply／generate 腳本（主題、hook、classicui.conf）
├── manifest.json                     # 插件 manifest：id、版本、進入點
├── panel.png                         # 面板原始截圖（文件用）
├── preview.png                       # 73:35 行銷封面，置於兩份 README 頂部
├── tabler-icons.ttf                  # ~8 KB 的 Tabler Icons 子集（15 個 codepoint），bar 與面板共用
└── .gitignore
```

插件安裝後，在 repo 以外接觸的所有路徑。各開關的旗標檔與 fcitx5 產物只存在於該功能開啟期間——關閉開關即刪除對應檔案，插件移除後不會殘留：

| 路徑 | 用途 | 存在時機 |
| --- | --- | --- |
| `~/.config/omarchy/plugins/glasschan.oma-swiss/` | 已部署的插件副本——`omarchy plugin add` 安裝、面板更新標示更新的就是它 | 安裝期間 |
| `~/.local/state/omarchy/toggles/hypr/super-alt-swap.lua` | 互換的旗標檔 | 互換開啟時 |
| `~/.local/state/omarchy/toggles/hypr/single-window-aspect-ratio.lua` | 比例的旗標檔（內容即所選比例） | 設定比例期間 |
| `~/.local/state/omarchy/toggles/hypr/opinionated-looks.lua` | Opinionated Looks 的旗標檔 | 外觀開啟時 |
| `~/.local/state/omarchy/toggles/hypr/oma-swiss-gaming-mode.lua` | 遊戲模式的旗標檔 | 遊戲模式開啟時 |
| `~/.local/state/omarchy/toggles/hypr/oma-swiss-hotkey.lua` | 比例快捷鍵固定的旗標檔 | 快捷鍵固定期間 |
| `~/.local/state/omarchy/toggles/hypr/oma-swiss-fcitx5.lua` | fcitx5 的旗標檔（其唯一一行同時就是生效中的 Hyprland 模糊規則） | fcitx5 主題開啟時 |
| `~/.local/state/glasschan.oma-swiss/lang` | 介面語言 | 首次變更語言後 |
| `~/.local/state/glasschan.oma-swiss/last-aspect` | 上次設定的比例（驅動面板預填與固定快捷鍵） | 首次設定比例後 |
| `~/.local/state/glasschan.oma-swiss/update-check` | 更新檢查快取（每日最多一次網路請求） | 首次開啟面板後 |
| `~/.local/state/glasschan.oma-swiss/update-notes` | 待更新版本的 release 說明 | 僅在有待更新版本時 |
| `~/.config/omarchy/hooks/theme-set.d/fcitx5` | fcitx5 重新配色 hook，呼叫已部署副本內的腳本 | fcitx5 主題開啟時 |
| `~/.local/share/fcitx5/themes/omarchy/` | 產生的 fcitx5 主題 | fcitx5 主題開啟時 |
| `~/.config/fcitx5/conf/classicui.conf` | fcitx5 的主題設定（`Theme=omarchy`）；原有檔案會先備份一次為 `classicui.conf.pre-oma-swiss` | fcitx5 主題開啟時（備份會保留） |

## 安裝／移除

```bash
omarchy plugin add <本 repo 的 git URL>     # 安裝
omarchy plugin remove glasschan.oma-swiss   # 移除
```

移除前，請先在面板關閉所有開關。每個開關都會留下一個小型狀態檔，在登入時重新套用設定 —— 關閉開關即刪除該檔，插件移除後不會殘留任何東西。移除前特別要先關閉「**輸入法候選視窗主題**」：開啟時它會安裝一個指向插件目錄的重新配色 hook，若插件在開關仍開啟時被移除，該 hook 會殘留並呼叫不存在的腳本。

## 依賴

無須額外安裝 —— 一切隨 Omarchy v4 內附：Hyprland 0.56+、`omarchy-capture-screenshot`（slurp）、`omarchy-capture-text`（OCR）、`omarchy-capture-qr`（zbar）、`omarchy-capture-screenrecording` 與 `omarchy-capture-screenrecording-with-webcam`（gpu-screen-recorder）及 `hyprpicker`。若有 `jq`（標準 Omarchy 安裝內建），待更新的面板會一併顯示新版本的更新說明；沒有亦不影響更新檢查。

「**輸入法候選視窗主題**」開關為可選功能，缺少依賴時會優雅降級：需要已安裝的標準 fcitx5 且 `omarchy-fcitx5.service` 處於運行狀態（絕不強制啟動已停止的服務），以及標準的 `omarchy-theme-color`。有 ImageMagick 的 `magick` 時會產生圓角 9-patch 背景；沒有時改用方形邊框的後備方案。

MIT。
