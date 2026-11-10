# Historique et réclamations

`screens/reclamation_screens.dart` contient l'historique, la liste filtrable des réclamations, le formulaire de création/modification et le détail avec suivi administratif.

Le client choisit une de ses réservations. `HomeFixRepository` déduit les deux utilisateurs depuis cette réservation ; la clé étrangère composite SQLite protège cette relation. Une seule réclamation ouverte par réservation est autorisée.

Une réclamation en attente peut être modifiée ou supprimée par son client. L'administrateur peut la passer en cours d'analyse, résolue ou rejetée avec une justification. Le traitement enregistre l'administrateur et la date. Une décision finale est conservée et visible par les deux participants.

Le panel administratif à deux sections se trouve dans `features/admin/`. Les avis/notations et notifications push n'ont pas été étendus dans ce périmètre.
