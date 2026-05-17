import 'package:get/get.dart';
import '../models/user_role.dart';

class RoleController extends GetxController {
  // Observable to track selected role
  Rx<UserRole?> selectedRole = Rx<UserRole?>(null);

  // Method to set the role
  void setRole(UserRole role) {
    selectedRole.value = role;
  }

  // Method to set role from string
  void setRoleFromString(String roleString) {
    selectedRole.value = UserRoleExtension.fromString(roleString);
  }

  // Method to get the current role
  UserRole? getRole() => selectedRole.value;

  // Method to clear role
  void clearRole() {
    selectedRole.value = null;
  }
}
