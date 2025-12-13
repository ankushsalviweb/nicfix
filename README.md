# NicFix 🛜

**One click. Connection fixed. Zero dependencies.**

A Windows Wi-Fi troubleshooting tool that consolidates expert-level network fixes into a single, beautiful interface.

![Windows 10/11](https://img.shields.io/badge/Windows-10%2F11-0078D6?logo=windows)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-5391FE?logo=powershell)
![License](https://img.shields.io/badge/License-MIT-green)
![Size](https://img.shields.io/badge/Size-86KB-brightgreen)

---

## ✨ Features

- 🎨 **Modern Dark UI** - Sleek sidebar navigation with beautiful design
- 🚀 **Hero Section** - Most-used fixes at your fingertips
- 📦 **Zero Dependencies** - Single 86KB executable, no installation needed
- 🔒 **Auto Admin** - Requests administrator rights automatically
- 💬 **Friendly Feedback** - Plain English success messages
- 🔇 **Silent Operation** - No console window, just the GUI

---

## 🖼️ Screenshot

The app features:
- Left sidebar with category navigation
- Hero section with quick-access action cards
- Compact action list with descriptions
- Collapsible technical log

---

## 🚀 Quick Start

1. **Download** `NicFix.exe` from [Releases](../../releases)
2. **Double-click** to run
3. **Accept** the UAC prompt
4. **Click** any fix!

---

## 🔧 Fix Categories

| Category | Risk Level | Actions |
|----------|------------|---------|
| ⚡ **Quick Fixes** | Safe | Flush DNS, Release/Renew IP, Restart Adapter |
| 🔄 **Network Stack** | Moderate | Reset Winsock, TCP/IP, ARP Cache, Firewall |
| 🔋 **Power Settings** | Common Fix | Disable Power Saving, High Performance Mode |
| 💾 **Driver Ops** | Advanced | Reinstall Driver, Reset Driver Settings |
| 📊 **Diagnostics** | Info Only | Network Report, IP Config, Connection Test |

---

## 🎯 Popular Fixes (Hero Section)

| Icon | Action | Best For |
|------|--------|----------|
| **D** | Flush DNS | "Page not found" errors |
| **R** | Restart WiFi | Random disconnections |
| **T** | Test Net | Check if internet is working |
| **P** | Power Fix | Laptop battery-related drops |

---

## 📋 Requirements

- Windows 10 or Windows 11
- Administrator rights (auto-requested)
- PowerShell 5.1+ (included in Windows)

---

## 🛠️ Building from Source

The app is a single PowerShell script with embedded WPF GUI.

```powershell
# Run directly
powershell -ExecutionPolicy Bypass -File NicFix.ps1

# Build executable (requires ps2exe module)
Install-Module ps2exe -Scope CurrentUser
Invoke-ps2exe -InputFile NicFix.ps1 -OutputFile NicFix.exe -NoConsole -RequireAdmin
```

---

## 👨‍💻 Author

**Ankush Salvi**  
*Coded with AI* ✨

---

## 📄 License

MIT License - See [LICENSE](LICENSE) for details.

Free to use, modify, and distribute.

---

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## ⭐ Star This Repo!

If NicFix helped fix your Wi-Fi issues, consider giving it a star!
