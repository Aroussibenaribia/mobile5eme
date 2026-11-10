import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mobile5eme/core/data/app_schema.dart';
import 'package:mobile5eme/core/data/homefix_repository.dart';
import 'package:mobile5eme/core/data/password_hasher.dart';
import 'package:mobile5eme/models/booking_model.dart';
import 'package:mobile5eme/models/reclamation_model.dart';
import 'package:mobile5eme/models/user_model.dart';
import 'package:mobile5eme/services/auth_service.dart';
import 'package:mobile5eme/services/professional_service.dart';

const demoPassword = 'HomeFix123!';
late String fixtureHash;

Future<Database> fixtureDatabase() async {
  final db = await databaseFactoryFfiNoIsolate.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
          singleInstance: false,
          version: 2,
          onConfigure: (db) => db.execute('PRAGMA foreign_keys=ON'),
          onCreate: (db, _) => AppSchema.create(db, seed: false)));
  for (final entry in {
    'client': 'client',
    'client2': 'client',
    'pro': 'professional',
    'pro2': 'professional',
    'admin': 'admin'
  }.entries) {
    await db.insert('users', {
      'id': entry.key,
      'email': '${entry.key}@homefix.test',
      'fullName': entry.key,
      'phone': '22123456',
      'city': 'Tunis',
      'role': entry.value,
      'createdAt': DateTime.now().toIso8601String(),
      'passwordHash': fixtureHash
    });
  }
  for (final id in ['pro', 'pro2']) {
    await db.insert('professionals', {
      'id': id,
      'specialty': 'Plomberie',
      'availableDays':
          jsonEncode(['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'])
    });
    await db.insert('services', {
      'id': 'service_$id',
      'proId': id,
      'title': 'Réparer une fuite',
      'description': 'Diagnostic et réparation de la fuite.',
      'price': 55,
      'duration': '60 min',
      'durationMinutes': 60,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String()
    });
  }
  return db;
}

