# 🚀 iOS App Automation Pipeline (Windows + Flutter)

Pipeline automatisé pour créer et publier des apps iOS depuis un PC Windows, sans Mac.

## Quick Start — Une seule commande

```powershell
git clone https://github.com/Samo1457/ios-pipeline.git && cd ios-pipeline && .\launch.ps1
```

Le script te pose les questions :
- 📱 **Nom de l'app** (obligatoire)
- 📁 **Chemin du dossier** (Entrée = défaut, ou chemin custom)
- 🏷️ **Bundle ID** (Entrée = défaut `com.samo`)
- 🔍 **Catégorie de recherche** (Entrée = skip)
- 📦 **Flutter create** (o/n)

Puis il fait tout automatiquement et ouvre VS Code.

## Stack

| Outil | Rôle |
|-------|------|
| **Flutter/Dart** | Framework cross-platform (iOS + Android) |
| **Claude Code** | Agent IA qui code l'app |
| **Codemagic** | CI/CD cloud (build iOS sans Mac) |
| **Playwright CLI** | Browser automation (recherche + App Store Connect) |
| **Axiom** | 184 skills iOS (SwiftUI, App Review, debugging) |
| **App Store Preflight** | Scanner anti-rejet (100+ Apple Review Guidelines) |
| **Karpathy CLAUDE.md** | Discipline de code (simplicité, chirurgical) |
| **IosScreenCaptureTool** | Screenshots iPhone via USB |

## Pipeline

```
Recherche → Build → Test → Screenshots → Upload → Preflight → Listing → Review
  30 min    4-8h    1-2h    30 min        15 min   15 min      30 min    15 min
```

## Documentation

- 📋 [PROCESS.md](docs/PROCESS.md) — Vue d'ensemble du process
- 🛠️ [SETUP_GUIDE.md](docs/SETUP_GUIDE.md) — Tuto d'installation complet
- 📖 [SKILL.md](SKILL.md) — Instructions pour Claude Code
- 📐 [CLAUDE.md](CLAUDE.md) — Conventions + discipline de code
- 📝 [experience.md](experience.md) — Journal des erreurs et solutions

## Coût

~120€ au démarrage + ~17$/mois (Claude Pro)

## Crédits

Inspiré par [All About AI](https://github.com/AllAboutAI-YT/) • Skills: [Axiom](https://charleswiltgen.github.io/Axiom/) • [App Store Preflight](https://github.com/truongduy2611/app-store-preflight-skills) • [Karpathy CLAUDE.md](https://github.com/forrestchang/andrej-karpathy-skills)
