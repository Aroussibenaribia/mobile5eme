import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/professional_model.dart';

class AuthService extends ChangeNotifier {
  bool get isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseAuth? get _auth => isFirebaseAvailable ? FirebaseAuth.instance : null;
  FirebaseFirestore? get _firestore =>
      isFirebaseAvailable ? FirebaseFirestore.instance : null;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthService() {
    _initAuthState();
  }

  void _initAuthState() {
    if (!isFirebaseAvailable || _auth == null) return;
    try {
      final firebaseUser = _auth?.currentUser;
      if (firebaseUser != null) {
        _fetchUserFromFirestore(firebaseUser.uid);
      }
    } catch (_) {}
  }

  Future<void> _fetchUserFromFirestore(String uid) async {
    if (!isFirebaseAvailable || _firestore == null) return;
    try {
      final doc = await _firestore!.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        _currentUser = UserModel.fromMap(doc.data()!, doc.id);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Firestore fetch error: $e');
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (!isFirebaseAvailable || _auth == null) {
      _isLoading = false;
      _errorMessage = 'Connexion Firebase non disponible. Vérifiez votre connexion internet.';
      notifyListeners();
      return false;
    }

    final cleanEmail = email.trim().toLowerCase();

    try {
      final cred = await _auth!.signInWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      final uid = cred.user!.uid;

      if (_firestore != null) {
        final doc = await _firestore!.collection('users').doc(uid).get();
        if (doc.exists && doc.data() != null) {
          _currentUser = UserModel.fromMap(doc.data()!, uid);
        } else {
          _currentUser = UserModel(
            id: uid,
            email: cleanEmail,
            fullName: cred.user?.displayName ?? cleanEmail.split('@').first,
            role: UserRole.client,
            createdAt: DateTime.now(),
          );
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      switch (e.code) {
        case 'user-not-found':
          _errorMessage = 'Aucun utilisateur trouvé avec cette adresse e-mail.';
          break;
        case 'wrong-password':
          _errorMessage = 'Mot de passe incorrect.';
          break;
        case 'invalid-email':
          _errorMessage = "Format d'adresse e-mail invalide.";
          break;
        case 'user-disabled':
          _errorMessage = 'Ce compte a été suspendu.';
          break;
        case 'invalid-credential':
          _errorMessage = 'Email ou mot de passe incorrect.';
          break;
        default:
          _errorMessage = e.message ?? 'Échec de la connexion.';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erreur de connexion : $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerClient({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String city,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (!isFirebaseAvailable || _auth == null) {
      _isLoading = false;
      _errorMessage = 'Connexion Firebase non disponible. Vérifiez votre connexion internet.';
      notifyListeners();
      return false;
    }

    final cleanEmail = email.trim().toLowerCase();

    try {
      final cred = await _auth!.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      final uid = cred.user!.uid;

      final newUser = UserModel(
        id: uid,
        email: cleanEmail,
        fullName: fullName.trim(),
        phone: phone.trim(),
        role: UserRole.client,
        city: city.trim().isEmpty ? 'Tunis' : city.trim(),
        createdAt: DateTime.now(),
      );

      if (_firestore != null) {
        await _firestore!.collection('users').doc(uid).set(newUser.toMap());
      }

      _currentUser = newUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      if (e.code == 'email-already-in-use') {
        _errorMessage = 'Cette adresse e-mail est déjà utilisée.';
      } else if (e.code == 'weak-password') {
        _errorMessage = 'Le mot de passe doit comporter au moins 6 caractères.';
      } else {
        _errorMessage = e.message ?? 'Échec de la création du compte.';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = "Erreur lors de l'inscription : $e";
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerProfessional({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String city,
    required String specialty,
    required double hourlyRate,
    required int experienceYears,
    required String bio,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (!isFirebaseAvailable || _auth == null) {
      _isLoading = false;
      _errorMessage = 'Connexion Firebase non disponible. Vérifiez votre connexion internet.';
      notifyListeners();
      return false;
    }

    final cleanEmail = email.trim().toLowerCase();

    try {
      final cred = await _auth!.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      final uid = cred.user!.uid;

      final newUser = UserModel(
        id: uid,
        email: cleanEmail,
        fullName: fullName.trim(),
        phone: phone.trim(),
        role: UserRole.professional,
        city: city.trim().isEmpty ? 'Tunis' : city.trim(),
        createdAt: DateTime.now(),
      );

      if (_firestore != null) {
        await _firestore!.collection('users').doc(uid).set(newUser.toMap());

        final proDetails = ProfessionalModel(
          id: uid,
          name: fullName.trim(),
          email: cleanEmail,
          phone: phone.trim(),
          avatarUrl: '',
          coverImageUrl: '',
          specialty: specialty,
          bio: bio.trim(),
          city: city.trim().isEmpty ? 'Tunis' : city.trim(),
          hourlyRate: hourlyRate,
          experienceYears: experienceYears,
          rating: 5.0,
          reviewCount: 0,
          isVerified: true,
          skills: [specialty, 'Intervention rapide', 'Devis gratuit'],
          services: [
            ProServiceItem(
              title: 'Intervention standard $specialty',
              description: 'Diagnostic et réparation initiale',
              price: hourlyRate,
              duration: '1h',
            ),
          ],
        );

        await _firestore!
            .collection('professionals')
            .doc(uid)
            .set(proDetails.toMap());
      }

      _currentUser = newUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      if (e.code == 'email-already-in-use') {
        _errorMessage = 'Cette adresse e-mail est déjà utilisée.';
      } else if (e.code == 'weak-password') {
        _errorMessage = 'Le mot de passe doit comporter au moins 6 caractères.';
      } else {
        _errorMessage = e.message ?? 'Échec de la création du compte professionnel.';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = "Erreur lors de l'inscription pro : $e";
      notifyListeners();
      return false;
    }
  }

  Future<void> updateProfile({
    required String fullName,
    required String phone,
    required String city,
    required String address,
    String? avatarUrl,
  }) async {
    if (_currentUser == null) return;
    _isLoading = true;
    notifyListeners();

    _currentUser = _currentUser!.copyWith(
      fullName: fullName,
      phone: phone,
      city: city,
      address: address,
      avatarUrl: avatarUrl ?? _currentUser!.avatarUrl,
    );

    if (isFirebaseAvailable && _firestore != null) {
      try {
        final updateData = <String, dynamic>{
          'fullName': fullName,
          'phone': phone,
          'city': city,
          'address': address,
        };
        if (avatarUrl != null) {
          updateData['avatarUrl'] = avatarUrl;
        }
        await _firestore!
            .collection('users')
            .doc(_currentUser!.id)
            .update(updateData);
      } catch (e) {
        debugPrint('Firestore update error: $e');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    if (isFirebaseAvailable && _auth != null) {
      try {
        await _auth!.signOut();
      } catch (_) {}
    }
    _currentUser = null;
    _isLoading = false;
    notifyListeners();
  }
}
