import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const ContolonerxsApp());
}

class ContolonerxsApp extends StatelessWidget {
  const ContolonerxsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contolonerxs',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF4F46E5),
        scaffoldBackgroundColor: const Color(0xFF1A1B25),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      ),
      home: const SplashPage(),
    );
  }
}

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
        animation: _controller,
        builder: (context, child) {
          // Gradient yang makin gelap halus seiring animasi berjalan
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
            child: child,
          );
        },
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

// ---------------------------------------------------------------------------
// HALAMAN LOGIN — glassmorphism, glow neon, animasi gembok penuh
// ---------------------------------------------------------------------------

// Status animasi gembok pada halaman login
enum _LockState { idle, typing, wrong, success }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _showError = false;

  // Animasi gembok: idle | mengetik | salah | berhasil (terbuka)
  late final AnimationController _lockAnimCtrl;
  // Glow di belakang gembok yang "bernapas"
  late final AnimationController _pulseCtrl;
  // Background gradient yang bergeser perlahan
  late final AnimationController _bgCtrl;
  late final Listenable _lockAndPulse;
  _LockState _lockState = _LockState.idle;

  static const Color _primary = Color(0xFF4F46E5);
  static const Color _accent = Color(0xFF7C3AED);
  static const Color _success = Color(0xFF16A34A);

  // Kredensial khusus yang diizinkan masuk.
  static const String _allowedUsername = 'arvirmdn';
  static const String _allowedPassword = 'arvixnxx44';

  @override
  void initState() {
    super.initState();
    _lockAnimCtrl = AnimationController(vsync: this);
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    _lockAndPulse = Listenable.merge([_lockAnimCtrl, _pulseCtrl]);
  }

  @override
  void dispose() {
    _lockAnimCtrl.dispose();
    _pulseCtrl.dispose();
    _bgCtrl.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- Animasi gembok -------------------------------------------------------

  // Saat mengetik: gembok bergoyang halus (rotasi kecil + sedikit membesar)
  // dan banner error (jika ada) disembunyikan lagi
  void _onTyping() {
    if (_showError) setState(() => _showError = false);
    if (_lockState == _LockState.wrong || _lockState == _LockState.success) {
      return;
    }
    _lockState = _LockState.typing;
    _lockAnimCtrl
      ..duration = const Duration(milliseconds: 380)
      ..forward(from: 0).whenComplete(() {
        if (mounted && _lockState == _LockState.typing) {
          setState(() => _lockState = _LockState.idle);
        }
      });
  }

  // Saat kredensial salah: gembok bergetar kencang + menyala merah
  void _playWrong() {
    setState(() {
      _lockState = _LockState.wrong;
      _lockAnimCtrl.duration = const Duration(milliseconds: 600);
    });
    _lockAnimCtrl.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => _lockState = _LockState.idle);
    });
  }

  // Saat kredensial benar: gembok terbuka, membesar dengan pop elastis,
  // berubah hijau, lalu pindah ke halaman Home
  void _playSuccess() {
    setState(() {
      _lockState = _LockState.success;
      _lockAnimCtrl.duration = const Duration(milliseconds: 900);
    });
    _lockAnimCtrl.forward(from: 0).then((_) async {
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    });
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;
    setState(() => _isLoading = false);

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username == _allowedUsername && password == _allowedPassword) {
      // Gembok terbuka -> animasi sukses -> menuju Home
      _playSuccess();
    } else {
      // Banner error inline + gembok bergetar + merah
      setState(() => _showError = true);
      _playWrong();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Gradient yang bergeser perlahan
          _buildAnimatedBackground(),
          // 2. Pola titik dekoratif
          const Positioned.fill(
            child: CustomPaint(painter: _DotGridPainter()),
          ),
          // 3. Orb glow lembut
          Positioned(
            top: -80,
            right: -60,
            child: _orb(240, _accent.withOpacity(0.35)),
          ),
          Positioned(
            bottom: -100,
            left: -70,
            child: _orb(280, const Color(0xFF9333EA).withOpacity(0.30)),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  // Kartu login: fade + naik dari bawah saat halaman dibuka
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 34 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: _buildGlassCard(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Background: gradient 3 warna yang warna & arahnya bergeser pelan
  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _bgCtrl,
      builder: (context, child) {
        final double t = _bgCtrl.value;
        Color drift(Color a, Color b, double phase) {
          final double k = (math.sin(2 * math.pi * (t + phase)) + 1) / 2;
          return Color.lerp(a, b, k)!;
        }

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1 + 0.5 * math.sin(2 * math.pi * t), -1),
              end: Alignment(1, 1 + 0.35 * math.cos(2 * math.pi * t)),
              colors: [
                drift(const Color(0xFF1E1B4B), const Color(0xFF312E81), 0.0),
                drift(_primary, _accent, 0.33),
                drift(_accent, const Color(0xFF4C1D95), 0.66),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _orb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0)],
        ),
      ),
    );
  }

  // Kartu kaca: blur background, border tipis, shadow dalam
  Widget _buildGlassCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.09),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 44,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildLogoArea(),
                const SizedBox(height: 22),
                Text(
                  'Contolonerxs',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Masuk untuk melanjutkan',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.65),
                  ),
                ),
                const SizedBox(height: 24),
                _buildErrorBanner(),
                const SizedBox(height: 16),
                _buildUsernameField(),
                const SizedBox(height: 16),
                _buildPasswordField(),
                const SizedBox(height: 24),
                _buildLoginButton(),
                const SizedBox(height: 16),
                Text(
                  'AMAN  •  CEPAT  •  TERPERCAYA',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.4),
                    letterSpacing: 2.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Banner error inline (menggantikan SnackBar) — muncul dengan animasi halus
  Widget _buildErrorBanner() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: _showError
          ? Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 11,
              ),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.16),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.redAccent.withOpacity(0.45),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Username atau password salah. Coba lagi.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }

  // Area gembok: glow bernapas + cincin tipis + gembok animasi
  Widget _buildLogoArea() {
    return AnimatedBuilder(
      animation: _lockAndPulse,
      builder: (context, _) {
        final double t = _lockAnimCtrl.value;
        // 0..1 napas glow
        final double breath =
            (math.sin(_pulseCtrl.value * math.pi) + 1) / 2;

        Color colorA = _primary;
        Color colorB = _accent;
        Color glow = _accent;
        IconData icon = Icons.lock_person_rounded;
        Widget lock = _lockBox(colorA, colorB, glow, icon);

        if (_lockState == _LockState.typing) {
          // Goyangan kecil bergelombang yang memudar
          final double wobble =
              math.sin(t * math.pi * 2.5) * 0.14 * (1 - t);
          lock = Transform.rotate(
            angle: wobble,
            child: Transform.scale(
              scale: 1 + 0.08 * math.sin(t * math.pi),
              child: _lockBox(colorA, colorB, glow, icon),
            ),
          );
        } else if (_lockState == _LockState.wrong) {
          // Bergetar horizontal + menyala merah lalu kembali
          final double shake = math.sin(t * math.pi * 6) * 13 * (1 - t);
          final Color c = Color.lerp(
            Colors.redAccent,
            _primary,
            Curves.easeOut.transform(t),
          )!;
          colorA = c;
          colorB = c;
          glow = c;
          lock = Transform.translate(
            offset: Offset(shake, 0),
            child: _lockBox(colorA, colorB, glow, icon),
          );
        } else if (_lockState == _LockState.success) {
          // Terbuka, membesar dengan pop elastis, hijau
          final double pop = Curves.elasticOut.transform(t);
          colorA = Color.lerp(
            _success,
            _primary,
            Curves.easeOut.transform(t),
          )!;
          colorB = Color.lerp(
            const Color(0xFF4ADE80),
            _accent,
            Curves.easeOut.transform(t),
          )!;
          glow = _success;
          icon = Icons.lock_open_rounded;
          lock = Transform.scale(
            scale: 0.65 + 0.45 * pop,
            child: _lockBox(colorA, colorB, glow, icon),
          );
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            // Glow napas di belakang gembok
            Container(
              width: 130 + 16 * breath,
              height: 130 + 16 * breath,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    glow.withOpacity(0.28 + 0.20 * breath),
                    glow.withOpacity(0),
                  ],
                ),
              ),
            ),
            // Cincin tipis
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.14),
                ),
              ),
            ),
            lock,
          ],
        );
      },
    );
  }

  // Kotak gembok dengan gradient + glow neon sesuai status
  Widget _lockBox(Color colorA, Color colorB, Color glow, IconData icon) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colorA, colorB]),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          // Glow neon
          BoxShadow(
            color: glow.withOpacity(0.55),
            blurRadius: 30,
            spreadRadius: 1,
          ),
          // Shadow dasar
          BoxShadow(
            color: Colors.black.withOpacity(0.30),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 34),
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData prefix,
    Widget? suffix,
  }) {
    OutlineInputBorder border(Color color, {double width = 1.2}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    final Color idle = Colors.white.withOpacity(0.12);
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.plusJakartaSans(
        color: Colors.white.withOpacity(0.6),
        fontSize: 13.5,
      ),
      prefixIcon: Icon(
        prefix,
        color: Colors.white.withOpacity(0.75),
        size: 20,
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white.withOpacity(0.07),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      border: border(idle),
      enabledBorder: border(idle),
      focusedBorder: border(const Color(0xFFA78BFA), width: 1.6),
      errorBorder: border(Colors.redAccent),
      focusedErrorBorder: border(Colors.redAccent, width: 1.6),
      errorStyle: GoogleFonts.plusJakartaSans(
        color: Colors.redAccent,
        fontSize: 12,
      ),
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      onChanged: (_) => _onTyping(),
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: Colors.white,
      ),
      cursorColor: const Color(0xFFA78BFA),
      decoration: _fieldDecoration(
        label: 'Username',
        prefix: Icons.person_outline,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Username tidak boleh kosong';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      onChanged: (_) => _onTyping(),
      obscureText: _obscurePassword,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: Colors.white,
      ),
      cursorColor: const Color(0xFFA78BFA),
      decoration: _fieldDecoration(
        label: 'Password',
        prefix: Icons.lock_outline,
        suffix: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: Colors.white.withOpacity(0.65),
            size: 20,
          ),
          onPressed: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Password tidak boleh kosong';
        }
        if (value.length < 4) {
          return 'Password minimal 4 karakter';
        }
        return null;
      },
    );
  }

  Widget _buildLoginButton() {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6D64F0), _accent],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(0.55),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: _isLoading ? null : _handleLogin,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Masuk',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// Pola titik dekoratif di background halaman login
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

// ---------------------------------------------------------------------------
// HALAMAN HOME
// ---------------------------------------------------------------------------
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
            stops: [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Contolonerxs',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      tooltip: 'Keluar',
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const LoginPage(),
                          ),
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF4F46E5).withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Color(0xFF4F46E5),
                              size: 44,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Login Berhasil!',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1B25),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Berhasil masuk sebagai arvirmdn',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
