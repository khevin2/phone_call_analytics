import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionStatusState {
  const PermissionStatusState({required this.hasPermissions, required this.limitedMode});

  final bool hasPermissions;
  final bool limitedMode;
}

const _limitedModeKey = 'limitedModeEnabled';

final permissionStateProvider = FutureProvider<PermissionStatusState>((ref) async {
  final phone = await Permission.phone.status;
  final prefs = await SharedPreferences.getInstance();
  final limitedMode = prefs.getBool(_limitedModeKey) ?? false;
  return PermissionStatusState(hasPermissions: phone.isGranted, limitedMode: limitedMode);
});

class PermissionService {
  Future<bool> requestCorePermissions() async {
    final statuses = await [Permission.phone].request();
    return statuses.values.every((status) => status.isGranted);
  }

  Future<bool> requestContactsPermission() async {
    final status = await Permission.contacts.request();
    return status.isGranted;
  }

  Future<void> enableLimitedMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_limitedModeKey, true);
  }

  Future<void> disableLimitedMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_limitedModeKey, false);
  }
}
