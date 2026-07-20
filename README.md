# 🖨️ Ricoh Aficio 1515 PCL — Windows Printer Setup

> A self-contained, one-click deployment kit for installing the **Ricoh Aficio 1515 PCL** printer driver on any Windows 10/11 (64-bit) machine — supporting both **network (TCP/IP)** and **USB** connections.

---

## 📋 Table of Contents

- [About](#-about)
- [Features](#-features)
- [Requirements](#-requirements)
- [Quick Start](#-quick-start)
- [What the Script Does](#-what-the-script-does)
- [Folder Structure](#-folder-structure)
- [Network vs USB Setup](#-network-vs-usb-setup)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

---

## 📖 About

This repository was created to simplify deploying the **Ricoh Aficio 1515 PCL** printer across multiple Windows machines — whether in an office, lab, or home network.

Instead of manually downloading drivers, navigating Device Manager, or running through Windows' Add Printer wizard on every machine, this kit lets you:

- ✅ Run a single `.bat` file as Administrator
- ✅ Choose **Network**, **USB**, or **Both**
- ✅ Enter a custom printer IP or use the **pre-configured default** (`192.168.0.50`)
- ✅ Have the printer fully installed and ready in under a minute

All driver files are bundled — **no internet connection required** on the target machine.

---

## ✨ Features

| Feature | Details |
|---------|---------|
| 🖥️ OS Check | Validates Windows 10/11 (64-bit) before proceeding |
| 🔄 Spooler Check | Auto-starts Print Spooler if it's stopped |
| 🌐 Network Setup | Creates a TCP/IP port with your IP (or the default `192.168.0.50`) |
| 🔌 USB Setup | Detects available USB ports and lets you select the right one |
| ♻️ Safe Reinstall | Detects existing printers and asks before overwriting |
| 📦 Fully Offline | All drivers bundled — no downloads needed |
| 🛡️ Windows 10 Compliant | Uses `pnputil`, `Add-PrinterDriver`, `Add-Printer` — all PS 5.1 native |

---

## ⚙️ Requirements

| Requirement | Details |
|-------------|---------|
| **OS** | Windows 10 or Windows 11 (64-bit only) |
| **PowerShell** | 5.1 or higher (pre-installed on all Win10/11 machines) |
| **Privileges** | Must run as **Administrator** |
| **Network Printer** | Ricoh must be powered on and reachable on the LAN |
| **USB Printer** | Ricoh must be plugged in **before** running the script |

---

## 🚀 Quick Start

### Step 1 — Get the files

**Option A — Clone with Git:**
```bash
git clone https://github.com/4awmy/ricoh-print-service.git
```

**Option B — Download ZIP:**  
Click the green **Code** button → **Download ZIP** → Extract it.

---

### Step 2 — Run setup

1. Open the extracted folder
2. **Right-click** `SETUP.bat`
3. Select **"Run as administrator"**

> ⚠️ If you double-click without admin rights, the script will warn you and exit safely.

---

### Step 3 — Follow the prompts

```
[STEP] Choose printer setup mode:
  [1] Network printer (TCP/IP)  - Ricoh connected via LAN
  [2] USB printer               - Ricoh connected via USB cable
  [3] Both                      - Install both

  Enter choice (1/2/3): _
```

For network mode, you'll be asked for the IP:

```
[STEP] Network printer IP configuration
  Default IP: 192.168.0.50
  Enter custom IP, or press Enter to use default [192.168.0.50]: _
```

Just press **Enter** to use the default, or type your printer's IP address.

---

## 🔍 What the Script Does

```
1. Checks Windows 10/11 (64-bit)
2. Verifies Print Spooler is running (starts it if not)
3. Verifies driver files are present in the 'drivers/' folder
4. Stages the Ricoh PCL driver using pnputil (Windows Driver Store)
5. Registers the driver with the Windows Print Subsystem
6. [Network] Creates a Standard TCP/IP port for the given IP
7. [Network] Adds "Ricoh Aficio 1515 PCL (Network)" printer
8. [USB]     Detects USB ports and adds "Ricoh Aficio 1515 PCL (USB)"
9. Displays a summary of all installed Ricoh printers
```

---

## 📁 Folder Structure

```
ricoh-print-service/
│
├── SETUP.bat                    ← Entry point — run this as Admin
├── Install-RicohPrinter.ps1    ← PowerShell installer (called by SETUP.bat)
├── README.md                    ← This file
│
└── drivers/
    ├── prnrc001.inf             ← Main driver INF (Ricoh Aficio series)
    ├── prnrc001.cat             ← Driver catalog / signature file
    ├── prnrc001.PNF             ← Pre-compiled INF (speeds up install)
    └── Amd64/                   ← 64-bit driver binaries
        ├── RIA1515.GPD          ← Ricoh Aficio 1515 printer description
        ├── RIAFRES.DLL          ← Ricoh resource DLL
        ├── RIAFUI1.DLL          ← Ricoh UI DLL
        ├── RIAFRES1.INI         ← Resource configuration
        ├── RICONFIG.XML         ← Printer config XML
        ├── UNIDRV.DLL           ← Windows Universal Printer Driver
        ├── UNIDRVUI.DLL         ← Universal Driver UI
        ├── UNIDRV.HLP           ← Driver help file
        └── ...                  ← Additional Ricoh model GPD/PPD files
```

---

## 🌐 Network vs USB Setup

### Network Printer

The Ricoh must have a **static IP** or a **DHCP reservation** on your router.

| Setting | Value |
|---------|-------|
| Default IP | `192.168.0.50` |
| Protocol | Standard TCP/IP (Port 9100) |
| Printer name added | `Ricoh Aficio 1515 PCL (Network)` |

To find your Ricoh's IP:
- Print a **configuration page** from the printer's menu
- Or check your **router's DHCP table**
- Or use `ping ricoh-aficio` if your network uses hostname resolution

---

### USB Printer

When using USB, the script lists all detected USB printer ports:

```
  Detected USB ports:
    - USB001
    - USB006
    - USB009

  Enter USB port name to use (e.g. USB001): USB009
```

> 💡 If multiple USB ports appear, try `USB009` first — it's typically the last connected device.

---

## 🔧 Troubleshooting

| Problem | Solution |
|---------|----------|
| `"Run as administrator"` keeps appearing | Right-click `SETUP.bat` → **Run as administrator** |
| `Driver INF not found` | Make sure `drivers/` folder is in the **same directory** as `SETUP.bat` |
| `pnputil` fails | Try rebooting, then running setup again |
| Printer added but won't print (network) | Ping the printer IP: `ping 192.168.0.50` — if it fails, check the IP |
| USB port not detected | Plug Ricoh into USB **before** running setup, then run again |
| Print Spooler won't start | Open `services.msc` → find **Print Spooler** → right-click → Start |
| Windows blocks the script | Right-click `Install-RicohPrinter.ps1` → Properties → **Unblock** |

---

## 🤝 Contributing

Pull requests are welcome! If you have improvements, fixes, or want to add support for more Ricoh models:

1. Fork the repo
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m "Add: description"`
4. Push and open a PR

---

## 📄 License

MIT License — free to use, modify, and distribute.

---

*Driver source: Windows 10/11 built-in Ricoh PCL driver (`prnrc001.inf`)*  
*Tested on: Windows 10 22H2, Windows 11 23H2*  
*Printer: Ricoh Aficio 1515 — Network IP `192.168.0.50`, USB*
