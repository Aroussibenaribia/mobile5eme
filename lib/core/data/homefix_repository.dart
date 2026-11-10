import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../features/forum/data/forum_database.dart';
import '../../models/user_model.dart';
import '../../models/professional_model.dart';
import '../../models/booking_model.dart';
import '../../models/reclamation_model.dart';
import '../../models/work_schedule.dart';
import 'password_hasher.dart';

class HomeFixException implements Exception {
  final String message;
  const HomeFixException(this.message);
  @override
  String toString() => message;
}

class HomeFixRepository extends ChangeNotifier {
  final Future<Database> Function() _open;
  HomeFixRepository({Future<Database> Function()? database})
      : _open = database ?? (() => ForumDatabase.instance.database);
  Future<Database> get database => _open();

  static String newId() {
    final random = Random.secure();
    return List.generate(
            16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'))
        .join();
  }

  static String _text(String text, String label, {int min = 1, int max = 200}) {
    final value = text.trim();
    if (value.length < min || value.length > max) {
      throw HomeFixException('$label : $min à $max caractères.');
    }
    return value;
  }

  static void _password(String password) {
    if (password.length < 8 || password.length > 128) {
      throw const HomeFixException(
          'Le mot de passe doit contenir 8 à 128 caractères.');
    }
  }

  Future<UserModel?> currentUser([DatabaseExecutor? executor]) async {
    final db = executor ?? await database;
    final rows = await db.rawQuery(
        'SELECT u.* FROM users u JOIN app_session s ON s.userId=u.id WHERE s.id=1 AND u.isActive=1');
    return rows.isEmpty ? null : UserModel.fromMap(rows.first);
  }

  Future<UserModel?> restoreSession() async {
    final db = await database;
    await db.delete('app_session', where: 'rememberMe=0');
    return currentUser(db);
  }

  Future<UserModel> _actor(DatabaseExecutor db, [UserRole? role]) async {
    final user = await currentUser(db);
    if (user == null) {
      throw const HomeFixException('Connectez-vous pour continuer.');
    }
    if (role != null && user.role != role) {
      throw const HomeFixException('Cette action ne vous est pas autorisée.');
    }
    return user;
  }

  Future<UserModel> login(String email, String password,
      {bool rememberMe = true}) async {
    final db = await database;
    final rows = await db.query('users',
        where: 'email = ?', whereArgs: [email.trim().toLowerCase()]);
    if (rows.isEmpty ||
        !await PasswordHasher.verify(
            password, rows.first['passwordHash'] as String)) {
      throw const HomeFixException('Adresse e-mail ou mot de passe incorrect.');
    }
    if (rows.first['isActive'] != 1) {
      throw const HomeFixException(
          'Ce compte est suspendu. Contactez l’administration.');
    }
    final user = UserModel.fromMap(rows.first);
    await db.insert('app_session',
        {'id': 1, 'userId': user.id, 'rememberMe': rememberMe ? 1 : 0},
        conflictAlgorithm: ConflictAlgorithm.replace);
    notifyListeners();
    return user;
  }

  Future<void> logout() async {
    await (await database).delete('app_session');
    notifyListeners();
  }

  Future<UserModel> register(
      {required String fullName,
      required String email,
      required String password,
      required String phone,
      required String city,
      required UserRole role,
      String specialty = '',
      double hourlyRate = 35,
      int experienceYears = 1,
      String bio = ''}) async {
    if (role == UserRole.admin) {
      throw const HomeFixException(
          'Les comptes administrateurs ne peuvent pas être créés ici.');
    }
    final name = _text(fullName, 'Nom', min: 2, max: 100);
    final cleanEmail = email.trim().toLowerCase();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(cleanEmail) ||
        cleanEmail.length > 180) {
      throw const HomeFixException('Adresse e-mail invalide.');
    }
    _password(password);
    if (role == UserRole.professional &&
        (!hourlyRate.isFinite ||
            hourlyRate <= 0 ||
            experienceYears < 0 ||
            experienceYears > 80)) {
      throw const HomeFixException('Tarif ou expérience invalide.');
    }
    if (role == UserRole.professional) _text(specialty, 'Spécialité', max: 80);
    final hash = await PasswordHasher.hash(password);
    final user = UserModel(
        id: newId(),
        email: cleanEmail,
        fullName: name,
        phone: _text(phone, 'Téléphone', min: 8, max: 25),
        role: role,
        city: _text(city, 'Ville', min: 2, max: 80),
        createdAt: DateTime.now());
    final db = await database;
    await db.transaction((tx) async {
      if ((await tx.query('users',
              columns: ['id'], where: 'email=?', whereArgs: [cleanEmail]))
          .isNotEmpty) {
        throw const HomeFixException('Cette adresse e-mail est déjà utilisée.');
      }
      await tx.insert('users', {...user.toMap(), 'passwordHash': hash});
      if (role == UserRole.professional) {
        await tx.insert('professionals', {
          'id': user.id,
          'specialty': specialty.trim(),
          'bio': bio.trim(),
          'hourlyRate': hourlyRate,
          'experienceYears': experienceYears,
          'skills': jsonEncode([specialty.trim()]),
          'availableDays':
              jsonEncode(['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'])
        });
      }
      await tx.insert('app_session', {'id': 1, 'userId': user.id},
          conflictAlgorithm: ConflictAlgorithm.replace);
    });
    notifyListeners();
    return user;
  }

