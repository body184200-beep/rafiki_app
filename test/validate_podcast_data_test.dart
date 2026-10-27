import 'package:flutter_test/flutter_test.dart';
import 'package:rafiki_app/features/guide/data/models/podcast_model.dart';

void main() {
  test('Validate Islamic Podcast Model & Serialization', () {
    final episode = PodcastEpisode.fromJson({
      'trackId': 101,
      'trackName': '001_كيف تحافظ على الصلاة؟ ｜ د. أحمد عبد المنعم',
      'description': '<p>حلقة إيمانية مميزة عن الصلاة</p>',
      'episodeUrl': 'https://example.com/audio.mp3',
      'trackTimeMillis': 1200000,
    }, channelId: 1, channelTitle: 'تربويات');

    expect(episode.id, 101);
    expect(episode.title, 'كيف تحافظ على الصلاة؟ - د. أحمد عبد المنعم');
    expect(episode.description, 'حلقة إيمانية مميزة عن الصلاة');
    expect(episode.audioUrl, 'https://example.com/audio.mp3');
    expect(episode.formattedDuration, '20 دقيقة');
    expect(episode.channelTitle, 'تربويات');

    final json = episode.toJson();
    expect(json['id'], 101);
    expect(json['audioUrl'], 'https://example.com/audio.mp3');
  });
}
