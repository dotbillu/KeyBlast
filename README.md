# **KeyBlast**

**A minimal, responsive, and fast Bash CLI typing test simulator.**

KeyBlast is a lightweight terminal typing trainer supporting English words, JavaScript syntax, and C++ syntax.
Designed for Linux terminals with real-time WPM, accuracy updates, live highlighting, and a clean UI.

<!-- paste this into your README.md where you want the gallery -->
<div style="display:flex;flex-wrap:wrap;gap:8px;margin:12px 0;">
  <img src="./media/keyblast1.png" alt="KeyBlast 1"
       style="flex:1 1 220px;min-width:140px;max-height:300px;width:100%;object-fit:cover;border-radius:8px;">
  <img src="./media/keyblast2.png" alt="KeyBlast 2"
       style="flex:1 1 220px;min-width:140px;max-height:300px;width:100%;object-fit:cover;border-radius:8px;">
  <img src="./media/keyblast3.png" alt="KeyBlast 3"
       style="flex:1 1 220px;min-width:140px;max-height:300px;width:100%;object-fit:cover;border-radius:8px;">
  <img src="./media/keyblast4.png" alt="KeyBlast 4"
       style="flex:1 1 220px;min-width:140px;max-height:300px;width:100%;object-fit:cover;border-radius:8px;">
</div>

---

## **Features**

- Real-time WPM + accuracy
- English, JavaScript, and C++ wordlists

---

## **Prerequisites**

Your script uses the following tools:

| Tool                         | Why it's needed             |
| ---------------------------- | --------------------------- |
| **zsh/bash**                 | Script runtime              |
| **bc**                       | WPM + accuracy calculations |
| **curl** or **wget**         | Downloading wordlists       |
| **figlet**                   | Big text banners            |
| **tput**                     | Terminal sizing             |
| **Nerd Fonts (recommended)** | Cleaner icons/spacing       |

Got it. Here’s a clearer split version:

---

## Arch Linux Setup for KeyBlast

### **Mandatory Packages**

These are required for KeyBlast to work properly:

```bash
paru -S figlet ttf-jetbrains-mono-nerd  # or yay -S figlet nerd-fonts-meslo
```

- `figlet` is used for stylized text in the terminal.
- Nerd Fonts (`ttf-jetbrains-mono-nerd` or `nerd-fonts-meslo`) are required for proper font rendering in the terminal.

---

### **Optional Packages for Full Experience**

These are not required, but improve usability and aesthetics:

```bash
paru -S zsh bc curl   # or yay -S zsh bc curl
```

- `zsh`: optional shell, can replace bash. Set as default with:

```bash
chsh -s $(which zsh)
```

- `bc`: used for calculations.
- `curl`: used to fetch remote resources.

---
### **Terminal Font Setup (Kitty example)**

1. List available fonts:

```bash
kitty list-fonts
```

Pick the Nerd Font you installed.

2. Or manually edit Kitty config:

```bash
nvim ~/.config/kitty/kitty.conf #or nano ifu are normie
```

Add or modify:

```bash
font_family JetBrainsMono Nerd Font 
#or font_family Meslo LG Nerd Font
font_size 12  # adjust as desired
```

---


### **Notes for Other Distros**
(cant say they surely work as i dont use these distros so feel free to ask gpt or gemini)
- **Ubuntu/Debian**:

```bash
sudo apt install figlet fonts-jetbrains-mono zsh bc curl
```

- **Fedora**:

```bash
sudo dnf install figlet jetbrains-mono-fonts zsh bc curl
```

---

## **Installation**

```bash
git clone https://github.com/dotbillu/KeyBlast
cd KeyBlast
sudo ./install.sh
```

This installs the `keyblast` command globally.

---

## **Run**

```bash
keyblast
```

Boom — typing test starts.
Use it whenever you’re bored or wanna warm up your fingers.

---

**Licensed under the MIT License — free to use, modify, and distribute.**