  Future<UserModel> updateProfile(
      {required String fullName,
      required String phone,
      required String city,
      required String address,
      String? avatarUrl,
      String? bio,
      List<String>? availableDays,
      bool? isAvailable}) async {
    final db = await database;
    final result = await db.transaction((tx) async {
      final actor = await _actor(tx);
      if (bio != null || availableDays != null || isAvailable != null) {
        if (!actor.isProfessional) {
          throw const HomeFixException(
              'Seul un professionnel peut modifier ses disponibilités.');
        }
        final professionalValues = <String, Object?>{};
        if (bio != null) {
          professionalValues['bio'] =
              _text(bio, 'Présentation', min: 0, max: 2000);
        }
        if (availableDays != null) {
          if (availableDays.isEmpty ||
              availableDays.any((day) => !WorkSchedule.days.contains(day)) ||
              availableDays.toSet().length != availableDays.length) {
            throw const HomeFixException(
                'Choisissez au moins un jour de travail valide.');
          }
          professionalValues['availableDays'] =
              jsonEncode(WorkSchedule.ordered(availableDays));
        }
        if (isAvailable != null) {
          professionalValues['isAvailable'] = isAvailable ? 1 : 0;
        }
        await tx.update('professionals', professionalValues,
            where: 'id=?', whereArgs: [actor.id]);
      }
      final values = <String, Object?>{
        'fullName': _text(fullName, 'Nom', min: 2, max: 100),
        'phone': _text(phone, 'Téléphone', min: 8, max: 25),
        'city': _text(city, 'Ville', min: 2, max: 80),
        'address': _text(address, 'Adresse', min: 0, max: 250)
      };
      if (avatarUrl != null) values['avatarUrl'] = avatarUrl;
      await tx.update('users', values, where: 'id=?', whereArgs: [actor.id]);
      return (await currentUser(tx))!;
    });
    notifyListeners();
    return result;
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    _password(newPassword);
    final db = await database;
    final actor = await _actor(db);
    final row =
        (await db.query('users', where: 'id=?', whereArgs: [actor.id])).single;
    if (!await PasswordHasher.verify(
        oldPassword, row['passwordHash'] as String)) {
      throw const HomeFixException('Mot de passe actuel incorrect.');
    }
    final hash = await PasswordHasher.hash(newPassword);
    await db.transaction((tx) async {
      if ((await _actor(tx)).id != actor.id) {
        throw const HomeFixException('La session a changé.');
      }
      await tx.update('users', {'passwordHash': hash},
          where: 'id=?', whereArgs: [actor.id]);
    });
  }

  Future<List<ProfessionalModel>> professionals() async {
    final db = await database;
    final rows = await db.rawQuery(
        '''SELECT p.*,u.fullName AS name,u.email,u.phone,u.city,u.address,u.avatarUrl
      FROM professionals p JOIN users u ON u.id=p.id WHERE u.isActive=1 ORDER BY p.rating DESC,u.fullName''');
    final services =
        await db.query('services', where: 'isActive=1', orderBy: 'title');
    return rows
        .map((r) => ProfessionalModel.fromMap({
              ...r,
              'isVerified': r['isVerified'] == 1,
              'isAvailable': r['isAvailable'] == 1,
              'skills': jsonDecode(r['skills'] as String),
              'availableDays': jsonDecode(r['availableDays'] as String),
              'services': services.where((s) => s['proId'] == r['id']).toList()
            }))
        .toList();
  }

  Future<List<ServiceModel>> services(String proId,
      {bool includeInactive = false}) async {
    final db = await database;
    if (includeInactive) {
      final actor = await _actor(db);
      if (actor.role != UserRole.admin &&
          (actor.role != UserRole.professional || actor.id != proId)) {
        throw const HomeFixException('Accès non autorisé.');
      }
    }
    return (await db.query('services',
            where: 'proId=?${includeInactive ? '' : ' AND isActive=1'}',
            whereArgs: [proId],
            orderBy: 'isActive DESC,title'))
        .map(ServiceModel.fromMap)
        .toList();
  }

