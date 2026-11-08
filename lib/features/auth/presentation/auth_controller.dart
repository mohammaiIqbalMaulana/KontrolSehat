import 'package:flutter/foundation.dart';

import '../../../core/errors/error_mapper.dart';
import '../data/auth_repository.dart';

/// Status layar Login dan Registrasi. Tidak mengenal widget.
class AuthController extends ChangeNotifier {
  AuthController(this._repo);

  final AuthRepository _repo;

  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  Future<bool> signIn(String email, String password) =>
      _run(() => _repo.signIn(email: email, password: password));

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required int birthYear,
    required String timezone,
  }) =>
      _run(
        () => _repo.signUp(
          email: email,
          password: password,
          fullName: fullName,
          birthYear: birthYear,
          timezone: timezone,
        ),
      );

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    if (_loading) return false;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on Object catch (e) {
      _error = ErrorMapper.message(e);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
