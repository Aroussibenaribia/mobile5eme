# Réservations

`screens/booking_screens.dart` contient la liste filtrable, le formulaire d'une prestation sélectionnée et le détail avec actions selon le rôle.

Les écritures passent par `HomeFixRepository` : `serviceId`, `clientId` et `proId` sont déduits du service et de la session. Le prix, le titre et la durée sont conservés dans la réservation. Les créneaux qui se chevauchent sont refusés dans une transaction SQLite.

Parcours : demande → confirmation → intervention en cours → terminée. L'annulation reste disponible avant le démarrage selon le rôle. Le client peut déposer une réclamation liée depuis le détail.

La recherche du catalogue reste dans `features/professionals/` et `ProfessionalService`. La géolocalisation GPS et les demandes de devis personnalisés ne sont pas implémentées dans ce périmètre.
