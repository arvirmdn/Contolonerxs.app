import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';
import 'music_screen.dart';

// ---------------------------------------------------------------------------
// HALAMAN HOME — layout ala Telegram (Obrolan/Room/Musik/Profil),
// tema glassmorphism senada halaman login
// ---------------------------------------------------------------------------
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color _primary = Color(0xFFC2410C);
  static const Color _accent = Color(0xFFEA580C);

  // 0 = Obrolan, 1 = Room, 2 = Musik, 3 = Profil (pengaturan digabung di sini)
  int _navIndex = 0;
  // 0 = Semua Obrolan, 1 = Arsip (cuma dipakai kalau _navIndex == 0)
  int _chatTab = 0;
  // 0 = Buat Room, 1 = Gabung Room (cuma dipakai kalau _navIndex == 1)
  int _roomTab = 0;

  bool _searchActive = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProfileUsername();
    _loadPrefs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient, senada splash & login
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF7C2D12), _primary, _accent],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),
          Positioned(top: -70, right: -60, child: _glowOrb(220, _accent.withOpacity(0.35))),
          Positioned(bottom: -90, left: -70, child: _glowOrb(240, _primary.withOpacity(0.35))),
          Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),

          SafeArea(
            child: Column(
              children: [
                // Top bar: nama app + search + menu
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                  child: _GlassPanel(
                    radius: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _searchActive
                              ? TextField(
                                  controller: _searchController,
                                  autofocus: true,
                                  style: const TextStyle(color: Colors.white, fontSize: 15),
                                  cursorColor: Colors.white,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    border: InputBorder.none,
                                    hintText: _navIndex == 1 ? 'Cari room...' : 'Cari obrolan...',
                                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.45)),
                                  ),
                                  onChanged: (v) => setState(() => _searchQuery = v),
                                )
                              : const Text(
                                  'Contolonerxs',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                        ),
                        Row(
                          children: [
                            if (_navIndex == 0 || _navIndex == 1)
                              IconButton(
                                icon: Icon(
                                  _searchActive ? Icons.close_rounded : Icons.search_rounded,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _searchActive = !_searchActive;
                                    if (!_searchActive) {
                                      _searchController.clear();
                                      _searchQuery = '';
                                    }
                                  });
                                },
                              ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                              color: const Color(0xFF2A231D),
                              onSelected: (value) async {
                                if (value == 'profil') {
                                  _setNavIndex(3);
                                } else if (value == 'keluar') {
                                  await _logout();
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'profil',
                                  child: Row(
                                    children: [
                                      Icon(Icons.person_rounded, color: Colors.white, size: 19),
                                      SizedBox(width: 10),
                                      Text('Profil & Pengaturan', style: TextStyle(color: Colors.white)),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'keluar',
                                  child: Row(
                                    children: [
                                      Icon(Icons.logout_rounded, color: Colors.redAccent, size: 19),
                                      SizedBox(width: 10),
                                      Text('Keluar', style: TextStyle(color: Colors.redAccent)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Tab pill: "Semua Obrolan"/"Arsip" di menu Obrolan,
                // "Buat Room"/"Gabung Room" di menu Room
                if (_navIndex == 0 || _navIndex == 1)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _GlassPanel(
                      radius: 22,
                      padding: const EdgeInsets.all(5),
                      child: _navIndex == 0
                          ? Row(
                              children: [
                                Expanded(
                                  child: _ChatTabButton(
                                    label: 'Semua Obrolan',
                                    badgeCount: 3,
                                    selected: _chatTab == 0,
                                    onTap: () => setState(() => _chatTab = 0),
                                  ),
                                ),
                                Expanded(
                                  child: _ChatTabButton(
                                    label: 'Arsip',
                                    selected: _chatTab == 1,
                                    onTap: () => setState(() => _chatTab = 1),
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: _ChatTabButton(
                                    label: 'Buat Room',
                                    selected: _roomTab == 0,
                                    onTap: () => setState(() => _roomTab = 0),
                                  ),
                                ),
                                Expanded(
                                  child: _ChatTabButton(
                                    label: 'Gabung Room',
                                    selected: _roomTab == 1,
                                    onTap: () => setState(() => _roomTab = 1),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                // Konten sesuai tab bawah yang aktif
                Expanded(child: _buildContent()),

                // Bottom nav: Obrolan / Room / Musik / Profil
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: _GlassPanel(
                    radius: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _NavItem(
                          icon: Icons.chat_bubble_rounded,
                          label: 'Obrolan',
                          badgeCount: 3,
                          selected: _navIndex == 0,
                          onTap: () => _setNavIndex(0),
                        ),
                        _NavItem(
                          icon: Icons.meeting_room_rounded,
                          label: 'Room',
                          selected: _navIndex == 1,
                          onTap: () => _setNavIndex(1),
                        ),
                        _NavItem(
                          icon: Icons.music_note_rounded,
                          label: 'Musik',
                          selected: _navIndex == 2,
                          onTap: () => _setNavIndex(2),
                        ),
                        _NavItem(
                          icon: Icons.person_rounded,
                          label: 'Profil',
                          selected: _navIndex == 3,
                          onTap: () => _setNavIndex(3),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_navIndex) {
      case 0:
        if (_searchActive && _searchQuery.trim().isNotEmpty) {
          return _EmptyState(
            key: const ValueKey('search-chat'),
            icon: Icons.search_off_rounded,
            title: 'Tidak ditemukan',
            subtitle: 'Gak ada obrolan yang cocok dengan "$_searchQuery"',
          );
        }
        return _EmptyState(
          key: ValueKey(_chatTab),
          icon: Icons.forum_rounded,
          title: _chatTab == 0 ? 'Belum ada obrolan' : 'Belum ada obrolan diarsipkan',
          subtitle: _chatTab == 0
              ? 'Obrolan kamu bakal muncul di sini'
              : 'Obrolan yang diarsipkan bakal muncul di sini',
        );
      case 1:
        if (_searchActive && _searchQuery.trim().isNotEmpty) {
          return _EmptyState(
            key: const ValueKey('search-room'),
            icon: Icons.search_off_rounded,
            title: 'Tidak ditemukan',
            subtitle: 'Gak ada room yang cocok dengan "$_searchQuery"',
          );
        }
        return _EmptyState(
          key: ValueKey(_roomTab),
          icon: _roomTab == 0 ? Icons.add_circle_outline_rounded : Icons.group_add_rounded,
          title: _roomTab == 0 ? 'Belum ada room dibuat' : 'Belum gabung room manapun',
          subtitle: _roomTab == 0
              ? 'Room yang kamu buat bakal muncul di sini'
              : 'Room yang kamu ikuti bakal muncul di sini',
        );
      case 2:
        return const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: MusicScreen(),
        );
      default:
        return _buildProfil();
    }
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool loading = false;
    String? error;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> submit() async {
              if (oldCtrl.text.isEmpty || newCtrl.text.isEmpty) {
                setDialogState(() => error = 'Semua kolom wajib diisi');
                return;
              }
              if (newCtrl.text.length < 4) {
                setDialogState(() => error = 'Sandi baru minimal 4 karakter');
                return;
              }
              if (newCtrl.text != confirmCtrl.text) {
                setDialogState(() => error = 'Ulangi sandi baru tidak cocok');
                return;
              }
              setDialogState(() {
                loading = true;
                error = null;
              });
              try {
                await AuthService.instance.changePassword(
                  oldPassword: oldCtrl.text,
                  newPassword: newCtrl.text,
                );
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sandi berhasil diubah')),
                );
              } on AuthApiException catch (e) {
                setDialogState(() {
                  loading = false;
                  error = e.message;
                });
              } catch (_) {
                setDialogState(() {
                  loading = false;
                  error = 'Terjadi kesalahan, coba lagi';
                });
              }
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF2A231D),
              title: const Text('Ubah Sandi', style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (error != null) ...[
                    Text(error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12.5)),
                    const SizedBox(height: 10),
                  ],
                  _passwordField(oldCtrl, 'Sandi lama'),
                  const SizedBox(height: 10),
                  _passwordField(newCtrl, 'Sandi baru'),
                  const SizedBox(height: 10),
                  _passwordField(confirmCtrl, 'Ulangi sandi baru'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: loading ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Batal', style: TextStyle(color: Colors.white70)),
                ),
                FilledButton(
                  onPressed: loading ? null : submit,
                  child: loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _passwordField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      obscureText: true,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Contolonerxs',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: _primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.lock_person_rounded, color: Colors.white, size: 30),
      ),
      children: const [
        SizedBox(height: 12),
        Text('Aman • Cepat • Terpercaya'),
      ],
    );
  }

  Widget _settingsTile(
    IconData icon,
    String label, {
    String? subtitle,
    bool danger = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: danger ? Colors.redAccent.shade100 : Colors.white),
      title: Text(
        label,
        style: TextStyle(
          color: danger ? Colors.redAccent.shade100 : Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12.5),
            ),
      trailing: danger
          ? null
          : const Icon(Icons.chevron_right_rounded, color: Colors.white54),
    );
  }

  Widget _switchTile(
    IconData icon,
    String label,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      onTap: () => onChanged(!value),
      leading: Icon(icon, color: Colors.white),
      title: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12.5),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.white,
        activeTrackColor: _accent,
        inactiveThumbColor: Colors.white70,
        inactiveTrackColor: Colors.white.withOpacity(0.15),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 20, 6, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withOpacity(0.55),
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _statTile(IconData icon, String value, String label) {
    return Expanded(
      child: _GlassPanel(
        radius: 18,
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.7), size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Divider(color: Colors.white.withOpacity(0.10), height: 1);

  String? _profileUsername;

  Future<void> _loadProfileUsername() async {
    final username = await AuthService.instance.currentUser();
    if (mounted) {
      setState(() => _profileUsername = username);
    }
  }

  // Preferensi lokal di halaman Profil (disimpan di SharedPreferences)
  static const String _prefNotifKey = 'contolonerxs_pref_notif';
  static const String _prefSoundKey = 'contolonerxs_pref_sound';
  bool _notifOn = true;
  bool _soundOn = true;

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notifOn = prefs.getBool(_prefNotifKey) ?? true;
      _soundOn = prefs.getBool(_prefSoundKey) ?? true;
    });
  }

  Future<void> _setPref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _logout() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _setNavIndex(int index) {
    setState(() {
      _navIndex = index;
      if (index != 0 && index != 1) {
        _searchActive = false;
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  Widget _buildProfil() {
    final String name = _profileUsername ?? '...';
    final String? initial = (_profileUsername != null && _profileUsername!.isNotEmpty)
        ? _profileUsername!.substring(0, 1).toUpperCase()
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        children: [
          // --- Kartu identitas: avatar (inisial) + nama + status ---
          _GlassPanel(
            radius: 24,
            padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [_accent, _primary],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _accent.withOpacity(0.4),
                                blurRadius: 22,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: initial == null
                              ? const Icon(Icons.person_rounded, color: Colors.white, size: 50)
                              : Text(
                                  initial,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 40,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Fitur ganti foto profil segera hadir')),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A231D),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.4),
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _showChangeUsernameDialog(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _profileChip(text: 'Akun Contolonerxs'),
                      _profileChip(text: 'Aktif', dotColor: const Color(0xFF4ADE80)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // --- Ringkasan cepat ---
          Row(
            children: [
              _statTile(Icons.chat_bubble_rounded, '0', 'Obrolan'),
              const SizedBox(width: 10),
              _statTile(Icons.meeting_room_rounded, '0', 'Room'),
              const SizedBox(width: 10),
              _statTile(Icons.verified_user_rounded, 'Aman', 'Status'),
            ],
          ),

          // --- Akun ---
          _sectionTitle('Akun'),
          _GlassPanel(
            radius: 20,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _settingsTile(
                  Icons.badge_rounded,
                  'Nama Akun',
                  subtitle: name,
                  onTap: () => _showChangeUsernameDialog(context),
                ),
                _divider(),
                _settingsTile(
                  Icons.lock_rounded,
                  'Privasi & Keamanan',
                  subtitle: 'Ganti kata sandi',
                  onTap: () => _showChangePasswordDialog(context),
                ),
              ],
            ),
          ),

          // --- Preferensi ---
          _sectionTitle('Preferensi'),
          _GlassPanel(
            radius: 20,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _switchTile(
                  Icons.notifications_rounded,
                  'Notifikasi',
                  'Pemberitahuan pesan & room',
                  _notifOn,
                  (v) {
                    setState(() => _notifOn = v);
                    _setPref(_prefNotifKey, v);
                  },
                ),
                _divider(),
                _switchTile(
                  Icons.volume_up_rounded,
                  'Suara',
                  'Nada saat ada notifikasi',
                  _soundOn,
                  (v) {
                    setState(() => _soundOn = v);
                    _setPref(_prefSoundKey, v);
                  },
                ),
              ],
            ),
          ),

          // --- Lainnya ---
          _sectionTitle('Lainnya'),
          _GlassPanel(
            radius: 20,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _settingsTile(
                  Icons.info_rounded,
                  'Tentang Aplikasi',
                  subtitle: 'Versi 1.0.0',
                  onTap: () => _showAboutDialog(context),
                ),
                _divider(),
                _settingsTile(
                  Icons.logout_rounded,
                  'Keluar',
                  danger: true,
                  onTap: _logout,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Aman • Cepat • Terpercaya',
            style: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileChip({required String text, Color? dotColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _showChangeUsernameDialog(BuildContext context) {
    final nameCtrl = TextEditingController(text: _profileUsername ?? '');
    bool loading = false;
    String? error;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> submit() async {
              final newName = nameCtrl.text.trim();
              if (newName.isEmpty) {
                setDialogState(() => error = 'Nama tidak boleh kosong');
                return;
              }
              setDialogState(() {
                loading = true;
                error = null;
              });
              try {
                final updated = await AuthService.instance.updateUsername(newName);
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                if (!mounted) return;
                setState(() => _profileUsername = updated);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nama akun berhasil diubah')),
                );
              } on AuthApiException catch (e) {
                setDialogState(() {
                  loading = false;
                  error = e.message;
                });
              } catch (_) {
                setDialogState(() {
                  loading = false;
                  error = 'Terjadi kesalahan, coba lagi';
                });
              }
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF2A231D),
              title: const Text('Ganti Nama Akun', style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (error != null) ...[
                    Text(error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12.5)),
                    const SizedBox(height: 10),
                  ],
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Nama baru',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: loading ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Batal', style: TextStyle(color: Colors.white70)),
                ),
                FilledButton(
                  onPressed: loading ? null : submit,
                  child: loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _glowOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
      ),
    );
  }
}

// Tombol tab "Semua Obrolan" / "Arsip"
class _ChatTabButton extends StatelessWidget {
  const _ChatTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? badgeCount;

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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white.withOpacity(0.6),
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13.5,
              ),
            ),
            if (badgeCount != null) ...[
              const SizedBox(width: 6),
              _Badge(count: badgeCount!),
            ],
          ],
        ),
      ),
    );
  }
}

// Item di bottom nav
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Colors.white.withOpacity(0.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    color: selected ? Colors.white : Colors.white.withOpacity(0.55),
                    size: 22,
                  ),
                  if (badgeCount != null)
                    Positioned(
                      right: -8,
                      top: -4,
                      child: _Badge(count: badgeCount!),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? Colors.white : Colors.white.withOpacity(0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFEA580C),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// Panel kaca buram (frosted glass) generik, dipakai di top bar, tab,
// bottom nav, dan konten — biar gayanya konsisten satu halaman
class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.child,
    required this.radius,
    required this.padding,
  });

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

// Tampilan kosong (belum ada obrolan/room)
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: Colors.white.withOpacity(0.35)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// Pola titik dekoratif tipis di background, senada halaman login
class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = Colors.white.withOpacity(0.05);
    const double spacing = 26;
    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