DateTime futureSlot([int hour = 10, int minute = 0]) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day + 2, hour, minute);
}

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    fixtureHash = await PasswordHasher.hash(demoPassword);
  });
  group('Password hashing', () {
    test('matches published PBKDF2-HMAC-SHA256 vectors', () {
      String hex(List<int> b) =>
          b.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
      expect(hex(PasswordHasher.derive('password', utf8.encode('salt'), 1)),
          '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b');
      expect(hex(PasswordHasher.derive('password', utf8.encode('salt'), 2)),
          'ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43');
    });
    test('uses independent salts and rejects incorrect/malformed credentials',
        () async {
      final next = await PasswordHasher.hash(demoPassword);
      expect(next, isNot(fixtureHash));
      expect(next, isNot(contains(demoPassword)));
      expect(await PasswordHasher.verify(demoPassword, next), isTrue);
      expect(await PasswordHasher.verify('wrong-password', next), isFalse);
      expect(await PasswordHasher.verify(demoPassword, 'invalid'), isFalse);
    });
  });

  group('Real SQLite repository', () {
    late Database db;
    late HomeFixRepository repo;
    Future<void> login(String id) async {
      await repo.login('$id@homefix.test', demoPassword);
    }

    Future<String> book([DateTime? slot]) => repo.book(
        serviceId: 'service_pro',
        scheduledDate: slot ?? futureSlot(),
        address: '12 Avenue de Tunis');
    Future<String> complaint(String booking) async {
      await repo.saveReclamation(
          bookingId: booking,
          subject: 'Fuite persistante',
          description: 'La fuite persiste malgré la réparation effectuée.');
      return (await repo.reclamations()).first.id;
    }

    setUp(() async {
      db = await fixtureDatabase();
      repo = HomeFixRepository(database: () async => db);
    });
    tearDown(() async {
      repo.dispose();
      await db.close();
    });

    test('auth persists its session and logout removes access', () async {
      final auth = AuthService(repository: repo);
      expect(auth.isAuthenticated, isFalse);
      expect(
          await auth.login(
              email: ' CLIENT@HOMEFIX.TEST ', password: demoPassword),
          isTrue);
      expect(auth.currentUser!.id, 'client');
      final reopened = HomeFixRepository(database: () async => db);
      expect((await reopened.currentUser())!.id, 'client');
      reopened.dispose();
      await auth.logout();
      expect(auth.currentUser, isNull);
      expect(await repo.currentUser(), isNull);
      expect(await repo.bookings(), isEmpty);
      auth.dispose();
    });
    test('public registration cannot grant admin and duplicate email is atomic',
        () async {
      await expectLater(
          repo.register(
              fullName: 'Fake Admin',
              email: 'new@homefix.test',
              password: demoPassword,
              phone: '22123456',
              city: 'Tunis',
              role: UserRole.admin),
          throwsA(isA<HomeFixException>()));
      await expectLater(
          repo.register(
              fullName: 'New Pro',
              email: 'PRO@HOMEFIX.TEST',
              password: demoPassword,
              phone: '22123456',
              city: 'Tunis',
              role: UserRole.professional,
              specialty: 'Plomberie'),
          throwsA(isA<HomeFixException>()));
      expect((await db.query('users')).length, 5);
      expect((await db.query('professionals')).length, 2);
    });

    test('unchecked remember-me remains valid only until the next app session',
        () async {
      await repo.login('client@homefix.test', demoPassword, rememberMe: false);
      expect((await repo.currentUser())!.id, 'client');
      expect(await repo.restoreSession(), isNull);
      await login('client');
      expect((await repo.restoreSession())!.id, 'client');
    });

    test('session migration preserves an existing remembered login', () async {
      await db.execute('DROP TABLE app_session');
      await db.execute(
          'CREATE TABLE app_session(id INTEGER PRIMARY KEY, userId TEXT REFERENCES users(id))');
      await db.insert('app_session', {'id': 1, 'userId': 'client'});
      await AppSchema.create(db, seed: false);
      expect((await repo.restoreSession())!.id, 'client');
    });
    test(
        'registration creates a linked pro; profile updates reach the catalogue',
        () async {
      final user = await repo.register(
          fullName: 'Nouvelle Artisane',
          email: 'new@homefix.test',
          password: demoPassword,
          phone: '22123456',
          city: 'Ariana',
          role: UserRole.professional,
          specialty: 'Maçonnerie');
      await repo.updateProfile(
          fullName: 'Nom modifié',
          phone: '22345678',
          city: 'Tunis',
          address: 'Nouvelle adresse');
      expect(
          (await repo.professionals()).singleWhere((p) => p.id == user.id).name,
          'Nom modifié');
      final row =
          (await db.query('users', where: 'id=?', whereArgs: [user.id])).single;
      expect(row['passwordHash'], isNot(demoPassword));
    });
    test('professional working days persist and control new bookings',
        () async {
      await login('pro');
      await repo.updateProfile(
          fullName: 'pro',
          phone: '22123456',
          city: 'Tunis',
          address: '',
          bio: 'Interventions de plomberie le dimanche.',
          availableDays: ['Dim'],
          isAvailable: true);
      final saved =
          (await repo.professionals()).singleWhere((p) => p.id == 'pro');
      expect(saved.availableDays, ['Dim']);
      expect(saved.bio, 'Interventions de plomberie le dimanche.');
      expect(
          (await repo.professionals())
              .singleWhere((p) => p.id == 'pro2')
              .availableDays
              .length,
          7);
      final start = futureSlot();
      final sunday = start.add(Duration(days: (7 - start.weekday) % 7));
      final monday = sunday.add(const Duration(days: 1));
      await login('client');
      await expectLater(book(monday), throwsA(isA<HomeFixException>()));
      final accepted = await book(sunday);
      await login('pro');
      await repo.updateProfile(
          fullName: 'pro',
          phone: '22123456',
          city: 'Tunis',
          address: '',
          availableDays: ['Lun'],
          isAvailable: false);
      expect((await repo.bookings()).single.id, accepted);
      await login('client');
      await expectLater(book(monday), throwsA(isA<HomeFixException>()));
    });
    test(
        'schedule validation and professional role protect atomic profile updates',
        () async {
      await login('pro');
      for (final days in <List<String>>[
        [],
        ['Invalid'],
        ['Lun', 'Lun']
      ]) {
        await expectLater(
            repo.updateProfile(
                fullName: 'Should not save',
                phone: '22123456',
                city: 'Tunis',
                address: '',
                availableDays: days),
            throwsA(isA<HomeFixException>()));
      }
      expect((await repo.currentUser())!.fullName, 'pro');
      await login('client');
      await expectLater(
          repo.updateProfile(
              fullName: 'Should not save',
              phone: '22123456',
              city: 'Tunis',
              address: '',
              availableDays: ['Dim'],
              isAvailable: false),
          throwsA(isA<HomeFixException>()));
      expect((await repo.currentUser())!.fullName, 'client');
    });
    test('professional catalogue loads SQLite and filters existing API',
        () async {
      final service = ProfessionalService(repository: repo);
      await service.loadProfessionals();
      expect(service.allProfessionals.length, 2);
      service.setCategory('Électricité');
      expect(service.filteredProfessionals, isEmpty);
      service.setCategory('Tous');
      service.setSearchQuery('pro2');
      expect(service.filteredProfessionals.single.id, 'pro2');
      service.dispose();
    });
    test('service CRUD checks ownership and preserves linked bookings',
        () async {
      await login('pro');
      await repo.saveService(
          title: 'Nouvelle prestation',
          description: 'Description complète de la prestation.',
          price: 80,
          durationMinutes: 90);
      final created = (await repo.services('pro'))
          .firstWhere((s) => s.title == 'Nouvelle prestation');
      expect(created.proId, 'pro');
      expect(created.id, isNotEmpty);
      await login('pro2');
      await expectLater(
          repo.saveService(
              id: created.id,
              title: 'Tentative modification',
              description: 'Cette modification ne doit jamais passer.',
              price: 1,
              durationMinutes: 60),
          throwsA(isA<HomeFixException>()));
      await expectLater(
          repo.deleteService(created.id), throwsA(isA<HomeFixException>()));
      await expectLater(repo.services('pro', includeInactive: true),
          throwsA(isA<HomeFixException>()));
      await login('client');
      await book();
      await login('pro');
      expect(await repo.deleteService('service_pro'), isFalse);
      expect(
          (await repo.services('pro', includeInactive: true))
              .singleWhere((s) => s.id == 'service_pro')
              .isActive,
          isFalse);
      expect(await repo.deleteService(created.id), isTrue);
      expect((await repo.bookings()).length, 1);
    });
    test('bookings derive users and snapshot service data', () async {
      await login('client');
      final id = await book();
      final b = (await repo.bookings()).single;
      expect(
          (b.clientId, b.proId, b.serviceId), ('client', 'pro', 'service_pro'));
      await login('pro');
      await repo.saveService(
          id: 'service_pro',
          title: 'Nouveau titre',
          description: 'Description modifiée après la réservation.',
          price: 100,
          durationMinutes: 120);
      await login('client');
      final old = (await repo.bookings()).singleWhere((b) => b.id == id);
      expect(old.estimatedPrice, 55);
      expect(old.serviceTitle, 'Réparer une fuite');
      expect(old.durationMinutes, 60);
    });
    test(
        'overlapping slots conflict, adjacent slots work and cancellation releases time',
        () async {
      await login('client');
      final first = await book();
      await login('client2');
      await expectLater(
          book(futureSlot(10, 30)), throwsA(isA<HomeFixException>()));
      await book(futureSlot(11));
      await login('client');
      await repo.updateBookingStatus(first, BookingStatus.cancelled);
      await login('client2');
      await book();
      expect((await repo.bookings()).length, 2);
    });
    test('concurrent reservation attempts cannot double-book', () async {
      await login('client');
      final results = await Future.wait([
        book().then<Object>((id) => id).catchError((Object e) => e),
        book().then<Object>((id) => id).catchError((Object e) => e)
      ]);
      expect(results.whereType<String>().length, 1);
      expect(results.whereType<HomeFixException>().length, 1);
    });
    test('rejects unavailable services, invalid hours and stale prices',
        () async {
      await login('client');
      await expectLater(
          book(futureSlot(19, 30)), throwsA(isA<HomeFixException>()));
      await expectLater(
          repo.book(
              serviceId: 'service_pro',
              scheduledDate: futureSlot(),
              address: 'Adresse complète',
              expectedPrice: 1),
          throwsA(isA<HomeFixException>()));
      await login('pro');
      await repo.deleteService('service_pro');
      await login('client');
      await expectLater(book(), throwsA(isA<HomeFixException>()));
    });
    test('status transitions belong to the correct professional/client',
        () async {
      await login('client');
      final id = await book();
      await expectLater(repo.updateBookingStatus(id, BookingStatus.confirmed),
          throwsA(isA<HomeFixException>()));
      await login('pro2');
      await expectLater(repo.updateBookingStatus(id, BookingStatus.confirmed),
          throwsA(isA<HomeFixException>()));
      await login('pro');
      for (final status in [
        BookingStatus.confirmed,
        BookingStatus.inProgress,
        BookingStatus.completed
      ]) {
        await repo.updateBookingStatus(id, status);
      }
      await login('client');
      await expectLater(repo.updateBookingStatus(id, BookingStatus.cancelled),
          throwsA(isA<HomeFixException>()));
    });
    test(
        'SQL foreign keys reject mismatched booking and complaint participants',
        () async {
      await login('client');
      final id = await book();
      await expectLater(
          db.update('bookings', {'proId': 'pro2'},
              where: 'id=?', whereArgs: [id]),
          throwsA(isA<DatabaseException>()));
      await expectLater(
          db.insert('reclamations', {
            'id': 'forged',
            'bookingId': id,
            'clientId': 'client2',
            'proId': 'pro',
            'subject': 'Invalid relation',
            'description': 'Invalid participants',
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String()
          }),
          throwsA(isA<DatabaseException>()));
    });
    test(
        'complaints are scoped to booking owner and prevent duplicate open cases',
        () async {
      await login('client');
      final booking = await book();
      final id = await complaint(booking);
      await expectLater(complaint(booking), throwsA(isA<HomeFixException>()));
      await login('client2');
      expect(await repo.reclamations(), isEmpty);
      await expectLater(complaint(booking), throwsA(isA<HomeFixException>()));
      await expectLater(
          repo.deleteReclamation(id), throwsA(isA<HomeFixException>()));
      await login('pro');
      expect((await repo.reclamations()).single.clientId, 'client');
      await login('pro2');
      expect(await repo.reclamations(), isEmpty);
    });
    test('only pending client complaints can be edited or deleted', () async {
      await login('client');
      final booking = await book();
      final id = await complaint(booking);
      await repo.saveReclamation(
          id: id,
          bookingId: booking,
          subject: 'Objet actualisé',
          description: 'Une description actualisée suffisamment détaillée.');
      expect((await repo.reclamations()).single.subject, 'Objet actualisé');
      await repo.deleteReclamation(id);
      expect(await repo.reclamations(), isEmpty);
    });
    test(
        'only admin reviews; review locks client edits and terminal decisions are final',
        () async {
      await login('client');
      final booking = await book();
      final id = await complaint(booking);
      await expectLater(
          repo.reviewReclamation(
              id, ReclamationStatus.resolved, 'Réponse non autorisée.'),
          throwsA(isA<HomeFixException>()));
      await login('pro');
      await expectLater(
          repo.reviewReclamation(
              id, ReclamationStatus.resolved, 'Réponse non autorisée.'),
          throwsA(isA<HomeFixException>()));
      await login('admin');
      await repo.reviewReclamation(id, ReclamationStatus.inReview,
          'Nous analysons les informations de cette intervention.');
      await login('client');
      await expectLater(
          repo.deleteReclamation(id), throwsA(isA<HomeFixException>()));
      await expectLater(
          repo.saveReclamation(
              id: id,
              bookingId: booking,
              subject: 'Modifier le litige',
              description: 'Impossible de modifier une réclamation en cours.'),
          throwsA(isA<HomeFixException>()));
      await login('admin');
      await repo.reviewReclamation(id, ReclamationStatus.resolved,
          'Une nouvelle intervention a été convenue avec les deux parties.');
      final r = (await repo.reclamations()).single;
      expect(r.reviewedByAdminId, 'admin');
      expect(r.reviewedAt, isNotNull);
      expect(r.status, ReclamationStatus.resolved);
      await expectLater(
          repo.reviewReclamation(id, ReclamationStatus.rejected,
              'Modifier une décision déjà clôturée.'),
          throwsA(isA<HomeFixException>()));
    });
    test(
        'admin user tools protect admin accounts and suspend professional visibility',
        () async {
      await login('client');
      await expectLater(repo.users(), throwsA(isA<HomeFixException>()));
      await login('admin');
      expect((await repo.users()).length, 5);
      await expectLater(
          repo.setUserActive('admin', false), throwsA(isA<HomeFixException>()));
      await repo.setUserActive('pro', false);
      expect((await repo.professionals()).any((p) => p.id == 'pro'), isFalse);
      await expectLater(login('pro'), throwsA(isA<HomeFixException>()));
      await repo.setUserActive('pro', true);
      await login('pro');
      expect((await repo.currentUser())!.isProfessional, isTrue);
    });
    test('admin password reset changes real credentials', () async {
      await login('admin');
      await repo.resetUserPassword('client', 'ChangedPass123!');
      await expectLater(login('client'), throwsA(isA<HomeFixException>()));
      await repo.login('client@homefix.test', 'ChangedPass123!');
      expect((await repo.currentUser())!.id, 'client');
    });
  });

  test('schema upgrade keeps existing forum records', () async {
    final directory =
        await Directory.systemTemp.createTemp('homefix_migration_');
    final path = '${directory.path}${Platform.pathSeparator}legacy.db';
    final old = await databaseFactoryFfiNoIsolate.openDatabase(path,
        options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, _) async {
              await db.execute(
                  'CREATE TABLE forum_posts(id TEXT PRIMARY KEY,title TEXT)');
              await db.insert('forum_posts',
                  {'id': 'existing', 'title': 'Question conservée'});
            }));
    await old.close();
    final upgraded = await databaseFactoryFfiNoIsolate.openDatabase(path,
        options: OpenDatabaseOptions(
            version: 2,
            onUpgrade: (db, oldVersion, newVersion) =>
                AppSchema.create(db, seed: false)));
    expect((await upgraded.query('forum_posts')).single['title'],
        'Question conservée');
    expect(await upgraded.query('users'), isEmpty);
    await upgraded.close();
    final resolved = await directory.resolveSymbolicLinks();
    if (resolved
        .startsWith(await Directory.systemTemp.resolveSymbolicLinks())) {
      await directory.delete(recursive: true);
    }
  });
}
