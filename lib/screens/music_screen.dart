import 'dart:ui' as ui;

import 'package:audio_service/audio_service.dart' show MediaItem;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../services/musikin_api.dart';

// ---------------------------------------------------------------------------
// HALAMAN MUSIK — search lagu, riwayat "Baru diputar", playlist,
// mini player + full player sheet. Nyambung ke backend Musikin (Railway).
// ---------------------------------------------------------------------------
class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final AudioPlayer _player = AudioPlayer();

  // 0 = Cari, 1 = Baru diputar, 2 = Playlist
  int _tab = 0;

  List<Track> _searchResults = [];
  List<Track> _history = [];
  List<Playlist> _playlists = [];
  Playlist? _openPlaylist;

  bool _loading = false;
  String? _error;

  Track? _currentTrack;
  bool _sheetOpen = false;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  @override
  void dispose() {
    _player.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPlaylists() async {
    try {
      final playlists = await MusikinApi.getPlaylists();
      if (mounted) setState(() => _playlists = playlists);
    } catch (_) {
      // diem-diem aja, sidebar playlist cuma kosong kalau gagal
    }
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final history = await MusikinApi.getHistory();
      if (mounted) setState(() => _history = history);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _doSearch(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await MusikinApi.search(q.trim());
      if (mounted) setState(() => _searchResults = results);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _playTrack(Track track) async {
    setState(() => _currentTrack = track);
    try {
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(track.streamUrl),
          tag: MediaItem(
            // ID unik per lagu, dipakai audio_service buat notifikasinya
            id: track.id,
            title: track.title,
            artist: track.artist,
            artUri: track.thumbnail.isNotEmpty ? Uri.parse(track.thumbnail) : null,
          ),
        ),
      );
      await _player.play();
      // dikirim ke server, gak perlu ditunggu buat lanjut mutar
      MusikinApi.pushHistory(track).catchError((_) {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal muter lagu: $e')),
        );
      }
    }
  }

  Future<void> _createPlaylist() async {
    final name = await _promptText('Buat playlist', 'Nama playlist');
    if (name == null || name.trim().isEmpty) return;
    try {
      final playlist = await MusikinApi.createPlaylist(name.trim());
      await _loadPlaylists();
      setState(() {
        _openPlaylist = playlist;
        _tab = 2;
      });
    } catch (e) {
      _showError('$e');
    }
  }

  Future<void> _renamePlaylist(Playlist playlist) async {
    final name = await _promptText('Ubah nama playlist', 'Nama baru', initial: playlist.name);
    if (name == null || name.trim().isEmpty) return;
    try {
      final updated = await MusikinApi.renamePlaylist(playlist.id, name.trim());
      await _loadPlaylists();
      setState(() => _openPlaylist = updated);
    } catch (e) {
      _showError('$e');
    }
  }

  Future<void> _addToPlaylist(Track track) async {
    if (_playlists.isEmpty) {
      _showError('Belum ada playlist. Buat dulu ya.');
      return;
    }
    final chosen = await showModalBottomSheet<Playlist>(
      context: context,
      backgroundColor: const Color(0xFF23243A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _playlists
              .map(
                (p) => ListTile(
                  leading: const Icon(Icons.playlist_play_rounded, color: Colors.white70),
                  title: Text(p.name, style: const TextStyle(color: Colors.white)),
                  onTap: () => Navigator.pop(ctx, p),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (chosen == null) return;
    try {
      await MusikinApi.addTrackToPlaylist(chosen.id, track);
      await _loadPlaylists();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ditambahkan ke "${chosen.name}"')),
        );
      }
    } catch (e) {
      _showError('$e');
    }
  }

  Future<String?> _promptText(String title, String hint, {String initial = ''}) {
    final ctrl = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF23243A),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
              child: _GlassPanel(
                radius: 22,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  onSubmitted: _doSearch,
                  onChanged: (v) {
                    if (v.trim().isEmpty) setState(() => _searchResults = []);
                  },
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Cari lagu atau artis...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.playlist_add_rounded, color: Colors.white70),
                      tooltip: 'Buat playlist',
                      onPressed: _createPlaylist,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _GlassPanel(
                radius: 22,
                padding: const EdgeInsets.all(5),
                child: Row(
                  children: [
                    Expanded(
                      child: _TabButton(
                        label: 'Cari',
                        selected: _tab == 0,
                        onTap: () => setState(() => _tab = 0),
                      ),
                    ),
                    Expanded(
                      child: _TabButton(
                        label: 'Baru diputar',
                        selected: _tab == 1,
                        onTap: () {
                          setState(() => _tab = 1);
                          _loadHistory();
                        },
                      ),
                    ),
                    Expanded(
                      child: _TabButton(
                        label: 'Playlist',
                        selected: _tab == 2,
                        onTap: () => setState(() => _tab = 2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),

        // Mini player, nempel di bawah konten
        if (_currentTrack != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () => setState(() => _sheetOpen = true),
              child: _MiniPlayer(track: _currentTrack!, player: _player),
            ),
          ),

        if (_sheetOpen && _currentTrack != null)
          _FullPlayerSheet(
            track: _currentTrack!,
            player: _player,
            onClose: () => setState(() => _sheetOpen = false),
            onAddToPlaylist: () => _addToPlaylist(_currentTrack!),
          ),
      ],
    );
  }

  Widget _buildBody() {
    if (_tab == 0) return _buildTrackListBody(_searchResults, emptyText: 'Ketik buat cari lagu');
    if (_tab == 1) return _buildTrackListBody(_history, emptyText: 'Belum ada lagu diputar');
    return _buildPlaylistBody();
  }

  Widget _buildTrackListBody(List<Track> tracks, {required String emptyText}) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white70));
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: TextStyle(color: Colors.white.withOpacity(0.7))),
      );
    }
    if (tracks.isEmpty) {
      return Center(
        child: Text(emptyText, style: TextStyle(color: Colors.white.withOpacity(0.5))),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 90),
      itemCount: tracks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) => _TrackTile(
        track: tracks[i],
        onTap: () => _playTrack(tracks[i]),
        onAdd: () => _addToPlaylist(tracks[i]),
      ),
    );
  }

  Widget _buildPlaylistBody() {
    if (_openPlaylist != null) {
      final p = _playlists.firstWhere((x) => x.id == _openPlaylist!.id, orElse: () => _openPlaylist!);
      return Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => setState(() => _openPlaylist = null),
              ),
              Expanded(
                child: Text(
                  p.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: Colors.white70),
                onPressed: () => _renamePlaylist(p),
              ),
            ],
          ),
          Expanded(
            child: p.tracks.isEmpty
                ? Center(
                    child: Text('Belum ada lagu di playlist ini',
                        style: TextStyle(color: Colors.white.withOpacity(0.5))),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 90),
                    itemCount: p.tracks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (_, i) => _TrackTile(
                      track: p.tracks[i],
                      onTap: () => _playTrack(p.tracks[i]),
                    ),
                  ),
          ),
        ],
      );
    }

    if (_playlists.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.playlist_add_rounded, size: 48, color: Colors.white.withOpacity(0.35)),
            const SizedBox(height: 12),
            Text('Belum ada playlist', style: TextStyle(color: Colors.white.withOpacity(0.6))),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _createPlaylist,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Buat playlist', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 90),
      itemCount: _playlists.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final p = _playlists[i];
        return _GlassPanel(
          radius: 14,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.queue_music_rounded, color: Colors.white70),
            title: Text(p.name, style: const TextStyle(color: Colors.white)),
            subtitle: Text('${p.tracks.length} lagu',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
            onTap: () => setState(() => _openPlaylist = p),
          ),
        );
      },
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white.withOpacity(0.6),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _TrackTile extends StatelessWidget {
  const _TrackTile({required this.track, required this.onTap, this.onAdd});
  final Track track;
  final VoidCallback onTap;
  final VoidCallback? onAdd;

  String _fmtDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: track.thumbnail.isNotEmpty
                  ? Image.network(track.thumbnail, width: 46, height: 46, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _thumbFallback())
                  : _thumbFallback(),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5)),
                  Text(track.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12)),
                ],
              ),
            ),
            Text(_fmtDuration(track.duration),
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11.5)),
            if (onAdd != null)
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white70, size: 20),
                onPressed: onAdd,
              ),
          ],
        ),
      ),
    );
  }

  Widget _thumbFallback() => Container(
        width: 46,
        height: 46,
        color: Colors.white.withOpacity(0.08),
        child: const Icon(Icons.music_note_rounded, color: Colors.white54, size: 20),
      );
}

