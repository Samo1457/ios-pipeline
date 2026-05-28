# launch.ps1 — LE script unique qui fait TOUT
# ══════════════════════════════════════════════════════════════════
#
#  USAGE :
#
#    git clone https://github.com/Samo1457/ios-pipeline.git && cd ios-pipeline && .\launch.ps1
#
# ══════════════════════════════════════════════════════════════════

$ErrorActionPreference = "Continue"

# ─── Banner ───
Write-Host @"

  ╔═══════════════════════════════════════════════════════════╗
  ║                                                           ║
  ║   🚀  iOS App Automation Pipeline                        ║
  ║       Windows + Flutter + Claude Code + VS Code           ║
  ║                                                           ║
  ╚═══════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

# ══════════════════════════════════════════════════════════════
# STEP 0 — Interactive config
# ══════════════════════════════════════════════════════════════

Write-Host "═══ Configuration du projet ═══`n" -ForegroundColor Yellow

# App name
$AppName = ""
while ([string]::IsNullOrWhiteSpace($AppName)) {
    $AppName = Read-Host "  📱 Nom de l'app (ex: sleep-tracker)"
    if ([string]::IsNullOrWhiteSpace($AppName)) {
        Write-Host "     ❌ Le nom est obligatoire`n" -ForegroundColor Red
    }
}

# Project path
$defaultDir = "$env:USERPROFILE\Projects\ios-apps\$AppName"
Write-Host "`n  📁 Dossier du projet" -ForegroundColor White
Write-Host "     Par défaut: $defaultDir" -ForegroundColor DarkGray
$customDir = Read-Host "     Chemin (Entrée = défaut, ou tape un chemin)"
if ([string]::IsNullOrWhiteSpace($customDir)) {
    $projectPath = $defaultDir
} else {
    $projectPath = $customDir
}

# Bundle org
$defaultOrg = "com.samo"
Write-Host "`n  🏷️  Bundle ID organisation" -ForegroundColor White
Write-Host "     Par défaut: $defaultOrg" -ForegroundColor DarkGray
$customOrg = Read-Host "     Org (Entrée = défaut, ou tape ex: com.monnom)"
if ([string]::IsNullOrWhiteSpace($customOrg)) {
    $BundleOrg = $defaultOrg
} else {
    $BundleOrg = $customOrg
}

# Category (optional)
Write-Host "`n  🔍 Catégorie pour la recherche d'idée (optionnel)" -ForegroundColor White
Write-Host "     Ex: health, productivity, finance, utilities" -ForegroundColor DarkGray
$Category = Read-Host "     Catégorie (Entrée = skip)"

# Flutter create
Write-Host "`n  📦 Créer le projet Flutter maintenant ?" -ForegroundColor White
Write-Host "     Si tu as déjà un projet Flutter, tape 'n'" -ForegroundColor DarkGray
$doFlutter = Read-Host "     Créer ? (o/n, défaut: o)"
if ([string]::IsNullOrWhiteSpace($doFlutter)) { $doFlutter = "o" }

$safeName = $AppName -replace '-', '_' -replace '[^\w]', ''

# ─── Recap ───
Write-Host @"

  ┌─────────────────────────────────────────────┐
  │  Récap                                       │
  │  App:       $AppName
  │  Bundle:    $BundleOrg.$safeName
  │  Dossier:   $projectPath
  │  Catégorie: $(if ($Category) { $Category } else { "(skip)" })
  │  Flutter:   $(if ($doFlutter -eq "o") { "oui" } else { "non" })
  └─────────────────────────────────────────────┘
"@ -ForegroundColor White

$confirm = Read-Host "  ▶️  On lance ? (o/n)"
if ($confirm -ne "o") {
    Write-Host "`n  Annulé.`n" -ForegroundColor Yellow
    exit 0
}

Write-Host ""

# ══════════════════════════════════════════════════════════════
# 1. CHECK + INSTALL DEPENDENCIES
# ══════════════════════════════════════════════════════════════

Write-Host "═══ 1/8  Dépendances ═══" -ForegroundColor Yellow

# Node.js
$hasNode = $false
try { node --version 2>$null | Out-Null; $hasNode = $true; Write-Host "  ✅ Node.js" -ForegroundColor Green } catch {}
if (-not $hasNode) { Write-Host "  ❌ Node.js manquant → https://nodejs.org" -ForegroundColor Red; exit 1 }

# Git
try { git --version 2>$null | Out-Null; Write-Host "  ✅ Git" -ForegroundColor Green }
catch { Write-Host "  ❌ Git manquant → https://git-scm.com" -ForegroundColor Red; exit 1 }

