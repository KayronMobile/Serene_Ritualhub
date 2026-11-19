import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/result.dart';

/// Serviço de persistência local (chave/valor JSON) sobre SharedPreferences.
///
/// Serviços encapsulam APIs externas/plataforma e não guardam estado
/// de domínio — a lógica fica nos repositórios.
class LocalStorageService {
  LocalStorageService({SharedPreferences? preferences})
    : _preferences = preferences;

  final _log = Logger('LocalStorageService');
  SharedPreferences? _preferences;

  Future<SharedPreferences> get _prefs async =>
      _preferences ??= await SharedPreferences.getInstance();

  Future<Result<Object?>> readJson(String key) async {
    try {
      final raw = (await _prefs).getString(key);
      if (raw == null) return const Result.ok(null);
      return Result.ok(jsonDecode(raw));
    } on Exception catch (e) {
      _log.warning('Falha ao ler $key', e);
      return Result.error(e);
    }
  }

  Future<Result<void>> writeJson(String key, Object? value) async {
    try {
      await (await _prefs).setString(key, jsonEncode(value));
      return const Result.ok(null);
    } on Exception catch (e) {
      _log.warning('Falha ao gravar $key', e);
      return Result.error(e);
    }
  }

  Future<Result<String?>> readString(String key) async {
    try {
      return Result.ok((await _prefs).getString(key));
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<void>> writeString(String key, String value) async {
    try {
      await (await _prefs).setString(key, value);
      return const Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<void>> remove(String key) async {
    try {
      await (await _prefs).remove(key);
      return const Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }
}
