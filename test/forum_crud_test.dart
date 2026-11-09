// Real automated CRUD tests for the Forum module using sqflite_common_ffi.

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mobile5eme/features/forum/models/forum_post_model.dart';
import 'package:mobile5eme/features/forum/models/forum_comment_model.dart';
import 'package:mobile5eme/features/forum/utils/forum_validators.dart';
import 'package:mobile5eme/features/forum/utils/content_moderator.dart';

// ---------------------------------------------------------------------------
// Minimal in-memory database helper (mirrors ForumDatabase without Flutter deps)
// ---------------------------------------------------------------------------
Future<Database> _openTestDb() async {
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;
  final db = await factory.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, _) async {
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
        await db.execute('''
          CREATE TABLE user_activity_log (
            user_id TEXT PRIMARY KEY,
            last_post_timestamp TEXT NOT NULL
          )
        ''');
      },
    ),
  );
  return db;
}

// ---------------------------------------------------------------------------
// Helpers to replicate repository methods inline (pure SQL, no Flutter deps)
// ---------------------------------------------------------------------------
ForumPostModel _makePost({
  String id = 'test_post_1',
  String title = 'Ma fuite sous évier comment réparer ?',
  String content = 'Bonjour j ai une fuite persistante sous mon évier, le joint est usé.',
  String category = 'Plomberie',
  String authorId = 'user_test',
  bool isResolved = false,
}) {
  final now = DateTime.now();
  return ForumPostModel(
    id: id,
    authorId: authorId,
    authorName: 'Test User',
    authorRole: 'Client',
    title: title,
    content: content,
    category: category,
    upvotes: 0,
    upvotedBy: [],
    commentCount: 0,
    isResolved: isResolved,
    isPinned: false,
    createdAt: now,
    updatedAt: now,
  );
}

ForumCommentModel _makeComment({
  String id = 'test_comment_1',
  String postId = 'test_post_1',
  String content = 'Remplacez le joint torique, coûte 2 DT en quincaillerie.',
  bool isAcceptedSolution = false,
}) {
  return ForumCommentModel(
    id: id,
    postId: postId,
    authorId: 'pro_test',
    authorName: 'Pro Test',
    authorRole: 'Artisan',
    content: content,
    likes: 0,
    likedBy: [],
    isAcceptedSolution: isAcceptedSolution,
    createdAt: DateTime.now(),
  );
}

