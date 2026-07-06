import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/discovery_record.dart';
import 'package:rafiki_app/features/gamification/domain/repositories/discovery_repository.dart' as domain;

class DiscoveryRepositoryImpl implements domain.DiscoveryRepository {
  static const String _prefix = 'discovery_record_';

  @override
  Future<List<DiscoveryRecord>> loadAll(List<String> rewardIds) async {
    final prefs = await SharedPreferences.getInstance();
    final List<DiscoveryRecord> list = [];
    for (final id in rewardIds) {
      final raw = prefs.getString('$_prefix$id');
      if (raw != null) {
        try {
          list.add(DiscoveryRecord.fromJson(jsonDecode(raw) as Map<String, dynamic>));
        } catch (_) {
          list.add(DiscoveryRecord(rewardId: id, discovered: false));
        }
      } else {
        list.add(DiscoveryRecord(rewardId: id, discovered: false));
      }
    }
    return list;
  }

  @override
  Future<void> save(DiscoveryRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix${record.rewardId}', jsonEncode(record.toJson()));
  }

  @override
  Future<void> clearAll(List<String> rewardIds) async {
    final prefs = await SharedPreferences.getInstance();
    for (final id in rewardIds) {
      await prefs.remove('$_prefix$id');
    }
  }
}
