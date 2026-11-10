# Plugin officiel Dart et Flutter pour Codex

Source officielle : [Flutter — Get started developing with AI](https://docs.flutter.dev/ai/get-started#codex).

La tentative de commande depuis l’agent a échoué lors du clone Git, car cette session ne peut pas se connecter à github.com. Aucun plugin Flutter n’est déclaré installé ou actif par cette intervention.

Exécuter dans le **PowerShell Windows habituel**, afin de modifier le profil Codex de LENOVO :

~~~powershell
codex.cmd plugin marketplace add flutter/agent-plugins
codex.cmd plugin add dart-flutter@dart-flutter
codex.cmd plugin list
~~~

La première commande ajoute le catalogue. La deuxième installe le plugin ; la dernière vérifie sa présence. Ouvrir ensuite une nouvelle session Codex pour utiliser les compétences et outils ajoutés.

Le serveur Dart du plugin doit pouvoir trouver le SDK. Flutter est installé dans `C:\Users\LENOVO\Downloads\flutter`. Si `dart` n’est pas trouvé, ajouter `C:\Users\LENOVO\Downloads\flutter\bin` au PATH utilisateur Windows, puis ouvrir un nouveau terminal. Aucun PATH global ni réglage de sécurité n’a été modifié par l’agent.
