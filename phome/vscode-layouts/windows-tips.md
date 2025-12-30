# Windows-Specific Tips for Dual Monitor VS Code

## PowerToys FancyZones (Highly Recommended!)

Microsoft PowerToys includes **FancyZones** - a window manager that's perfect for your setup.

### Install PowerToys
```powershell
winget install Microsoft.PowerToys
```

### Suggested FancyZones Layout for Portrait Monitor
Create a custom layout with 3 horizontal zones:
1. **Top (40%)**: VS Code auxiliary window (Explorer/Outline)
2. **Middle (40%)**: Terminal (Windows Terminal or VS Code terminal window)
3. **Bottom (20%)**: Notes/Docs/Browser DevTools

### Keyboard Shortcuts
- `Win + Arrow`: Snap windows to zones
- Hold `Shift` while dragging to activate FancyZones

---

## Windows Snap Layouts (Windows 11)

Hover over the maximize button to see snap layout options.

For Portrait:
- Use the "3 stacked" layout
- Top: VS Code aux window
- Middle: Terminal
- Bottom: Browser/Docs

---

## AutoHotkey Scripts (Advanced)

### Quick Window Arrangement Script
```autohotkey
; Win+1: Move focused window to primary monitor
#1::
WinGetActiveTitle, Title
WinMove, %Title%, , 0, 0, 1920, 1080
return

; Win+2: Move focused window to portrait monitor (adjust coordinates)
#2::
WinGetActiveTitle, Title
WinMove, %Title%, , 1920, 0, 1080, 1920
return

; Win+Shift+V: Open new VS Code window
#+v::
Run, code -n
return
```

---

## VS Code Window Management

### Open Second Window with Same Workspace
```
Ctrl+Shift+P → "Workspaces: Duplicate As Workspace in New Window"
```

### Move Terminal to Second Monitor
1. Right-click terminal tab
2. Select "Move Terminal into Editor Area"  
3. Drag the editor tab to your second monitor

### Move Any Editor Tab to New Window
- `Ctrl+Alt+M` (with the keybinding from this pack)
- Or: Right-click tab → "Move into New Window"

---

## Recommended Windows Terminal Setup

If you prefer Windows Terminal over VS Code's integrated terminal:

### settings.json snippet for Windows Terminal
```json
{
    "profiles": {
        "defaults": {
            "font": {
                "face": "CaskaydiaCove Nerd Font",
                "size": 11
            }
        }
    },
    "initialPosition": "1920,600",  // Opens on portrait monitor
    "initialCols": 100,
    "initialRows": 40
}
```

---

## Quick Setup Checklist

- [ ] Install PowerToys and configure FancyZones
- [ ] Set up VS Code keybindings from this pack
- [ ] Create 2 VS Code workspace layout presets with Restore Editors extension
- [ ] Configure Windows Terminal to open on portrait monitor
- [ ] Test `Ctrl+Alt+D` to duplicate workspace to new window
