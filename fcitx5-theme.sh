#!/bin/sh
# fcitx5-theme.sh — glasschan.oma-swiss fcitx5 candidate-window theming.
#
# apply    install classicui.conf + theme-set hook + blur flag, then generate
# unapply  remove everything this feature owns; fcitx5/Hyprland back to stock
# generate re-render the theme from the ACTIVE Omarchy palette (also the
#          theme-set hook body: omarchy-theme-set runs it on every theme
#          change, so the candidate window retints itself)
#
# Generator logic is carried verbatim in substance from the approved
# standalone implementation (~/omarchy-custom-scripts/setup-fcitx5-theme.sh,
# user-approved 2026-09-06): palette via omarchy-theme-color with fallbacks,
# 9-patch PNGs (96x96 background, stroke #ffffff1c width 2, roundrectangle
# 1,1 94,94 radius 7; 64x64 highlight, roundrectangle 0,0 63,63 radius 5),
# square Color + BorderColor fallback without ImageMagick, and the same
# theme.conf section set.
#
# Hardening contract (same classes as scripts/check-hardening.sh): every
# file write lands through a same-directory mktemp + mv -f (rename replaces
# a planted symlink instead of following it — never a redirection to a final
# path); every hyprctl/systemctl call runs under coreutils timeout 10,
# magick and the service restart under 15; the service is never force-started
# (a stopped or masked omarchy-fcitx5.service stays stopped).

set -u

THEME_DIR="$HOME/.local/share/fcitx5/themes/omarchy"
CLASSICUI_CONF="$HOME/.config/fcitx5/conf/classicui.conf"
CLASSICUI_BACKUP="$CLASSICUI_CONF.pre-oma-swiss"
HOOK_FILE="$HOME/.config/omarchy/hooks/theme-set.d/fcitx5"
FLAG_FILE="$HOME/.local/state/omarchy/toggles/hypr/oma-swiss-fcitx5.lua"
LOOKNFEEL_LUA="$HOME/.config/hypr/looknfeel.lua"
LEGACY_GENERATOR="$HOME/.local/bin/omarchy-theme-set-fcitx5"
SERVICE="omarchy-fcitx5.service"

# One boolean, one file: Omarchy require_all's every lua in toggles/hypr, so
# the content IS the live Hyprland layer rule and the existence is the
# plugin's state (FileView watch + status). Exactly one line.
FLAG_LUA='hl.layer_rule({ match = { namespace = "fcitx" }, blur = true })'

# Legacy block left behind by the standalone installer this feature absorbed.
BEGIN_MARKER="-- BEGIN fcitx5 candidate blur (setup-fcitx5-theme.sh)"
END_MARKER="-- END fcitx5 candidate blur (setup-fcitx5-theme.sh)"

# Atomic, symlink-safe write: stdin lands on "$1" through a same-directory
# mktemp (O_EXCL) + mv -f — the rename replaces a pre-planted symlink rather
# than truncating through it. The parent directory is created first.
atomic_write() {
  _aw_target="$1"
  _aw_dir=$(dirname -- "$_aw_target")
  mkdir -p -- "$_aw_dir" || return 1
  _aw_tmp=$(mktemp -- "$_aw_dir/.oma-swiss-fcitx5.XXXXXX") || return 1
  cat >"$_aw_tmp" &&
    mv -f -- "$_aw_tmp" "$_aw_target" ||
    { rm -f -- "$_aw_tmp"; return 1; }
}

# theme_token KEY FALLBACK — one semantic palette token from the live Omarchy
# theme; a missing resolver or token degrades to the fallback (light themes
# included), exactly like the standalone generator.
theme_token() {
  _tt_val=""
  if command -v omarchy-theme-color >/dev/null 2>&1; then
    _tt_val=$(timeout 10 omarchy-theme-color "$1" "$2" 2>/dev/null)
  fi
  [ -n "$_tt_val" ] || _tt_val="$2"
}