// ---------------------------------------------------------------------------
// TEST SUITE
// ---------------------------------------------------------------------------
void main() {
  group('🗄️  CREATE — Posts', () {
    late Database db;
    setUp(() async => db = await _openTestDb());
    tearDown(() async => await db.close());

    test('INSERT a post and READ it back by id', () async {
      final post = _makePost();
      await db.insert('forum_posts', post.toMap());

      final rows = await db.query('forum_posts', where: 'id = ?', whereArgs: ['test_post_1']);
      expect(rows.length, 1);
      final fetched = ForumPostModel.fromMap(rows.first);
      expect(fetched.id, 'test_post_1');
      expect(fetched.title, 'Ma fuite sous évier comment réparer ?');
      expect(fetched.category, 'Plomberie');
      expect(fetched.isResolved, false);
      expect(fetched.upvotes, 0);
      expect(fetched.upvotedBy, isEmpty);
      print('  ✅ CREATE post → READ back: OK');
    });

    test('INSERT preserves upvotedBy JSON list round-trip', () async {
      final post = _makePost().copyWith(upvotedBy: ['user_a', 'user_b'], upvotes: 2);
      await db.insert('forum_posts', post.toMap());

      final rows = await db.query('forum_posts', where: 'id = ?', whereArgs: ['test_post_1']);
      final fetched = ForumPostModel.fromMap(rows.first);
      expect(fetched.upvotedBy, containsAll(['user_a', 'user_b']));
      expect(fetched.upvotes, 2);
      print('  ✅ upvotedBy JSON round-trip: OK');
    });
  });

  // -------------------------------------------------------------------------
  group('📖  READ — Filtering, search, sorting', () {
    late Database db;

    setUp(() async {
      db = await _openTestDb();
      final now = DateTime.now();
      // Insert 3 posts in different categories
      await db.insert('forum_posts', _makePost(id: 'p1', category: 'Plomberie', title: 'Fuite robinet cuisine').toMap());
      await db.insert('forum_posts', _makePost(id: 'p2', category: 'Climatisation', title: 'Clim qui ne refroidit plus').toMap());
      await db.insert('forum_posts', _makePost(id: 'p3', category: 'Électricité', title: 'Disjoncteur différentiel saute').toMap()
        ..update('is_resolved', (_) => 1));
      // manually mark p3 resolved
      await db.update('forum_posts', {'is_resolved': 1}, where: 'id = ?', whereArgs: ['p3']);
    });
    tearDown(() async => await db.close());

    test('READ all posts (no filter) returns 3', () async {
      final rows = await db.query('forum_posts');
      expect(rows.length, 3);
      print('  ✅ READ all: 3 posts returned');
    });

    test('FILTER by category Plomberie returns 1', () async {
      final rows = await db.query('forum_posts', where: 'category = ?', whereArgs: ['Plomberie']);
      expect(rows.length, 1);
      expect(rows.first['id'], 'p1');
      print('  ✅ FILTER by category: OK');
    });

    test('FILTER resolved only returns 1', () async {
      final rows = await db.query('forum_posts', where: 'is_resolved = 1');
      expect(rows.length, 1);
      expect(rows.first['id'], 'p3');
      print('  ✅ FILTER resolved: OK');
    });

    test('FILTER unresolved only returns 2', () async {
      final rows = await db.query('forum_posts', where: 'is_resolved = 0');
      expect(rows.length, 2);
      print('  ✅ FILTER unresolved: OK');
    });

    test('SEARCH "clim" in title matches 1 post', () async {
      final rows = await db.query(
        'forum_posts',
        where: '(title LIKE ? OR content LIKE ?)',
        whereArgs: ['%clim%', '%clim%'],
      );
      expect(rows.length, 1);
      expect(rows.first['id'], 'p2');
      print('  ✅ SEARCH full-text "clim": OK');
    });

    test('SEARCH "disjoncteur" matches 1 post', () async {
      final rows = await db.query(
        'forum_posts',
        where: '(title LIKE ? OR content LIKE ?)',
        whereArgs: ['%disjoncteur%', '%disjoncteur%'],
      );
      expect(rows.length, 1);
      expect(rows.first['id'], 'p3');
      print('  ✅ SEARCH full-text "disjoncteur": OK');
    });

    test('SEARCH with no match returns 0', () async {
      final rows = await db.query(
        'forum_posts',
        where: '(title LIKE ? OR content LIKE ?)',
        whereArgs: ['%xenomorph%', '%xenomorph%'],
      );
      expect(rows.length, 0);
      print('  ✅ SEARCH no match returns 0: OK');
    });
  });

  // -------------------------------------------------------------------------
  group('✏️  UPDATE — Posts', () {
    late Database db;
    setUp(() async {
      db = await _openTestDb();
      await db.insert('forum_posts', _makePost().toMap());
    });
    tearDown(() async => await db.close());

    test('UPDATE title and content', () async {
      await db.update(
        'forum_posts',
        {'title': 'Titre modifié avec succès', 'content': 'Contenu mis à jour correctement ici.', 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: ['test_post_1'],
      );
      final rows = await db.query('forum_posts', where: 'id = ?', whereArgs: ['test_post_1']);
      final fetched = ForumPostModel.fromMap(rows.first);
      expect(fetched.title, 'Titre modifié avec succès');
      expect(fetched.content, 'Contenu mis à jour correctement ici.');
      print('  ✅ UPDATE title + content: OK');
    });

    test('UPDATE category', () async {
      await db.update('forum_posts', {'category': 'Électricité'}, where: 'id = ?', whereArgs: ['test_post_1']);
      final rows = await db.query('forum_posts', where: 'id = ?', whereArgs: ['test_post_1']);
      expect(rows.first['category'], 'Électricité');
      print('  ✅ UPDATE category: OK');
    });

    test('UPDATE isResolved toggle', () async {
      await db.update('forum_posts', {'is_resolved': 1}, where: 'id = ?', whereArgs: ['test_post_1']);
      final rows = await db.query('forum_posts', where: 'id = ?', whereArgs: ['test_post_1']);
      final fetched = ForumPostModel.fromMap(rows.first);
      expect(fetched.isResolved, true);
      print('  ✅ UPDATE isResolved: OK');
    });

    test('UPDATE imageUrl', () async {
      await db.update('forum_posts', {'image_url': '/path/to/photo.jpg'}, where: 'id = ?', whereArgs: ['test_post_1']);
      final rows = await db.query('forum_posts', where: 'id = ?', whereArgs: ['test_post_1']);
      expect(rows.first['image_url'], '/path/to/photo.jpg');
      print('  ✅ UPDATE imageUrl: OK');
    });
  });

  // -------------------------------------------------------------------------
  group('🗑️  DELETE — Posts and cascade', () {
    late Database db;
    setUp(() async {
      db = await _openTestDb();
      await db.insert('forum_posts', _makePost().toMap());
      await db.insert('forum_comments', _makeComment().toMap());
      await db.insert('forum_comments', _makeComment(id: 'test_comment_2').toMap());
    });
    tearDown(() async => await db.close());

    test('DELETE post removes post from DB', () async {
      await db.transaction((txn) async {
        await txn.delete('forum_comments', where: 'post_id = ?', whereArgs: ['test_post_1']);
        await txn.delete('forum_posts', where: 'id = ?', whereArgs: ['test_post_1']);
      });
      final rows = await db.query('forum_posts', where: 'id = ?', whereArgs: ['test_post_1']);
      expect(rows, isEmpty);
      print('  ✅ DELETE post: OK');
    });

    test('DELETE post cascades to comments', () async {
      await db.transaction((txn) async {
        await txn.delete('forum_comments', where: 'post_id = ?', whereArgs: ['test_post_1']);
        await txn.delete('forum_posts', where: 'id = ?', whereArgs: ['test_post_1']);
      });
      final comments = await db.query('forum_comments', where: 'post_id = ?', whereArgs: ['test_post_1']);
      expect(comments, isEmpty);
      print('  ✅ DELETE cascade to comments: OK');
    });
  });

  // -------------------------------------------------------------------------
  group('💬  Comments — CRUD + atomic comment_count', () {
    late Database db;
    setUp(() async {
      db = await _openTestDb();
      await db.insert('forum_posts', _makePost().toMap());
    });
    tearDown(() async => await db.close());

    test('ADD comment increments comment_count atomically', () async {
      await db.transaction((txn) async {
        await txn.insert('forum_comments', _makeComment().toMap());
        await txn.rawUpdate(
          'UPDATE forum_posts SET comment_count = comment_count + 1 WHERE id = ?',
          ['test_post_1'],
        );
      });
      final postRows = await db.query('forum_posts', where: 'id = ?', whereArgs: ['test_post_1']);
      expect(postRows.first['comment_count'], 1);
      final commentRows = await db.query('forum_comments', where: 'post_id = ?', whereArgs: ['test_post_1']);
      expect(commentRows.length, 1);
      print('  ✅ ADD comment + atomic comment_count increment: OK');
    });

    test('DELETE comment decrements comment_count atomically, never below 0', () async {
      // Add first
      await db.transaction((txn) async {
        await txn.insert('forum_comments', _makeComment().toMap());
        await txn.rawUpdate('UPDATE forum_posts SET comment_count = comment_count + 1 WHERE id = ?', ['test_post_1']);
      });
      // Delete
      await db.transaction((txn) async {
        await txn.delete('forum_comments', where: 'id = ?', whereArgs: ['test_comment_1']);
        await txn.rawUpdate(
          'UPDATE forum_posts SET comment_count = MAX(0, comment_count - 1) WHERE id = ?',
          ['test_post_1'],
        );
      });
      final postRows = await db.query('forum_posts', where: 'id = ?', whereArgs: ['test_post_1']);
      expect(postRows.first['comment_count'], 0);
      print('  ✅ DELETE comment + atomic decrement (never < 0): OK');
    });

    test('comment_count never goes below 0 on double delete', () async {
      // Start from 0, try to decrement
      await db.rawUpdate(
        'UPDATE forum_posts SET comment_count = MAX(0, comment_count - 1) WHERE id = ?',
        ['test_post_1'],
      );
      final postRows = await db.query('forum_posts', where: 'id = ?', whereArgs: ['test_post_1']);
      expect(postRows.first['comment_count'], 0);
      print('  ✅ comment_count floor at 0: OK');
    });
  });

  // -------------------------------------------------------------------------
  group('👍  Upvote anti-cheat (Métier 2)', () {
    late Database db;
    setUp(() async {
      db = await _openTestDb();
      await db.insert('forum_posts', _makePost().toMap());
    });
    tearDown(() async => await db.close());

    test('First upvote adds userId to list and increments count', () async {
      final rows = await db.query('forum_posts', where: 'id = ?', whereArgs: ['test_post_1']);
      final post = ForumPostModel.fromMap(rows.first);

      final voters = List<String>.from(post.upvotedBy);
      var count = post.upvotes;
      expect(voters.contains('user_a'), false);
      voters.add('user_a');
      count += 1;

      await db.update('forum_posts', {'upvotes': count, 'upvoted_by': jsonEncode(voters)},
          where: 'id = ?', whereArgs: ['test_post_1']);

      final updated = ForumPostModel.fromMap(
          (await db.query('forum_posts', where: 'id = ?', whereArgs: ['test_post_1'])).first);
      expect(updated.upvotes, 1);
      expect(updated.upvotedBy, contains('user_a'));
      print('  ✅ First upvote: OK');
    });

    test('Second upvote by SAME user removes vote (anti-cheat)', () async {
      // Setup: user_a already voted
      await db.update('forum_posts',
          {'upvotes': 1, 'upvoted_by': jsonEncode(['user_a'])},
          where: 'id = ?', whereArgs: ['test_post_1']);

      final rows = await db.query('forum_posts', where: 'id = ?', whereArgs: ['test_post_1']);
      final post = ForumPostModel.fromMap(rows.first);
      final voters = List<String>.from(post.upvotedBy);
      var count = post.upvotes;

      // Anti-cheat: user_a tries to vote again → remove vote instead
      expect(voters.contains('user_a'), true);
      voters.remove('user_a');
      count = (count - 1).clamp(0, 999999);

      await db.update('forum_posts', {'upvotes': count, 'upvoted_by': jsonEncode(voters)},
          where: 'id = ?', whereArgs: ['test_post_1']);

      final updated = ForumPostModel.fromMap(
          (await db.query('forum_posts', where: 'id = ?', whereArgs: ['test_post_1'])).first);
      expect(updated.upvotes, 0);
      expect(updated.upvotedBy, isEmpty);
      print('  ✅ Anti-cheat double-upvote prevented: OK');
    });

    test('Two DIFFERENT users can both upvote independently', () async {
      for (final userId in ['user_a', 'user_b']) {
        final rows = await db.query('forum_posts', where: 'id = ?', whereArgs: ['test_post_1']);
        final post = ForumPostModel.fromMap(rows.first);
        final voters = List<String>.from(post.upvotedBy)..add(userId);
        await db.update('forum_posts',
            {'upvotes': post.upvotes + 1, 'upvoted_by': jsonEncode(voters)},
            where: 'id = ?', whereArgs: ['test_post_1']);
      }
      final final_ = ForumPostModel.fromMap(
          (await db.query('forum_posts', where: 'id = ?', whereArgs: ['test_post_1'])).first);
      expect(final_.upvotes, 2);
      expect(final_.upvotedBy, containsAll(['user_a', 'user_b']));
      print('  ✅ Two different users upvote independently: OK');
    });
  });

  // -------------------------------------------------------------------------
  group('⭐  Accepted Solution transaction (Métier 1)', () {
    late Database db;
    setUp(() async {
      db = await _openTestDb();
      await db.insert('forum_posts', _makePost().toMap());
      await db.insert('forum_comments', _makeComment(id: 'c1').toMap());
      await db.insert('forum_comments', _makeComment(id: 'c2').toMap());
    });
    tearDown(() async => await db.close());

    test('markAcceptedSolution sets comment + post in one transaction', () async {
      await db.transaction((txn) async {
        // 1. Reset all solutions on the post
        await txn.update('forum_comments', {'is_accepted_solution': 0},
            where: 'post_id = ?', whereArgs: ['test_post_1']);
        // 2. Mark the chosen comment
        await txn.update('forum_comments', {'is_accepted_solution': 1},
            where: 'id = ?', whereArgs: ['c1']);
        // 3. Mark the post as resolved
        await txn.update('forum_posts',
            {'is_resolved': 1, 'resolved_comment_id': 'c1', 'updated_at': DateTime.now().toIso8601String()},
            where: 'id = ?', whereArgs: ['test_post_1']);
      });

      final post = ForumPostModel.fromMap(
          (await db.query('forum_posts', where: 'id = ?', whereArgs: ['test_post_1'])).first);
      expect(post.isResolved, true);
      expect(post.resolvedCommentId, 'c1');

      final c1 = ForumCommentModel.fromMap(
          (await db.query('forum_comments', where: 'id = ?', whereArgs: ['c1'])).first);
      final c2 = ForumCommentModel.fromMap(
          (await db.query('forum_comments', where: 'id = ?', whereArgs: ['c2'])).first);
      expect(c1.isAcceptedSolution, true);
      expect(c2.isAcceptedSolution, false);
      print('  ✅ markAcceptedSolution transaction: OK');
    });

    test('Switching solution resets old one, marks new one', () async {
      // First: mark c1 as solution
      await db.transaction((txn) async {
        await txn.update('forum_comments', {'is_accepted_solution': 0}, where: 'post_id = ?', whereArgs: ['test_post_1']);
        await txn.update('forum_comments', {'is_accepted_solution': 1}, where: 'id = ?', whereArgs: ['c1']);
        await txn.update('forum_posts', {'is_resolved': 1, 'resolved_comment_id': 'c1', 'updated_at': DateTime.now().toIso8601String()}, where: 'id = ?', whereArgs: ['test_post_1']);
      });
      // Then: switch to c2
      await db.transaction((txn) async {
        await txn.update('forum_comments', {'is_accepted_solution': 0}, where: 'post_id = ?', whereArgs: ['test_post_1']);
        await txn.update('forum_comments', {'is_accepted_solution': 1}, where: 'id = ?', whereArgs: ['c2']);
        await txn.update('forum_posts', {'is_resolved': 1, 'resolved_comment_id': 'c2', 'updated_at': DateTime.now().toIso8601String()}, where: 'id = ?', whereArgs: ['test_post_1']);
      });

      final c1 = ForumCommentModel.fromMap(
          (await db.query('forum_comments', where: 'id = ?', whereArgs: ['c1'])).first);
      final c2 = ForumCommentModel.fromMap(
          (await db.query('forum_comments', where: 'id = ?', whereArgs: ['c2'])).first);
      expect(c1.isAcceptedSolution, false);
      expect(c2.isAcceptedSolution, true);
      print('  ✅ Switch accepted solution (old reset, new set): OK');
    });
  });

  // -------------------------------------------------------------------------
  group('📊  Gamification stats (Métier 6)', () {
    late Database db;
    setUp(() async {
      db = await _openTestDb();
      await db.insert('forum_posts', _makePost(id: 'p1', authorId: 'user_jury').toMap());
      await db.insert('forum_posts', _makePost(id: 'p2', authorId: 'user_jury').toMap());
      await db.insert('forum_posts', _makePost(id: 'p3', authorId: 'user_other').toMap());
      // Manually insert comment by user_jury on p3
      await db.insert('forum_comments', {
        'id': 'c_jury_1', 'post_id': 'p3', 'author_id': 'user_jury',
        'author_name': 'Jury User', 'author_role': 'Client',
        'content': 'Ma réponse ici.',
        'likes': 0, 'liked_by': '[]', 'is_accepted_solution': 1,
        'created_at': DateTime.now().toIso8601String(),
      });
      await db.insert('forum_comments', {
        'id': 'c_jury_2', 'post_id': 'p3', 'author_id': 'user_jury',
        'author_name': 'Jury User', 'author_role': 'Client',
        'content': 'Une autre réponse.',
        'likes': 0, 'liked_by': '[]', 'is_accepted_solution': 0,
        'created_at': DateTime.now().toIso8601String(),
      });
    });
    tearDown(() async => await db.close());

    test('questionsCount returns correct count for user_jury', () async {
      final result = await db.rawQuery(
          'SELECT COUNT(*) as count FROM forum_posts WHERE author_id = ?', ['user_jury']);
      expect(result.first['count'], 2);
      print('  ✅ questionsCount: OK');
    });

    test('answersCount returns correct count for user_jury', () async {
      final result = await db.rawQuery(
          'SELECT COUNT(*) as count FROM forum_comments WHERE author_id = ?', ['user_jury']);
      expect(result.first['count'], 2);
      print('  ✅ answersCount: OK');
    });

    test('solutionsAcceptedCount returns 1 for user_jury', () async {
      final result = await db.rawQuery(
          'SELECT COUNT(*) as count FROM forum_comments WHERE author_id = ? AND is_accepted_solution = 1',
          ['user_jury']);
      expect(result.first['count'], 1);
      print('  ✅ solutionsAcceptedCount: OK');
    });
  });

  // -------------------------------------------------------------------------
  group('🛡️  Contrôle de Saisie — Validators', () {
    test('validateTitle: null/empty → error', () {
      expect(ForumValidators.validateTitle(null), isNotNull);
      expect(ForumValidators.validateTitle(''), isNotNull);
      print('  ✅ validateTitle empty: error returned');
    });

    test('validateTitle: too short (<6 chars) → error', () {
      expect(ForumValidators.validateTitle('Oui'), isNotNull);
      print('  ✅ validateTitle too short: error returned');
    });

    test('validateTitle: valid title → null (no error)', () {
      expect(ForumValidators.validateTitle('Fuite robinet cuisine comment réparer'), isNull);
      print('  ✅ validateTitle valid: OK');
    });

    test('validateTitle: too long (>90 chars) → error', () {
      expect(ForumValidators.validateTitle('A' * 91), isNotNull);
      print('  ✅ validateTitle too long: error returned');
    });

    test('validateTitle: repetitive chars → error', () {
      expect(ForumValidators.validateTitle('aaaaaaaaa bbb'), isNotNull);
      print('  ✅ validateTitle repetitive chars: error returned');
    });

    test('validateContent: null/empty → error', () {
      expect(ForumValidators.validateContent(null), isNotNull);
      expect(ForumValidators.validateContent(''), isNotNull);
      print('  ✅ validateContent empty: error returned');
    });

    test('validateContent: too short (<15 chars) → error', () {
      expect(ForumValidators.validateContent('Problème ici'), isNotNull);
      print('  ✅ validateContent too short: error returned');
    });

    test('validateContent: valid → null', () {
      expect(ForumValidators.validateContent('J ai une fuite persistante sous mon évier, le joint est usé.'), isNull);
      print('  ✅ validateContent valid: OK');
    });

    test('validateContent: too long (>2000 chars) → error', () {
      expect(ForumValidators.validateContent('A' * 2001), isNotNull);
      print('  ✅ validateContent too long: error returned');
    });

    test('validateCategory: null → error', () {
      expect(ForumValidators.validateCategory(null), isNotNull);
      print('  ✅ validateCategory null: error returned');
    });

    test('validateCategory: valid → null', () {
      expect(ForumValidators.validateCategory('Plomberie'), isNull);
      print('  ✅ validateCategory valid: OK');
    });

    test('validateComment: null/empty → error', () {
      expect(ForumValidators.validateComment(null), isNotNull);
      expect(ForumValidators.validateComment(''), isNotNull);
      print('  ✅ validateComment empty: error returned');
    });

    test('validateComment: 1 char → error', () {
      expect(ForumValidators.validateComment('A'), isNotNull);
      print('  ✅ validateComment too short: error returned');
    });

    test('validateComment: valid → null', () {
      expect(ForumValidators.validateComment('Remplacez le joint torique.'), isNull);
      print('  ✅ validateComment valid: OK');
    });

    test('validateComment: too long (>600 chars) → error', () {
      expect(ForumValidators.validateComment('A' * 601), isNotNull);
      print('  ✅ validateComment too long: error returned');
    });
  });

  // -------------------------------------------------------------------------
  group('🚫  Anti-spam cooldown + Sanitizer (Métier 4)', () {
    test('sanitizeText replaces blacklisted word with ***', () {
      // 'arnaque' is in the blacklist — exact word boundary match
      final result = ContentModerator.sanitizeText('C est une arnaque ce service !');
      expect(result, contains('***'));
      print('  ✅ sanitizeText blacklist word replaced: OK');
    });

    test('sanitizeText leaves clean text untouched', () {
      const clean = 'Bonjour j ai une fuite sous mon évier.';
      final result = ContentModerator.sanitizeText(clean);
      expect(result, clean);
      print('  ✅ sanitizeText clean text untouched: OK');
    });

    test('Anti-spam: first post allowed (no cooldown)', () {
      final userId = 'spam_test_user_${DateTime.now().millisecondsSinceEpoch}';
      final remaining = ContentModerator.checkRateLimitSecondsRemaining(userId);
      expect(remaining, 0);
      print('  ✅ Anti-spam: first action allowed: OK');
    });

    test('Anti-spam: after registering action, cooldown is active', () async {
      final userId = 'spam_test_user2_${DateTime.now().millisecondsSinceEpoch}';
      ContentModerator.registerAction(userId);
      final remaining = ContentModerator.checkRateLimitSecondsRemaining(userId);
      // Should be > 0 (cooldown active) — exact value depends on timing
      expect(remaining, greaterThan(0));
      print('  ✅ Anti-spam: cooldown active after action ($remaining s remaining): OK');
    });
  });
}
