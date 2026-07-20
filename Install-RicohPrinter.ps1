#Requires -RunAsAdministrator
#Requires -Version 5.1
<#
.SYNOPSIS
    Ricoh Aficio 1515 PCL - Printer Setup Script
.DESCRIPTION
    Installs the Ricoh Aficio 1515 PCL printer driver and sets up:
      - Network printer (TCP/IP port, custom or default IP: 192.168.0.50)
      - USB printer (if a USB Ricoh is connected)
    Compatible: Windows 10 / 11 (64-bit), PowerShell 5.1+
.VERSION
    1.2 (ASCII-clean, Windows 10 compliant)
#>

# --------------------------------------------------
#  CONFIG
# --------------------------------------------------
$DriverName     = "Ricoh Aficio 1515 PCL"
$DefaultIP      = "192.168.0.50"
$NetworkPrinter = "Ricoh Aficio 1515 PCL (Network)"
$USBPrinter     = "Ricoh Aficio 1515 PCL (USB)"

# Resolve script directory safely (works in PS 5.1 and PS 7+)
if ($PSScriptRoot) {
    $ScriptDir = $PSScriptRoot
} else {
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
}
$DriverFolder = Join-Path $ScriptDir "drivers"
$InfFile      = Join-Path $DriverFolder "prnrc001.inf"

# --------------------------------------------------
#  HELPERS
# --------------------------------------------------
function Write-Step { param([string]$msg) Write-Host "" ; Write-Host "[STEP] $msg" -ForegroundColor Cyan }
function Write-OK   { param([string]$msg) Write-Host "  [OK] $msg"  -ForegroundColor Green }
function Write-Warn { param([string]$msg) Write-Host "  [!!] $msg"  -ForegroundColor Yellow }
function Write-Fail { param([string]$msg) Write-Host " [ERR] $msg"  -ForegroundColor Red }

# --------------------------------------------------
#  BANNER
# --------------------------------------------------
Clear-Host
Write-Host ""
Write-Host "  ============================================================" -ForegroundColor Magenta
Write-Host "     Ricoh Aficio 1515 PCL - Printer Setup  (v1.2)          " -ForegroundColor Magenta
Write-Host "     Windows 10/11 Compatible Deployment Script              " -ForegroundColor Magenta
Write-Host "  ============================================================" -ForegroundColor Magenta
Write-Host ""

# --------------------------------------------------
#  CHECK: Windows 10 or higher
# --------------------------------------------------
Write-Step "Checking OS compatibility..."
$osVersion = [System.Environment]::OSVersion.Version

if ($osVersion.Major -lt 10) {
    Write-Fail "This script requires Windows 10 or higher."
    Write-Fail "Detected OS version: $($osVersion.ToString())"
    Read-Host "Press Enter to exit"
    exit 1
}

$osBuild = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuild
$friendlyName = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ProductName
Write-OK "OS: $friendlyName (Build $osBuild) - Compatible"

# --------------------------------------------------
#  CHECK: 64-bit architecture required
# --------------------------------------------------
if ([System.Environment]::Is64BitOperatingSystem -eq $false) {
    Write-Fail "These drivers are 64-bit only. 32-bit Windows is not supported."
    Read-Host "Press Enter to exit"
    exit 1
}
Write-OK "Architecture: 64-bit - Compatible"

# --------------------------------------------------
#  CHECK: Print Spooler running
# --------------------------------------------------
Write-Step "Checking Print Spooler service..."
$spooler = Get-Service -Name Spooler -ErrorAction SilentlyContinue
if (-not $spooler -or $spooler.Status -ne 'Running') {
    Write-Warn "Print Spooler is not running. Attempting to start it..."
    try {
        Start-Service -Name Spooler -ErrorAction Stop
        Write-OK "Print Spooler started."
    } catch {
        Write-Fail "Could not start Print Spooler: $($_.Exception.Message)"
        Write-Fail "Open services.msc and start 'Print Spooler' manually, then re-run this script."
        Read-Host "Press Enter to exit"
        exit 1
    }
} else {
    Write-OK "Print Spooler is running."
}

