// lib/state/pet_repository.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'pet.dart';

abstract class PetRepository {
  Future<Pet?> load();
  Future<void> save(Pet pet);
  Future<void> clear();
}

class PrefsPetRepository implements PetRepository {
  static const _key = 'pet_state';

  @override
  Future<Pet?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    return Pet.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> save(Pet pet) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(pet.toJson()));
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
