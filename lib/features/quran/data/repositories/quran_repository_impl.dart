import '../../domain/repositories/quran_repository.dart' as domain;
import '../datasources/quran_local_data_source.dart';

class QuranRepositoryImpl implements domain.QuranRepository {
  final QuranLocalDataSource _localDataSource;

  QuranRepositoryImpl(this._localDataSource);

  @override
  Future<List<Map<String, dynamic>>> getSurahs() {
    return _localDataSource.getSurahs();
  }
}

class QuranRepository extends QuranRepositoryImpl {
  QuranRepository() : super(QuranLocalDataSource());
}
