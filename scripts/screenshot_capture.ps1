# screenshot_capture.ps1 — iPhone Screenshot Capture via USB
# Requires: IosScreenCaptureTool OR pymobiledevice3
# Usage: .\scripts\screenshot_capture.ps1 -Mode auto
# Usage: .\scripts\screenshot_capture.ps1 -Mode guided -Screens "home,settings,profile,detail"

param(
    [ValidateSet("auto", "guided", "single")]
    [string]$Mode = "guided",

    [string]$Screens = "",

    [string]$OutputDir = ".\screenshots\debug",

    [ValidateSet("iosscreencapture", "pymobiledevice3")]
    [string]$Tool = "iosscreencapture"
)

# --- Create output directory ---
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# --- Capture function ---
function Take-Screenshot {
    param([string]$Name)

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $filename = "${Name}_${timestamp}.png"
    $filepath = Join-Path $OutputDir $filename

    if ($Tool -eq "iosscreencapture") {
        # IosScreenCaptureTool method
        $result = & .\IosScreenCaptureTool.exe --capture-frame $filepath
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ Captured: $filename" -ForegroundColor Green
            return $filepath
        } else {
            Write-Host "  ❌ Capture failed. Is the iPhone connected and unlocked?" -ForegroundColor Red
            return $null
        }
    } else {
        # pymobiledevice3 method
        try {
            pymobiledevice3 developer dvt screenshot $filepath
            Write-Host "  ✅ Captured: $filename" -ForegroundColor Green
            return $filepath
        } catch {
            Write-Host "  ❌ Capture failed: $_" -ForegroundColor Red
            return $null
        }
    }
}

# --- Main ---
Write-Host "`n📱 iPhone Screenshot Capture" -ForegroundColor Cyan
Write-Host "   Tool: $Tool | Mode: $Mode | Output: $OutputDir" -ForegroundColor Gray
Write-Host "=" * 50

switch ($Mode) {
    "single" {
        Write-Host "`n📸 Capturing single screenshot..." -ForegroundColor Yellow
        $path = Take-Screenshot -Name "screenshot"
        if ($path) {
            Write-Host "`n   File: $path" -ForegroundColor White
        }
    }

    "guided" {
        if ([string]::IsNullOrEmpty($Screens)) {
            Write-Host "`n⚠️  Specify screens: -Screens 'home,settings,profile'" -ForegroundColor Red
            exit 1
        }

        $screenList = $Screens -split ","
        $captured = @()
        $i = 1

        foreach ($screen in $screenList) {
            $screen = $screen.Trim()
            $paddedNum = $i.ToString("D2")

            Write-Host "`n➡️  [$i/$($screenList.Count)] Navigate to '$screen' on your iPhone" -ForegroundColor Yellow
            Write-Host "   Press ENTER when ready (or 'skip' to skip, 'quit' to stop)..." -ForegroundColor Gray

            $input = Read-Host

            if ($input -eq "quit") {
                Write-Host "   Stopped by user." -ForegroundColor Yellow
                break
            }
            if ($input -eq "skip") {
                Write-Host "   Skipped." -ForegroundColor Yellow
                $i++
                continue
            }

            # Small delay for animations to finish
            Start-Sleep -Milliseconds 500

            $path = Take-Screenshot -Name "${paddedNum}_${screen}"
            if ($path) { $captured += $path }

            $i++
        }

        Write-Host "`n🎉 Done! Captured $($captured.Count)/$($screenList.Count) screenshots" -ForegroundColor Green
        Write-Host "   Location: $OutputDir`n" -ForegroundColor White
    }

    "auto" {
        Write-Host "`n🔄 Auto mode: capturing every 3 seconds" -ForegroundColor Yellow
        Write-Host "   Navigate through your app. Press Ctrl+C to stop.`n" -ForegroundColor Gray

        $count = 1
        try {
            while ($true) {
                $paddedNum = $count.ToString("D3")
                Take-Screenshot -Name "auto_${paddedNum}"
                $count++
                Start-Sleep -Seconds 3
            }
        } catch {
            Write-Host "`n   Stopped. Captured $($count - 1) screenshots." -ForegroundColor Yellow
        }
    }
}
