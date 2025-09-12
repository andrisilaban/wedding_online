import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _tokenKey = 'token';
  static const _invitationId = 'invitationID';
  static const _eventId = 'eventID';
  static const String _defaultInvitationId = '0'; // Default value
  static const String _defaultEventId = '0'; // Default value

  // TOKEN METHODS
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

  // INVITATION ID METHODS
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

  // EVENT ID METHODS
  Future<void> saveEventId(String eventID) async {
    final prefs = await SharedPreferences.getInstance();
    debugPrint('----');
    debugPrint('event id: $eventID');
    await prefs.setString(_eventId, eventID);
  }

  Future<String?> getEventID() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_eventId);
  }

  // Method tambahan untuk mendapatkan event ID dengan default value
  Future<String> getEventIDOrDefault() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_eventId) ?? _defaultEventId;
  }

  // Method untuk mengecek apakah ada event ID yang tersimpan
  Future<bool> hasEventId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_eventId);
  }

  // Method untuk menghapus event ID (misalnya setelah selesai edit)
  Future<void> clearEventId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_eventId);
  }

  // CLEAR METHODS
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Method untuk clear data tertentu saja
  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<void> clearInvitationData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_invitationId);
  }
}