# Restart the supervised fcitx5 service so classicui re-reads its theme —
# fcitx5-remote -r alone does not pick theme changes up (hard-won fact #3).
# Guarded: a stopped/disabled install is never force-started.
restart_service() {
  if timeout 10 systemctl --user is-active --quiet "$SERVICE" 2>/dev/null; then
    timeout 15 systemctl --user restart "$SERVICE"
  fi
}

# Migration cleanup, run on EVERY apply AND unapply: the standalone installer
# (~/omarchy-custom-scripts/setup-fcitx5-theme.sh) owned the same artifacts
# through different paths. Strip its looknfeel.lua marker block and remove
# its generator — two writers of the same files is the hazard this absorbs.
legacy_cleanup() {
  if [ -f "$LOOKNFEEL_LUA" ] && grep -qF -- "$BEGIN_MARKER" "$LOOKNFEEL_LUA" 2>/dev/null; then
    strip_marker_block || echo "fcitx5-theme: failed to strip legacy marker block" >&2
  fi
  rm -f -- "$LEGACY_GENERATOR"
}

# Remove the BEGIN..END marker block (plus one blank line directly before it)
# from looknfeel.lua; everything else stays untouched. Same range semantics
# as the standalone's strip_block_range, but landing through mktemp + mv -f
# instead of sed -i so a planted symlink cannot redirect the edit.
strip_marker_block() {
  _sb_total=$(wc -l <"$LOOKNFEEL_LUA")
  _sb_begin=$(grep -nF -- "$BEGIN_MARKER" "$LOOKNFEEL_LUA" | head -n 1 | cut -d: -f 1)
  [ -n "$_sb_begin" ] || return 0
  _sb_end=$(grep -nF -- "$END_MARKER" "$LOOKNFEEL_LUA" | head -n 1 | cut -d: -f 1)
  case "$_sb_end" in "" | *[!0-9]*) _sb_end=$_sb_total ;; esac
  [ "$_sb_end" -ge "$_sb_begin" ] || _sb_end=$_sb_total
  if [ "$_sb_begin" -gt 1 ]; then
    _sb_prev=$(sed -n "$((_sb_begin - 1))p" "$LOOKNFEEL_LUA")
    [ -n "$_sb_prev" ] || _sb_begin=$((_sb_begin - 1))
  fi
  _sb_dir=$(dirname -- "$LOOKNFEEL_LUA")
  _sb_tmp=$(mktemp -- "$_sb_dir/.oma-swiss-fcitx5.XXXXXX") || return 1
  {
    sed -n "1,$((_sb_begin - 1))p" "$LOOKNFEEL_LUA"
    sed -n "$((_sb_end + 1)),\$p" "$LOOKNFEEL_LUA"
  } >"$_sb_tmp" &&
    mv -f -- "$_sb_tmp" "$LOOKNFEEL_LUA" ||
    { rm -f -- "$_sb_tmp"; return 1; }
}

