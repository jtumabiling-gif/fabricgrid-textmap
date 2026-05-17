enum UserRole {
  user,
  shopOwner,
  admin,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.user:
        return 'User';
      case UserRole.shopOwner:
        return 'Shop Owner';
      case UserRole.admin:
        return 'Admin';
    }
  }

  String get stringValue {
    switch (this) {
      case UserRole.user:
        return 'USER';
      case UserRole.shopOwner:
        return 'SHOP_OWNER';
      case UserRole.admin:
        return 'ADMIN';
    }
  }

  static UserRole fromString(String value) {
    switch (value.toUpperCase()) {
      case 'USER':
        return UserRole.user;
      case 'SHOP_OWNER':
        return UserRole.shopOwner;
      case 'ADMIN':
        return UserRole.admin;
      default:
        return UserRole.user;
    }
  }
}
