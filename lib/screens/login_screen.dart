import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home_screen.dart';

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
