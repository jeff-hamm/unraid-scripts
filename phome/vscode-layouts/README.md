# VS Code Dual Monitor Layouts
## Primary Landscape + Secondary Portrait Setup

Based on Reddit research and community best practices, here are optimized layouts for your dual-monitor setup.

---

## 🎯 Key Techniques (From Reddit Community)

### 1. **Detachable Tabs** (VS Code 1.85+)
You can now drag editor tabs/terminals to a separate window!
- Right-click terminal → "Move Terminal into Editor Area"
- Drag the tab to your second monitor
- Use `Terminal: Create New Terminal in Editor Area` command

### 2. **Two Windows, Same Workspace**
- `Ctrl+Shift+P` → `Workspaces: Duplicate As Workspace in New Window`
- Configure each window differently

### 3. **Terminal on Right** (Popular for Landscape)
Many devs move terminal to the right to preserve vertical code space.

### 4. **Explorer on Right**
Less distracting - content doesn't shift when toggling.

---

## 📐 Layout Presets

### Layout A: "Focused Coder" (Landscape Primary)
- **Primary (Landscape)**: Code only, Zen Mode or Centered Layout
- **Secondary (Portrait)**: Explorer + Terminal stacked vertically
- Best for: Deep work sessions

### Layout B: "Full Control" (Landscape Primary)  
- **Primary**: Code + Terminal on RIGHT side
- **Secondary**: Explorer + Outline + Problems + Source Control
- Best for: Active development with frequent terminal use

### Layout C: "Debug Mode"
- **Primary**: Code + Debug Console side-by-side
- **Secondary**: Variables + Watch + Call Stack + Breakpoints (stacked - great for portrait!)
- Best for: Debugging sessions

### Layout D: "Review Mode"
- **Primary**: Two files side-by-side (diff view)
- **Secondary**: Git Changes + Timeline + Terminal
- Best for: Code review, git operations

---

## ⚙️ Settings to Apply

Copy these to your `settings.json` (`Ctrl+Shift+P` → "Open User Settings JSON")

### Files in this folder:
- **[settings-landscape-focused.jsonc](settings-landscape-focused.jsonc)** - Zen mode, minimal UI
- **[settings-landscape-fullcontrol.jsonc](settings-landscape-fullcontrol.jsonc)** - Terminal on right (Reddit favorite!)
- **[settings-portrait-auxiliary.jsonc](settings-portrait-auxiliary.jsonc)** - For your 2nd window on portrait
- **[settings-debug-mode.jsonc](settings-debug-mode.jsonc)** - Debug layout
- **[keybindings-layouts.jsonc](keybindings-layouts.jsonc)** - Quick switch shortcuts
- **[windows-tips.md](windows-tips.md)** - PowerToys, window managers, tips
- **[github-resources.md](github-resources.md)** - Popular VS Code dotfiles repos

---

## 🚀 Quick Start

1. **Duplicate workspace to new window**: `Ctrl+Alt+D` (after adding keybindings)
2. **Move that window to your portrait monitor**
3. **Apply portrait settings to that workspace**
4. **Save layouts with Restore Editors extension**

---

