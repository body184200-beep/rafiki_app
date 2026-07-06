import '../entities/discovery_record.dart';
export '../entities/discovery_record.dart';

abstract class DiscoveryRepository {
  Future<List<DiscoveryRecord>> loadAll(List<String> rewardIds);
  Future<void> save(DiscoveryRecord record);
  Future<void> clearAll(List<String> rewardIds);
}
