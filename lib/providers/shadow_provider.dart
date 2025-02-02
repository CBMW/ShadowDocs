import 'package:flutter/material.dart';
import '../models/shadow.dart';

class ShadowProvider with ChangeNotifier {
  final List<Shadow> _shadows = [];

  List<Shadow> get shadows => _shadows;

  void addShadow(Shadow shadow) {
    _shadows.add(shadow);
    notifyListeners();
  }

  void removeShadow(String id) {
    _shadows.removeWhere((shadow) => shadow.id == id);
    notifyListeners();
  }

  // Additional methods for joining, sharing shadows
}
