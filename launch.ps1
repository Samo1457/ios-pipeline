# launch.ps1
# USAGE: cd ios-pipeline ; .\launch.ps1

$ErrorActionPreference = "Continue"

Clear-Host
Write-Host ""
Write-Host "  =================================================" -ForegroundColor Cyan
Write-Host "   iOS App Automation Pipeline" -ForegroundColor Cyan
Write-Host "   Windows + Flutter + Claude Code + VS Code" -ForegroundColor Cyan
Write-Host "  =================================================" -ForegroundColor Cyan
Write-Host ""

# === STEP 0 - Interactive config ===
Write-Host "--- Configuration du projet ---" -ForegroundColor Yellow
Write-Host ""

# App name (obligatoire)
$AppName = ""
while ([string]::IsNullOrWhiteSpace($AppName)) {
    $AppName = Read-Host "  Nom de l'app (ex: sleep-tracker)"
    if ([string]::IsNullOrWhiteSpace($AppName)) {
        Write-Host "  Le nom est obligatoire" -ForegroundColor Red
    }
}

# Project path
$defaultDir = "$env:USERPROFILE\Projects\ios-apps\$AppName"
Write-Host ""
Write-Host "  Dossier du projet" -ForegroundColor White
Write-Host "  Defaut: $defaultDir" -ForegroundColor DarkGray
$customDir = Read-Host "  Chemin (Entree = defaut)"
if ([string]::IsNullOrWhiteSpace($customDir)) {
    $projectPath = $defaultDir
} else {
    $projectPath = $customDir
}

# Bundle org
Write-Host ""
Write-Host "  Bundle ID organisation" -ForegroundColor White
Write-Host "  Defaut: com.samo" -ForegroundColor DarkGray
$customOrg = Read-Host "  Org (Entree = com.samo)"
if ([string]::IsNullOrWhiteSpace($customOrg)) {
    $BundleOrg = "com.samo"
} else {
    $BundleOrg = $customOrg
}

# Category (optional)
Write-Host ""
Write-Host "  Categorie de recherche (optionnel)" -ForegroundColor White
Write-Host "  Ex: health, productivity, finance, utilities" -ForegroundColor DarkGray
$Category = Read-Host "  Categorie (Entree = skip)"

# Flutter create
Write-Host ""
Write-Host "  Creer le projet Flutter maintenant ?" -ForegroundColor White
$doFlutterRaw = Read-Host "  (o/n, Entree = o)"
if ([string]::IsNullOrWhiteSpace($doFlutterRaw)) { $doFlutter = "o" } else { $doFlutter = $doFlutterRaw }

# Safe flutter name
$safeName = $AppName -replace '-', '_' -replace '[^\w]', ''

# Recap
Write-Host ""
Write-Host "  -----------------------------------------" -ForegroundColor White
Write-Host "  App:       $AppName" -ForegroundColor White
Write-Host "  Bundle:    $BundleOrg.$safeName" -ForegroundColor White
Write-Host "  Dossier:   $projectPath" -ForegroundColor White
if ([string]::IsNullOrWhiteSpace($Category)) {
    Write-Host "  Categorie: (skip)" -ForegroundColor White
} else {
    Write-Host "  Categorie: $Category" -ForegroundColor White
}
if ($doFlutter -eq "o") {
    Write-Host "  Flutter:   oui" -ForegroundColor White
} else {
    Write-Host "  Flutter:   non" -ForegroundColor White
}
Write-Host "  -----------------------------------------" -ForegroundColor White
Write-Host ""

$confirm = Read-Host "  On lance ? (o/n)"
if ($confirm -ne "o") {
    Write-Host "  Annule." -ForegroundColor Yellow
    exit 0
}

Write-Host ""

# === STEP 1 - Dependencies ===
Write-Host "--- 1/8  Dependances ---" -ForegroundColor Yellow

$hasNode = $false
try { node --version 2>$null | Out-Null; $hasNode = $true; Write-Host "  OK  Node.js" -ForegroundColor Green } catch {}
if (-not $hasNode) { Write-Host "  MANQUANT Node.js -> https://nodejs.org" -ForegroundColor Red; exit 1 }