# --------------------------------------------------
#  STEP 0: Verify driver files
# --------------------------------------------------
Write-Step "Verifying driver files..."
if (-not (Test-Path $InfFile)) {
    Write-Fail "Driver INF not found at: $InfFile"
    Write-Fail "Make sure the 'drivers' folder is in the same directory as this script."
    Read-Host "Press Enter to exit"
    exit 1
}
Write-OK "Driver files found at: $DriverFolder"

# --------------------------------------------------
#  STEP 1: Choose setup mode
# --------------------------------------------------
Write-Step "Choose printer setup mode:"
Write-Host "  [1] Network printer (TCP/IP)  - Ricoh connected via LAN" -ForegroundColor White
Write-Host "  [2] USB printer               - Ricoh connected via USB cable" -ForegroundColor White
Write-Host "  [3] Both                      - Install both" -ForegroundColor White
Write-Host ""

$mode = ""
do {
    $mode = (Read-Host "  Enter choice (1/2/3)").Trim()
} while ($mode -ne "1" -and $mode -ne "2" -and $mode -ne "3")

# --------------------------------------------------
#  STEP 2: Ask for IP (network mode only)
# --------------------------------------------------
$PrinterIP = $DefaultIP
if ($mode -eq "1" -or $mode -eq "3") {
    Write-Step "Network printer IP configuration"
    Write-Host "  Default IP: $DefaultIP" -ForegroundColor White
    $customIP = (Read-Host "  Enter custom IP, or press Enter to use default [$DefaultIP]").Trim()

    if ($customIP -ne "") {
        if ($customIP -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') {
            $PrinterIP = $customIP
            Write-OK "Using IP: $PrinterIP"
        } else {
            Write-Warn "Invalid IP format. Falling back to default: $DefaultIP"
            $PrinterIP = $DefaultIP
        }
    } else {
        Write-OK "Using default IP: $PrinterIP"
    }
}

# --------------------------------------------------
#  STEP 3: Install driver via pnputil
#  pnputil /add-driver is supported on Windows 10+
#  Add-PrinterDriver -InfPath is unreliable on PS 5.1
#  so we stage via pnputil first, then register by name only
# --------------------------------------------------
Write-Step "Installing Ricoh printer driver..."

$driverInstalled = Get-PrinterDriver -Name $DriverName -ErrorAction SilentlyContinue
if ($driverInstalled) {
    Write-Warn "Driver '$DriverName' is already installed. Skipping driver install."
} else {
    Write-Host "  Staging driver with pnputil (this may take a moment)..." -ForegroundColor White
    $pnpOutput = & pnputil.exe /add-driver "$InfFile" /install 2>&1
    $pnpExit   = $LASTEXITCODE

    Write-Host "  pnputil output:" -ForegroundColor DarkGray
    $pnpOutput | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }

    if ($pnpExit -eq 0 -or $pnpExit -eq 259) {
        # Exit 259 = ERROR_NO_MORE_ITEMS means driver already staged - safe to continue
        Write-OK "Driver staged in Windows Driver Store."
    } else {
        Write-Warn "pnputil exit code: $pnpExit - will attempt fallback method."
    }

    # Register driver with the Windows print subsystem (by name, after pnputil staged it)
    try {
        Add-PrinterDriver -Name $DriverName -ErrorAction Stop
        Write-OK "Driver '$DriverName' added to print subsystem."
    } catch {
        Write-Warn "Add-PrinterDriver: $($_.Exception.Message)"
        Write-Warn "This may be OK if pnputil already registered it."
    }
}

# Verify driver is now available
$driverCheck = Get-PrinterDriver -Name $DriverName -ErrorAction SilentlyContinue
if (-not $driverCheck) {
    Write-Fail "Driver '$DriverName' is still not available after installation."
    Write-Fail "Try running the script again, or install the driver manually from the 'drivers' folder."
    Read-Host "Press Enter to exit"
    exit 1
}
Write-OK "Driver verified: '$DriverName'"

