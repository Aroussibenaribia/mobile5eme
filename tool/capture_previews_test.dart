// Actual Flutter widgets rendered against the production SQLite seed data.
// Run explicitly: flutter test --no-pub tool/capture_previews_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mobile5eme/core/data/app_schema.dart';
import 'package:mobile5eme/core/data/homefix_repository.dart';
import 'package:mobile5eme/core/theme/app_theme.dart';
import 'package:mobile5eme/features/admin/screens/admin_screen.dart';
import 'package:mobile5eme/features/home/screens/home_screen.dart';
import 'package:mobile5eme/features/profile/screens/profile_screen.dart';
import 'package:mobile5eme/features/profile/screens/edit_profile_screen.dart';
import 'package:mobile5eme/features/professionals/screens/pro_list_screen.dart';
import 'package:mobile5eme/features/professionals/screens/pro_detail_screen.dart';
import 'package:mobile5eme/features/auth/screens/login_screen.dart';
import 'package:mobile5eme/features/services/screens/services_screen.dart';
import 'package:mobile5eme/features/search_and_booking/screens/booking_screens.dart';
import 'package:mobile5eme/features/reviews_and_history/screens/reclamation_screens.dart';
import 'package:mobile5eme/services/auth_service.dart';
import 'package:mobile5eme/services/homefix_data.dart';
import 'package:mobile5eme/services/professional_service.dart';

void main() {
  late Database db;
  late HomeFixRepository repo;
  late AuthService auth;
  late HomeFixData data;
  late ProfessionalService professionals;
  late ThemeData previewTheme;
  final boundaryKey = GlobalKey();

  setUpAll(() async {
    sqfliteFfiInit();
    db = await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(
            singleInstance: false,
            onConfigure: (db) => db.execute('PRAGMA foreign_keys=ON'),
            onCreate: (db, _) => AppSchema.create(db),
            version: 3));
    repo = HomeFixRepository(database: () async => db);
    auth = AuthService(repository: repo);
    data = HomeFixData(repo);
    professionals = ProfessionalService(repository: repo);
    await data.refresh();
    await professionals.loadProfessionals();

    // The app uses Plus Jakarta Sans. The preview uses Flutter's local Roboto
    // so screenshot generation requires no font downloads or cloud services.
    final sdk = Platform.environment['FLUTTER_ROOT'];
    if (sdk == null) throw StateError('Set FLUTTER_ROOT to the Flutter SDK.');
    final font =
        File('$sdk/bin/cache/artifacts/material_fonts/roboto-regular.ttf');
    final loader = FontLoader('Roboto')
      ..addFont(Future.value(ByteData.sublistView(await font.readAsBytes())));
    await loader.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(await File(
              '$sdk/bin/cache/artifacts/material_fonts/materialicons-regular.otf')
          .readAsBytes())));
    await icons.load();
    final symbolsPath = Platform.environment['HOMEFIX_PREVIEW_SYMBOL_FONT'];
    if (symbolsPath != null) {
      final symbols = FontLoader('PreviewSymbols')
        ..addFont(Future.value(
            ByteData.sublistView(await File(symbolsPath).readAsBytes())));
      await symbols.load();
    }
    final theme = AppTheme.withTextTheme(ThemeData.light().textTheme.apply(
        fontFamily: 'Roboto', fontFamilyFallback: const ['PreviewSymbols']));
    previewTheme = theme.copyWith(
        appBarTheme: theme.appBarTheme.copyWith(
            titleTextStyle: theme.appBarTheme.titleTextStyle!
                .copyWith(fontFamily: 'Roboto')),
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: theme.elevatedButtonTheme.style!.copyWith(
                textStyle: WidgetStatePropertyAll(theme
                    .elevatedButtonTheme.style!.textStyle!
                    .resolve({})!.copyWith(fontFamily: 'Roboto')))));
    await Directory('docs/previews').create(recursive: true);
  });

  tearDownAll(() async {
    data.dispose();
    professionals.dispose();
    auth.dispose();
    repo.dispose();
    await db.close();
  });

  Widget app(Widget page) => RepaintBoundary(
      key: boundaryKey,
      child: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: repo),
            ChangeNotifierProvider.value(value: auth),
            ChangeNotifierProvider.value(value: data),
            ChangeNotifierProvider.value(value: professionals)
          ],
          child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: previewTheme,
              home: page)));

  testWidgets('capture real SQLite screens at phone size', (tester) async {
    debugDisableShadows = false;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<void> login(String email) async {
      final result = await tester
          .runAsync(() => auth.login(email: email, password: 'HomeFix123!'));
      expect(result, isTrue);
      await tester.runAsync(data.refresh);
    }

    Future<void> save(String name) async {
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final boundary = boundaryKey.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final bitmap = await boundary.toImage(pixelRatio: 2);
        final png = await bitmap.toByteData(format: ui.ImageByteFormat.png);
        await File('docs/previews/$name.png')
            .writeAsBytes(png!.buffer.asUint8List());
        bitmap.dispose();
      });
    }

    await login('admin@homefix.com');
    await tester.pumpWidget(app(const AdminScreen()));
    await save('01-admin-reclamations');
    await tester.tap(find.text('Utilisateurs').last);
    await save('02-admin-utilisateurs');
    await tester
        .pumpWidget(app(const ReclamationDetailScreen(id: 'reclamation_demo')));
    await save('03-analyse-reclamation');
    await tester.drag(find.byType(ListView).first, const Offset(0, -530));
    await save('04-decision-admin');

    await login('pro@homefix.com');
    await tester.pumpWidget(app(const ServicesScreen()));
    await save('05-services-professionnel');
    await tester.pumpWidget(app(const ServiceEditorScreen()));
    await save('06-nouvelle-prestation');

    await login('client@homefix.com');
    final pro = professionals.getById('pro_karim')!;
    await tester.pumpWidget(
        app(BookingFormScreen(professional: pro, service: pro.services.first)));
    await save('07-reservation-client');
    await tester.pumpWidget(
        app(const BookingDetailScreen(id: 'booking_demo_completed')));
    await save('08-detail-reservation');
    await tester.pumpWidget(
        app(const ReclamationFormScreen(bookingId: 'booking_demo_completed')));
    await save('09-reclamation-client');
    await tester.pumpWidget(app(const HomeScreen()));
    await save('10-accueil-client');
    await tester.pumpWidget(app(const ProListScreen()));
    await save('11-catalogue-artisans');
    await tester.pumpWidget(app(ProDetailScreen(professional: pro)));
    await save('12-fiche-artisan');
    await tester.pumpWidget(app(const LoginScreen()));
    await save('13-connexion');
    await login('pro@homefix.com');
    await tester.pumpWidget(app(const ProfileScreen()));
    await save('14-profil-professionnel');
    await tester.pumpWidget(app(const EditProfileScreen()));
    await save('15-modifier-profil');
    await tester.drag(
        find.byType(SingleChildScrollView).first, const Offset(0, -650));
    await save('16-jours-de-travail');
    await tester.pumpWidget(app(const HomeScreen()));
    await save('17-accueil-professionnel');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    debugDisableShadows = true;
  }, timeout: const Timeout(Duration(minutes: 3)));
}