try { git --version 2>$null | Out-Null; Write-Host "  OK  Git" -ForegroundColor Green }
catch { Write-Host "  MANQUANT Git -> https://git-scm.com" -ForegroundColor Red; exit 1 }

$hasFlutter = $false
try { flutter --version 2>$null | Out-Null; $hasFlutter = $true; Write-Host "  OK  Flutter" -ForegroundColor Green } catch {}
if (-not $hasFlutter) { Write-Host "  WARN Flutter non installe -> https://docs.flutter.dev/get-started/install/windows" -ForegroundColor Yellow }

$hasCode = $false
try { code --version 2>$null | Out-Null; $hasCode = $true; Write-Host "  OK  VS Code" -ForegroundColor Green }
catch { Write-Host "  WARN VS Code non trouve -> https://code.visualstudio.com" -ForegroundColor Yellow }

try { claude --version 2>$null | Out-Null; Write-Host "  OK  Claude Code" -ForegroundColor Green }
catch {
    Write-Host "  Installation Claude Code..." -ForegroundColor Gray
    npm install -g @anthropic-ai/claude-code 2>$null
    Write-Host "  OK  Claude Code installe" -ForegroundColor Green
}

try { playwright-cli --version 2>$null | Out-Null; Write-Host "  OK  Playwright CLI" -ForegroundColor Green }
catch {
    Write-Host "  Installation Playwright CLI..." -ForegroundColor Gray
    npm install -g "@playwright/cli@latest" 2>$null
    playwright-cli install-browser 2>$null
    Write-Host "  OK  Playwright CLI installe" -ForegroundColor Green
}

Write-Host ""

# === STEP 2 - Create project ===
Write-Host "--- 2/8  Creation du projet ---" -ForegroundColor Yellow

$scaffoldSource = Get-Location

if (Test-Path $projectPath) {
    Write-Host "  WARN $projectPath existe deja" -ForegroundColor Yellow
    $ow = Read-Host "  Ecraser ? (o/n)"
    if ($ow -eq "o") {
        Remove-Item -Path $projectPath -Recurse -Force
    }
}

if (-not (Test-Path $projectPath)) {
    New-Item -ItemType Directory -Path $projectPath -Force | Out-Null
}

$filesToCopy = @("SKILL.md", "CLAUDE.md", "experience.md", "codemagic.yaml", ".gitignore")
foreach ($f in $filesToCopy) {
    $src = Join-Path $scaffoldSource $f
    if (Test-Path $src) { Copy-Item $src -Destination $projectPath -Force }
}

$dirsToCopy = @("scripts", "docs", "screenshots", "verification", "research")
foreach ($d in $dirsToCopy) {
    $src = Join-Path $scaffoldSource $d
    $dst = Join-Path $projectPath $d
    if (Test-Path $src) {
        Copy-Item $src -Destination $dst -Recurse -Force
    } else {
        New-Item -ItemType Directory -Path $dst -Force | Out-Null
    }
}