# --------------------------------------------------
#  STEP 4a: Setup Network Printer
# --------------------------------------------------
if ($mode -eq "1" -or $mode -eq "3") {
    Write-Step "Setting up Network Printer at $PrinterIP..."
    $portName = $PrinterIP

    # Create TCP/IP port if it does not already exist
    $existingPort = Get-PrinterPort -Name $portName -ErrorAction SilentlyContinue
    if (-not $existingPort) {
        try {
            Add-PrinterPort -Name $portName -PrinterHostAddress $portName -ErrorAction Stop
            Write-OK "TCP/IP port created: $portName"
        } catch {
            Write-Fail "Failed to create TCP/IP port: $($_.Exception.Message)"
        }
    } else {
        Write-Warn "Port '$portName' already exists. Reusing it."
    }

    # Check if the network printer already exists
    $existingNetPrinter = Get-Printer -Name $NetworkPrinter -ErrorAction SilentlyContinue
    $installNetwork = $true

    if ($existingNetPrinter) {
        Write-Warn "Printer '$NetworkPrinter' already exists."
        $overwrite = (Read-Host "  Remove and reinstall? (Y/N)").Trim().ToUpper()
        if ($overwrite -eq "Y") {
            Remove-Printer -Name $NetworkPrinter -ErrorAction SilentlyContinue
            Write-OK "Existing printer removed."
        } else {
            Write-Warn "Skipping network printer installation."
            $installNetwork = $false
        }
    }

    if ($installNetwork) {
        try {
            Add-Printer -Name $NetworkPrinter -DriverName $DriverName -PortName $portName -ErrorAction Stop
            Write-OK "Network printer added: '$NetworkPrinter'"
        } catch {
            Write-Fail "Failed to add network printer: $($_.Exception.Message)"
        }
    }
}

# --------------------------------------------------
#  STEP 4b: Setup USB Printer
# --------------------------------------------------
if ($mode -eq "2" -or $mode -eq "3") {
    Write-Step "Setting up USB Printer..."

    $usbPorts    = @(Get-PrinterPort | Where-Object { $_.Name -like "USB*" })
    $usbPortName = ""

    if ($usbPorts.Count -eq 0) {
        Write-Warn "No USB printer ports detected."
        Write-Warn "Make sure the Ricoh is plugged in and powered on, then try again."
        $usbPortName = (Read-Host "  Or enter USB port name manually (e.g. USB001), press Enter to skip").Trim()
    } else {
        Write-Host "  Detected USB ports:" -ForegroundColor White
        $usbPorts | ForEach-Object { Write-Host "    - $($_.Name)" -ForegroundColor White }
        $usbPortName = (Read-Host "  Enter USB port name to use (e.g. USB001)").Trim()
    }

    if ($usbPortName -ne "") {
        $portExists = Get-PrinterPort -Name $usbPortName -ErrorAction SilentlyContinue
        if (-not $portExists) {
            Write-Warn "Port '$usbPortName' not found. USB printer may not be connected."
        }

        $existingUSBPrinter = Get-Printer -Name $USBPrinter -ErrorAction SilentlyContinue
        $installUSB = $true

        if ($existingUSBPrinter) {
            Write-Warn "Printer '$USBPrinter' already exists."
            $overwrite = (Read-Host "  Remove and reinstall? (Y/N)").Trim().ToUpper()
            if ($overwrite -eq "Y") {
                Remove-Printer -Name $USBPrinter -ErrorAction SilentlyContinue
                Write-OK "Existing USB printer removed."
            } else {
                Write-Warn "Skipping USB printer installation."
                $installUSB = $false
            }
        }

        if ($installUSB) {
            try {
                Add-Printer -Name $USBPrinter -DriverName $DriverName -PortName $usbPortName -ErrorAction Stop
                Write-OK "USB printer added: '$USBPrinter'"
            } catch {
                Write-Fail "Failed to add USB printer: $($_.Exception.Message)"
            }
        }
    } else {
        Write-Warn "No USB port selected. Skipping USB printer setup."
    }
}

# --------------------------------------------------
#  STEP 5: Summary
# --------------------------------------------------
Write-Host ""
Write-Host "  ============================================================" -ForegroundColor Magenta
Write-Host "                    Setup Complete!                           " -ForegroundColor Green
Write-Host "  ============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Installed Ricoh Printers:" -ForegroundColor White

$ricohPrinters = @(Get-Printer | Where-Object { $_.Name -like "*Ricoh*" })
if ($ricohPrinters.Count -gt 0) {
    $ricohPrinters | Format-Table Name, PortName, DriverName -AutoSize
} else {
    Write-Warn "No Ricoh printers found. Please check errors above."
}

Write-Host ""
Read-Host "Press Enter to exit"