generate() {
  theme_token background "#1a1b26"
  bg="$_tt_val"
  theme_token lighter_background "$bg"
  bg_light="$_tt_val"
  theme_token selection "$bg_light"
  selection="$_tt_val"
  theme_token foreground "#ffffff"
  fg="$_tt_val"
  theme_token bright_foreground "$fg"
  fg_bright="$_tt_val"
  theme_token accent "$fg_bright"
  accent="$_tt_val"
  theme_token muted "$selection"
  muted="$_tt_val"

  mkdir -p -- "$THEME_DIR" || return 1

  # Stock page-arrow / radio assets, copied once from the default theme.
  for asset in arrow.png next.png prev.png radio.png; do
    [ -f "$THEME_DIR/$asset" ] ||
      cp "/usr/share/fcitx5/themes/default/$asset" "$THEME_DIR/" 2>/dev/null ||
      true
  done

  # Rounded base with the translucent rim baked into the 9-patch PNG —
  # fcitx5 has no native rounding and Hyprland layer rules support no
  # rounding field, so the PNG is the only way. The rim is the midpoint of
  # OmaSwiss's gradient border rgba(ffffff30)->rgba(ffffff08). Without
  # ImageMagick: square base + BorderColor fallback.
  BG_MARGIN=2
  BG_BORDER_LINES="BorderColor=#ffffff1c
BorderWidth=2"
  BG_IMAGE_LINE=""
  if command -v magick >/dev/null 2>&1; then
    _bg_tmp=$(mktemp -- "$THEME_DIR/.background.XXXXXX") || return 1
    if timeout 15 magick -size 96x96 xc:none -stroke "#ffffff1c" -strokewidth 2 \
      -fill "$bg" -draw "roundrectangle 1,1 94,94 7,7" \
      "PNG32:$_bg_tmp" 2>/dev/null &&
      mv -f -- "$_bg_tmp" "$THEME_DIR/background.png"; then
      BG_MARGIN=10
      BG_BORDER_LINES=""
      BG_IMAGE_LINE="Image=background.png"
    else
      rm -f -- "$_bg_tmp"
    fi
  fi

  # Selected-candidate highlight: all four corners 5px rounded. HL_MARGIN is
  # BOTH the 9-patch slice and the outward expansion of the highlight box, so
  # [InputPanel/ContentMargin] (8) must stay > HL_MARGIN (6): the highlight
  # then stops inside the 2px rim instead of covering it. One style applies
  # to ALL candidate rows — uniform 5px is the approved compromise.
  HL_MARGIN=6
  HL_IMAGE_LINE="Image=highlight.png"
  if command -v magick >/dev/null 2>&1; then
    _hl_tmp=$(mktemp -- "$THEME_DIR/.highlight.XXXXXX") || return 1
    if timeout 15 magick -size 64x64 xc:none -fill "$bg_light" \
      -draw "roundrectangle 0,0 63,63 5,5" \
      "PNG32:$_hl_tmp" 2>/dev/null &&
      mv -f -- "$_hl_tmp" "$THEME_DIR/highlight.png"; then
      :
    else
      rm -f -- "$_hl_tmp"
      HL_IMAGE_LINE=""
    fi
  else
    HL_IMAGE_LINE=""
  fi
  [ -n "$HL_IMAGE_LINE" ] || HL_MARGIN=5

  # fcitx5 themes DO use INI sections (unlike conf/*.conf). Both Highlight
  # and HighlightBackground are written — fcitx5 silently ignores unknown
  # sections, whichever is real takes effect (hard-won fact #10).
  atomic_write "$THEME_DIR/theme.conf" <<EOF || return 1
[Metadata]
Name=Omarchy
Version=1
Author=fcitx5-theme.sh
Description=Generated from the active omarchy theme palette
ScaleWithDPI=True

[InputPanel]
NormalColor=$fg
HighlightColor=$fg_bright
HighlightCandidateColor=$accent
HighlightBackgroundColor=$bg_light
PageButtonAlignment=Last Candidate

[InputPanel/TextMargin]
Left=5
Right=5
Top=5
Bottom=5

[InputPanel/ContentMargin]
Left=8
Right=8
Top=8
Bottom=8

[InputPanel/Background]
Color=$bg
$BG_BORDER_LINES
$BG_IMAGE_LINE

[InputPanel/Background/Margin]
Left=$BG_MARGIN
Right=$BG_MARGIN
Top=$BG_MARGIN
Bottom=$BG_MARGIN

[InputPanel/Highlight]
Color=$bg_light
$HL_IMAGE_LINE

[InputPanel/Highlight/Margin]
Left=$HL_MARGIN
Right=$HL_MARGIN
Top=$HL_MARGIN
Bottom=$HL_MARGIN

[InputPanel/HighlightBackground]
Color=$bg_light
$HL_IMAGE_LINE

[InputPanel/HighlightBackground/Margin]
Left=$HL_MARGIN
Right=$HL_MARGIN
Top=$HL_MARGIN
Bottom=$HL_MARGIN

[InputPanel/PrevPage]
Image=prev.png

[InputPanel/PrevPage/ClickMargin]
Left=5
Right=5
Top=4
Bottom=4

[InputPanel/NextPage]
Image=next.png

[InputPanel/NextPage/ClickMargin]
Left=5
Right=5
Top=4
Bottom=4

[Menu/Background]
Color=$bg
$BG_BORDER_LINES
$BG_IMAGE_LINE

[Menu/Background/Margin]
Left=$BG_MARGIN
Right=$BG_MARGIN
Top=$BG_MARGIN
Bottom=$BG_MARGIN

[Menu/ContentMargin]
Left=2
Right=2
Top=2
Bottom=2

[Menu/CheckBox]
Image=radio.png

[Menu/SubMenu]
Image=arrow.png

[Menu/Highlight]
Color=$bg_light

[Menu/Highlight/Margin]
Left=5
Right=5
Top=5
Bottom=5

[Menu/Separator]
Color=$muted

[Menu/TextMargin]
Left=5
Right=5
Top=5
Bottom=5
EOF

  restart_service
}

