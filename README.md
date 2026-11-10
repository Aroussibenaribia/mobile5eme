# HomeFix — Flutter + SQLite

Home services booking application for clients and professionals in Tunisia. The French interface now uses warm ivory surfaces, deep green accents, clearer typography, and compact artisan profiles. The feature folders, Provider state management, and community forum are retained.

Accounts, professional profiles, services, bookings, complaints, sessions, and forum records now use SQLite. Firebase packages and configuration have been removed.

## Review the interfaces

Open [the screen gallery](docs/previews/index.html). These are actual Flutter widgets rendered with the production SQLite demo data at a 390 × 844 phone size. They are widget previews, not screenshots from an installed Android APK. The previews use local Roboto fonts; the application keeps its existing Plus Jakarta Sans theme.

## Demo accounts

| Role | Email | Password |
| --- | --- | --- |
| Client | `client@homefix.com` | `HomeFix123!` |
| Professional | `pro@homefix.com` | `HomeFix123!` |
| Administrator | `admin@homefix.com` | `HomeFix123!` |

The login screen includes shortcuts to these accounts, using real authentication. Demo records are inserted only when the accounts table is empty. Public registration creates client or professional accounts; it cannot grant the administrator role.

Five professionals and their services are seeded, including plumbing, electricity, masonry/construction, air conditioning, and painting. A completed plumbing booking and a pending complaint are included for reviewing the admin workflow.

## Implemented workflow

1. **Professional:** sign in and open **Prestations**. Add, edit, archive/reactivate, or remove an offering with its title, description, price in DT, and duration. Each service has a stable ID and belongs to the authenticated professional. Removing a service used by a booking archives it so the booking history remains valid.
2. **Client:** search the professional catalogue, open an artisan, and select a specific offering. Choose the date, time, intervention address, and optional notes. The reservation stores `serviceId`, `clientId`, and `proId` automatically, together with the agreed title, price, and duration.
3. **Booking:** the professional confirms the request, starts the intervention, then completes it. Client cancellation is available while pending or confirmed; the professional can also cancel before starting. Overlapping bookings for the same professional are rejected. Slots must respect the professional's available days and 08:00–19:00 hours.
4. **Complaint:** the client opens a booking or **Historique → Réclamations**, selects their booking, and describes the issue. Both participants come from that booking. The client can edit/delete a pending complaint. Only one open complaint is allowed per booking.
5. **Administrator:** login opens a panel with exactly **Réclamations** and **Utilisateurs**. Search/filter complaints, inspect the related booking and both participants, then record an analysis/decision and justification. Statuses are **En attente**, **En cours d’analyse**, **Résolue**, and **Rejetée**. A final decision is retained in history and visible to the client and professional.
6. **User administration:** search/filter accounts, inspect contact details, suspend/reactivate a client or professional, or reset their password. Suspension preserves history and hides a professional from the public catalogue. Administrator accounts are protected from these user controls.

Professionals can edit their presentation, choose any working days from Monday through Sunday, and pause new reservations under **Profil → Modifier mon profil**. These settings are saved in SQLite and drive the public profile and client booking calendar. Already booked appointments are retained.

Profile editing and password changes use SQLite. **Se souvenir de moi** controls session restoration after restarting the application. Signed-out password recovery directs the user to the administrator because this local application has no email service.

## Structure

~~~text
lib/
  core/
    data/
      app_schema.dart           Tables, indexes, migrations, demo data
      homefix_repository.dart   SQLite operations and workflow/role checks
      password_hasher.dart      Salted PBKDF2-HMAC-SHA256 passwords
    theme/                      Existing AppColors and AppTheme
    widgets/                    Shared controls and feature cards
  models/
    user_model.dart             Client / professional / admin
    professional_model.dart     Professional profile and catalogue
    service_model.dart          Owned service offering
    booking_model.dart          Booking and agreed service snapshot
    reclamation_model.dart      Complaint, analysis, decision
  services/
    auth_service.dart           Authentication and session state
    professional_service.dart   Catalogue, category/search filters
    homefix_data.dart           Shared role-scoped screen data
  features/
    services/                   Professional service management
    search_and_booking/         Booking form, list, details, status actions
    reviews_and_history/        History and complaint CRUD/follow-up
    admin/                      Complaint and user administration
    forum/                      Existing forum and shared database opener
    auth/ home/ professionals/ profile/ shell/
  main.dart                     Provider wiring and app entry point
