import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/professional_model.dart';

class ProfessionalService extends ChangeNotifier {
  List<ProfessionalModel> _professionals = [];
  String _selectedCategory = 'Tous';
  String _searchQuery = '';
  bool _isLoading = false;
  StreamSubscription<QuerySnapshot>? _proSubscription;
  StreamSubscription<QuerySnapshot>? _userSubscription;

  List<ProfessionalModel> get allProfessionals => _professionals;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  bool get isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseFirestore? get _firestore =>
      isFirebaseAvailable ? FirebaseFirestore.instance : null;

  ProfessionalService() {
    fetchFromFirestore();
    _initRealtimeListeners();
  }

  void _initRealtimeListeners() {
    if (!isFirebaseAvailable || _firestore == null) return;
    try {
      _proSubscription?.cancel();
      _proSubscription = _firestore!
          .collection('professionals')
          .snapshots()
          .listen((_) {
        fetchFromFirestore();
      }, onError: (e) {
        debugPrint('Realtime pro listener error: $e');
      });

      _userSubscription?.cancel();
      _userSubscription = _firestore!
          .collection('users')
          .where('role', isEqualTo: 'professional')
          .snapshots()
          .listen((_) {
        fetchFromFirestore();
      }, onError: (e) {
        debugPrint('Realtime user pro listener error: $e');
      });
    } catch (e) {
      debugPrint('Realtime init error: $e');
    }
  }

  Future<void> fetchFromFirestore() async {
    if (!isFirebaseAvailable || _firestore == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final Map<String, ProfessionalModel> proMap = {};

      // 1. Fetch from 'professionals' collection
      try {
        final proSnap = await _firestore!.collection('professionals').get();
        for (final doc in proSnap.docs) {
          try {
            final data = doc.data();
            final pro = ProfessionalModel.fromMap(data, doc.id);
            proMap[pro.id] = pro;
          } catch (e) {
            debugPrint('Error parsing pro doc ${doc.id}: $e');
          }
        }
      } catch (e) {
        debugPrint('Error fetching professionals collection: $e');
      }

      // 2. Fetch from 'users' collection where role is professional (fallback / sync)
      try {
        final userSnap = await _firestore!
            .collection('users')
            .where('role', isEqualTo: 'professional')
            .get();
        for (final doc in userSnap.docs) {
          final data = doc.data();
          if (!proMap.containsKey(doc.id)) {
            proMap[doc.id] = ProfessionalModel(
              id: doc.id,
              name: data['fullName'] ?? data['name'] ?? 'Professionnel',
              email: data['email'] ?? '',
              phone: data['phone'] ?? '',
              avatarUrl: data['avatarUrl'] ?? '',
              coverImageUrl: '',
              specialty: data['specialty'] ?? 'Services à domicile',
              bio: data['bio'] ?? 'Professionnel certifié HomeFix',
              city: data['city'] ?? 'Tunis',
              hourlyRate: (data['hourlyRate'] as num?)?.toDouble() ?? 35.0,
              experienceYears: (data['experienceYears'] as num?)?.toInt() ?? 3,
              rating: (data['rating'] as num?)?.toDouble() ?? 5.0,
              reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
              isVerified: true,
              skills: [data['specialty'] ?? 'Services', 'Intervention rapide'],
            );
          }
        }
      } catch (e) {
        debugPrint('Error fetching users for pros: $e');
      }

      final list = proMap.values.toList();
      list.sort((a, b) => b.rating.compareTo(a.rating));
      _professionals = list;
    } catch (e) {
      debugPrint('Firestore professionals fetch error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<ProfessionalModel> get filteredProfessionals {
    return _professionals.where((pro) {
      final matchesCategory = _selectedCategory == 'Tous' ||
          pro.specialty.trim().toLowerCase() == _selectedCategory.trim().toLowerCase() ||
          pro.skills.any((s) => s.trim().toLowerCase() == _selectedCategory.trim().toLowerCase());
      final matchesQuery = _searchQuery.isEmpty ||
          pro.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          pro.specialty.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          pro.city.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          pro.skills.any((s) => s.toLowerCase().contains(_searchQuery.toLowerCase()));
      return matchesCategory && matchesQuery;
    }).toList();
  }

  List<ProfessionalModel> get topRatedProfessionals {
    final list = List<ProfessionalModel>.from(_professionals);
    list.sort((a, b) => b.rating.compareTo(a.rating));
    return list.take(6).toList();
  }

  ProfessionalModel? getById(String id) {
    try {
      return _professionals.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  @override
  void dispose() {
    _proSubscription?.cancel();
    _userSubscription?.cancel();
    super.dispose();
  }
}