apply() {
  # 1. Back up the user's own classicui.conf once, before we own the file.
  #    Never overwrite an existing backup — it may be the only copy.
  if [ -f "$CLASSICUI_CONF" ] && ! grep -q '^Theme=omarchy$' "$CLASSICUI_CONF" 2>/dev/null; then
    [ -e "$CLASSICUI_BACKUP" ] || cp -p -- "$CLASSICUI_CONF" "$CLASSICUI_BACKUP"
  fi

  # 2. classicui.conf — fcitx5 conf/*.conf files are SECTION-LESS key=value:
  #    an [INI] header makes fcitx5 file every key under a section it never
  #    reads and silently fall back to defaults (hard-won fact #1).
  atomic_write "$CLASSICUI_CONF" <<'EOF'
Theme=omarchy
DarkTheme=omarchy
UseDarkTheme=False
PerScreenDPI=True
Font="OPPO Sans 4.0 11"
EOF

  # 3. theme-set hook: omarchy-theme-set runs it on every theme change, so
  #    the candidate window retints itself even when the bar is not loaded.
  atomic_write "$HOOK_FILE" <<'EOF'
#!/bin/sh
# glasschan.oma-swiss: re-tint the fcitx5 candidate window on theme change.
sh "$HOME/.config/omarchy/plugins/glasschan.oma-swiss/fcitx5-theme.sh" generate
EOF
  chmod 755 "$HOOK_FILE" 2>/dev/null || true

  # 4. Migration: kill any leftover standalone install (both directions).
  legacy_cleanup

  # 5. The blur flag is written LAST on apply (the feature lands as one
  #    decision), then Hyprland picks up the layer rule.
  atomic_write "$FLAG_FILE" <<EOF || return 1
$FLAG_LUA
EOF
  timeout 10 hyprctl reload >/dev/null 2>&1 || true

  # 6-7. Generate for the current palette, then make classicui re-read it.
  if ! generate; then
    echo "fcitx5-theme: theme generation failed" >&2
    return 1
  fi
  restart_service
}

unapply() {
  # 1. Flag out FIRST (absent = stock exactly), then Hyprland drops the rule.
  rm -f -- "$FLAG_FILE"
  timeout 10 hyprctl reload >/dev/null 2>&1 || true

  # 2. Hook out — no more retints.
  rm -f -- "$HOOK_FILE"

  # 3. classicui.conf: only touch it when we own it (Theme=omarchy). Restore
  #    the pre-install backup when there is one, else remove our file.
  if [ -f "$CLASSICUI_CONF" ] && grep -q '^Theme=omarchy$' "$CLASSICUI_CONF" 2>/dev/null; then
    if [ -f "$CLASSICUI_BACKUP" ]; then
      mv -f -- "$CLASSICUI_BACKUP" "$CLASSICUI_CONF"
    else
      rm -f -- "$CLASSICUI_CONF"
    fi
  fi

  # 4. The generated theme.
  rm -rf -- "$THEME_DIR"

  # 5. Migration cleanup (same as apply).
  legacy_cleanup

  # 6. Let a running fcitx5 drop the theme.
  restart_service
}

case "${1:-}" in
  apply) apply ;;
  unapply) unapply ;;
  generate) generate ;;
  *)
    echo "usage: fcitx5-theme.sh apply|unapply|generate" >&2
    exit 1
    ;;
esac
