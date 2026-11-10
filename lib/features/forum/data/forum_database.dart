import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' as native;
import '../../../core/data/app_schema.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/forum_post_model.dart';
import '../models/forum_comment_model.dart';

class ForumDatabase {
  static final ForumDatabase instance = ForumDatabase._init();
  static Database? _database;
  static Future<Database>? _opening;

  ForumDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    return _opening ??= _initDB('homefix_forum.db').then((db) {
      _database = db;
      return db;
    }).catchError((Object error) {
      _opening = null;
      throw error;
    });
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      throw UnsupportedError(
          'SQLite locale nécessite Android, iOS ou un ordinateur.');
    }

    // Select a factory for this database without replacing sqflite's global
    // default, which may already have been registered by another plugin.
    final DatabaseFactory factory;
    if (Platform.isAndroid || Platform.isIOS) {
      factory = native.databaseFactorySqflitePlugin;
    } else {
      sqfliteFfiInit();
      factory = databaseFactoryFfi;
    }

    final dbPath = await factory.getDatabasesPath();
    final path = join(dbPath, filePath);

    return await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 5,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 3) await AppSchema.create(db);
          if (oldVersion < 4) await AppSchema.create(db);
          if (oldVersion < 5) await AppSchema.create(db);
        },
        onCreate: _createDB,
      ),
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Table forum_posts
    await db.execute('''
      CREATE TABLE forum_posts (
        id TEXT PRIMARY KEY,
        author_id TEXT NOT NULL,
        author_name TEXT NOT NULL,
        author_avatar TEXT,
        author_role TEXT DEFAULT 'Client',
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        category TEXT NOT NULL,
        image_url TEXT,
        upvotes INTEGER DEFAULT 0,
        upvoted_by TEXT DEFAULT '[]',
        comment_count INTEGER DEFAULT 0,
        is_resolved INTEGER DEFAULT 0,
        resolved_comment_id TEXT,
        is_pinned INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 2. Table forum_comments
    await db.execute('''
      CREATE TABLE forum_comments (
        id TEXT PRIMARY KEY,
        post_id TEXT NOT NULL,
        author_id TEXT NOT NULL,
        author_name TEXT NOT NULL,
        author_avatar TEXT,
        author_role TEXT DEFAULT 'Artisan',
        content TEXT NOT NULL,
        likes INTEGER DEFAULT 0,
        liked_by TEXT DEFAULT '[]',
        is_accepted_solution INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (post_id) REFERENCES forum_posts(id) ON DELETE CASCADE
      )
    ''');

    // 3. Table user_activity_log
    await db.execute('''
      CREATE TABLE user_activity_log (
        user_id TEXT PRIMARY KEY,
        last_post_timestamp TEXT NOT NULL
      )
    ''');

    // Indexes for high performance
    await db.execute(
        'CREATE INDEX idx_forum_posts_category ON forum_posts(category)');
    await db.execute(
        'CREATE INDEX idx_forum_posts_created ON forum_posts(created_at DESC)');
    await db.execute(
        'CREATE INDEX idx_forum_comments_post_id ON forum_comments(post_id)');

    // Seed realistic Tunisian data for demonstration
    await AppSchema.create(db);
    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    final now = DateTime.now();

    // Question 1: Plomberie (Résolue avec Solution Acceptée)
    final p1 = ForumPostModel(
      id: 'post_seed_1',
      authorId: 'client_sarra',
      authorName: 'Sarra Mansouri',
      authorRole: 'Client',
      title: 'Fuite persistante sous l\'évier de cuisine à Ariana',
      content:
          'Bonjour à tous, j\'ai une fuite au niveau du raccord PVC sous le siphon de l\'évier. L\'eau coule dès que j\'ouvre le robinet à fond. Est-ce qu\'il faut changer tout le siphon ou un simple joint torique suffit ? Merci d\'avance pour vos conseils !',
      category: 'Plomberie',
      upvotes: 6,
      upvotedBy: ['pro_karim', 'user_ahmed', 'user_yassine'],
      commentCount: 2,
      isResolved: true,
      resolvedCommentId: 'comment_seed_1_1',
      isPinned: true,
      createdAt: now.subtract(const Duration(days: 1, hours: 4)),
      updatedAt: now.subtract(const Duration(days: 1, hours: 2)),
    );

    // Question 2: Climatisation (En cours)
    final p2 = ForumPostModel(
      id: 'post_seed_2',
      authorId: 'user_tarek',
      authorName: 'Tarek Trabelsi',
      authorRole: 'Client',
      title: 'Mon climatiseur split souffle de l\'air tiède au lieu de froid',
      content:
          'Mon split 12000 BTU tourne bien mais il ne produit aucun froid depuis hier. Les filtres sont pourtant nettoyés. Pensez-vous qu\'il s\'agit d\'une fuite de gaz Fréon R410A ou du condensateur de démarrage extérieur ?',
      category: 'Climatisation',
      upvotes: 9,
      upvotedBy: ['pro_anis', 'user_mohamed'],
      commentCount: 2,
      isResolved: false,
      createdAt: now.subtract(const Duration(hours: 6)),
      updatedAt: now.subtract(const Duration(hours: 5)),
    );

    // Question 3: Électricité (Résolue)
    final p3 = ForumPostModel(
      id: 'post_seed_3',
      authorId: 'user_mariem',
      authorName: 'Mariem Ben Salah',
      authorRole: 'Client',
      title:
          'Disjoncteur différentiel 30mA qui saute quand j\'allume le chauffe-eau',
      content:
          'Dès que le chauffe-eau électrique se met en marche, tout l\'appartement disjoncte. Le fusible du chauffe-eau est de 16A. Est-ce la résistance qui est à la terre ou le thermostat ?',
      category: 'Électricité',
      upvotes: 12,
      upvotedBy: ['pro_karim', 'user_tarek', 'user_ali'],
      commentCount: 1,
      isResolved: true,
      resolvedCommentId: 'comment_seed_3_1',
      isPinned: false,
      createdAt: now.subtract(const Duration(days: 3)),
      updatedAt: now.subtract(const Duration(days: 2)),
    );

    // Question 4: Peinture
    final p4 = ForumPostModel(
      id: 'post_seed_4',
      authorId: 'user_yassine',
      authorName: 'Yassine Khelifi',
      authorRole: 'Client',
      title:
          'Quelle peinture anti-humidité recommandez-vous pour salle de bain ?',
      content:
          'Je rénove une salle d\'eau peu aérée à La Marsa et des traces noires de moisissure apparaissent au plafond. Faut-il appliquer une sous-couche glycéro ou une peinture acrylique fongicide spéciale pièces humides ?',
      category: 'Peinture',
      upvotes: 4,
      upvotedBy: ['user_sarra'],
      commentCount: 1,
      isResolved: false,
      createdAt: now.subtract(const Duration(hours: 14)),
      updatedAt: now.subtract(const Duration(hours: 14)),
    );

    // Insert Posts
    for (final p in [p1, p2, p3, p4]) {
      await db.insert('forum_posts', p.toMap());
    }

    // Comments for Post 1
    final c1_1 = ForumCommentModel(
      id: 'comment_seed_1_1',
      postId: 'post_seed_1',
      authorId: 'pro_karim',
      authorName: 'Karim Ben Ali',
      authorRole: 'Artisan Plombier',
      content:
          'Bonjour Sarra. Dans 90% des cas, c\'est le joint conique en caoutchouc noir ou blanc entre la bague filetée et le tube qui s\'est desséché ou déplacé. Dévissez à la main, vérifiez le sens du cône (la pointe vers le bas), nettoyez le filetage et resserrez fermement sans forcer. Si la bague est fendue, remplacez le siphon complet (environ 15 DT en quincaillerie).',
      likes: 8,
      likedBy: ['client_sarra', 'user_ahmed', 'user_tarek'],
      isAcceptedSolution: true,
      createdAt: now.subtract(const Duration(days: 1, hours: 3)),
    );

    final c1_2 = ForumCommentModel(
      id: 'comment_seed_1_2',
      postId: 'post_seed_1',
      authorId: 'user_ahmed',
      authorName: 'Ahmed Ayadi',
      authorRole: 'Client',
      content:
          'J\'ai eu le même souci le mois dernier, mettre un tour de ruban Téflon sur le pas de vis m\'a dépanné immédiatement !',
      likes: 2,
      likedBy: ['client_sarra'],
      isAcceptedSolution: false,
      createdAt: now.subtract(const Duration(days: 1, hours: 2)),
    );

    // Comments for Post 2
    final c2_1 = ForumCommentModel(
      id: 'comment_seed_2_1',
      postId: 'post_seed_2',
      authorId: 'pro_anis',
      authorName: 'Anis Mahfoudh',
      authorRole: 'Artisan Frigoriste',
      content:
          'Bonjour Tarek. Allez vérifier si le ventilateur de l\'unité extérieure tourne. Si le ventilateur tourne mais pas le compresseur (aucun bruit de moteur), c\'est quasi-certainement le condensateur permanent (35µF en général, coûte environ 25 DT). Si le compresseur tourne en continu sans faire de froid, vous avez une fuite de fluide.',
      likes: 5,
      likedBy: ['user_tarek'],
      isAcceptedSolution: false,
      createdAt: now.subtract(const Duration(hours: 4)),
    );

    final c2_2 = ForumCommentModel(
      id: 'comment_seed_2_2',
      postId: 'post_seed_2',
      authorId: 'user_tarek',
      authorName: 'Tarek Trabelsi',
      authorRole: 'Client',
      content:
          'Merci Si Anis ! Effectivement le ventilateur tourne mais le compresseur reste silencieux. Je vais faire appel à un pro sur HomeFix pour remplacer le condensateur en sécurité.',
      likes: 1,
      likedBy: ['pro_anis'],
      isAcceptedSolution: false,
      createdAt: now.subtract(const Duration(hours: 3)),
    );

    // Comments for Post 3
    final c3_1 = ForumCommentModel(
      id: 'comment_seed_3_1',
      postId: 'post_seed_3',
      authorId: 'pro_karim',
      authorName: 'Karim Ben Ali',
      authorRole: 'Artisan',
      content:
          'C\'est typique d\'un blindage de résistance stéatite ou blindée percé par le calcaire. L\'eau entre en contact avec le filament électrique, créant un courant de fuite vers la carcasse métallique : le différentiel 30mA saute instantanément pour protéger votre vie. La résistance doit être remplacée d\'urgence.',
      likes: 11,
      likedBy: ['user_mariem', 'user_ali'],
      isAcceptedSolution: true,
      createdAt: now.subtract(const Duration(days: 2, hours: 20)),
    );

    // Comments for Post 4
    final c4_1 = ForumCommentModel(
      id: 'comment_seed_4_1',
      postId: 'post_seed_4',
      authorId: 'pro_hamadi',
      authorName: 'Hamadi Chaabane',
      authorRole: 'Artisan Peintre',
      content:
          'Nettoyez d\'abord avec de l\'eau javellisée pour tuer les spores de moisissure. Laissez sécher 24h, puis appliquez une sous-couche isolante et 2 couches de peinture acrylique anti-condensation avec additif anti-fongique.',
      likes: 3,
      likedBy: ['user_yassine'],
      isAcceptedSolution: false,
      createdAt: now.subtract(const Duration(hours: 8)),
    );

    // Insert Comments
    for (final c in [c1_1, c1_2, c2_1, c2_2, c3_1, c4_1]) {
      await db.insert('forum_comments', c.toMap());
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
    _database = null;
    _opening = null;
  }
}
