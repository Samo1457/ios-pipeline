# Experience Log

Ce fichier est mis à jour après chaque app. Claude Code doit le lire au début de chaque nouveau projet pour éviter de répéter les mêmes erreurs.

---

## Template par entrée

```
### [Date] — App: [Nom] — Problème: [Description courte]
**Contexte:** ce qui s'est passé
**Cause:** pourquoi c'est arrivé
**Fix:** comment ça a été résolu
**Temps perdu:** X minutes/heures
**Prévention:** ce qu'il faut faire différemment
```

---

## Erreurs connues Flutter + Codemagic

### Codemagic — Code Signing

**Problème:** Build iOS échoue avec "No signing certificate found"
**Fix:** Vérifier que le fichier `.p8` est uploadé dans Codemagic > Team settings > Code signing. S'assurer que le Key ID et Issuer ID correspondent à ceux de App Store Connect > Users and Access > Keys.

### Codemagic — CocoaPods

**Problème:** Build échoue sur `pod install` avec des packages Flutter
**Fix:** Ajouter dans `codemagic.yaml` :
```yaml
scripts:
  - name: Install pods
    script: |
      cd ios && pod install --repo-update
```

### Flutter — Null Safety

**Problème:** Packages anciens cassent le build avec des erreurs null safety
**Fix:** Toujours vérifier la compatibilité null safety sur pub.dev avant d'ajouter un package. Utiliser les versions les plus récentes.

### Flutter — iOS Permissions

**Problème:** App rejetée par Apple car les descriptions de permissions dans Info.plist sont manquantes ou trop vagues
**Fix:** Toujours ajouter des descriptions claires et spécifiques :
```xml
<key>NSCameraUsageDescription</key>
<string>Cette app utilise la caméra pour scanner des documents</string>
```

### Flutter — App Icons

**Problème:** Icône de l'app floue ou mal dimensionnée sur iOS
**Fix:** Utiliser le package `flutter_launcher_icons` avec une image source de 1024x1024 minimum, sans transparence, sans coins arrondis (iOS les arrondit automatiquement).

### Screenshots — Format

**Problème:** Screenshots rejetés par App Store Connect
**Fix:** Les screenshots doivent être en PNG ou JPEG, sans canal alpha, aux résolutions exactes requises. Utiliser le mode `--no-sound-null-safety` si le test d'intégration échoue sur Codemagic.

---

## Apps Expédiées

(Sera rempli après chaque app)

| # | Nom | Date | Catégorie | Temps total | Revenue | Notes |
|---|-----|------|-----------|-------------|---------|-------|
| 1 | — | — | — | — | — | — |
