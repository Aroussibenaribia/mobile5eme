import 'package:flutter/foundation.dart';
import '../core/data/homefix_repository.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final HomeFixRepository repository;
  UserModel? _currentUser;
  bool _isLoading = false, _disposed = false;
  String? _errorMessage;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AuthService({HomeFixRepository? repository, bool restoreSession = false})
      : repository = repository ?? HomeFixRepository() {
    if (restoreSession) _restore();
  }
  void _emit() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _restore() async {
    try {
      _currentUser = await repository.restoreSession();
    } catch (_) {
      _errorMessage = 'Impossible de restaurer la session.';
    }
    _emit();
  }

  Future<bool> _authenticate(Future<UserModel> Function() action) async {
    if (_isLoading) return false;
    _isLoading = true;
    _errorMessage = null;
    _emit();
    try {
      _currentUser = await action();
      return true;
    } catch (e) {
      _errorMessage = e is HomeFixException
          ? e.message
          : 'Impossible de terminer cette action. Réessayez.';
      return false;
    } finally {
      _isLoading = false;
      _emit();
    }
  }

  Future<bool> login(
          {required String email,
          required String password,
          bool rememberMe = true}) =>
      _authenticate(
          () => repository.login(email, password, rememberMe: rememberMe));
  Future<bool> registerClient(
          {required String fullName,
          required String email,
          required String password,
          required String phone,
          required String city}) =>
      _authenticate(() => repository.register(
          fullName: fullName,
          email: email,
          password: password,
          phone: phone,
          city: city,
          role: UserRole.client));
  Future<bool> registerProfessional(
          {required String fullName,
          required String email,
          required String password,
          required String phone,
          required String city,
          required String specialty,
          required double hourlyRate,
          required int experienceYears,
          required String bio}) =>
      _authenticate(() => repository.register(
          fullName: fullName,
          email: email,
          password: password,
          phone: phone,
          city: city,
          role: UserRole.professional,
          specialty: specialty,
          hourlyRate: hourlyRate,
          experienceYears: experienceYears,
          bio: bio));
  Future<void> updateProfile(
      {required String fullName,
      required String phone,
      required String city,
      required String address,
      String? avatarUrl,
      String? bio,
      List<String>? availableDays,
      bool? isAvailable}) async {
    _isLoading = true;
    _errorMessage = null;
    _emit();
    try {
      _currentUser = await repository.updateProfile(
          fullName: fullName,
          phone: phone,
          city: city,
          address: address,
          avatarUrl: avatarUrl,
          bio: bio,
          availableDays: availableDays,
          isAvailable: isAvailable);
    } catch (e) {
      _errorMessage = e is HomeFixException
          ? e.message
          : 'Impossible de modifier le profil.';
      rethrow;
    } finally {
      _isLoading = false;
      _emit();
    }
  }

  Future<void> logout() async {
    await repository.logout();
    _currentUser = null;
    _errorMessage = null;
    _emit();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
