import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _accessToken = "access_token";
  static const _refreshToken = "refresh_token";
  static const _expires = "expires";

  static const _userId = "user_id";
  static const _fullName = "full_name";
  static const _email = "email";
  static const _phone = "phone";
  static const _profilePicture = "profile_picture";
  static const _username = "username";

  static const _roles = "roles";
  static const _branches = "branches";
  static const _selectedBranch = "selectedBranch";
  static const _permissions = "permissions";

  static const _organizationId = "organization_id";
  static const _organizationName = "organization_name";
  static const _currentGroup = "current_group";

  static Map<String, dynamic> _asMap(Object? value) {
    return value is Map
        ? Map<String, dynamic>.from(value)
        : <String, dynamic>{};
  }

  static Future<void> saveSession(Map<String, dynamic> response) async {
    final prefs = await SharedPreferences.getInstance();

    final session = _asMap(response["data"]);
    final user = _asMap(session["user"] ?? session);
    final groups = session["groups"] is List
        ? List<Map<String, dynamic>>.from(
            (session["groups"] as List).map(_asMap),
          )
        : <Map<String, dynamic>>[];

    await prefs.setString(_accessToken, response["token"] ?? "");

    await prefs.setString(_refreshToken, response["refreshToken"] ?? "");

    await prefs.setString(_expires, response["expired"] ?? "");

    await prefs.setString(
      "expires_at",
      DateTime.now().add(const Duration(days: 1)).toIso8601String(),
    );

    await prefs.setInt(_userId, (user["id"] as num?)?.toInt() ?? 0);

    await prefs.setString(_fullName, user["fullName"] ?? "");

    await prefs.setString(_email, user["email"] ?? "");

    await prefs.setString(_phone, user["phone"] ?? "");

    await prefs.setString(_username, user["username"] ?? "");

    await prefs.setString(_profilePicture, user["profilePictureUrl"] ?? "");

    final roles = <String>[];

    if (user["roles"] is List) {
      for (final role in user["roles"]) {
        if (role is String) {
          roles.add(role);
        } else if (role is Map) {
          roles.add(role["name"]);
        }
      }
    }

    await prefs.setStringList(_roles, roles);

    // final permissions = <String>[];

    // if (user['branches'] != null) {
    //   for (final branch in user['branches']) {
    //     final roles = branch['user']['roles'];
    //     if (roles != null) {
    //       for (final role in roles) {
    //         final rolePermissions = role['permissions'];
    //         if (rolePermissions != null) {
    //           for (final permission in rolePermissions) {
    //             permissions.add(permission['name']);
    //           }
    //         }
    //       }
    //     }
    //   }
    // }

    // await prefs.setStringList(_permissions, permissions);

    final permissions = <String>{}; // Set removes duplicates

    if (user['branches'] is List) {
      for (final branch in user['branches']) {
        final role = branch['role'];

        if (role != null && role['permissions'] != null) {
          for (final permission in role['permissions']) {
            permissions.add(permission['name']);
          }
        }
      }
    }

    await prefs.setStringList(_permissions, permissions.toList());
    await prefs.setString(_branches, jsonEncode(user["branches"] ?? []));
    await prefs.setString('groups', jsonEncode(groups));

    if (groups.isNotEmpty) {
      final primary = groups.firstWhere(
        (item) => item['settingsConfigured'] == true,
        orElse: () => groups.first,
      );
      final group = _asMap(primary['group']);
      await prefs.setString(_currentGroup, jsonEncode(group));
      await prefs.setInt(
        'current_group_id',
        (group['groupId'] as num?)?.toInt() ?? 0,
      );
      await prefs.setString(
        'current_group_name',
        group['groupName'] ?? 'Vikoba group',
      );
      await prefs.setString(
        'current_group_currency',
        group['currency'] ?? 'TZS',
      );
    }

    // Save organization details
    if (user["branches"] != null && user["branches"].isNotEmpty) {
      final firstBranch = user["branches"][0];

      final organization = firstBranch["branch"]["organization"];

      if (organization != null) {
        await prefs.setInt(_organizationId, organization["id"] ?? 0);

        await prefs.setString(_organizationName, organization["name"] ?? "");
      }

      await prefs.setInt("selectedBranchId", firstBranch["branch"]["id"] ?? 0);
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessToken);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshToken);
  }

  static Future<String?> getFullName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fullName);
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_email);
  }

  static Future<String?> getPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_phone);
  }

  static Future<List<String>> getRoles() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_roles) ?? [];
  }

  static Future<List<Map<String, dynamic>>> getBranches() async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getString(_branches);

    if (data == null) {
      return [];
    }

    final decoded = jsonDecode(data);

    return List<Map<String, dynamic>>.from(decoded);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_accessToken);
  }

  static Future<bool> isAccessTokenExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final expires = prefs.getString("expires_at");

    if (expires == null) return true;

    return DateTime.now().isAfter(DateTime.parse(expires));
  }

  static Future<void> updateTokens({
    required String token,
    required String refreshToken,
    required String expires,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_accessToken, token);
    await prefs.setString(_refreshToken, refreshToken);
    await prefs.setString(_expires, expires);
  }

  static Future<void> saveSelectedBranch(Map<String, dynamic> branch) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedBranch, jsonEncode(branch));
  }

  static Future<void> saveSelectedBranchId(Map<String, dynamic> branch) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("selectedBranchId", jsonEncode(branch['id']));
  }

  static Future<Map<String, dynamic>?> getSelectedBranch() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_selectedBranch);

    if (json == null) return null;
    return jsonDecode(json);
  }

  static Future<int?> getSelectedBranchId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("selectedBranchId");
  }

  static Future<bool> hasSelectedBranch() async {
    final selected = await getSelectedBranch();
    return selected != null;
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userId);
  }

  static Future<void> navigateAfterLogin() async {
    Get.offAllNamed('/member');
  }

  static Future<List<String>> getPermissions() async {
    final prefs = await SharedPreferences.getInstance();

    final permissions = prefs.getStringList(_permissions) ?? [];

    print("SAVED PERMISSIONS =====> $permissions");

    return permissions;
  }

  static Future<int?> getOrganizationId() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getInt(_organizationId);
  }

  static Future<String?> getOrganizationName() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_organizationName);
  }

  static Future<int?> getCurrentGroupId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('current_group_id');
  }

  static Future<String> getCurrentGroupName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('current_group_name') ?? 'Vikoba group';
  }

  static Future<String> getCurrentGroupCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('current_group_currency') ?? 'TZS';
  }
}
