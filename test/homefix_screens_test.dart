import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mobile5eme/core/data/homefix_repository.dart';
import 'package:mobile5eme/core/data/password_hasher.dart';
import 'package:mobile5eme/features/admin/screens/admin_screen.dart';
import 'package:mobile5eme/features/profile/screens/edit_profile_screen.dart';
import 'package:mobile5eme/features/profile/screens/profile_screen.dart';
import 'package:mobile5eme/features/home/screens/home_screen.dart';
import 'package:mobile5eme/features/professionals/screens/pro_detail_screen.dart';
import 'package:mobile5eme/core/widgets/editorial_widgets.dart';
import 'package:mobile5eme/features/services/screens/services_screen.dart';
import 'package:mobile5eme/features/search_and_booking/screens/booking_screens.dart';
import 'package:mobile5eme/features/reviews_and_history/screens/reclamation_screens.dart';
import 'package:mobile5eme/features/shell/screens/main_shell_screen.dart';
import 'package:mobile5eme/models/reclamation_model.dart';
import 'package:mobile5eme/services/auth_service.dart';
import 'package:mobile5eme/services/homefix_data.dart';
import 'package:mobile5eme/services/professional_service.dart';
import 'homefix_repository_test.dart' as fixture;

void main() {
  late Database db;
  late HomeFixRepository repo;
  late AuthService auth;
  late HomeFixData data;
  late ProfessionalService professionals;
  setUpAll(() async {
    sqfliteFfiInit();
    fixture.fixtureHash = await PasswordHasher.hash(fixture.demoPassword);
  });
  setUp(() async {
    db = await fixture.fixtureDatabase();
    repo = HomeFixRepository(database: () async => db);
    auth = AuthService(repository: repo);
    data = HomeFixData(repo);
    professionals = ProfessionalService(repository: repo);
    await data.refresh();
    await professionals.loadProfessionals();
  });
  tearDown(() async {
    data.dispose();
    professionals.dispose();
    auth.dispose();
    repo.dispose();
    await db.close();
  });
  Widget app(Widget page) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: repo),
            ChangeNotifierProvider.value(value: auth),
            ChangeNotifierProvider.value(value: data),
            ChangeNotifierProvider.value(value: professionals)
          ],
          child: MaterialApp(
              theme: ThemeData(
                  useMaterial3: true,
                  colorScheme:
                      ColorScheme.fromSeed(seedColor: const Color(0xFF0D9488))),
              home: page));

  testWidgets('admin is routed to exactly complaints and user accounts',
      (tester) async {
    await tester.runAsync(() => auth.login(
        email: 'admin@homefix.test', password: fixture.demoPassword));
    await tester.runAsync(data.refresh);
    await tester.pumpWidget(app(const MainShellScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(AdminScreen), findsOneWidget);
    final navigation =
        tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    expect(
        navigation.items.map((e) => e.label), ['Réclamations', 'Utilisateurs']);
    await tester.tap(find.text('Utilisateurs').last);
    await tester.pumpAndSettle();
    expect(find.text('client'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('pro'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'professional can choose Sunday and the client calendar follows it',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() =>
        auth.login(email: 'pro@homefix.test', password: fixture.demoPassword));
    await tester.runAsync(data.refresh);
    await tester.pumpWidget(app(const ProfileScreen()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Modifier mes jours de travail'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modifier mes jours de travail'));
    await tester.pumpAndSettle();
    expect(find.byType(EditProfileScreen), findsOneWidget);
    expect(find.byType(FilterChip), findsNWidgets(7));
    for (final day in ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam']) {
      final chip = find.widgetWithText(FilterChip, day);
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.text('Enregistrer les modifications'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer les modifications'));
    await tester.pumpAndSettle();
    await tester.runAsync(professionals.loadProfessionals);
    final pro = professionals.getById('pro')!;
    expect(pro.availableDays, ['Dim']);
    await tester.runAsync(() => auth.login(
        email: 'client@homefix.test', password: fixture.demoPassword));
    await tester.runAsync(data.refresh);
    await tester.pumpWidget(app(
        BookingFormScreen(professional: pro, service: pro.services.single)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Date'));
    await tester.pumpAndSettle();
    final calendar =
        tester.widget<CalendarDatePicker>(find.byType(CalendarDatePicker));
    final sunday = DateTime(2027, 1, 3);
    expect(calendar.initialDate!.weekday, DateTime.sunday);
    expect(calendar.selectableDayPredicate!(sunday), isTrue);
    expect(
        calendar.selectableDayPredicate!(sunday.add(const Duration(days: 1))),
        isFalse);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'home and artisan details fit narrow screens and expose real actions',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(const HomeScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Notifications'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
        app(ProDetailScreen(professional: professionals.getById('pro')!)));
    await tester.pumpAndSettle();
    expect(find.text('Appeler'), findsNothing);
    expect(find.text('Message'), findsNothing);
    expect(find.byIcon(Icons.favorite_border), findsNothing);
    await tester.scrollUntilVisible(find.byType(WeekDays), 180,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.byType(WeekDays), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('service editor validates input and saves an owned offering',
      (tester) async {
    await tester.runAsync(() =>
        auth.login(email: 'pro@homefix.test', password: fixture.demoPassword));
    await tester.runAsync(data.refresh);
    await tester.pumpWidget(app(const ServiceEditorScreen()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Enregistrer'));
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text('Au moins 3 caractères.'), findsOneWidget);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Nouvelle intervention');
    await tester.enterText(
        fields.at(1), 'Une intervention complète de plomberie.');
    await tester.enterText(fields.at(2), '75,50');
    await tester.enterText(fields.at(3), '90');
    await tester.ensureVisible(find.text('Enregistrer'));
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    final rows = (await tester.runAsync(() => repo.services('pro')))!;
    expect(
        rows.any((s) =>
            s.title == 'Nouvelle intervention' &&
            s.price == 75.5 &&
            s.proId == 'pro'),
        isTrue);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'client books the selected service then files its linked complaint',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() => auth.login(
        email: 'client@homefix.test', password: fixture.demoPassword));
    await tester.runAsync(data.refresh);
    final pro = professionals.getById('pro')!;
    await tester.pumpWidget(app(
        BookingFormScreen(professional: pro, service: pro.services.single)));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextFormField).first, '12 Avenue de Tunis');
    await tester.ensureVisible(find.text('Confirmer la demande'));
    await tester.tap(find.text('Confirmer la demande'));
    await tester.pumpAndSettle();
    await tester.runAsync(data.refresh);
    await tester.pumpAndSettle();
    expect(find.byType(BookingDetailScreen), findsOneWidget);
    expect(find.text('55.00 DT'), findsOneWidget);
    final booking = ((await tester.runAsync(repo.bookings))!).single;
    expect(booking.serviceId, 'service_pro');
    expect(booking.clientId, 'client');
    expect(booking.proId, 'pro');
    // Let the booking confirmation message finish before interacting below it.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Déposer une réclamation'));
    await tester.tap(find.text('Déposer une réclamation'));
    await tester.pumpAndSettle();
    expect(find.byType(ReclamationFormScreen), findsOneWidget);
    await tester.enterText(
        find.byType(TextFormField).at(0), 'Demande de précision');
    await tester.enterText(find.byType(TextFormField).at(1),
        'Merci de clarifier le déroulement de cette intervention réservée.');
    await tester.ensureVisible(find.text('Envoyer à l’administration'));
    await tester.tap(find.text('Envoyer à l’administration'));
    await tester.pumpAndSettle();
    final complaint = ((await tester.runAsync(repo.reclamations))!).single;
    expect(complaint.bookingId, booking.id);
    expect(complaint.clientId, booking.clientId);
    expect(complaint.proId, booking.proId);
    expect(complaint.status, ReclamationStatus.pending);
    expect(find.byType(BookingDetailScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'admin reviews the actual booked client complaint through its form',
      (tester) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() => auth.login(
        email: 'client@homefix.test', password: fixture.demoPassword));
    final booking = (await tester.runAsync(() => repo.book(
        serviceId: 'service_pro',
        scheduledDate: fixture.futureSlot(),
        address: '12 Avenue de Tunis')))!;
    await tester.runAsync(() => repo.saveReclamation(
        bookingId: booking,
        subject: 'Intervention à analyser',
        description: 'Une description complète de la réclamation du client.'));
    final id = ((await tester.runAsync(repo.reclamations))!).single.id;
    await tester.runAsync(() => auth.login(
        email: 'admin@homefix.test', password: fixture.demoPassword));
    await tester.runAsync(data.refresh);
    await tester.pumpWidget(app(ReclamationDetailScreen(id: id)));
    await tester.pumpAndSettle();
    expect(find.text('client'), findsOneWidget);
    expect(find.text('pro'), findsOneWidget);
    await tester.ensureVisible(find.text('En cours d’analyse'));
    await tester.tap(find.text('En cours d’analyse'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Résolue').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(TextFormField).last);
    await tester.enterText(find.byType(TextFormField).last,
        'Une nouvelle intervention a été convenue avec les deux parties.');
    await tester.ensureVisible(find.text('Enregistrer le traitement'));
    await tester.tap(find.text('Enregistrer le traitement'));
    await tester.pumpAndSettle();
    expect(((await tester.runAsync(repo.reclamations))!).single.status,
        ReclamationStatus.resolved);
    expect(find.text('Analyse administrative'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
