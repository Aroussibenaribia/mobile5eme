# HomeFix — audit et refonte du 10 novembre

## Contrôles retirés

| Ancien élément | Motif |
| --- | --- |
| Notifications sur l’accueil et dans le profil | Aucun module de notifications connecté |
| Favoris sur la fiche artisan | État temporaire sans enregistrement ni liste consultable |
| Partage du profil | Annonçait une copie sans copier de lien |
| Appeler / Message | Affichaient un message sans lancer d’appel ni conversation |
| Aide / Support du profil | Adresse de démonstration sans service de support |
| Bannière « intervention en moins de 2h » | Aucun engagement ni traitement correspondant |
| Compteurs par métier et « 100% vérifiés » | Valeurs statiques ne correspondant pas au catalogue |
| Grand bandeau de couverture vide | Absence d’image réelle |
| Tarif horaire dans le parcours de réservation | Le prix accepté vient de la prestation choisie |
| Introduction imposée à chaque ouverture | Retarde l’accès et déborde sur de petits écrans |
| Écrans placeholder inutilisés | Remplacés par les vrais modules |

Le partage d’une publication du forum est conservé : il utilise le véritable partage Android. Les votes, commentaires, filtres, statistiques du forum, réservations et réclamations conservent leurs actions fonctionnelles. Les désactivations temporaires pendant un chargement ou un enregistrement restent nécessaires.

## Disponibilités modifiables

La version précédente affichait les jours mais ne proposait pas d’éditeur. Les valeurs par défaut étaient **Lun–Sam, soit six jours**.

Dans **Profil → Modifier mon profil**, un professionnel peut maintenant :

- sélectionner les jours du lundi au dimanche ;
- modifier sa présentation ;
- mettre en pause ou reprendre les nouvelles réservations ;
- enregistrer ces choix dans la base SQLite existante.

La réservation client initialise la date sur un jour ouvert et désactive les autres jours dans le calendrier. Le dépôt en base vérifie à nouveau les jours, la disponibilité et les conflits de créneaux. Un changement de planning conserve les rendez-vous déjà pris. Les créneaux restent limités à 08h–19h, comme dans le workflow existant.

Les comptes clients ne peuvent pas modifier une disponibilité professionnelle. Les valeurs invalides, doublons et sélections vides sont refusés sans sauvegarde partielle du profil.

## Direction visuelle

Surfaces ivoire, vert profond, typographie Plus Jakarta Sans, portraits avec initiales en carrés arrondis, titres lisibles et prix par prestation. L’accueil professionnel montre les demandes et le catalogue ; l’accueil client mène à la recherche et aux métiers. Les listes et formulaires partagent les mêmes styles et états.

Les nouveaux écrans évitent les grandes couvertures vides, les faux boutons de communication et les promesses décoratives. Ils s’appuient sur les données du compte et les prestations réelles.

## Vérification

**79 tests réussis**, analyse Flutter sans problème et compilation du bundle Dart/assets Android réussie. La capture des 17 aperçus est également réussie.

Les tests vérifient notamment la sélection du dimanche seul dans le profil, son enregistrement et son effet dans le calendrier client, les droits sur le planning, la mise en pause, et les dispositions à 320 pixels de large. La capture explicite produit 17 images des widgets réels avec les données SQLite de démonstration.

La refonte a ensuite été compilée et installée avec succès depuis le PowerShell Windows habituel. Son accueil est vérifié dans l’émulateur. Une correction du choix du pilote SQLite a ensuite été validée par les 79 tests et une analyse sans erreur ; appuyer sur R dans Flutter pour charger cette dernière correction.

## Où se trouvent les fichiers ?

Projet : `C:\Users\LENOVO\Downloads\mobile5eme-Forum`.

Base SQLite dans l’émulateur : `/data/data/com.example.mobile5eme/databases/homefix_forum.db`. Elle n’est pas un fichier du projet Windows. Les nouvelles disponibilités réutilisent les tables existantes, sans supprimer les comptes ni les réservations.
