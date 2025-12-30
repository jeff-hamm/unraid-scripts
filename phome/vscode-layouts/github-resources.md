# Curated VS Code Settings Repositories

A list of popular GitHub repositories with VS Code configurations you can learn from.

## Most Popular (500+ stars)

### [antfu/vscode-settings](https://github.com/antfu/vscode-settings)
**Anthony Fu's settings** - Minimalistic, clean setup with Vitesse theme. Great for web dev.
- Focus: Clean, distraction-free
- Highlight: Custom snippets, carbon icons

### [sobolevn/dotfiles](https://github.com/sobolevn/dotfiles)
**Complete dev environment** - macOS + zsh + vscode + python. Ansible-based.
- Focus: Developer happiness, minimalism
- Highlight: Full system automation

### [nicksp/dotfiles](https://github.com/nicksp/dotfiles)
**Modern stack** - VSCode + Cursor + Ghostty + Obsidian
- Focus: AI-assisted coding, modern tools
- Highlight: Claude integration, lazygit

### [sapegin/dotfiles](https://github.com/sapegin/dotfiles)
**macOS complete** - zsh, git, VS Code
- Focus: JavaScript/React development
- Highlight: Clean, well-documented

### [palashmon/awesome-vscode-settings](https://github.com/palashmon/awesome-vscode-settings)
**Curated list** - Collection of settings tips and tricks
- Focus: Learning resource
- Highlight: Many examples explained

## Windows-Specific

### [Vabolos/windots](https://github.com/Vabolos/windots)
**Windows 11 rice** - Windows Terminal, catppuccin theme, yasb, glazewm
- Focus: Aesthetic Windows setup
- Highlight: Tiling window manager (GlazeWM)

### [jacquindev/windots](https://github.com/jacquindev/windots)
**Complete Windows 11** - PowerShell, flow-launcher, komorebi
- Focus: Modern Windows development
- Highlight: Another tiling WM option (Komorebi)

### [JuanOrbegoso/Dotfiles-for-Windows-11](https://github.com/JuanOrbegoso/Dotfiles-for-Windows-11)
**Setup script** - PowerShell based
- Focus: Easy automation
- Highlight: Chocolatey + WSL setup

---

## Window Managers for Windows (Great for Dual Monitors!)

### GlazeWM
https://github.com/glzr-io/glazewm
- Tiling window manager for Windows
- Inspired by i3wm
- **Perfect for dual monitor setups!**

### Komorebi
https://github.com/LGUG2Z/komorebi
- Tiling window manager for Windows
- Works with AutoHotkey
- Dynamic workspace management

### PowerToys FancyZones
https://docs.microsoft.com/powertoys
- Microsoft's official solution
- Easy to use, built-in
- Custom zone layouts

---

## Quick Setup Commands

### Clone antfu's settings (minimal)
```bash
curl -L https://raw.githubusercontent.com/antfu/vscode-settings/main/.vscode/settings.json -o ~/my-vscode-settings.json
```

### Clone using degit
```bash
npx degit antfu/vscode-settings#main/.vscode .vscode-from-antfu
```

### Browse settings online
Just append `1s` to github.com to use github1s:
- https://github1s.com/antfu/vscode-settings

---

## Layout-Specific Tips from Popular Configs

### Common patterns across top configs:

1. **Minimap off** - Most power users disable it
   ```json
   "editor.minimap.enabled": false
   ```

2. **Activity bar hidden** - Use keyboard shortcuts instead
   ```json
   "workbench.activityBar.location": "hidden"
   ```

3. **Tabs off or single** - Navigate with Ctrl+P
   ```json
   "workbench.editor.showTabs": "single"
   ```

4. **Breadcrumbs off** - For more vertical space
   ```json
   "breadcrumbs.enabled": false
   ```

5. **Line numbers relative** - Popular with vim users
   ```json
   "editor.lineNumbers": "relative"
   ```
