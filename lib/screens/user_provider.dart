import 'package:flutter/cupertino.dart';

class UserProvider extends ChangeNotifier {
  String _userId = '';
  String _userRole = '';
  String _userName = '';
  String? _salonId;
  String _email = '';

  String get userId => _userId;
  String get userRole => _userRole;
  String get userName => _userName;
  String? get salonId => _salonId;
  String get email => _email;

  void setUserDetails({
    required String id,
    required String role,
    required String name,
    String? salonId,
    required String email,
  }) {
    _userId = id;
    _userRole = role;
    _userName = name;
    _salonId = salonId;
    _email = email;

    debugPrint(
        'User Details Set:\nUser ID: $_userId\nRole: $_userRole\nName: $_userName\nSalon ID: ${_salonId ?? "None"}\nEmail: $_email');
    notifyListeners();
  }

  void clearUserDetails() {
    _userId = '';
    _userRole = '';
    _userName = '';
    _salonId = null;
    _email = '';

    debugPrint('User details cleared');
    notifyListeners();
  }
}