class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer({required this.track, required this.player});
  final Track track;
  final AudioPlayer player;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: track.thumbnail.isNotEmpty
                ? Image.network(track.thumbnail, width: 40, height: 40, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.music_note_rounded, color: Colors.white70))
                : const Icon(Icons.music_note_rounded, color: Colors.white70),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                Text(track.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 11)),
              ],
            ),
          ),
          StreamBuilder<PlayerState>(
            stream: player.playerStateStream,
            builder: (context, snapshot) {
              final playing = snapshot.data?.playing ?? false;
              return IconButton(
                icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white),
                onPressed: () => playing ? player.pause() : player.play(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FullPlayerSheet extends StatelessWidget {
  const _FullPlayerSheet({
    required this.track,
    required this.player,
    required this.onClose,
    required this.onAddToPlaylist,
  });

  final Track track;
  final AudioPlayer player;
  final VoidCallback onClose;
  final VoidCallback onAddToPlaylist;

  String _fmt(Duration? d) {
    if (d == null) return '0:00';
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: const Color(0xFF14152080),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 32),
                      onPressed: onClose,
                    ),
                  ),
                  const Spacer(),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: track.thumbnail.isNotEmpty
                        ? Image.network(track.thumbnail, width: 240, height: 240, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _artworkFallback())
                        : _artworkFallback(),
                  ),
                  const SizedBox(height: 24),
                  Text(track.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(track.artist,
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                  const SizedBox(height: 20),
                  StreamBuilder<Duration>(
                    stream: player.positionStream,
                    builder: (context, snapshot) {
                      final position = snapshot.data ?? Duration.zero;
                      final total = player.duration ?? Duration.zero;
                      final maxMs = total.inMilliseconds > 0 ? total.inMilliseconds.toDouble() : 1.0;
                      return Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: Colors.white,
                              inactiveTrackColor: Colors.white24,
                              thumbColor: Colors.white,
                            ),
                            child: Slider(
                              min: 0,
                              max: maxMs,
                              value: position.inMilliseconds.clamp(0, maxMs.toInt()).toDouble(),
                              onChanged: (v) => player.seek(Duration(milliseconds: v.toInt())),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_fmt(position), style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
                                Text(_fmt(total), style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<PlayerState>(
                    stream: player.playerStateStream,
                    builder: (context, snapshot) {
                      final playing = snapshot.data?.playing ?? false;
                      return Container(
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                        child: IconButton(
                          iconSize: 32,
                          icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.black),
                          onPressed: () => playing ? player.pause() : player.play(),
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: onAddToPlaylist,
                    icon: const Icon(Icons.playlist_add_rounded, color: Colors.white70),
                    label: const Text('Tambah ke playlist', style: TextStyle(color: Colors.white70)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _artworkFallback() => Container(
        width: 240,
        height: 240,
        color: Colors.white.withOpacity(0.08),
        child: const Icon(Icons.music_note_rounded, color: Colors.white54, size: 64),
      );
}

// Panel kaca buram, konsisten sama home_screen.dart
class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child, required this.radius, required this.padding});
  final Widget child;
  final double radius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.09),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: child,
        ),
      ),
    );
  }
}
