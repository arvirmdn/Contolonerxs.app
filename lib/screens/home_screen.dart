import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'login_screen.dart';

// ---------------------------------------------------------------------------
// HALAMAN HOME — layout ala Telegram (Obrolan/Room/Pengaturan/Profil),
// tema glassmorphism senada halaman login
// ---------------------------------------------------------------------------
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color _primary = Color(0xFF4F46E5);
  static const Color _accent = Color(0xFF7C3AED);

  // 0 = Obrolan, 1 = Room, 2 = Pengaturan, 3 = Profil
  int _navIndex = 0;
  // 0 = Semua Obrolan, 1 = Arsip (cuma dipakai kalau _navIndex == 0)
  int _chatTab = 0;
  // 0 = Buat Room, 1 = Gabung Room (cuma dipakai kalau _navIndex == 1)
  int _roomTab = 0;

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
                colors: [Color(0xFF312E81), _primary, _accent],
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
                        const Text(
                          'Contolonerxs',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.search_rounded, color: Colors.white),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                              onPressed: () {},
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

                // Bottom nav: Obrolan / Room / Pengaturan / Profil
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
                          onTap: () => setState(() => _navIndex = 0),
                        ),
                        _NavItem(
                          icon: Icons.meeting_room_rounded,
                          label: 'Room',
                          selected: _navIndex == 1,
                          onTap: () => setState(() => _navIndex = 1),
                        ),
                        _NavItem(
                          icon: Icons.settings_rounded,
                          label: 'Pengaturan',
                          selected: _navIndex == 2,
                          onTap: () => setState(() => _navIndex = 2),
                        ),
                        _NavItem(
                          icon: Icons.person_rounded,
                          label: 'Profil',
                          selected: _navIndex == 3,
                          onTap: () => setState(() => _navIndex = 3),
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
        return _EmptyState(
          key: ValueKey(_chatTab),
          icon: Icons.forum_rounded,
          title: _chatTab == 0 ? 'Belum ada obrolan' : 'Belum ada obrolan diarsipkan',
          subtitle: _chatTab == 0
              ? 'Obrolan kamu bakal muncul di sini'
              : 'Obrolan yang diarsipkan bakal muncul di sini',
        );
      case 1:
        return _EmptyState(
          key: ValueKey(_roomTab),
          icon: _roomTab == 0 ? Icons.add_circle_outline_rounded : Icons.group_add_rounded,
          title: _roomTab == 0 ? 'Belum ada room dibuat' : 'Belum gabung room manapun',
          subtitle: _roomTab == 0
              ? 'Room yang kamu buat bakal muncul di sini'
              : 'Room yang kamu ikuti bakal muncul di sini',
        );
      case 2:
        return _buildPengaturan();
      default:
        return _buildProfil();
    }
  }

  Widget _buildPengaturan() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: _GlassPanel(
        radius: 20,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _settingsTile(Icons.notifications_rounded, 'Notifikasi'),
            _divider(),
            _settingsTile(Icons.lock_rounded, 'Privasi & Keamanan'),
            _divider(),
            _settingsTile(Icons.palette_rounded, 'Tampilan'),
            _divider(),
            _settingsTile(
              Icons.logout_rounded,
              'Keluar',
              danger: true,
              onTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsTile(IconData icon, String label, {bool danger = false, VoidCallback? onTap}) {
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
      trailing: danger
          ? null
          : const Icon(Icons.chevron_right_rounded, color: Colors.white54),
    );
  }

  Widget _divider() => Divider(color: Colors.white.withOpacity(0.10), height: 1);

  Widget _buildProfil() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: _GlassPanel(
        radius: 24,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.12),
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.4),
              ),
              child: const Icon(Icons.person_rounded, color: Colors.white, size: 44),
            ),
            const SizedBox(height: 18),
            const Text(
              'arvirmdn',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Akun Contolonerxs',
              style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 14),
            ),
          ],
        ),
      ),
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
        color: const Color(0xFF7C3AED),
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