test/                           Repository, workflow, UI, and forum tests
tool/capture_previews_test.dart  Reproducible widget preview capture
docs/previews/                  Screen gallery and PNG previews
~~~

`ProServiceItem` remains an alias for `ServiceModel` so the original professional model remains compatible with the new offering model.

## Relationships and storage

~~~mermaid
erDiagram
    users ||--o| professionals : professional_profile
    professionals ||--o{ services : owns
    users ||--o{ bookings : client
    professionals ||--o{ bookings : worker
    services ||--o{ bookings : selected_service
    bookings ||--o{ reclamations : subject_of
    users o|--o{ reclamations : admin_reviewer
~~~

The database is `homefix_forum.db`, schema version **3**. Opening an existing forum database creates the new tables and keeps its posts/comments. Upgrading the first local account schema also adds the remembered-session flag without dropping data.

Foreign keys are enabled. A composite service/professional key prevents mismatched booking ownership; a composite booking/client/professional key prevents a complaint from referring to different participants. Mutations enforce the current session's role and ownership inside transactions. Passwords use independently salted PBKDF2-HMAC-SHA256 hashes with 210,000 iterations.

SQLite data belongs to this app installation. To demonstrate client, professional, and administrator interactions, sign out and switch accounts on the same installation. Separate phones do not share the database. Existing Firebase cloud accounts/data are not imported. The original forum functionality remains in its existing module.

## Run on Android

Install Flutter, Android Studio/Android SDK, and start an emulator or connect a phone. From this project folder:

~~~powershell
flutter pub get
flutter devices
flutter run -d <device-id>
~~~

On this computer Flutter is installed at `C:\Users\LENOVO\Downloads\flutter`; if `flutter` is not on PATH, use `& 'C:\Users\LENOVO\Downloads\flutter\bin\flutter.bat'` instead. The Android emulator detected during this session was `emulator-5580`.

For an Android-only session on Windows without desktop symlinks enabled, set these process-local flags before the Flutter commands:

~~~powershell
$env:FLUTTER_WINDOWS='false'
$env:FLUTTER_LINUX='false'
$env:FLUTTER_MACOS='false'
~~~

Dependencies are already cached on this machine. For a restricted/offline terminal, use `flutter pub get --offline`, followed by `flutter test --no-pub` or `flutter run --no-pub -d <device-id>`.

## Latest source and Flutter plugin

The working project is `C:\Users\LENOVO\Downloads\mobile5eme-Forum`. The current redesign snapshot is `C:\Users\LENOVO\Downloads\HomeFix-redesign-source.zip`.

The official Flutter plugin setup is documented in [CODEX_FLUTTER_PLUGIN.md](docs/CODEX_FLUTTER_PLUGIN.md). The attempted marketplace addition could not reach GitHub from this session, so it is not installed by this change.

## Verification

~~~powershell
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug
~~~

The first SQLite Android APK was built and installed successfully from the user's normal Windows terminal on 9 November 2026. The **10 November redesign was subsequently built and installed successfully from the user's normal terminal**, and its new home screen was visually verified in the emulator. A copy of that native build is saved as `C:\Users\LENOVO\Downloads\HomeFix-redesign.apk`. A small SQLite initialization warning was then fixed in source; press capital `R` in the active Flutter terminal to apply that latest fix, or rebuild to include it in a standalone APK. An installable copy is saved at `C:\Users\LENOVO\Downloads\HomeFix-SQLite.apk`. See [IMPLEMENTATION.md](IMPLEMENTATION.md) and [the redesign audit](docs/REDESIGN.md) for verification details. The older baseline remains at `C:\Users\LENOVO\Downloads\HomeFix-original-preview.apk`.

To regenerate previews, set `FLUTTER_ROOT` to the SDK folder and run:

~~~powershell
flutter test --no-pub tool/capture_previews_test.dart
~~~

The optional `HOMEFIX_PREVIEW_SYMBOL_FONT` environment variable can point to a local symbol font for preview fallback glyphs. Preview generation does not modify the user's database.
