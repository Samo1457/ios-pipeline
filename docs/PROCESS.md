# Process — iOS App Automation Pipeline (Windows)

## Vue d'ensemble

```
 RECHERCHE ──→ BUILD ──→ TEST ──→ SCREENSHOTS ──→ UPLOAD ──→ PREFLIGHT ──→ LISTING ──→ REVIEW
 (Playwright    (Claude   (Android     (Codemagic     (Codemagic   (Preflight    (Playwright   (Humain)
  CLI)          Code +    Emulator +    Integration    CI/CD)       + Axiom)      CLI +
                Flutter)  iPhone USB)   Tests)                                    Claude Code)
```

**Temps cible par app : 1-2 jours**
**Skills IA : Axiom (184 skills iOS) + App Store Preflight (100+ rejection rules) + Karpathy coding discipline**

---

## Phase 1 — Recherche (30 min)

**Qui :** Claude Code + Playwright CLI
**Quoi :** Trouver une idée d'app iOS avec demande réelle et faible concurrence

| Étape | Action | Outil |
|-------|--------|-------|
| 1.1 | Lancer 8 stems Google Autosuggest | `scripts/research.ps1` |
| 1.2 | Vérifier saturation App Store | iTunes Search API |
| 1.3 | Valider demande sur Reddit | Playwright CLI (scrape + analyse) |
| 1.4 | Scorer et classer les idées | Claude Code |
| 1.5 | Pivot si idée bloquée par Apple | Claude Code |

**Output :** Top 3 idées avec scores + choix final

---

## Phase 2 — Build (4-8h)

**Qui :** Claude Code (autonome)
**Quoi :** Générer l'app Flutter complète

| Étape | Action | Commande |
|-------|--------|----------|
| 2.1 | Créer le projet Flutter | `flutter create --org com.ORG app_name` |
| 2.2 | Coder l'app (screens, navigation, logic) | Claude Code |
| 2.3 | Ajouter le thème et les assets | Claude Code |
| 2.4 | Tester localement | `flutter run` (Android) |
| 2.5 | Corriger les erreurs | Claude Code (boucle) |
| 2.6 | Générer le test de screenshots | `dart run scripts/screenshot_test_generator.dart` |

**Output :** App fonctionnelle + tests + screenshot test

---

## Phase 3 — Test (1-2h)

**Qui :** Claude Code + Humain (iPhone)
**Quoi :** Valider l'app sur Android et iOS

| Étape | Action | Outil |
|-------|--------|-------|
| 3.1 | Tests unitaires | `flutter test` |
| 3.2 | Test sur émulateur Android | `flutter run -d emulator` |
| 3.3 | Push → Codemagic build iOS | `git push origin main` |
| 3.4 | Installer via TestFlight sur iPhone | App TestFlight |
| 3.5 | Capture screenshots iPhone | `scripts/screenshot_capture.ps1` |
| 3.6 | Claude analyse les screenshots | Claude Code (vision) |
| 3.7 | Corriger si nécessaire | Boucle Phase 2-3 |

**Output :** App validée sur les deux plateformes

---

## Phase 4 — Screenshots App Store (30 min)

**Qui :** Codemagic (automatique)
**Quoi :** Générer les screenshots aux formats requis

| Étape | Action | Outil |
|-------|--------|-------|
| 4.1 | Push sur branche `screenshots/v1` | Git |
| 4.2 | Codemagic exécute les integration tests | Codemagic |
| 4.3 | Screenshots capturés sur vrais devices iOS | Codemagic |
| 4.4 | Télécharger les artifacts | Codemagic dashboard |

**Output :** Screenshots PNG aux bonnes résolutions

---

## Phase 5 — Upload Build (15 min)

**Qui :** Codemagic (automatique)
**Quoi :** Builder et uploader l'IPA

| Étape | Action | Qui |
|-------|--------|-----|
| 5.1 | Build IPA signé | Codemagic |
| 5.2 | Upload sur TestFlight | Codemagic |

**Trigger :** `git push origin main` → Codemagic démarre automatiquement

---

## Phase 5.25 — Preflight Anti-Rejet (15 min) 🆕

**Qui :** Claude Code + App Store Preflight + Axiom
**Quoi :** Scanner le projet pour détecter les motifs de rejet Apple AVANT soumission

| Étape | Action | Outil |
|-------|--------|-------|
| 5.25.1 | Scanner le code pour rejection patterns | App Store Preflight |
| 5.25.2 | Corriger tous les items REJECTION | Claude Code |
| 5.25.3 | Vérifier conformité Apple Review Guidelines | Axiom (app-review-guidelines) |
| 5.25.4 | Checklist qualité expert | Axiom (expert-review-checklist) |
| 5.25.5 | Re-scanner pour confirmer corrections | App Store Preflight |

**Output :** Projet clean, zéro REJECTION, prêt pour listing

---

## Phase 5.5 — Listing App Store (30 min) 🆕

**Qui :** Claude Code + Playwright CLI
**Quoi :** Remplir automatiquement la fiche App Store Connect

| Étape | Action | Outil |
|-------|--------|-------|
| 5.5.1 | Charger la session Apple | `playwright-cli state-load appstore_auth.json` |
| 5.5.2 | Créer la fiche app | Playwright CLI (formulaire) |
| 5.5.3 | Remplir métadonnées (nom, description, keywords) | Playwright CLI |
| 5.5.4 | Uploader les screenshots | Playwright CLI |
| 5.5.5 | Configurer prix et age rating | Playwright CLI |
| 5.5.6 | Ajouter privacy policy URL | Playwright CLI |
| 5.5.7 | Screenshot de vérification | `playwright-cli screenshot` |

**Output :** Fiche App Store remplie, prête pour review humaine

**⛔ Claude Code ne clique JAMAIS "Submit for Review"**

---

## Phase 6 — Review humaine (15 min)

**Qui :** Humain uniquement
**Quoi :** Dernière vérification avant soumission

Checklist :
- [ ] Vérifier le screenshot de vérification (`./verification/listing_complete.png`)
- [ ] Ouvrir App Store Connect et vérifier chaque champ
- [ ] Screenshots correctes et représentatives
- [ ] Description claire, pas de fautes
- [ ] Build TestFlight testé sur iPhone
- [ ] Privacy policy live et accessible
- [ ] Pas de private APIs utilisées
- [ ] Info.plist : descriptions des permissions claires
- [ ] Catégorie et age rating corrects
- [ ] Prix configuré

→ **Submit for Review** ✅

---

## Après chaque app

1. Mettre à jour `experience.md` avec les erreurs rencontrées
2. Committer les changements au repo scaffolding
3. Noter le temps total et les revenues dans le tableau de suivi
4. Identifier ce qui peut être mieux automatisé pour la prochaine