$screenshotDirs = @("screenshots\appstore", "screenshots\debug", "screenshots\test")
foreach ($sd in $screenshotDirs) {
    $d = Join-Path $projectPath $sd
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

Set-Location $projectPath
Write-Host "  OK  Projet cree: $projectPath" -ForegroundColor Green
Write-Host ""

# === STEP 3 - Flutter create ===
Write-Host "--- 3/8  Flutter ---" -ForegroundColor Yellow

if ($doFlutter -eq "o" -and $hasFlutter -and (-not (Test-Path "pubspec.yaml"))) {
    flutter create --org $BundleOrg --project-name $safeName . 2>$null
    Write-Host "  OK  flutter create ($BundleOrg.$safeName)" -ForegroundColor Green
} elseif (Test-Path "pubspec.yaml") {
    Write-Host "  SKIP pubspec.yaml existe deja" -ForegroundColor Gray
} elseif ($doFlutter -ne "o") {
    Write-Host "  SKIP choix utilisateur" -ForegroundColor Gray
} else {
    Write-Host "  SKIP Flutter non installe" -ForegroundColor Yellow
}

Write-Host ""

# === STEP 4 - Skills ===
Write-Host "--- 4/8  Skills IA ---" -ForegroundColor Yellow

Write-Host "  Installation App Store Preflight..." -ForegroundColor Gray
npx skills add truongduy2611/app-store-preflight-skills 2>$null
Write-Host "  OK  Preflight (100+ Apple rejection rules)" -ForegroundColor Green

Write-Host "  Installation Playwright skills..." -ForegroundColor Gray
playwright-cli install --skills 2>$null
Write-Host "  OK  Playwright skills" -ForegroundColor Green

Write-Host "  INFO Axiom -> dans Claude Code: /plugin marketplace add CharlesWiltgen/Axiom" -ForegroundColor DarkGray
Write-Host ""

# === STEP 5 - Codemagic config ===
Write-Host "--- 5/8  Config Codemagic ---" -ForegroundColor Yellow

if (Test-Path "codemagic.yaml") {
    $content = Get-Content "codemagic.yaml" -Raw
    $content = $content -replace 'com\.YOURORG\.APP_NAME', "$BundleOrg.$safeName"
    $content = $content -replace 'APP_NAME: "APP_NAME"', "APP_NAME: `"$safeName`""
    $content | Set-Content "codemagic.yaml" -Encoding UTF8
    Write-Host "  OK  codemagic.yaml -> $BundleOrg.$safeName" -ForegroundColor Green
} else {
    Write-Host "  SKIP codemagic.yaml non trouve" -ForegroundColor Gray
}

Write-Host ""

# === STEP 6 - Git ===
Write-Host "--- 6/8  Git ---" -ForegroundColor Yellow

if (Test-Path ".git") { Remove-Item -Path ".git" -Recurse -Force 2>$null }
git init 2>$null | Out-Null
git add -A 2>$null
git commit -m "feat: $AppName initial scaffold" 2>$null | Out-Null
Write-Host "  OK  Git init + premier commit" -ForegroundColor Green
Write-Host ""

# === STEP 7 - VS Code ===
Write-Host "--- 7/8  VS Code ---" -ForegroundColor Yellow

if ($hasCode) {
    code $projectPath 2>$null
    Write-Host "  OK  VS Code ouvert" -ForegroundColor Green
} else {
    Write-Host "  WARN Ouvre manuellement: $projectPath" -ForegroundColor Yellow
}

Write-Host ""

# === STEP 8 - Claude Code prompt ===
Write-Host "--- 8/8  Prompt Claude Code ---" -ForegroundColor Yellow

$promptLines = @(
    "read @SKILL.md",
    "read @CLAUDE.md",
    "read @experience.md"
)

if (-not [string]::IsNullOrWhiteSpace($Category)) {
    $promptLines += ""
    $promptLines += "Start research phase for category `"$Category`". Find at least 5 shippable iOS app ideas. Use Playwright CLI for Google Trends and Reddit validation. Use iTunes Search API for saturation check. Score each idea (Demand x Saturation x Feasibility) and present the top 5 ranked."
}

$promptLines -join "`n" | Set-Content -Path ".claude-init.md" -Encoding UTF8
Write-Host "  OK  Prompt sauvegarde dans .claude-init.md" -ForegroundColor Green
Write-Host ""

# === DONE ===
Write-Host "  =================================================" -ForegroundColor Green
Write-Host "                   C'EST PRET !" -ForegroundColor Green
Write-Host "  =================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Dossier: $projectPath" -ForegroundColor White
Write-Host "  Bundle:  $BundleOrg.$safeName" -ForegroundColor White
Write-Host ""
Write-Host "  Dans le terminal VS Code:" -ForegroundColor White
Write-Host ""
Write-Host "    claude" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Puis:" -ForegroundColor White
Write-Host "    read @SKILL.md" -ForegroundColor Cyan
Write-Host "    read @CLAUDE.md" -ForegroundColor Cyan
Write-Host "    read @experience.md" -ForegroundColor Cyan

if (-not [string]::IsNullOrWhiteSpace($Category)) {
    Write-Host "    Start research phase for `"$Category`"" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "  Premiere fois seulement:" -ForegroundColor White
Write-Host "    /plugin marketplace add CharlesWiltgen/Axiom" -ForegroundColor DarkGray
Write-Host ""
