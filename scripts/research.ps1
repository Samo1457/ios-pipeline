# research.ps1 — Phase 1: App Idea Research Automation
# Uses: Playwright CLI (browser automation) + iTunes Search API
# Usage: .\scripts\research.ps1 -Category "health"

param(
    [Parameter(Mandatory=$true)]
    [string]$Category,

    [int]$MaxResults = 25,

    [switch]$SkipReddit
)

$stems = @(
    "$Category app for",
    "$Category tracker",
    "$Category app that",
    "best $Category app",
    "$Category reminder",
    "$Category calculator",
    "$Category log",
    "$Category helper"
)

$results = @()

Write-Host "`n🔍 PHASE 1 — Recherche d'idées pour la catégorie: $Category" -ForegroundColor Cyan
Write-Host "=" * 60

# --- Step 1: Google Autosuggest (API, no browser needed) ---
Write-Host "`n📊 Étape 1: Google Autosuggest" -ForegroundColor Yellow

foreach ($stem in $stems) {
    Write-Host "  Querying: '$stem'" -ForegroundColor Gray
    try {
        $encoded = [System.Web.HttpUtility]::UrlEncode($stem)
        $url = "https://suggestqueries.google.com/complete/search?client=firefox&q=$encoded"
        $response = Invoke-RestMethod -Uri $url -Method Get
        $suggestions = $response[1]

        foreach ($suggestion in $suggestions) {
            if ($suggestion -ne $stem) {
                $results += [PSCustomObject]@{
                    Stem       = $stem
                    Suggestion = $suggestion
                    Saturation = $null
                    Score      = $null
                    RedditHits = 0
                }
            }
        }
    } catch {
        Write-Host "    ⚠️  Erreur: $_" -ForegroundColor Red
    }
}

Write-Host "  ✅ $($results.Count) suggestions trouvées" -ForegroundColor Green

# --- Step 2: iTunes Search API (saturation check) ---
Write-Host "`n📱 Étape 2: Vérification saturation App Store" -ForegroundColor Yellow

foreach ($result in $results) {
    $query = $result.Suggestion -replace '\s+', '+'
    $url = "https://itunes.apple.com/search?term=$query&entity=software&limit=$MaxResults&country=fr"

    try {
        $response = Invoke-RestMethod -Uri $url -Method Get
        $count = $response.resultCount
        $result.Saturation = $count

        if ($count -lt 5)       { $result.Score = 5 }
        elseif ($count -lt 10)  { $result.Score = 4 }
        elseif ($count -lt 15)  { $result.Score = 3 }
        elseif ($count -lt 20)  { $result.Score = 2 }
        else                    { $result.Score = 1 }

        Write-Host "  $($result.Suggestion): $count apps (score: $($result.Score))" -ForegroundColor Gray
    } catch {
        Write-Host "    ⚠️  iTunes API error for '$($result.Suggestion)'" -ForegroundColor Red
        $result.Score = 0
    }

    Start-Sleep -Milliseconds 300
}

# --- Step 3: Reddit demand check via Playwright CLI ---
if (-not $SkipReddit) {
    Write-Host "`n🔎 Étape 3: Validation Reddit via Playwright CLI" -ForegroundColor Yellow

    $topIdeas = $results | Where-Object { $_.Score -ge 3 } | Sort-Object Score -Descending | Select-Object -First 10

    if ($topIdeas.Count -gt 0) {
        Write-Host "  Lancement du navigateur..." -ForegroundColor Gray
        playwright-cli open "https://www.reddit.com" --headed 2>$null

        foreach ($idea in $topIdeas) {
            $searchQuery = ($idea.Suggestion -replace '\s+', '+') + "+app+iphone"
            $redditUrl = "https://www.reddit.com/search/?q=$searchQuery&type=link&sort=new"

            Write-Host "  Checking Reddit: $($idea.Suggestion)" -ForegroundColor Gray

            try {
                playwright-cli goto $redditUrl 2>$null
                Start-Sleep -Seconds 2

                $snapshot = playwright-cli snapshot 2>&1

                # Count demand signals in snapshot
                $demandPhrases = @("wish there was", "looking for", "any app that", "need an app", "recommend", "alternative")
                $hits = 0
                foreach ($phrase in $demandPhrases) {
                    if ($snapshot -match $phrase) { $hits++ }
                }
                $idea.RedditHits = $hits

                if ($hits -gt 0) {
                    Write-Host "    ✅ $hits demand signal(s) found" -ForegroundColor Green
                } else {
                    Write-Host "    ⚪ No strong signals" -ForegroundColor Gray
                }

                # Screenshot for review
                $screenshotName = $idea.Suggestion -replace '\s+', '_' -replace '[^\w]', ''
                playwright-cli screenshot "./research/reddit_$screenshotName.png" 2>$null

            } catch {
                Write-Host "    ⚠️  Reddit check failed: $_" -ForegroundColor Red
            }

            Start-Sleep -Milliseconds 500
        }
    }
} else {
    Write-Host "`n⏭️  Étape 3: Reddit skipped (use without -SkipReddit to enable)" -ForegroundColor Yellow
}

# --- Step 4: Output ranked results ---
Write-Host "`n🏆 TOP IDÉES (triées par score)" -ForegroundColor Yellow
Write-Host "-" * 60

$ranked = $results | Where-Object { $_.Score -gt 0 } | Sort-Object @{Expression={$_.Score * 10 + $_.RedditHits}; Descending=$true} | Select-Object -First 15

$i = 1
foreach ($r in $ranked) {
    $color = if ($r.Score -ge 4) { "Green" } elseif ($r.Score -ge 3) { "Yellow" } else { "Red" }
    $reddit = if ($r.RedditHits -gt 0) { " | 🔥 $($r.RedditHits) Reddit signals" } else { "" }
    Write-Host "  $i. [$($r.Score)/5] $($r.Suggestion) ($($r.Saturation) apps)$reddit" -ForegroundColor $color
    $i++
}

# --- Save results ---
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$outputPath = ".\research\results_${Category}_${timestamp}.json"

if (-not (Test-Path ".\research")) {
    New-Item -ItemType Directory -Path ".\research" -Force | Out-Null
}

$ranked | ConvertTo-Json | Set-Content -Path $outputPath -Encoding UTF8
Write-Host "`n💾 Résultats sauvegardés: $outputPath" -ForegroundColor Cyan

Write-Host "`n📝 Prochaine étape:" -ForegroundColor White
Write-Host "   Demander à Claude Code de scorer la faisabilité de chaque idée" -ForegroundColor Gray
Write-Host "   puis choisir la meilleure et lancer la Phase 2 (Build).`n" -ForegroundColor Gray
