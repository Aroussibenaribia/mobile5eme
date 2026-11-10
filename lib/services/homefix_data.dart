import 'package:flutter/foundation.dart';
import '../core/data/homefix_repository.dart';
import '../models/user_model.dart';
import '../models/service_model.dart';
import '../models/booking_model.dart';
import '../models/reclamation_model.dart';

class HomeFixData extends ChangeNotifier {
  final HomeFixRepository repository;
  List<ServiceModel> services = [];
  List<BookingModel> bookings = [];
  List<ReclamationModel> reclamations = [];
  List<UserModel> users = [];
  bool isLoading = false;
  String? error;
  bool _disposed = false;
  int _generation = 0;
  HomeFixData(this.repository) {
    repository.addListener(refresh);
    refresh();
  }
  Future<void> refresh() async {
    final generation = ++_generation;
    isLoading = true;
    error = null;
    if (!_disposed) notifyListeners();
    try {
      final actor = await repository.currentUser();
      final nextBookings = await repository.bookings();
      final nextReclamations = await repository.reclamations();
      final nextServices = actor?.isProfessional == true
          ? await repository.services(actor!.id, includeInactive: true)
          : <ServiceModel>[];
      final nextUsers =
          actor?.isAdmin == true ? await repository.users() : <UserModel>[];
      if (_disposed || generation != _generation) return;
      bookings = nextBookings;
      reclamations = nextReclamations;
      services = nextServices;
      users = nextUsers;
    } catch (e) {
      if (!_disposed && generation == _generation) {
        error = e is HomeFixException
            ? e.message
            : 'Impossible de charger les données. Réessayez.';
        bookings = [];
        reclamations = [];
        services = [];
        users = [];
      }
    } finally {
      if (!_disposed && generation == _generation) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    repository.removeListener(refresh);
    super.dispose();
  }
}
