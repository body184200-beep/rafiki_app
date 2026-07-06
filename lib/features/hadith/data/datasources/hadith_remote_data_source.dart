import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/hadith.dart';

class HadithRemoteDataSource {
  static const String _baseUrl = 'https://hadith-api.vercel.app';

  Future<List<HadithBookModel>> getBooks() async {
    final response = await http.get(Uri.parse('$_baseUrl/books')).timeout(
          const Duration(seconds: 5),
        );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final list = decoded['data'] as List;
      return list.map((e) => HadithBookModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load books from remote API');
  }

  Future<List<HadithModel>> getHadithsRange(String bookId, int start, int end) async {
    final url = Uri.parse('$_baseUrl/books/$bookId?range=$start-$end');
    final response = await http.get(url).timeout(const Duration(seconds: 6));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final hadithsData = decoded['data']['hadiths'] as List;
      final name = decoded['data']['name'] as String? ?? bookId;

      return hadithsData.map<HadithModel>((e) {
        final map = e as Map<String, dynamic>;
        map['source'] = name;
        map['book'] = bookId;
        return HadithModel.fromJson(map);
      }).toList();
    }
    throw Exception('Failed to load hadiths from remote API');
  }

  Future<HadithModel> getHadithByNumber(String bookId, int number) async {
    final response = await http.get(Uri.parse('$_baseUrl/books/$bookId/$number')).timeout(
          const Duration(seconds: 5),
        );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final map = decoded['data'] as Map<String, dynamic>;
      map['source'] = bookId;
      map['book'] = bookId;
      return HadithModel.fromJson(map);
    }
    throw Exception('Failed to load hadith $number from remote API');
  }
}