  Future<void> saveService(
      {String? id,
      required String title,
      required String description,
      required double price,
      required int durationMinutes,
      bool isActive = true}) async {
    final name = _text(title, 'Titre', min: 3, max: 100);
    final details = _text(description, 'Description', min: 10, max: 2000);
    if (!price.isFinite ||
        price <= 0 ||
        price > 1000000 ||
        durationMinutes < 15 ||
        durationMinutes > 480) {
      throw const HomeFixException(
          'Prix positif et durée de 15 à 480 minutes requis.');
    }
    final db = await database;
    await db.transaction((tx) async {
      final actor = await _actor(tx, UserRole.professional);
      final now = DateTime.now().toIso8601String();
      final values = <String, Object?>{
        'title': name,
        'description': details,
        'price': price,
        'duration': '$durationMinutes min',
        'durationMinutes': durationMinutes,
        'isActive': isActive ? 1 : 0,
        'updatedAt': now
      };
      if (id == null) {
        await tx.insert('services',
            {...values, 'id': newId(), 'proId': actor.id, 'createdAt': now});
      } else {
        final rows = await tx.query('services',
            where: 'id=? AND proId=?', whereArgs: [id, actor.id]);
        if (rows.isEmpty) {
          throw const HomeFixException(
              'Service introuvable ou accès non autorisé.');
        }
        await tx.update('services', values,
            where: 'id=? AND proId=?', whereArgs: [id, actor.id]);
      }
    });
    notifyListeners();
  }

  /// Returns false when a booked service is archived to preserve its history.
  Future<bool> deleteService(String id) async {
    final db = await database;
    final removed = await db.transaction((tx) async {
      final actor = await _actor(tx, UserRole.professional);
      if ((await tx.query('services',
              where: 'id=? AND proId=?', whereArgs: [id, actor.id]))
          .isEmpty) {
        throw const HomeFixException(
            'Service introuvable ou accès non autorisé.');
      }
      final used = (await tx.query('bookings',
              columns: ['id'], where: 'serviceId=?', whereArgs: [id], limit: 1))
          .isNotEmpty;
      if (used) {
        await tx.update('services',
            {'isActive': 0, 'updatedAt': DateTime.now().toIso8601String()},
            where: 'id=?', whereArgs: [id]);
      } else {
        await tx.delete('services', where: 'id=?', whereArgs: [id]);
      }
      return !used;
    });
    notifyListeners();
    return removed;
  }

  Future<List<BookingModel>> bookings() async {
    final db = await database;
    final actor = await currentUser(db);
    if (actor == null) return [];
    final where = actor.isAdmin
        ? null
        : (actor.isProfessional ? 'proId=?' : 'clientId=?');
    return (await db.query('bookings',
            where: where,
            whereArgs: where == null ? null : [actor.id],
            orderBy: 'startEpoch DESC'))
        .map((m) => BookingModel.fromMap(m))
        .toList();
  }

