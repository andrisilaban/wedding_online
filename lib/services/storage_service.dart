import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _tokenKey = 'token';
  static const _invitationId = 'invitationID';
  static const String _defaultInvitationId = '0'; // Default value

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    debugPrint('----');
    debugPrint(token);
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> saveInvitationId(String invitationID) async {
    final prefs = await SharedPreferences.getInstance();
    debugPrint('----');
    debugPrint('invitation id: $invitationID');
    await prefs.setString(_invitationId, invitationID);
  }

  // Perbaikan: Mengembalikan String? dan handle null case
  Future<String?> getInvitationID() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_invitationId);
  }

  // Method tambahan untuk mendapatkan invitation ID dengan default value
  Future<String> getInvitationIDOrDefault() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_invitationId) ?? _defaultInvitationId;
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
