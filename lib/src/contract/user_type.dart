import 'package:flutter/foundation.dart';

enum UserType {
  user,
  advanced,
  //
  developer;

  static UserType fromValue(int? v) {
    switch (v) {
      case 0:
        return UserType.user;
      case 1:
        return UserType.advanced;
      case 2:
        return UserType.developer;
      default:
        return UserType.user;
    }
  }

  static UserType current = kDebugMode ? UserType.developer : UserType.user;
}
