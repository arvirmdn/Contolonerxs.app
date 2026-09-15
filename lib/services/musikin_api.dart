import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/musikin_config.dart';

class Track {
  Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.thumbnail,
    required this.duration,
  });

  final String id;
  final String title;
  final String artist;
  final String thumbnail;
  final int duration;

  factory Track.fromJson(Map<String, dynamic> json) => Track(
        id: json['id'] as String,
        title: (json['title'] as String?) ?? 'Tanpa judul',
        artist: (json['artist'] as String?) ?? '',
        thumbnail: (json['thumbnail'] as String?) ?? '',
        duration: (json['duration'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'thumbnail': thumbnail,
        'duration': duration,
      };

  String get streamUrl => '${MusikinConfig.baseUrl}/api/stream/$id';
}

class Playlist {
  Playlist({required this.id, required this.name, required this.tracks});

  final String id;
  final String name;
  final List<Track> tracks;

  factory Playlist.fromJson(Map<String, dynamic> json) => Playlist(
        id: json['id'] as String,
        name: (json['name'] as String?) ?? '',
        tracks: ((json['tracks'] as List?) ?? [])
            .map((t) => Track.fromJson(t as Map<String, dynamic>))
            .toList(),
      );
}

// Exception khusus biar UI bisa nampilin pesan yang jelas ke user
class MusikinApiException implements Exception {
  MusikinApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class MusikinApi {
  static final Uri _base = Uri.parse(MusikinConfig.baseUrl);

  static Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on http.ClientException {
      throw MusikinApiException('Gagal konek ke server musik. Cek koneksi internet kamu.');
    } catch (e) {
      if (e is MusikinApiException) rethrow;
      throw MusikinApiException('Terjadi kesalahan: $e');
    }
  }

  static Future<List<Track>> search(String query, {int limit = 20}) {
    return _guard(() async {
      final uri = _base.replace(
        path: '/api/search',
        queryParameters: {'q': query, 'limit': '$limit'},
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) {
        throw MusikinApiException('Gagal mencari lagu (${res.statusCode}).');
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return ((data['results'] as List?) ?? [])
          .map((t) => Track.fromJson(t as Map<String, dynamic>))
          .toList();
    });
  }

  static Future<List<Track>> getHistory() {
    return _guard(() async {
      final uri = _base.replace(path: '/api/history');
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        throw MusikinApiException('Gagal ambil riwayat (${res.statusCode}).');
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return ((data['history'] as List?) ?? [])
          .map((t) => Track.fromJson(t as Map<String, dynamic>))
          .toList();
    });
  }

  static Future<void> pushHistory(Track track) {
    return _guard(() async {
      final uri = _base.replace(path: '/api/history');
      await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(track.toJson()))
          .timeout(const Duration(seconds: 15));
    });
  }

  static Future<void> clearHistory() {
    return _guard(() async {
      final uri = _base.replace(path: '/api/history');
      await http.delete(uri).timeout(const Duration(seconds: 15));
    });
  }

  static Future<List<Playlist>> getPlaylists() {
    return _guard(() async {
      final uri = _base.replace(path: '/api/playlists');
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        throw MusikinApiException('Gagal ambil playlist (${res.statusCode}).');
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return ((data['playlists'] as List?) ?? [])
          .map((p) => Playlist.fromJson(p as Map<String, dynamic>))
          .toList();
    });
  }

  static Future<Playlist> createPlaylist(String name) {
    return _guard(() async {
      final uri = _base.replace(path: '/api/playlists');
      final res = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'name': name}))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        throw MusikinApiException('Gagal buat playlist (${res.statusCode}).');
      }
      return Playlist.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    });
  }

  static Future<Playlist> renamePlaylist(String id, String name) {
    return _guard(() async {
      final uri = _base.replace(path: '/api/playlists/$id');
      final res = await http
          .put(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'name': name}))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        throw MusikinApiException('Gagal ubah nama playlist (${res.statusCode}).');
      }
      return Playlist.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    });
  }

  static Future<void> deletePlaylist(String id) {
    return _guard(() async {
      final uri = _base.replace(path: '/api/playlists/$id');
      await http.delete(uri).timeout(const Duration(seconds: 15));
    });
  }

  static Future<Playlist> addTrackToPlaylist(String playlistId, Track track) {
    return _guard(() async {
      final uri = _base.replace(path: '/api/playlists/$playlistId/tracks');
      final res = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'track': track.toJson()}))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        throw MusikinApiException('Gagal tambah lagu ke playlist (${res.statusCode}).');
      }
      return Playlist.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    });
  }

  static Future<void> removeTrackFromPlaylist(String playlistId, String trackId) {
    return _guard(() async {
      final uri = _base.replace(path: '/api/playlists/$playlistId/tracks/$trackId');
      await http.delete(uri).timeout(const Duration(seconds: 15));
    });
  }
}
