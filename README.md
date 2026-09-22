# 🏋️ IronPulse — App iOS Native de Suivi de Musculation

**IronPulse** est une application iOS native moderne développée avec **SwiftUI**, **SwiftData** et **Swift Charts** (iOS 17+), spécialement conçue pour être ultra-rapide et intuitive pendant l'entraînement en salle, tout en offrant des statistiques poussées pour analyser sa progression et équilibrer ses groupes musculaires.

Elle est **100% autonome et locale** : aucun compte à créer, aucun serveur externe, aucune dépendance à l'App Store ou à iCloud. Elle s'installe facilement via **Sideloadly** sous Windows grâce à une compilation gratuite dans le cloud avec **GitHub Actions**.

---

## ⚡ Fonctionnalités Clés

### 1. Enregistrement de Séance en Salle (Live Workout)
- **Démarrage rapide** : Lancez une séance libre, chargez une séance de votre programme en 1 clic ou dupliquez votre dernière séance.
- **Saisie ultra-ergonomique** : Gros boutons tactiles adaptés aux mains encombrées, retour haptique physique (`UIImpactFeedbackGenerator`) à chaque validation.
- **Recopie instantanée** : Bouton pour recopier en un tap les charges et répétitions réalisées lors de la séance précédente sur chaque exercice.
- **Calcul automatique du 1RM** : Estimation instantanée de votre charge maximale théorique pour chaque série (Formule standardisée d'Epley : $Charge \times (1 + Reps / 30)$).
- **Échelle d'effort RPE** : Saisie rapide du RPE (Rate of Perceived Exertion de 6 à 10) avec indications claires des répétitions en réserve (RIR).
- **Minuteur de repos automatique** :
  - Se déclenche dès qu'une série est validée (configurable : 30s, 60s, 90s, 120s, 180s).
  - Alerte visuelle circulaire, vibration haptique et carillon sonore à expiration.
  - Notification locale planifiée (`UNUserNotificationCenter`) : vous êtes alerté même avec l'iPhone verrouillé ou en arrière-plan.

### 2. Bibliothèque Complète d'Exercices & Routines
- **35+ exercices fondamentaux préremplis** : Développé couché, squat, deadlift, tractions, rowing, développé militaire, dips, curl biceps, extensions triceps, fentes, hip thrust, mollets, abdominaux, etc.
- **10 Groupes musculaires anatomiques** : Pectoraux, Dos, Épaules, Biceps, Triceps, Quadriceps, Ischio-jambiers, Mollets, Fessiers, Abdominaux.
- **Création d'exercices personnalisés** : Nom, groupes musculaires ciblés, équipement (Barre, Haltères, Poulie, Machine, Poids du corps, Élastique), catégorie (Polyarticulaire / Isolation).
- **Gestionnaire de Programmes & Routines** :
  - Programmes types intégrés : **Push / Pull / Legs (PPL)** et **Haut / Bas du Corps (Upper / Lower)**.
  - Suivi automatique de l'avancement dans le cycle et suggestion de la séance du jour.

### 3. Statistiques & Visualisations (Swift Charts)
- **« Quoi entraîner aujourd'hui ? » (Moteur de récupération)** :
  - Analyse des séances des 14 derniers jours.
  - Calcule pour chaque muscle le temps de repos écoulé et affiche un statut : 🟢 *Prêt* (48-72h), 🟡 *En récupération* (<48h), 🔴 *Priorité* (≥5 jours sans sollicitation).
  - Met en avant les muscles à cibler en priorité pour un physique équilibré et sans surentraînement.
- **Volume par groupe musculaire** :
  - Graphique en barres Swift Charts filtrable sur **7 jours**, **30 jours** ou **Tout l'historique**.
- **Courbes de progression par exercice** :
  - Graphique interactif montrant l'évolution de la **Charge Max**, du **1RM estimé** et du **Volume total** dans le temps.
  - Cartes des **Records Personnels (PR)** : 🏆 Charge Max, ⚡ 1RM théorique, 📦 Meilleur volume en une séance.
- **Calendrier d'assiduité (Heatmap)** :
  - Grille de contribution annuelle style GitHub (16 semaines) avec intensité de couleur pour visualiser la régularité des entraînements.
- **Statistiques Globales** :
  - Nombre total de séances, volume cumulé soulevé (en tonnes), total des séries validées et fréquence moyenne par semaine.

### 4. Spécifique Sideload, Santé & Sauvegarde
- **Export & Import JSON intégral** : Sauvegardez l'intégralité de vos séances, exercices personnalisés, routines et pesées dans un fichier JSON partageable (AirDrop, Fichiers, iCloud Drive, Mail).
- **Export CSV** : Exportez l'historique de chaque série pour analyse dans Microsoft Excel, Apple Numbers ou Google Sheets.
- **Suivi du poids de corps** : Historique et graphique dédié de votre pesée corporelle au fil des semaines.
- **Apple Santé (HealthKit)** : Écriture optionnelle des entraînements (`HKWorkout`) et lecture/écriture du poids corporel.
- **Mode Sombre OLED** : Interface sombre soignée avec accents contrastés haute lisibilité.

---

## 🛠️ Guide de Compilation et d'Installation depuis Windows

Xcode fonctionne uniquement sous macOS. Grâce à **GitHub Actions**, vous pouvez compiler l'application gratuitement dans le cloud et générer le fichier `.ipa` directement depuis Windows, sans jamais avoir besoin d'acheter un Mac.

### Étape 1 : Mettre le projet sur votre GitHub (Gratuit)
1. Créez un compte gratuit sur [GitHub](https://github.com) si vous n'en avez pas déjà un.
2. Créez un nouveau dépôt (public ou privé), par exemple nommé `IronPulse`.
3. Depuis votre terminal sous Windows (dans ce dossier) :
   ```bash
   git add .
   git commit -m "Initial commit IronPulse iOS App"
   git remote add origin https://github.com/VOTRE_PSEUDO/IronPulse.git
   git branch -M main
   git push -u origin main
   ```

### Étape 2 : Lancer la compilation Cloud (GitHub Actions)
1. Rendez-vous sur votre dépôt GitHub dans votre navigateur.
2. Cliquez sur l'onglet **Actions**.
3. Dans la liste à gauche, cliquez sur le workflow **Build iOS IPA (IronPulse)**.
4. Cliquez sur le bouton **Run workflow** à droite, puis validez.
5. GitHub lance une machine virtuelle macOS gratuite qui :
   - Génère le projet Xcode avec `xcodegen`.
   - Compile l'application iOS en mode *Release* sans signature (`CODE_SIGNING_ALLOWED=NO`).
   - Package l'application dans une archive `IronPulse.ipa`.
6. Au bout de 2 à 3 minutes, le build passe au vert ✅.
7. Cliquez sur le run terminé, descendez tout en bas dans la section **Artifacts**, et téléchargez l'archive **`IronPulse-ipa.zip`**.
8. Dézippez le fichier pour obtenir votre fichier **`IronPulse.ipa`**.

### Étape 3 : Installer l'application avec Sideloadly sous Windows
1. Téléchargez et installez **[Sideloadly](https://sideloadly.io/)** (logiciel gratuit et réputé pour Windows).
2. Connectez votre iPhone à votre PC en USB (déverrouillez l'écran et appuyez sur *"Faire confiance à cet ordinateur"* si demandé).
3. Ouvrez Sideloadly :
   - Votre iPhone apparaît dans le champ **Device**.
   - Glissez-déposez le fichier **`IronPulse.ipa`** dans l'encadré prévu à cet effet.
   - Saisissez votre **Apple ID** (votre identifiant Apple habituel).
   - Cliquez sur le bouton **Start**.
4. Sideloadly signe automatiquement l'application avec votre identifiant et l'installe sur votre iPhone.

### Étape 4 : Première ouverture sur l'iPhone
Lors du premier lancement de l'application sur votre iPhone, iOS peut afficher *"Développeur non approuvé"*. C'est la procédure normale pour les applications sideloadées :
1. Sur l'iPhone, ouvrez **Réglages** > **Général** > **Gestion des appareils** (ou *VPN et gestion des appareils*).
2. Touchez votre adresse Apple ID.
3. Touchez **Faire confiance à [votre email]**.
4. Lancez **IronPulse** et commencez votre premier entraînement ! 🎉

---

## 💾 Gestion de l'expiration des 7 jours (Apple ID gratuit)

> [!IMPORTANT]
> **Avec un identifiant Apple gratuit** :
> Apple limite la validité de la signature gratuite à **7 jours**. Au bout de 7 jours, l'application ne s'ouvre plus et nécessite d'être réinstallée via Sideloadly (en reconnectant l'iPhone et en recliquant sur *Start*).
>
> **Pour préserver vos données en toute sécurité** :
> 1. Ouvrez IronPulse > Onglet **Accueil** > Roue crantée ⚙️ (**Réglages**).
> 2. Touchez **Exporter la sauvegarde (JSON)** et enregistrez le fichier dans vos Fichiers iOS ou envoyez-le par AirDrop / Email.
> 3. Si vous réinstallez l'application à neuf, touchez simplement **Importer une sauvegarde (JSON)** pour restaurer instantanément tout votre historique, vos records et vos programmes !
>
> *(Si vous possédez un compte Apple Développeur payant à 99$/an, la signature Sideloadly reste valide 365 jours sans réinstallation).*

---

## 🏗️ Structure Technique du Projet

```
IronPulse/
├── App/
│   ├── IronPulseApp.swift            # Point d'entrée @main et configuration SwiftData
│   └── AppState.swift                # État global réactif (séance active, chronomètre)
├── Models/
│   ├── MuscleGroup.swift             # Énumération des 10 groupes musculaires
│   ├── Exercise.swift                # Modèle SwiftData (@Model)
│   ├── ExerciseSet.swift             # Modèle de série avec calcul 1RM Epley & volume
│   ├── WorkoutExercise.swift         # Modèle exercice rattaché à une séance
│   ├── Workout.swift                 # Modèle de séance d'entraînement
│   ├── Routine.swift                 # Programmes et cycles d'entraînement
│   └── BodyWeightEntry.swift         # Historique des pesées corporelles
├── ViewModels/
│   ├── RestTimerViewModel.swift      # Minuteur de repos avec alertes & haptique
│   └── StatisticsViewModel.swift     # Moteur de calcul (récupération, volume, PRs, heatmap)
├── Views/
│   ├── MainTabView.swift             # Navigation en 4 onglets
│   ├── Dashboard/                    # Accueil, Quoi entraîner, Heatmap, Graphiques
│   ├── ActiveWorkout/                # Interface séance en direct & saisie rapide
│   ├── History/                      # Historique et détail des séances passées
│   ├── Library/                      # Bibliothèque d'exercices & gestion des routines
│   ├── Settings/                     # Sauvegarde JSON/CSV, Suivi poids, Réglages
│   └── Components/                   # Gros boutons, sélecteur RPE, cartes de métriques
├── Services/
│   ├── ExerciseDataSeeder.swift      # Préremplissage de 35+ exercices fondamentaux
│   ├── BackupService.swift           # Export/Import JSON intégral & export CSV
│   ├── NotificationManager.swift     # Alertes locales de repos et rappels d'entraînement
│   └── HealthKitManager.swift        # Synchronisation avec Apple Santé
├── Resources/
│   ├── Assets.xcassets/              # AppIcon et AccentColor
│   └── Info.plist                    # Déclaration des permissions HealthKit et système
├── project.yml                       # Définition déclarative XcodeGen
├── IronPulse.xcodeproj/              # Projet Xcode pré-configuré avec schéma partagé
└── .github/workflows/build.yml       # Automatisation CI/CD GitHub Actions pour .ipa
```

---

## 🔒 Confidentialité & Respect de la Vie Privée
- **Zéro tracking** : Aucun tracker publicitaire, aucune télémétrie, aucun framework tiers.
- **100% Hors-ligne** : Vos données restent exclusivement sur votre appareil dans votre base de données locale SwiftData.
