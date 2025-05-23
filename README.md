# Gestionnaire de Documents Flutter

Application Flutter de gestion de documents simple et intuitive, conçue pour organiser et accéder facilement à vos fichiers importants.

## Description

Cette application permet aux utilisateurs de créer, modifier, et gérer des documents numériques. Chaque document peut avoir un titre, une description, une catégorie, des tags, et un fichier attaché. L'application offre des fonctionnalités de recherche, de filtrage, de mise en favoris, un historique de consultation et une corbeille pour une gestion complète du cycle de vie des documents.

L'interface utilisateur est basée sur Material 3 pour un look moderne et une expérience utilisateur agréable.

## Fonctionnalités Principales

*   **Création et Édition de Documents** : Formulaire complet pour ajouter ou modifier les détails d'un document.
*   **Attachement de Fichiers** : Possibilité d'attacher n'importe quel type de fichier à un document. Les fichiers sont copiés dans un espace de stockage dédié à l'application.
*   **Ouverture de Fichiers Attachés** : Ouvrir les fichiers directement depuis l'application en utilisant le visualiseur par défaut du système.
*   **Favoris** : Marquer et retrouver facilement les documents importants.
*   **Historique de Consultation** : Un écran dédié affiche les documents consultés récemment.
*   **Corbeille** : Les documents supprimés sont d'abord déplacés vers la corbeille, avec options pour restaurer ou supprimer définitivement.
*   **Recherche et Filtrage** :
    *   Recherche textuelle sur les titres, descriptions et noms de fichiers.
    *   Filtrage par catégorie de document.
*   **Navigation Intuitives** : Barre de navigation inférieure pour accéder aux sections :
    *   Mes Documents
    *   Historique
    *   Assistant IA (fonctionnalité simulée/placeholder)
    *   Quiz (fonctionnalité simulée/placeholder)
    *   Corbeille
*   **Thème Material 3** : Interface utilisateur moderne et adaptable.

## Instructions pour Lancer le Projet

1.  **Prérequis** : Assurez-vous d'avoir [Flutter SDK](https://flutter.dev/docs/get-started/install) installé sur votre machine.
2.  **Cloner le Dépôt** (si applicable) ou ouvrir le projet.
3.  **Installer les Dépendances** :
    ```bash
    flutter pub get
    ```
4.  **Lancer l'Application** :
    Connectez un appareil ou lancez un émulateur, puis exécutez :
    ```bash
    flutter run
    ```

## Structure du Projet (Aperçu)

*   `lib/` : Contient tout le code source Dart.
    *   `main.dart`: Point d'entrée de l'application, contient `MainScreen` qui gère la navigation principale et l'état global.
    *   `models/`: Définit les modèles de données (ex: `document.dart`).
    *   `screens/`: Contient les différents écrans/pages de l'application (ex: `home_screen.dart`, `edit_document_screen.dart`, etc.).
    *   `widgets/`: Contient les widgets réutilisables (ex: `document_card.dart`).
    *   `theme/`: Définit le thème de l'application (ex: `app_theme.dart`).
*   `pubspec.yaml`: Définit les métadonnées du projet et les dépendances.
*   `README.md`: Ce fichier.

## État Actuel et Limitations

*   **Gestion de l'état en mémoire** : Actuellement, toutes les données des documents (y compris les favoris, l'historique, la corbeille) sont stockées en mémoire et sont perdues à la fermeture de l'application. Une solution de persistance (comme SQLite) était initialement prévue et pourrait être réintégrée.
*   **Fonctionnalités IA et Quiz** : Les écrans "Assistant IA" et "Quiz" sont des placeholders avec une interface utilisateur simulée. Leur logique métier n'est pas implémentée.
*   **Pas de gestion des utilisateurs/comptes.**
*   **Gestion des fichiers** : Les fichiers attachés sont copiés dans le dossier de documents de l'application. La suppression définitive d'un document supprime également le fichier physique associé.