# Flutter
$hasFlutter = $false
try { flutter --version 2>$null | Out-Null; $hasFlutter = $true; Write-Host "  ✅ Flutter" -ForegroundColor Green } catch {}
if (-not $hasFlutter) { Write-Host "  ⚠️  Flutter manquant → https://docs.flutter.dev/get-started/install/windows" -ForegroundColor Yellow }

# VS Code
$hasCode = $false
try { code --version 2>$null | Out-Null; $hasCode = $true; Write-Host "  ✅ VS Code" -ForegroundColor Green }
catch { Write-Host "  ⚠️  VS Code manquant → https://code.visualstudio.com" -ForegroundColor Yellow }

# Claude Code — auto-install
try { claude --version 2>$null | Out-Null; Write-Host "  ✅ Claude Code" -ForegroundColor Green }
catch {
    Write-Host "  📦 Installation de Claude Code..." -ForegroundColor Gray
    npm install -g @anthropic-ai/claude-code 2>$null
    Write-Host "  ✅ Claude Code installé" -ForegroundColor Green
}

# Playwright CLI — auto-install
try { playwright-cli --version 2>$null | Out-Null; Write-Host "  ✅ Playwright CLI" -ForegroundColor Green }
catch {
    Write-Host "  📦 Installation de Playwright CLI + navigateur..." -ForegroundColor Gray
    npm install -g @playwright/cli@latest 2>$null
    playwright-cli install-browser 2>$null
    Write-Host "  ✅ Playwright CLI installé" -ForegroundColor Green
}

Write-Host ""

# ══════════════════════════════════════════════════════════════
# 2. CREATE PROJECT DIRECTORY + COPY SCAFFOLD
# ══════════════════════════════════════════════════════════════

Write-Host "═══ 2/8  Création du projet ═══" -ForegroundColor Yellow

# Save current location (the cloned repo)
$scaffoldSource = Get-Location

if (Test-Path $projectPath) {
    Write-Host "  ⚠️  $projectPath existe déjà" -ForegroundColor Yellow
    $ow = Read-Host "  Écraser ? (o/n)"
    if ($ow -eq "o") { Remove-Item -Path $projectPath -Recurse -Force }
    else { Write-Host "  → On continue avec l'existant" -ForegroundColor Gray }
}

if (-not (Test-Path $projectPath)) {
    New-Item -ItemType Directory -Path $projectPath -Force | Out-Null
}

# Copy scaffold files to the new project
$filesToCopy = @(
    "SKILL.md", "CLAUDE.md", "experience.md", "codemagic.yaml", ".gitignore"
)
foreach ($f in $filesToCopy) {
    $src = Join-Path $scaffoldSource $f
    if (Test-Path $src) { Copy-Item $src -Destination $projectPath -Force }
}

# Copy directories
@("scripts", "docs", "screenshots", "verification", "research") | ForEach-Object {
    $src = Join-Path $scaffoldSource $_
    $dst = Join-Path $projectPath $_
    if (Test-Path $src) {
        Copy-Item $src -Destination $dst -Recurse -Force
    } else {
        New-Item -ItemType Directory -Path $dst -Force | Out-Null
    }
}

