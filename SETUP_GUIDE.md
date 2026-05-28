# 🛠️ Guide d'Installation Complet

## Ce guide couvre TOUT ce que tu dois faire toi-même, étape par étape.

**Temps estimé : 2-3 heures (une seule fois)**

---

## PARTIE 1 — Comptes à créer

### 1.1 Compte Apple Developer (obligatoire, 99€/an)

1. Va sur https://developer.apple.com/programs/
2. Clique "Enroll"
3. Connecte-toi avec ton Apple ID (ou crée-en un)
4. Choisis "Individual" (pas "Organization")
5. Paie les 99€/an
6. ⏱️ **Délai : 24-48h** pour validation par Apple

**Après activation :**
7. Va dans App Store Connect : https://appstoreconnect.apple.com
8. Va dans "Users and Access" → "Integrations" → "App Store Connect API"
9. Clique "+" pour générer une clé API
   - Nom : `codemagic-key`
   - Rôle : **Admin**
10. Télécharge le fichier `.p8` (⚠️ tu ne peux le télécharger qu'UNE SEULE FOIS)
11. Note le **Key ID** et le **Issuer ID** affichés sur la page

### 1.2 Compte Codemagic (gratuit pour commencer)

1. Va sur https://codemagic.io
2. Inscris-toi avec GitHub
3. Connecte ton repo GitHub
4. Va dans "Teams" → "Integrations" → "App Store Connect"
5. Upload ta clé `.p8`
6. Entre le Key ID et Issuer ID
7. Codemagic se chargera du code signing automatiquement

**Forfait gratuit :** 500 minutes de build/mois (= environ 8-10 apps)

### 1.3 Compte GitHub (si pas déjà fait)

1. https://github.com — crée un compte
2. Crée un repo privé : `ios-automation-flutter`
3. Clone-le sur ton PC :
   ```powershell
   git clone https://github.com/TON_USER/ios-automation-flutter.git
   ```

---

## PARTIE 2 — Installations sur ton PC Windows

### 2.1 Flutter SDK

1. Télécharge Flutter : https://docs.flutter.dev/get-started/install/windows
2. Extrais le zip dans `C:\flutter`
3. Ajoute `C:\flutter\bin` au PATH Windows :
   - Recherche Windows → "Variables d'environnement"
   - Variable "Path" → Modifier → Nouveau → `C:\flutter\bin`
4. Ouvre un nouveau terminal PowerShell et vérifie :
   ```powershell
   flutter doctor
   ```
5. Résous les éventuels problèmes affichés par `flutter doctor`

### 2.2 Android Studio (pour l'émulateur Android)

1. Télécharge : https://developer.android.com/studio
2. Installe avec les options par défaut
3. Au premier lancement :
   - Accepte les licences SDK
   - Installe le SDK Android (API 34+)
4. Crée un émulateur :
   - Tools → Device Manager → Create Virtual Device
   - Choisis "Pixel 7" → Next
   - System Image : télécharge la dernière version
   - Finish
5. Vérifie :
   ```powershell
   flutter doctor
   # ✅ Android toolchain
   # ✅ Android Studio
   ```

### 2.3 Node.js (pour Playwright CLI et Claude Code)

1. Télécharge : https://nodejs.org (version LTS, 20+)
2. Installe avec les options par défaut
3. Vérifie :
   ```powershell
   node --version    # doit être >= 20
   npm --version
   ```

### 2.4 Playwright CLI (browser automation)

C'est l'outil qui permet à Claude Code de contrôler un navigateur — pour la recherche d'idées et l'automatisation d'App Store Connect.

```powershell
# Installation globale
npm install -g @playwright/cli@latest

# Installer le navigateur Chromium
playwright-cli install-browser

# Installer les skills pour Claude Code
playwright-cli install --skills

# Vérifier que tout fonctionne
playwright-cli open "https://google.com" --headed
# → Un navigateur Chrome doit s'ouvrir sur Google
# → Ferme-le avec Ctrl+C dans le terminal
```

**Test complet :**
```powershell
playwright-cli open "https://google.com" --headed
playwright-cli snapshot
# Tu devrais voir une liste d'éléments avec des [ref=eXX]
playwright-cli screenshot test_playwright.png
# Un fichier PNG doit être créé
```

### 2.5 Claude Code

1. Vérifie que Node.js est installé (étape 2.3)
2. Installe Claude Code :
   ```powershell
   npm install -g @anthropic-ai/claude-code
   ```
3. Lance et connecte-toi :
   ```powershell
   claude
   # Suis les instructions de connexion
   ```
4. Tu as besoin d'un plan Claude **Pro** minimum (17$/mois)
   - Idéalement **Max** (100$/mois) pour le throughput illimité

### 2.6 Skills IA pour le développement iOS

Ces skills rendent Claude Code expert en développement iOS et en conformité App Store.

**A. Axiom (184 skills iOS) :**
```powershell
# Dans Claude Code, exécuter :
/plugin marketplace add CharlesWiltgen/Axiom
# Puis /plugin → chercher "axiom" → Install
```
Couvre : SwiftUI, debugging, concurrency, App Review Guidelines, StoreKit, code signing, performance. Les skills s'activent automatiquement quand tu poses des questions liées à iOS.

**B. App Store Preflight (scanner anti-rejet) :**
```powershell
# Dans le dossier de ton projet :
npx skills add truongduy2611/app-store-preflight-skills
```
Scanne ton projet pour détecter les 100+ motifs de rejet Apple. À exécuter AVANT chaque soumission.

**C. Karpathy Coding Discipline :**
Déjà intégré dans le CLAUDE.md du repo. Claude Code le lit automatiquement.

### 2.7 Git

1. Si pas déjà installé : https://git-scm.com/download/win
2. Configure :
   ```powershell
   git config --global user.name "Ton Nom"
   git config --global user.email "ton@email.com"
   ```

### 2.8 VS Code (recommandé)

1. Télécharge : https://code.visualstudio.com
2. Installe les extensions :
   - Flutter
   - Dart
   - GitLens

---

## PARTIE 3 — Configurer ton iPhone pour le testing

### 3.1 Installer iTunes (drivers USB)

1. Télécharge iTunes depuis le Microsoft Store
2. Installe-le (même si tu ne l'utilises pas, il installe les drivers USB nécessaires)

### 3.2 Activer le Mode Développeur sur iPhone

1. Branche ton iPhone en USB au PC
2. Sur l'iPhone : Settings → Privacy & Security → Developer Mode
   - ⚠️ Si "Developer Mode" n'apparaît pas, installe d'abord IosScreenCaptureTool (étape 3.3), lance-le, et la toggle apparaîtra
3. Active Developer Mode → l'iPhone redémarre
4. Après redémarrage, confirme "Turn On"

### 3.3 Installer IosScreenCaptureTool

1. Va sur https://github.com/BieleckiLtd/IosScreenCaptureTool/releases
2. Télécharge `IosScreenCaptureTool-win-x64.zip`
3. Extrais dans un dossier (ex: `C:\Tools\IosScreenCaptureTool\`)
4. Lance `IosScreenCaptureTool.exe`
   - Au premier lancement : installe Python 3.12 + pymobiledevice3 automatiquement (1 min)
   - Branche ton iPhone → "Trust This Computer" sur l'iPhone
5. Tu devrais voir l'écran de ton iPhone mirrored dans la fenêtre
6. Teste la capture en ligne de commande :
   ```powershell
   cd C:\Tools\IosScreenCaptureTool
   .\IosScreenCaptureTool.exe --capture-frame C:\Users\TON_USER\test_capture.png
   ```
   Si le fichier PNG est créé → ✅ tout fonctionne

### 3.4 (Alternative) Installer pymobiledevice3

Si tu préfères la méthode directe sans IosScreenCaptureTool :
```powershell
pip install pymobiledevice3
pymobiledevice3 usbmux list                   # Vérifier que l'iPhone est détecté
pymobiledevice3 mounter auto-mount             # Monter le developer disk
pymobiledevice3 developer dvt screenshot test.png  # Tester
```

### 3.5 Installer TestFlight sur ton iPhone

1. App Store → cherche "TestFlight" → Installe
2. C'est par là que tu recevras les builds Codemagic pour tester

---

## PARTIE 4 — Première connexion App Store Connect (Playwright)

Cette étape sauvegarde ta session Apple pour que Claude Code puisse automatiser le remplissage des fiches d'app.

```powershell
# Ouvre App Store Connect dans Playwright
playwright-cli open "https://appstoreconnect.apple.com" --headed

# → Connecte-toi avec ton Apple ID
# → Complète la 2FA sur ton iPhone
# → Attends d'être sur le dashboard

# Sauvegarde la session
playwright-cli state-save appstore_auth.json

# Vérifie que ça marche
playwright-cli state-load appstore_auth.json
playwright-cli goto "https://appstoreconnect.apple.com/apps"
playwright-cli snapshot
# Tu devrais voir la liste de tes apps (vide au début)
```

⚠️ **Ajoute `appstore_auth.json` à ton `.gitignore` !**

```powershell
echo "appstore_auth.json" >> .gitignore
```

La session expire après ~30 jours. Quand ça arrive, refais cette étape.

---

## PARTIE 5 — Configurer la Privacy Policy (GitHub Pages)

1. Dans ton repo GitHub, crée un fichier `docs/index.html` :
   ```html
   <!DOCTYPE html>
   <html>
   <head><title>Privacy Policy - [APP_NAME]</title></head>
   <body>
     <!-- Copie le contenu de docs/privacy_policy.md ici en HTML -->
   </body>
   </html>
   ```
2. Va dans ton repo GitHub → Settings → Pages
3. Source : Deploy from a branch → `main` → `/docs`
4. Save
5. Ta privacy policy sera disponible à :
   `https://TON_USER.github.io/ios-automation-flutter/`

---

## PARTIE 6 — Premier lancement du pipeline

### 6.1 Copier les fichiers scaffolding

```powershell
cd C:\Users\TON_USER\Projects
git clone https://github.com/TON_USER/ios-automation-flutter.git app1
cd app1
```

### 6.2 Lancer Claude Code

```powershell
claude
```

Dans Claude Code :
```
> read @SKILL.md
> read @CLAUDE.md
> read @experience.md
> Start research phase for category "health". Find at least 5 app ideas.
```

Claude Code va :
1. Lancer Playwright CLI pour scraper Google + Reddit
2. Interroger l'iTunes Search API
3. Te présenter les top idées scorées

### 6.3 Après le choix de l'idée

```
> Build the app: [description de l'idée choisie]
> Generate screenshot integration test
> Run flutter test
```

### 6.4 Envoyer sur Codemagic

```powershell
git add -A
git commit -m "feat: initial app build"
git push origin main
```
→ Codemagic démarre automatiquement le build iOS + Android

### 6.5 Tester sur iPhone

1. Attends la notification TestFlight sur ton iPhone (~10-15 min)
2. Ouvre TestFlight → installe le build
3. Sur ton PC :
   ```powershell
   .\scripts\screenshot_capture.ps1 -Mode guided -Screens "home,settings,detail,profile"
   ```
4. Navigue dans l'app quand le script te le demande

### 6.6 Remplir la fiche App Store (automatisé)

```
> Run the App Store Connect automation for "APP_NAME" with bundle ID "com.org.appname"
```

Claude Code utilise Playwright CLI pour remplir tous les champs automatiquement.

### 6.7 Review finale et soumission

1. Vérifie le screenshot `./verification/listing_complete.png`
2. Ouvre App Store Connect dans ton navigateur
3. Vérifie chaque champ
4. Submit for Review ✅

---

## PARTIE 7 — Checklist de vérification

Avant de lancer ton premier pipeline complet :

```
COMPTES
  [ ] Apple Developer account actif (99€/an payé)
  [ ] Clé API .p8 téléchargée + Key ID + Issuer ID notés
  [ ] Codemagic connecté à GitHub + clé .p8 uploadée
  [ ] GitHub repo privé créé

PC WINDOWS
  [ ] Flutter SDK installé + flutter doctor OK
  [ ] Android Studio + émulateur configuré
  [ ] Node.js 20+ installé
  [ ] Playwright CLI installé + browser installé + skills installées
  [ ] Claude Code installé + connecté
  [ ] Git configuré
  [ ] VS Code + extensions Flutter/Dart

SKILLS IA
  [ ] Axiom installé (/plugin marketplace add CharlesWiltgen/Axiom)
  [ ] App Store Preflight installé (npx skills add truongduy2611/app-store-preflight-skills)
  [ ] CLAUDE.md contient les principes Karpathy (déjà inclus dans le repo)

PLAYWRIGHT
  [ ] playwright-cli open "https://google.com" --headed → fonctionne
  [ ] playwright-cli snapshot → affiche les refs
  [ ] Session App Store Connect sauvegardée (appstore_auth.json)
  [ ] appstore_auth.json ajouté au .gitignore

IPHONE
  [ ] iTunes installé (drivers USB)
  [ ] Developer Mode activé
  [ ] IosScreenCaptureTool fonctionnel (test de capture OK)
  [ ] TestFlight installé
  [ ] iPhone trusted avec le PC

GITHUB PAGES
  [ ] Privacy policy template publiée
  [ ] URL accessible : https://USER.github.io/REPO/

CODEMAGIC
  [ ] Repo connecté
  [ ] Code signing configuré (clé .p8)
  [ ] codemagic.yaml dans le repo
  [ ] BUNDLE_ID et APP_NAME mis à jour dans codemagic.yaml
```

---

## Résumé des coûts

| Élément | Coût | Fréquence |
|---------|------|-----------|
| Apple Developer | 99€ | /an |
| Claude Code Pro | ~17$ | /mois |
| Codemagic | 0€ (500 min gratuites) | /mois |
| Flutter, Android Studio, Git, VS Code | 0€ | gratuit |
| Playwright CLI, IosScreenCaptureTool | 0€ | gratuit |
| **TOTAL** | **~120€ au démarrage + ~17$/mois** | |

---

## FAQ

**Q: Combien de temps pour le premier setup ?**
R: 2-3 heures. Après, chaque nouvelle app prend 1-2 jours.

**Q: Et si Codemagic dépasse les 500 minutes gratuites ?**
R: Le plan payant commence à 49$/mois. Mais 500 minutes = environ 8-10 builds complets, suffisant pour 3-4 apps/mois.

**Q: Est-ce que je peux aussi publier sur Google Play ?**
R: Oui ! Flutter compile pour Android aussi. Il suffit de créer un compte Google Play Console (25$ une fois) et d'ajouter la config dans `codemagic.yaml`.

**Q: Mon iPhone est trop vieux, ça marche ?**
R: TestFlight nécessite iOS 13+. IosScreenCaptureTool fonctionne avec Developer Mode (iOS 16+). Si ton iPhone est plus ancien, utilise Appetize.io comme alternative.

**Q: Je n'ai pas d'iPhone du tout ?**
R: Tu peux quand même ship des apps ! Utilise Appetize.io (simulateur iOS dans le navigateur) pour les tests, et Codemagic pour les screenshots.

**Q: La session App Store Connect expire, que faire ?**
R: Relance `playwright-cli open "https://appstoreconnect.apple.com" --headed`, reconnecte-toi, puis `playwright-cli state-save appstore_auth.json`. C'est 30 secondes.

**Q: Playwright CLI vs Surfagent ?**
R: Playwright CLI est plus mature (Microsoft), mieux intégré avec Claude Code, et gère la persistence d'authentification. Surfagent est un projet plus récent avec moins de documentation.
