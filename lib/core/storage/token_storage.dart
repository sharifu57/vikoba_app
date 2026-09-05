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

  static Future<void> saveSession(Map<String, dynamic> response) async {
    final prefs = await SharedPreferences.getInstance();

    final user = response["data"];

    await prefs.setString(_accessToken, response["token"] ?? "");

    await prefs.setString(_refreshToken, response["refreshToken"] ?? "");

    await prefs.setString(_expires, response["expired"] ?? "");

    await prefs.setString(
      "expires_at",
      DateTime.now().add(const Duration(days: 1)).toIso8601String(),
    );

    await prefs.setInt(_userId, user["id"] ?? 0);

    await prefs.setString(_fullName, user["fullName"] ?? "");

    await prefs.setString(_email, user["email"] ?? "");

    await prefs.setString(_phone, user["phone"] ?? "");

    await prefs.setString(_username, user["username"] ?? "");

    await prefs.setString(_profilePicture, user["profilePictureUrl"] ?? "");

    final roles = <String>[];

    if (user["roles"] != null) {
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

    if (user['branches'] != null) {
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
    final branches = await TokenStorage.getBranches();
    final selectedBranch = await TokenStorage.getSelectedBranch();

    //get roles and see if has supplier role
    final roles = await TokenStorage.getRoles();

    if (roles.contains("SUPPLIER")) {
      Get.offAllNamed("/supplier-wrapper");
      return;
    }

    if (selectedBranch != null) {
      Get.offAllNamed("/wrapper");
      return;
    }

    if (branches.length == 1) {
      await TokenStorage.saveSelectedBranch(branches.first);
      Get.offAllNamed("/wrapper");
      return;
    }

    if (branches.isEmpty) {
      Get.offAllNamed("/no-branch");
      return;
    }

    Get.offAllNamed("/select-branch");
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
}