  Future<String> book(
      {required String serviceId,
      required DateTime scheduledDate,
      required String address,
      String notes = '',
      double? expectedPrice}) async {
    final location = _text(address, 'Adresse', min: 5, max: 250);
    if (notes.length > 2000) {
      throw const HomeFixException('Notes trop longues.');
    }
    if (scheduledDate
            .isBefore(DateTime.now().add(const Duration(minutes: 5))) ||
        scheduledDate.isAfter(DateTime.now().add(const Duration(days: 365)))) {
      throw const HomeFixException(
          'Choisissez un créneau futur dans les 12 prochains mois.');
    }
    final db = await database;
    final id = await db.transaction((tx) async {
      final actor = await _actor(tx, UserRole.client);
      final rows = await tx.rawQuery(
          '''SELECT s.*,p.specialty,p.availableDays,p.isAvailable,u.fullName AS proName
        FROM services s JOIN professionals p ON p.id=s.proId JOIN users u ON u.id=p.id
        WHERE s.id=? AND s.isActive=1 AND u.isActive=1''', [serviceId]);
      if (rows.isEmpty || rows.single['isAvailable'] != 1) {
        throw const HomeFixException('Ce service n’est plus disponible.');
      }
      final service = rows.single;
      if (expectedPrice != null &&
          (service['price'] as num).toDouble() != expectedPrice) {
        throw const HomeFixException(
            'Le tarif a changé. Consultez à nouveau la prestation avant de réserver.');
      }
      final days = jsonDecode(service['availableDays'] as String) as List;
      const week = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      if (!days.contains(week[scheduledDate.weekday - 1]) ||
          scheduledDate.hour < 8 ||
          scheduledDate
              .add(Duration(minutes: service['durationMinutes'] as int))
              .isAfter(DateTime(scheduledDate.year, scheduledDate.month,
                  scheduledDate.day, 19))) {
        throw const HomeFixException(
            'Choisissez un jour disponible et un créneau entre 08h et 19h.');
      }
      final start = scheduledDate.millisecondsSinceEpoch;
      final end = start + (service['durationMinutes'] as int) * 60000;
      final conflicts = await tx.rawQuery(
          "SELECT id FROM bookings WHERE proId=? AND status!='cancelled' AND startEpoch<? AND endEpoch>?",
          [service['proId'], end, start]);
      if (conflicts.isNotEmpty) {
        throw const HomeFixException(
            'Ce créneau est déjà réservé. Choisissez un autre horaire.');
      }
      final id = newId();
      final now = DateTime.now().toIso8601String();
      await tx.insert('bookings', {
        'id': id,
        'serviceId': serviceId,
        'clientId': actor.id,
        'proId': service['proId'],
        'clientName': actor.fullName,
        'proName': service['proName'],
        'proSpecialty': service['specialty'],
        'serviceTitle': service['title'],
        'scheduledDate': scheduledDate.toIso8601String(),
        'timeSlot':
            '${scheduledDate.hour.toString().padLeft(2, '0')}:${scheduledDate.minute.toString().padLeft(2, '0')}',
        'address': location,
        'estimatedPrice': service['price'],
        'durationMinutes': service['durationMinutes'],
        'startEpoch': start,
        'endEpoch': end,
        'status': 'pending',
        'clientNotes': notes.trim(),
        'createdAt': now,
        'updatedAt': now
      });
      return id;
    });
    notifyListeners();
    return id;
  }

  Future<void> updateBookingStatus(String id, BookingStatus status) async {
    final db = await database;
    await db.transaction((tx) async {
      final actor = await _actor(tx);
      final rows = await tx.query('bookings', where: 'id=?', whereArgs: [id]);
      if (rows.isEmpty) {
        throw const HomeFixException('Réservation introuvable.');
      }
      final row = rows.single;
      final old = BookingStatus.values.byName(row['status'] as String);
      final clientCancel = actor.role == UserRole.client &&
          row['clientId'] == actor.id &&
          status == BookingStatus.cancelled &&
          [BookingStatus.pending, BookingStatus.confirmed].contains(old);
      final allowed = <BookingStatus, List<BookingStatus>>{
        BookingStatus.pending: [
          BookingStatus.confirmed,
          BookingStatus.cancelled
        ],
        BookingStatus.confirmed: [
          BookingStatus.inProgress,
          BookingStatus.cancelled
        ],
        BookingStatus.inProgress: [BookingStatus.completed]
      };
      final proUpdate = actor.isProfessional &&
          row['proId'] == actor.id &&
          (allowed[old]?.contains(status) ?? false);
      if (!clientCancel && !proUpdate) {
        throw const HomeFixException('Changement de statut non autorisé.');
      }
      await tx.update(
          'bookings',
          {
            'status': status.name,
            'updatedAt': DateTime.now().toIso8601String()
          },
          where: 'id=?',
          whereArgs: [id]);
    });
    notifyListeners();
  }

  Future<List<ReclamationModel>> reclamations() async {
    final db = await database;
    final actor = await currentUser(db);
    if (actor == null) return [];
    final where = actor.isAdmin
        ? ''
        : (actor.isProfessional ? ' WHERE r.proId=?' : ' WHERE r.clientId=?');
    final rows = await db.rawQuery(
        '''SELECT r.*,b.clientName,b.proName,b.serviceTitle FROM reclamations r
      JOIN bookings b ON b.id=r.bookingId$where ORDER BY r.createdAt DESC''',
        actor.isAdmin ? [] : [actor.id]);
    return rows.map(ReclamationModel.fromMap).toList();
  }

