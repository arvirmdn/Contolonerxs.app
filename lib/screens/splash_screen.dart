import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'login_screen.dart';

// ---------------------------------------------------------------------------
// SPLASH SCREEN — animasi pembuka sebelum masuk ke halaman login
// ---------------------------------------------------------------------------
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  static const String _appName = 'Contolonerxs';
  static const List<String> _statusSteps = [
    'Menyiapkan aplikasi...',
    'Memuat data...',
    'Hampir siap...',
  ];

  late final AnimationController _controller;
  // Logo "bernapas" pelan setelah animasi pop selesai
  late final AnimationController _breatheCtrl;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..forward();
    _breatheCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    // Setelah animasi selesai -> pindah ke halaman login dengan fade halus
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 700),
            pageBuilder: (_, __, ___) => const LoginPage(),
            transitionsBuilder: (_, animation, __, child) {
              final curved = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              );
              return FadeTransition(
                opacity: curved,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.97, end: 1.0)
                      .animate(curved),
                  child: child,
                ),
              );
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _breatheCtrl.dispose();
    super.dispose();
  }

  // Helper: nilai 0..1 untuk segmen waktu tertentu dari controller
  double _seg(double start, double end) {
    return ((_controller.value - start) / (end - start)).clamp(0.0, 1.0);
  }

  // Indeks teks status yang sedang aktif, berdasarkan progres controller
  int _statusIndex() {
    final double t = _seg(0.20, 0.95);
    final int idx = (t * _statusSteps.length).floor();
    return idx.clamp(0, _statusSteps.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        // PENTING: seluruh isi splash (logo, nama, progress) HARUS ada di
        // dalam `builder`, bukan di `child` — karena `child` di-cache dan
        // cuma di-build sekali oleh Flutter, sehingga animasinya jadi
        // "beku" (tidak pernah terlihat bergerak) walau controller jalan.
        animation: _controller,
        builder: (context, _) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(
                    const Color(0xFF4F46E5),
                    const Color(0xFF312E81),
                    _controller.value,
                  )!,
                  Color.lerp(
                    const Color(0xFF9333EA),
                    const Color(0xFF4C1D95),
                    _controller.value,
                  )!,
                ],
              ),
            ),
            child: Stack(
              children: [
                // Lingkaran dekoratif lembut
                Positioned(
                  top: -60,
                  right: -60,
                  child: _glowCircle(180, 0.10),
                ),
                Positioned(
                  bottom: -80,
                  left: -70,
                  child: _glowCircle(220, 0.08),
                ),
                SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLogo(),
                        const SizedBox(height: 28),
                        _buildName(),
                        const SizedBox(height: 12),
                        _buildTagline(),
                        const SizedBox(height: 48),
                        _buildProgress(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _glowCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }

  // Logo: muncul dengan efek memantul (elastic) + fade in + glow lembut,
  // lalu "bernapas" pelan dan dikelilingi ring loading yang muter terus
  Widget _buildLogo() {
    final double t = Curves.elasticOut.transform(_seg(0.0, 0.35));
    final double fade = _seg(0.0, 0.25);
    return Transform.scale(
      scale: 0.55 + 0.45 * t,
      child: Opacity(
        opacity: fade,
        // Dengarkan _breatheCtrl secara terpisah supaya napas logo
        // tetap jalan terus tanpa harus nunggu _controller utama tick
        child: AnimatedBuilder(
          animation: _breatheCtrl,
          builder: (context, child) {
            final double breathe =
                Curves.easeInOut.transform(_breatheCtrl.value);
            final double breatheScale =
                1.0 + 0.05 * breathe * _seg(0.35, 0.45);
            return Transform.scale(scale: breatheScale, child: child);
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.35 * fade),
                      Colors.white.withOpacity(0),
                    ],
                  ),
                ),
              ),
              // Ring loading tipis yang muter terus di sekeliling logo
              Opacity(
                opacity: _seg(0.1, 0.3),
                child: SizedBox(
                  width: 122,
                  height: 122,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withOpacity(0.85),
                    ),
                    backgroundColor: Colors.white.withOpacity(0.12),
                  ),
                ),
              ),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 32,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_person_rounded,
                  size: 48,
                  color: Color(0xFF4F46E5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Nama aplikasi: huruf muncul satu per satu dari bawah
  Widget _buildName() {
    final letters = _appName.split('');
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < letters.length; i++)
          _SplashLetter(
            letter: letters[i],
            index: i,
            count: letters.length,
            controller: _controller,
          ),
      ],
    );
  }

  Widget _buildTagline() {
    return Opacity(
      opacity: _seg(0.62, 0.82),
      child: Text(
        'AMAN  •  CEPAT  •  TERPERCAYA',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white70,
          letterSpacing: 4,
        ),
      ),
    );
  }

  Widget _buildProgress() {
    return Column(
      children: [
        Opacity(
          opacity: _seg(0.15, 0.25),
          child: Container(
            width: 180,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.centerLeft,
            child: Container(
              width: 180 * _seg(0.15, 0.95),
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildStatusText(),
      ],
    );
  }

  // Teks status loading yang berganti-ganti seiring progres splash,
  // dengan crossfade halus antar teks supaya nggak terasa kaku
  Widget _buildStatusText() {
    final int idx = _statusIndex();
    return Opacity(
      opacity: _seg(0.2, 0.35),
      child: SizedBox(
        height: 16,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: Text(
            _statusSteps[idx],
            key: ValueKey<int>(idx),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.7),
              letterSpacing: .3,
            ),
          ),
        ),
      ),
    );
  }
}

// Satu huruf animasi: naik dari bawah dengan sedikit bounce
class _SplashLetter extends StatelessWidget {
  const _SplashLetter({
    required this.letter,
    required this.index,
    required this.count,
    required this.controller,
  });

  final String letter;
  final int index;
  final int count;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final double start = 0.30 + (0.42 * index / count);
    final double end = start + 0.10;
    final double t =
        ((controller.value - start) / (end - start)).clamp(0.0, 1.0);
    final double curved = Curves.easeOutBack.transform(t);
    return Transform.translate(
      offset: Offset(0, 22 * (1 - curved)),
      child: Opacity(
        opacity: t,
        child: Text(
          letter,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
