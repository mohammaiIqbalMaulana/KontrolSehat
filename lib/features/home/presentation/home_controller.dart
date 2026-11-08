import 'package:flutter/foundation.dart';

import '../../../core/errors/error_mapper.dart';
import '../../medication/data/doses_repository.dart';
import '../data/profile_repository.dart';

enum HomeStatus { loading, ready, failed }

/// Memuat data Beranda. Urutan wajib: `ensure_doses` dulu, baru data
/// lain dibaca (FR-207).
class HomeController extends ChangeNotifier {
  HomeController({required this.profiles, required this.doses});

  final ProfileRepository profiles;
  final DosesRepository doses;

  HomeStatus _status = HomeStatus.loading;
  Profile? _profile;
  String? _error;

  HomeStatus get status => _status;
  Profile? get profile => _profile;
  String? get error => _error;

  Future<void> load() async {
    _status = HomeStatus.loading;
    _error = null;
    notifyListeners();
    try {
      await doses.ensureDoses();
      _profile = await profiles.fetchMine();
      _status = HomeStatus.ready;
    } on Object catch (e) {
      _error = ErrorMapper.message(e);
      _status = HomeStatus.failed;
    }
    notifyListeners();
  }
}
