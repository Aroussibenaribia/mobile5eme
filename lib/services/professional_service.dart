import 'package:flutter/foundation.dart';
import '../core/data/homefix_repository.dart';
import '../models/professional_model.dart';

class ProfessionalService extends ChangeNotifier {
  final HomeFixRepository repository;
  List<ProfessionalModel> _professionals = [];
  String _selectedCategory = 'Tous', _searchQuery = '';
  bool _isLoading = false, _disposed = false;
  int _generation = 0;
  String? errorMessage;
  List<ProfessionalModel> get allProfessionals => _professionals;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  ProfessionalService({HomeFixRepository? repository})
      : repository = repository ?? HomeFixRepository() {
    this.repository.addListener(loadProfessionals);
    loadProfessionals();
  }
  Future<void> loadProfessionals() async {
    final generation = ++_generation;
    _isLoading = true;
    errorMessage = null;
    if (!_disposed) notifyListeners();
    try {
      final result = await repository.professionals();
      if (!_disposed && generation == _generation) _professionals = result;
    } catch (_) {
      if (!_disposed && generation == _generation) {
        errorMessage = 'Impossible de charger les artisans.';
      }
    } finally {
      if (!_disposed && generation == _generation) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  List<ProfessionalModel> get filteredProfessionals {
    return _professionals.where((pro) {
      final matchesCategory = _selectedCategory == 'Tous' ||
          pro.specialty.trim().toLowerCase() ==
              _selectedCategory.trim().toLowerCase() ||
          pro.skills.any((s) =>
              s.trim().toLowerCase() == _selectedCategory.trim().toLowerCase());
      final matchesQuery = _searchQuery.isEmpty ||
          pro.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          pro.specialty.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          pro.city.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          pro.skills.any(
              (s) => s.toLowerCase().contains(_searchQuery.toLowerCase())) ||
          pro.services.any((s) =>
              s.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              s.description.toLowerCase().contains(_searchQuery.toLowerCase()));
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
    _disposed = true;
    repository.removeListener(loadProfessionals);
    super.dispose();
  }
}