# Ensure screenshot subdirs exist
@("screenshots/appstore", "screenshots/debug", "screenshots/test") | ForEach-Object {
    $d = Join-Path $projectPath $_
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

Set-Location $projectPath
Write-Host "  ✅ Projet créé: $projectPath`n" -ForegroundColor Green

# ══════════════════════════════════════════════════════════════
# 3. FLUTTER CREATE
# ══════════════════════════════════════════════════════════════

Write-Host "═══ 3/8  Flutter ═══" -ForegroundColor Yellow

if ($doFlutter -eq "o" -and $hasFlutter -and -not (Test-Path "pubspec.yaml")) {
    flutter create --org $BundleOrg --project-name $safeName . 2>$null
    Write-Host "  ✅ flutter create ($BundleOrg.$safeName)`n" -ForegroundColor Green
} elseif (Test-Path "pubspec.yaml") {
    Write-Host "  ⏭️  pubspec.yaml existe déjà`n" -ForegroundColor Gray
} elseif ($doFlutter -ne "o") {
    Write-Host "  ⏭️  Skip (choix utilisateur)`n" -ForegroundColor Gray
} else {
    Write-Host "  ⏭️  Flutter non installé`n" -ForegroundColor Yellow
}

# ══════════════════════════════════════════════════════════════
# 4. INSTALL SKILLS
# ══════════════════════════════════════════════════════════════

Write-Host "═══ 4/8  Skills IA ═══" -ForegroundColor Yellow

Write-Host "  📦 App Store Preflight..." -ForegroundColor Gray
npx skills add truongduy2611/app-store-preflight-skills 2>$null
Write-Host "  ✅ Preflight (100+ Apple rejection rules)" -ForegroundColor Green

Write-Host "  📦 Playwright CLI skills..." -ForegroundColor Gray
playwright-cli install --skills 2>$null
Write-Host "  ✅ Playwright skills" -ForegroundColor Green

Write-Host "  ℹ️  Axiom → dans Claude Code: /plugin marketplace add CharlesWiltgen/Axiom`n" -ForegroundColor DarkGray

# ══════════════════════════════════════════════════════════════
# 5. UPDATE CODEMAGIC CONFIG
# ══════════════════════════════════════════════════════════════

Write-Host "═══ 5/8  Config Codemagic ═══" -ForegroundColor Yellow

if (Test-Path "codemagic.yaml") {
    (Get-Content "codemagic.yaml" -Raw) `
        -replace 'com\.YOURORG\.APP_NAME', "$BundleOrg.$safeName" `
        -replace 'APP_NAME: "APP_NAME"', "APP_NAME: `"$safeName`"" |
        Set-Content "codemagic.yaml" -Encoding UTF8
    Write-Host "  ✅ codemagic.yaml → $BundleOrg.$safeName`n" -ForegroundColor Green
} else {
    Write-Host "  ⏭️  Pas de codemagic.yaml`n" -ForegroundColor Gray
}

# ══════════════════════════════════════════════════════════════
# 6. GIT INIT
# ══════════════════════════════════════════════════════════════

Write-Host "═══ 6/8  Git ═══" -ForegroundColor Yellow

if (Test-Path ".git") { Remove-Item -Path ".git" -Recurse -Force 2>$null }
git init 2>$null | Out-Null
git add -A 2>$null
git commit -m "feat: $AppName — initial scaffold" 2>$null | Out-Null
Write-Host "  ✅ Git init + premier commit`n" -ForegroundColor Green

# ══════════════════════════════════════════════════════════════
# 7. OPEN VS CODE
# ══════════════════════════════════════════════════════════════

Write-Host "═══ 7/8  VS Code ═══" -ForegroundColor Yellow

if ($hasCode) {
    code $projectPath 2>$null
    Write-Host "  ✅ VS Code ouvert`n" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  VS Code non trouvé — ouvre le dossier manuellement: $projectPath`n" -ForegroundColor Yellow
}

# ══════════════════════════════════════════════════════════════
# 8. GENERATE CLAUDE CODE PROMPT
# ══════════════════════════════════════════════════════════════

Write-Host "═══ 8/8  Prompt Claude Code ═══" -ForegroundColor Yellow

$prompt = "read @SKILL.md`nread @CLAUDE.md`nread @experience.md"

if (-not [string]::IsNullOrWhiteSpace($Category)) {
    $prompt += "`n`nStart research phase for category `"$Category`". Find at least 5 shippable iOS app ideas. Use Playwright CLI for Google Trends and Reddit validation. Use iTunes Search API for App Store saturation check. Score each idea (Demand x Saturation x Feasibility) and present the top 5 ranked."
}

$prompt | Set-Content -Path ".claude-init.md" -Encoding UTF8

Write-Host @"

  ╔═══════════════════════════════════════════════════════════╗
  ║                                                           ║
  ║                    ✅ C'EST PRÊT !                       ║
  ║                                                           ║
  ╠═══════════════════════════════════════════════════════════╣
  ║                                                           ║
  ║  📁 $projectPath
  ║  📦 $BundleOrg.$safeName
  ║                                                           ║
  ║  Dans le terminal VS Code, tape :                         ║
  ║                                                           ║
  ║    claude                                                 ║
  ║                                                           ║
  ║  Puis :                                                   ║
  ║                                                           ║
  ║    read @SKILL.md                                         ║
  ║    read @CLAUDE.md                                        ║
  ║    read @experience.md                                    ║
"@ -ForegroundColor Green

if (-not [string]::IsNullOrWhiteSpace($Category)) {
    Write-Host "  ║                                                           ║" -ForegroundColor Green
    Write-Host "  ║    Start research phase for `"$Category`"" -ForegroundColor Green
}

Write-Host @"
  ║                                                           ║
  ║  Première fois seulement :                                ║
  ║    /plugin marketplace add CharlesWiltgen/Axiom           ║
  ║                                                           ║
  ╚═══════════════════════════════════════════════════════════╝

"@ -ForegroundColor Green
