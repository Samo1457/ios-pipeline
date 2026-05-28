# appstore_upload.ps1 — Phase 5.5: App Store Connect Automation
# Uses: Playwright CLI for browser automation
# Usage: .\scripts\appstore_upload.ps1 -AppName "MyApp" -BundleId "com.org.myapp"

param(
    [Parameter(Mandatory=$true)]
    [string]$AppName,

    [Parameter(Mandatory=$true)]
    [string]$BundleId,

    [string]$Subtitle = "",
    [string]$Description = "",
    [string]$Keywords = "",
    [string]$Category = "Utilities",
    [string]$PrivacyUrl = "",
    [string]$SupportUrl = "",
    [string]$Price = "Free",
    [string]$ScreenshotsDir = ".\screenshots\appstore",
    [string]$AuthFile = ".\appstore_auth.json",
    [string]$VerificationDir = ".\verification"
)

# --- Setup ---
if (-not (Test-Path $VerificationDir)) {
    New-Item -ItemType Directory -Path $VerificationDir -Force | Out-Null
}

Write-Host "`n🍎 PHASE 5.5 — App Store Connect Automation" -ForegroundColor Cyan
Write-Host "   App: $AppName ($BundleId)" -ForegroundColor Gray
Write-Host "=" * 55

# --- Step 1: Load authentication ---
Write-Host "`n🔐 Étape 1: Chargement de la session" -ForegroundColor Yellow

if (Test-Path $AuthFile) {
    playwright-cli state-load $AuthFile 2>$null
    Write-Host "  ✅ Session chargée depuis $AuthFile" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  Pas de session sauvegardée. Connexion manuelle requise." -ForegroundColor Red
    Write-Host "  → Connecte-toi dans le navigateur qui va s'ouvrir (2FA)" -ForegroundColor Yellow
    playwright-cli open "https://appstoreconnect.apple.com" --headed 2>$null

    Read-Host "  Appuie ENTRÉE après t'être connecté"

    playwright-cli state-save $AuthFile 2>$null
    Write-Host "  ✅ Session sauvegardée dans $AuthFile" -ForegroundColor Green
}

# --- Step 2: Navigate to App Store Connect ---
Write-Host "`n📱 Étape 2: Navigation vers App Store Connect" -ForegroundColor Yellow

playwright-cli goto "https://appstoreconnect.apple.com/apps" 2>$null
Start-Sleep -Seconds 3

$snapshot = playwright-cli snapshot 2>&1

# Check if we're actually logged in
if ($snapshot -match "Sign In" -or $snapshot -match "Apple ID") {
    Write-Host "  ⚠️  Session expirée. Reconnexion nécessaire." -ForegroundColor Red
    Write-Host "  → Connecte-toi dans le navigateur (2FA)" -ForegroundColor Yellow
    Read-Host "  Appuie ENTRÉE après t'être connecté"
    playwright-cli state-save $AuthFile 2>$null
    playwright-cli goto "https://appstoreconnect.apple.com/apps" 2>$null
    Start-Sleep -Seconds 3
}

Write-Host "  ✅ Connecté à App Store Connect" -ForegroundColor Green

# --- Step 3: Create new app ---
Write-Host "`n➕ Étape 3: Création de la nouvelle app" -ForegroundColor Yellow

playwright-cli snapshot 2>$null
Write-Host "  → Cherche le bouton '+' ou 'New App'..." -ForegroundColor Gray

# The agent (Claude Code) takes over here:
# It reads the snapshot, identifies refs, and fills fields.
# This script provides the template; Claude Code adapts to actual refs.

Write-Host @"

  ┌─────────────────────────────────────────────────┐
  │  INSTRUCTIONS POUR CLAUDE CODE                  │
  │                                                 │
  │  À partir d'ici, Claude Code prend le relais.   │
  │  Utilise playwright-cli snapshot pour identifier │
  │  les refs de chaque champ, puis :               │
  │                                                 │
  │  1. Clique "+" ou "New App"                     │
  │  2. Remplis :                                   │
  │     - Platform: iOS                             │
  │     - Name: $AppName
  │     - Subtitle: $Subtitle
  │     - Bundle ID: $BundleId
  │     - SKU: $($BundleId -replace '\.', '_')
  │     - Primary Language: French                  │
  │     - Category: $Category
  │  3. Clique "Create"                             │
  │  4. Remplis la description :                    │
  │     "$($Description.Substring(0, [Math]::Min(50, $Description.Length)))..."
  │  5. Keywords: $Keywords
  │  6. Privacy URL: $PrivacyUrl
  │  7. Support URL: $SupportUrl
  │  8. Upload screenshots depuis :                 │
  │     $ScreenshotsDir
  │  9. Set price: $Price
  │  10. Complete age rating (all "None")           │
  │  11. Screenshot de vérification :               │
  │      playwright-cli screenshot                  │
  │      $VerificationDir\listing_complete.png      │
  │                                                 │
  │  ⛔ NE PAS cliquer "Submit for Review"          │
  └─────────────────────────────────────────────────┘

"@ -ForegroundColor White

# --- Step 4: Upload screenshots ---
if (Test-Path $ScreenshotsDir) {
    $screenshots = Get-ChildItem -Path $ScreenshotsDir -Filter "*.png" | Sort-Object Name
    Write-Host "`n📸 Étape 4: Screenshots trouvés ($($screenshots.Count))" -ForegroundColor Yellow
    foreach ($s in $screenshots) {
        Write-Host "  - $($s.Name)" -ForegroundColor Gray
    }
    Write-Host "  → Claude Code uploade chaque fichier via:" -ForegroundColor Gray
    Write-Host "    playwright-cli upload $ScreenshotsDir\<filename>" -ForegroundColor DarkGray
} else {
    Write-Host "`n⚠️  Dossier screenshots non trouvé: $ScreenshotsDir" -ForegroundColor Red
    Write-Host "  → Exécute d'abord la Phase 4 (Codemagic screenshots)" -ForegroundColor Yellow
}

# --- Step 5: Verification ---
Write-Host "`n✅ Étape 5: Vérification" -ForegroundColor Yellow
Write-Host "  Après que Claude Code a tout rempli :" -ForegroundColor Gray
Write-Host "  1. Vérifie le screenshot: $VerificationDir\listing_complete.png" -ForegroundColor Gray
Write-Host "  2. Ouvre App Store Connect dans ton navigateur" -ForegroundColor Gray
Write-Host "  3. Vérifie chaque champ manuellement" -ForegroundColor Gray
Write-Host "  4. Clique 'Submit for Review' quand tout est OK" -ForegroundColor Gray

Write-Host "`n🎯 Script terminé. Claude Code prend le relais pour remplir les champs.`n" -ForegroundColor Cyan
