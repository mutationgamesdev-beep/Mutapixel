import 'package:shared_preferences/shared_preferences.dart';

/// Stores the user's own AI API key on their device.
/// The key never leaves the device except in direct calls to the AI API.
class AiSettings {
  static const _keyName = 'ai_openai_key';

  static Future<String?> loadKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_keyName)?.trim();
    return (key == null || key.isEmpty) ? null : key;
  }

  static Future<void> saveKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, key.trim());
  }

  static Future<void> clearKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyName);
  }
}
