import 'package:easy_localization/easy_localization.dart';

class RoleFormatter {
  static String format(String role) {
    switch (role) {
      case 'admin':
        return 'role_admin'.tr();
      case 'member':
        return 'role_member'.tr();
      default:
        return 'role_user'.tr();
    }
  }
}