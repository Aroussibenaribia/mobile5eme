import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mobile5eme/services/auth_service.dart';
import 'package:mobile5eme/services/professional_service.dart';

void main() {
  group('AuthService Tests (Membre 1)', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService();
    });

    test('Initial user is unauthenticated when no active session', () {
      expect(authService.isAuthenticated, isFalse);
      expect(authService.currentUser, isNull);
    });

    test('Logout clears current user', () async {
      final initialFactory = databaseFactoryOrNull;
      await authService.logout();
      expect(databaseFactoryOrNull, same(initialFactory),
          reason:
              'Opening HomeFix must not replace the global SQLite factory.');
      expect(authService.isAuthenticated, isFalse);
      expect(authService.currentUser, isNull);
    });
  });

  group('ProfessionalService Tests (Membre 1)', () {
    late ProfessionalService proService;

    setUp(() {
      proService = ProfessionalService();
    });

    test('Initial list is empty before SQLite loading completes', () {
      expect(proService.allProfessionals, isEmpty);
      expect(proService.filteredProfessionals, isEmpty);
    });

    test('Category filtering updates selected category', () {
      proService.setCategory('Plomberie');
      expect(proService.selectedCategory, 'Plomberie');

      proService.setCategory('Tous');
      expect(proService.selectedCategory, 'Tous');
    });

    test('Search query updates active filter', () {
      proService.setSearchQuery('Karim');
      expect(proService.searchQuery, 'Karim');

      proService.setSearchQuery('');
      expect(proService.searchQuery, '');
    });
  });
}