  Future<void> saveReclamation(
      {String? id,
      required String bookingId,
      required String subject,
      required String description}) async {
    final title = _text(subject, 'Objet', min: 5, max: 150);
    final body = _text(description, 'Description', min: 20, max: 4000);
    final db = await database;
    await db.transaction((tx) async {
      final actor = await _actor(tx, UserRole.client);
      final bookings = await tx.query('bookings',
          where: 'id=? AND clientId=?', whereArgs: [bookingId, actor.id]);
      if (bookings.isEmpty) {
        throw const HomeFixException(
            'Choisissez une réservation qui vous appartient.');
      }
      final now = DateTime.now().toIso8601String();
      if (id == null) {
        if ((await tx.rawQuery(
                "SELECT id FROM reclamations WHERE bookingId=? AND status IN ('pending','inReview')",
                [bookingId]))
            .isNotEmpty) {
          throw const HomeFixException(
              'Une réclamation est déjà ouverte pour cette réservation.');
        }
        await tx.insert('reclamations', {
          'id': newId(),
          'bookingId': bookingId,
          'clientId': actor.id,
          'proId': bookings.single['proId'],
          'subject': title,
          'description': body,
          'createdAt': now,
          'updatedAt': now
        });
      } else {
        final rows = await tx.query('reclamations',
            where: "id=? AND clientId=? AND status='pending'",
            whereArgs: [id, actor.id]);
        if (rows.isEmpty || rows.single['bookingId'] != bookingId) {
          throw const HomeFixException(
              'Seule une réclamation en attente peut être modifiée.');
        }
        await tx.update('reclamations',
            {'subject': title, 'description': body, 'updatedAt': now},
            where: 'id=?', whereArgs: [id]);
      }
    });
    notifyListeners();
  }

  Future<void> deleteReclamation(String id) async {
    final db = await database;
    await db.transaction((tx) async {
      final actor = await _actor(tx, UserRole.client);
      final count = await tx.delete('reclamations',
          where: "id=? AND clientId=? AND status='pending'",
          whereArgs: [id, actor.id]);
      if (count != 1) {
        throw const HomeFixException(
            'Seule votre réclamation en attente peut être supprimée.');
      }
    });
    notifyListeners();
  }

  Future<void> reviewReclamation(
      String id, ReclamationStatus status, String response) async {
    final note = _text(response, 'Réponse administrative', min: 10, max: 4000);
    if (status == ReclamationStatus.pending) {
      throw const HomeFixException('Choisissez un statut de traitement.');
    }
    final db = await database;
    await db.transaction((tx) async {
      final actor = await _actor(tx, UserRole.admin);
      final rows =
          await tx.query('reclamations', where: 'id=?', whereArgs: [id]);
      if (rows.isEmpty) {
        throw const HomeFixException('Réclamation introuvable.');
      }
      final old =
          ReclamationStatus.values.byName(rows.single['status'] as String);
      if (old == ReclamationStatus.resolved ||
          old == ReclamationStatus.rejected) {
        throw const HomeFixException('Cette réclamation est déjà clôturée.');
      }
      final now = DateTime.now().toIso8601String();
      await tx.update(
          'reclamations',
          {
            'status': status.name,
            'adminResponse': note,
            'reviewedByAdminId': actor.id,
            'reviewedAt': now,
            'updatedAt': now
          },
          where: 'id=?',
          whereArgs: [id]);
    });
    notifyListeners();
  }

  Future<List<UserModel>> users() async {
    final db = await database;
    await _actor(db, UserRole.admin);
    return (await db.query('users',
            columns: [
              'id',
              'email',
              'fullName',
              'phone',
              'role',
              'avatarUrl',
              'city',
              'address',
              'createdAt',
              'isActive'
            ],
            orderBy: 'fullName'))
        .map((m) => UserModel.fromMap(m))
        .toList();
  }

  Future<void> setUserActive(String id, bool active) async {
    final db = await database;
    await db.transaction((tx) async {
      await _actor(tx, UserRole.admin);
      final rows = await tx.query('users', where: 'id=?', whereArgs: [id]);
      if (rows.isEmpty || rows.single['role'] == 'admin') {
        throw const HomeFixException(
            'Les comptes administrateurs sont protégés.');
      }
      await tx.update('users', {'isActive': active ? 1 : 0},
          where: 'id=?', whereArgs: [id]);
    });
    notifyListeners();
  }

  Future<void> resetUserPassword(String id, String password) async {
    _password(password);
    final db = await database;
    await _actor(db, UserRole.admin);
    final hash = await PasswordHasher.hash(password);
    await db.transaction((tx) async {
      await _actor(tx, UserRole.admin);
      final rows = await tx.query('users', where: 'id=?', whereArgs: [id]);
      if (rows.isEmpty || rows.single['role'] == 'admin') {
        throw const HomeFixException(
            'Choisissez un compte client ou professionnel.');
      }
      await tx.update('users', {'passwordHash': hash},
          where: 'id=?', whereArgs: [id]);
    });
  }
}
