import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'password_hasher.dart';

class AppSchema {
  static Future<void> create(Database db, {bool seed = true}) async {
    await db.execute('''CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY, email TEXT NOT NULL COLLATE NOCASE UNIQUE,
      fullName TEXT NOT NULL, phone TEXT NOT NULL DEFAULT '',
      role TEXT NOT NULL CHECK(role IN ('client','professional','admin')),
      avatarUrl TEXT, city TEXT NOT NULL DEFAULT 'Tunis', address TEXT NOT NULL DEFAULT '',
      createdAt TEXT NOT NULL, isActive INTEGER NOT NULL DEFAULT 1 CHECK(isActive IN (0,1)),
      passwordHash TEXT NOT NULL)''');
    await db.execute('''CREATE TABLE IF NOT EXISTS professionals (
      id TEXT PRIMARY KEY REFERENCES users(id) ON DELETE RESTRICT,
      specialty TEXT NOT NULL, bio TEXT NOT NULL DEFAULT '',
      coverImageUrl TEXT NOT NULL DEFAULT '', hourlyRate REAL NOT NULL DEFAULT 30,
      experienceYears INTEGER NOT NULL DEFAULT 1, rating REAL NOT NULL DEFAULT 0,
      reviewCount INTEGER NOT NULL DEFAULT 0, isVerified INTEGER NOT NULL DEFAULT 0,
      isAvailable INTEGER NOT NULL DEFAULT 1, skills TEXT NOT NULL DEFAULT '[]',
      availableDays TEXT NOT NULL DEFAULT '[]')''');
    await db.execute('''CREATE TABLE IF NOT EXISTS services (
      id TEXT PRIMARY KEY, proId TEXT NOT NULL REFERENCES professionals(id),
      title TEXT NOT NULL, description TEXT NOT NULL, price REAL NOT NULL CHECK(price > 0),
      duration TEXT NOT NULL, durationMinutes INTEGER NOT NULL CHECK(durationMinutes BETWEEN 15 AND 480),
      isActive INTEGER NOT NULL DEFAULT 1 CHECK(isActive IN (0,1)),
      createdAt TEXT NOT NULL, updatedAt TEXT NOT NULL, UNIQUE(id,proId))''');
    await db.execute('''CREATE TABLE IF NOT EXISTS bookings (
      id TEXT PRIMARY KEY, serviceId TEXT NOT NULL, clientId TEXT NOT NULL REFERENCES users(id),
      proId TEXT NOT NULL REFERENCES professionals(id), clientName TEXT NOT NULL,
      proName TEXT NOT NULL, proSpecialty TEXT NOT NULL, serviceTitle TEXT NOT NULL,
      scheduledDate TEXT NOT NULL, timeSlot TEXT NOT NULL, address TEXT NOT NULL,
      estimatedPrice REAL NOT NULL, durationMinutes INTEGER NOT NULL,
      startEpoch INTEGER NOT NULL, endEpoch INTEGER NOT NULL,
      status TEXT NOT NULL CHECK(status IN ('pending','confirmed','inProgress','completed','cancelled')),
      clientNotes TEXT, createdAt TEXT NOT NULL, updatedAt TEXT NOT NULL,
      UNIQUE(id,clientId,proId), FOREIGN KEY(serviceId,proId) REFERENCES services(id,proId))''');
    await db.execute('''CREATE TABLE IF NOT EXISTS reclamations (
      id TEXT PRIMARY KEY, bookingId TEXT NOT NULL, clientId TEXT NOT NULL, proId TEXT NOT NULL,
      subject TEXT NOT NULL, description TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','inReview','resolved','rejected')),
      reviewedByAdminId TEXT REFERENCES users(id), adminResponse TEXT, reviewedAt TEXT,
      createdAt TEXT NOT NULL, updatedAt TEXT NOT NULL,
      FOREIGN KEY(bookingId,clientId,proId) REFERENCES bookings(id,clientId,proId))''');
    await db.execute('''CREATE UNIQUE INDEX IF NOT EXISTS one_open_reclamation
      ON reclamations(bookingId) WHERE status IN ('pending','inReview')''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS booking_pro_time ON bookings(proId,startEpoch,endEpoch)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS booking_client ON bookings(clientId)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS reclamation_client ON reclamations(clientId)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS reclamation_status ON reclamations(status,createdAt)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS service_owner ON services(proId,isActive)');
    await db.execute('''CREATE TABLE IF NOT EXISTS app_session (
      id INTEGER PRIMARY KEY CHECK(id=1), userId TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      rememberMe INTEGER NOT NULL DEFAULT 1 CHECK(rememberMe IN (0,1)))''');
    final sessionColumns = await db.rawQuery('PRAGMA table_info(app_session)');
    if (!sessionColumns.any((column) => column['name'] == 'rememberMe')) {
      await db.execute(
          'ALTER TABLE app_session ADD COLUMN rememberMe INTEGER NOT NULL DEFAULT 1');
    }
    // Messaging between users and artisans
    await db.execute('''CREATE TABLE IF NOT EXISTS messages (
      id TEXT PRIMARY KEY,
      senderId TEXT NOT NULL REFERENCES users(id),
      receiverId TEXT NOT NULL REFERENCES users(id),
      senderName TEXT NOT NULL DEFAULT '',
      receiverName TEXT NOT NULL DEFAULT '',
      content TEXT NOT NULL,
      createdAt TEXT NOT NULL,
      isRead INTEGER NOT NULL DEFAULT 0 CHECK(isRead IN (0,1)))''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(senderId, createdAt)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_messages_receiver ON messages(receiverId, createdAt)');
    // Password reset tokens (simulated email verification)
    await db.execute('''CREATE TABLE IF NOT EXISTS password_reset_tokens (
      id TEXT PRIMARY KEY,
      userId TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      token TEXT NOT NULL,
      expiresAt TEXT NOT NULL,
      usedAt TEXT)''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_prt_userId ON password_reset_tokens(userId)');
    if (seed &&
        Sqflite.firstIntValue(
                await db.rawQuery('SELECT COUNT(*) FROM users')) ==
            0) {
      await _seed(db);
    }
    if (seed &&
        (Sqflite.firstIntValue(
                await db.rawQuery('SELECT COUNT(*) FROM messages')) ??
            0) ==
            0) {
      await _seedMessages(db);
    }
  }

  static Future<void> _seed(Database db) async {
    final now = DateTime.now();
    final people = [
      [
        'admin_homefix',
        'admin@homefix.com',
        'Administration HomeFix',
        'admin',
        'Tunis'
      ],
      [
        'client_sarra',
        'client@homefix.com',
        'Sarra Mansouri',
        'client',
        'Ariana'
      ],
      [
        'pro_karim',
        'pro@homefix.com',
        'Karim Ben Ali',
        'professional',
        'Tunis'
      ],
      [
        'pro_ines',
        'ines@homefix.com',
        'Inès Trabelsi',
        'professional',
        'Ariana'
      ],
      [
        'pro_youssef',
        'youssef@homefix.com',
        'Youssef Gharbi',
        'professional',
        'La Marsa'
      ],
      ['pro_anis', 'anis@homefix.com', 'Anis Hamdi', 'professional', 'Tunis'],
      [
        'pro_hamadi',
        'hamadi@homefix.com',
        'Hamadi Chaabane',
        'professional',
        'Ben Arous'
      ],
    ];
    final hashes = await Future.wait(
        people.map((_) => PasswordHasher.hash('HomeFix123!')));
    for (var i = 0; i < people.length; i++) {
      final p = people[i];
      await db.insert('users', {
        'id': p[0],
        'email': p[1],
        'fullName': p[2],
        'role': p[3],
        'city': p[4],
        'phone': '22123456',
        'address': 'Avenue Habib Bourguiba',
        'createdAt': now.toIso8601String(),
        'passwordHash': hashes[i]
      });
    }
    final trades = [
      [
        'pro_karim',
        'Plomberie',
        'Réparation de fuite',
        'Diagnostic et réparation des fuites et raccords.',
        55.0,
        60
      ],
      [
        'pro_ines',
        'Électricité',
        'Installation de prises',
        'Pose et sécurisation de prises électriques.',
        45.0,
        60
      ],
      [
        'pro_youssef',
        'Maçonnerie',
        'Petits travaux de maçonnerie',
        'Réparation des murs, joints et finitions.',
        90.0,
        120
      ],
      [
        'pro_anis',
        'Climatisation',
        'Entretien de climatiseur',
        'Nettoyage des filtres et contrôle du fonctionnement.',
        70.0,
        90
      ],
      [
        'pro_hamadi',
        'Peinture',
        'Peinture intérieure',
        'Préparation du support et application de peinture.',
        120.0,
        180
      ],
    ];
    for (final t in trades) {
      final id = t[0] as String;
      await db.insert('professionals', {
        'id': id,
        'specialty': t[1],
        'bio': 'Artisan à votre écoute, travail soigné et devis transparent.',
        'hourlyRate': 35,
        'experienceYears': 7,
        'rating': 4.8,
        'isVerified': 1,
        'skills': jsonEncode([t[1], 'Travail soigné', 'Devis transparent']),
        'availableDays': jsonEncode(['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'])
      });
      await db.insert('services', {
        'id': 'service_$id',
        'proId': id,
        'title': t[2],
        'description': t[3],
        'price': t[4],
        'duration': '${t[5]} min',
        'durationMinutes': t[5],
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String()
      });
    }
    final past = DateTime(now.year, now.month, now.day - 3, 10);
    await db.insert('bookings', {
      'id': 'booking_demo_completed',
      'serviceId': 'service_pro_karim',
      'clientId': 'client_sarra',
      'proId': 'pro_karim',
      'clientName': 'Sarra Mansouri',
      'proName': 'Karim Ben Ali',
      'proSpecialty': 'Plomberie',
      'serviceTitle': 'Réparation de fuite',
      'scheduledDate': past.toIso8601String(),
      'timeSlot': '10:00',
      'address': 'Ariana, Avenue Habib Bourguiba',
      'estimatedPrice': 55,
      'durationMinutes': 60,
      'startEpoch': past.millisecondsSinceEpoch,
      'endEpoch': past.add(const Duration(hours: 1)).millisecondsSinceEpoch,
      'status': 'completed',
      'clientNotes': 'Fuite sous l’évier de cuisine.',
      'createdAt': past.toIso8601String(),
      'updatedAt': past.toIso8601String()
    });
    await db.insert('reclamations', {
      'id': 'reclamation_demo',
      'bookingId': 'booking_demo_completed',
      'clientId': 'client_sarra',
      'proId': 'pro_karim',
      'subject': 'La fuite persiste après l’intervention',
      'description':
          'Une petite fuite est réapparue sous l’évier. Je souhaite une analyse et une solution.',
      'createdAt': now.subtract(const Duration(hours: 5)).toIso8601String(),
      'updatedAt': now.toIso8601String()
    });
    await _seedMessages(db);
  }

  static Future<void> _seedMessages(Database db) async {
    final now = DateTime.now();
    const clientSarra = 'client_sarra';
    const proKarim = 'pro_karim';
    const proInes = 'pro_ines';

    // Verify users exist before inserting messages
    final userCount = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM users WHERE id IN (?, ?, ?)',
            [clientSarra, proKarim, proInes])) ??
        0;
    if (userCount < 2) return;

    final demoMessages = [
      // Conversation between Sarra (Client) and Karim (Artisan Plombier)
      {
        'id': 'msg_demo_1',
        'senderId': clientSarra,
        'receiverId': proKarim,
        'senderName': 'Sarra Mansouri',
        'receiverName': 'Karim Ben Ali',
        'content':
            'Bonjour Si Karim, j\'ai une fuite d\'eau sous l\'évier de cuisine.',
        'createdAt':
            now.subtract(const Duration(days: 2, hours: 3)).toIso8601String(),
        'isRead': 1,
      },
      {
        'id': 'msg_demo_2',
        'senderId': proKarim,
        'receiverId': clientSarra,
        'senderName': 'Karim Ben Ali',
        'receiverName': 'Sarra Mansouri',
        'content':
            'Bonjour Mme Sarra. Avez-vous fermé la vanne d\'arrêt principale ? Je peux passer demain matin vers 10h.',
        'createdAt':
            now.subtract(const Duration(days: 2, hours: 2, minutes: 40)).toIso8601String(),
        'isRead': 1,
      },
      {
        'id': 'msg_demo_3',
        'senderId': clientSarra,
        'receiverId': proKarim,
        'senderName': 'Sarra Mansouri',
        'receiverName': 'Karim Ben Ali',
        'content': 'Oui la vanne est coupée. Vers 10h c\'est parfait, merci !',
        'createdAt':
            now.subtract(const Duration(days: 2, hours: 2, minutes: 20)).toIso8601String(),
        'isRead': 1,
      },
      {
        'id': 'msg_demo_4',
        'senderId': proKarim,
        'receiverId': clientSarra,
        'senderName': 'Karim Ben Ali',
        'receiverName': 'Sarra Mansouri',
        'content':
            'Parfait, c\'est noté. À demain avec les raccords et joints adaptés.',
        'createdAt':
            now.subtract(const Duration(days: 2, hours: 2)).toIso8601String(),
        'isRead': 1,
      },
      // Conversation between Sarra (Client) and Inès (Artisan Électricienne)
      {
        'id': 'msg_demo_5',
        'senderId': clientSarra,
        'receiverId': proInes,
        'senderName': 'Sarra Mansouri',
        'receiverName': 'Inès Trabelsi',
        'content':
            'Bonjour Inès, faites-vous aussi la rénovation du tableau électrique ?',
        'createdAt':
            now.subtract(const Duration(hours: 4)).toIso8601String(),
        'isRead': 1,
      },
      {
        'id': 'msg_demo_6',
        'senderId': proInes,
        'receiverId': clientSarra,
        'senderName': 'Inès Trabelsi',
        'receiverName': 'Sarra Mansouri',
        'content':
            'Bonjour Sarra ! Oui tout à fait, remise aux normes complète et pose de disjoncteurs différentiels.',
        'createdAt':
            now.subtract(const Duration(hours: 1, minutes: 30)).toIso8601String(),
        'isRead': 0, // Unread message for Sarra!
      },
    ];

    for (final msg in demoMessages) {
      await db.insert('messages', msg,
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }
}
