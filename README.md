# 🏠 HomeFix — Plateforme de Services à Domicile

Application mobile développée avec **Flutter & Firebase** mettant en relation des clients avec des professionnels certifiés pour divers services à domicile (Plomberie, Électricité, Climatisation, Peinture, Nettoyage, Réparation informatique).

---

## 👥 Répartition du Travail en Équipe

| Membre | Périmètre Fonctionnel | Dossier Assigné | Statut |
| :--- | :--- | :--- | :--- |
| **Membre 1** *(Actuel)* | • **Écran d'Accueil (HomeFix Dashboard)**<br>• **Authentification** (Connexion, Inscription Client/Pro, MDP oublié)<br>• **Gestion des Profils** (Consultation & Édition Client / Pro)<br>• **Catalogue & Fiche détaillée des Professionnels** | `lib/features/home/`<br>`lib/features/auth/`<br>`lib/features/profile/`<br>`lib/features/professionals/`<br>`lib/core/` & `lib/models/` |  **Terminé & Testé** |
| **Membre 2** | • Recherche avancée de services<br>• Prise de rendez-vous & sélection de créneau horaire<br>• Demande de service à domicile & géolocalisation | `lib/features/search_and_booking/` |  *Espace & Modèles prêts pour Membre 2* |
| **Membre 3** | • Évaluations & avis clients (étoiles, commentaires)<br>• Réclamations & signalements de litiges<br>• Historique complet des demandes<br>• Système de notifications | `lib/features/reviews_and_history/` |  *Espace & Modèles prêts pour Membre 3* |

---

## 🚀 Lancement Rapide & Comptes Démo

Pour lancer l'application :
```bash
flutter pub get
flutter run
```

### ⚡ Accès Démo en 1 Clic (Idéal pour l'Évaluation & Présentation) :
L'application démarre directement sur un compte connecté pour naviguer immédiatement, et propose sur l'écran de connexion des boutons d'accès rapide :
- **Mode Client** : `client@homefix.com` (Sarra Mansouri)
- **Mode Professionnel** : `pro@homefix.com` (Karim Ben Ali — Plombier certifié)
- **Bascule instantanée** : Depuis l'onglet **Profil**, un bouton permet de basculer entre Client et Pro en un seul clic !

---

## 📂 Architecture du Projet

```
lib/
├── core/
│   ├── theme/          # AppColors & AppTheme (Palette Teal / Slate moderne)
│   └── widgets/        # CustomButton, CustomTextField, ProAvatar, RatingBadge
├── models/
│   ├── user_model.dart             # Modèle Client & Pro avec sérialisation
│   ├── professional_model.dart     # Fiche artisan, tarifs, prestations, avis
│   ├── service_category_model.dart # 6 catégories (Plomberie, Électricité...)
│   ├── booking_model.dart          # Modèle partagé pour le Membre 2
│   └── review_model.dart           # Modèle partagé pour le Membre 3
├── services/
│   ├── auth_service.dart           # Gestion de session, inscription, switch de rôle
│   └── professional_service.dart   # Catalogue, filtres par métier, recherche
├── features/
│   ├── home/                       # [MEMBRE 1] Dashboard complet d'accueil
│   ├── auth/                       # [MEMBRE 1] Login, Register (Client/Pro), Forgot Password
│   ├── profile/                    # [MEMBRE 1] Profil utilisateur & modification
│   ├── professionals/              # [MEMBRE 1] Liste & fiche détaillée avec tarifs
│   ├── search_and_booking/         # [MEMBRE 2] Dossier réservé avec README explicatif
│   ├── reviews_and_history/        # [MEMBRE 3] Dossier réservé avec README explicatif
│   └── shell/                      # BottomNavigationBar fluide reliant les 5 modules
└── main.dart                       # Point d'entrée avec MultiProvider
```

---

## 🧪 Tests Unitaires

Tous les tests unitaires du Membre 1 sont vérifiés :
```bash
flutter test
```
```
00:02 +10: All tests passed!
```
