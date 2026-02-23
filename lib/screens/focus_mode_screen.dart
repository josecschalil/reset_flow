import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:reset_flow/models/focus_session.dart';
import 'package:reset_flow/providers/focus_provider.dart';

// ─── Ambient background star data ────────────────────────────────
class _AmbientStar {
  final double x, y, radius, phase, speed;
  const _AmbientStar(this.x, this.y, this.radius, this.phase, this.speed);
}

// ─────────────────────────────────────────────────────────────────
//  Main Screen
// ─────────────────────────────────────────────────────────────────
class FocusModeScreen extends ConsumerStatefulWidget {
  final String? taskName;
  const FocusModeScreen({super.key, this.taskName});

  @override
  ConsumerState<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends ConsumerState<FocusModeScreen>
    with TickerProviderStateMixin {

  static const platform = MethodChannel('com.resetflow/app_lock');

  int _selectedMinutes = 25;
  int _secondsRemaining = 25 * 60;
  bool _isActive = false;
  Timer? _ticker;
  DateTime? _sessionStartTime;

  DateTime _viewingMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _viewingAllTime = false;

  late AnimationController _skyAnim;   // ambient star twinkle
  late AnimationController _timerAnim; // ring progress

  late List<_AmbientStar> _ambientStars;

  @override
  void initState() {
    super.initState();
    _skyAnim = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
    _timerAnim = AnimationController(vsync: this, duration: Duration(minutes: _selectedMinutes))
      ..addListener(() => setState(() {}));

    final rnd = math.Random(99991);
    _ambientStars = List.generate(80, (_) => _AmbientStar(
      rnd.nextDouble(),
      rnd.nextDouble() * 0.75,
      0.5 + rnd.nextDouble() * 1.6,
      rnd.nextDouble() * math.pi * 2,
      0.4 + rnd.nextDouble() * 1.5,
    ));
  }

  @override
  void dispose() {
    _skyAnim.dispose();
    _timerAnim.dispose();
    _ticker?.cancel();
    _stopLockTask();
    super.dispose();
  }

  Future<void> _startLockTask() async {
    try { await platform.invokeMethod('startLockTask'); } catch (_) {}
  }
  Future<void> _stopLockTask() async {
    try { await platform.invokeMethod('stopLockTask'); } catch (_) {}
  }

  void _startTimer() async {
    HapticFeedback.mediumImpact();
    _timerAnim.duration = Duration(minutes: _selectedMinutes);
    _timerAnim.forward(from: 0);
    setState(() {
      _isActive = true;
      _sessionStartTime = DateTime.now();
      _secondsRemaining = _selectedMinutes * 60;
    });
    await _startLockTask();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _onComplete();
      }
    });
  }

  void _onComplete() async {
    _ticker?.cancel();
    _timerAnim.stop();
    await _stopLockTask();
    HapticFeedback.heavyImpact();

    int rating = _selectedMinutes < 25 ? 1 : _selectedMinutes < 45 ? 2 : 3;
    await ref.read(focusProvider.notifier).addSession(FocusSession(
      startTime: _sessionStartTime ?? DateTime.now(),
      durationMinutes: _selectedMinutes,
      status: 'completed',
      rating: rating,
    ));
    setState(() { _isActive = false; _secondsRemaining = _selectedMinutes * 60; });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✦ A new star earned!')),
      );
    }
  }

  void _giveUp() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF12162B),
        title: const Text('Give Up?', style: TextStyle(color: Colors.white, fontSize: 18)),
        content: const Text('This will add a faded star to your sky.',
            style: TextStyle(color: Colors.white54)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Keep Focusing')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              _ticker?.cancel();
              _timerAnim.stop();
              await _stopLockTask();
              await ref.read(focusProvider.notifier).addSession(FocusSession(
                startTime: _sessionStartTime ?? DateTime.now(),
                durationMinutes: _selectedMinutes - (_secondsRemaining ~/ 60),
                status: 'failed', rating: 0,
              ));
              setState(() { _isActive = false; _secondsRemaining = _selectedMinutes * 60; });
            },
            child: const Text('Give Up', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _injectDemoData() async {
    final rnd = math.Random();
    final now = DateTime.now();
    for (int i = 0; i < 18; i++) {
      int off = rnd.nextInt(now.day > 0 ? now.day : 1);
      final date = now.subtract(Duration(days: off, hours: rnd.nextInt(12)));
      bool fail = rnd.nextDouble() < 0.2;
      int dur = fail ? 10 : [15, 30, 60][rnd.nextInt(3)];
      int rating = fail ? 0 : dur == 15 ? 1 : dur == 30 ? 2 : 3;
      await ref.read(focusProvider.notifier).addSession(FocusSession(
        startTime: date, durationMinutes: dur,
        status: fail ? 'failed' : 'completed', rating: rating,
      ));
    }
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demo generated!')));
  }

  void _showResetMenu() {
    final notifier = ref.read(focusProvider.notifier);
    final now = DateTime.now();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF12162B),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 3, margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          Text(
            _viewingAllTime ? 'Reset Options' : 'Reset — ${DateFormat('MMMM yyyy').format(_viewingMonth)}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (!_viewingAllTime) ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_month_outlined, color: Colors.orange, size: 20),
            title: const Text('Clear This Month', style: TextStyle(color: Colors.orange, fontSize: 14)),
            onTap: () async {
              Navigator.pop(ctx);
              await notifier.deleteSessionsByMonth(_viewingMonth.year, _viewingMonth.month);
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Month cleared.')));
            },
          ),
          if (!_viewingAllTime) ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.today_outlined, color: Colors.blueAccent, size: 20),
            title: const Text('Clear a Specific Day', style: TextStyle(color: Colors.blueAccent, fontSize: 14)),
            onTap: () async {
              Navigator.pop(ctx);
              final d = await showDatePicker(
                context: context, initialDate: now,
                firstDate: DateTime(2024), lastDate: now,
                builder: (c, child) => Theme(data: ThemeData.dark(), child: child!),
              );
              if (d != null) {
                final s = DateFormat('yyyy-MM-dd').format(d);
                await notifier.deleteSessionsByDay(s);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$s cleared.')));
              }
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 20),
            title: const Text('Clear Everything', style: TextStyle(color: Colors.redAccent, fontSize: 14)),
            onTap: () async {
              Navigator.pop(ctx);
              final ok = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  backgroundColor: const Color(0xFF12162B),
                  title: const Text('Clear all stars?', style: TextStyle(color: Colors.white, fontSize: 16)),
                  content: const Text('Erases your entire star history.', style: TextStyle(color: Colors.white54, fontSize: 13)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(c, true),
                        child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
                  ],
                ),
              );
              if (ok == true) {
                await notifier.clearAllSessions();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All cleared.')));
              }
            },
          ),
        ]),
      ),
    );
  }

  String get _timerString {
    final m = _secondsRemaining ~/ 60;
    final s = _secondsRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final focusState = ref.watch(focusProvider);
    final screenSize = MediaQuery.of(context).size;
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final now = DateTime.now();

    final visibleSessions = _viewingAllTime
        ? focusState.sessions
        : focusState.sessions.where((s) =>
    s.startTime.year == _viewingMonth.year &&
        s.startTime.month == _viewingMonth.month).toList();

    final bright = visibleSessions.where((s) => s.status == 'completed').length;
    final dead = visibleSessions.where((s) => s.status == 'failed').length;
    final mins = visibleSessions.where((s) => s.status == 'completed')
        .fold(0, (a, s) => a + s.durationMinutes);

    final canGoFwd = !_viewingAllTime &&
        (_viewingMonth.year < now.year ||
            (_viewingMonth.year == now.year && _viewingMonth.month < now.month));

    return PopScope(
      canPop: !_isActive,
      child: Scaffold(
        backgroundColor: const Color(0xFF060914),
        body: Stack(children: [

          // ── 1) Sky background (ambient + scene) ──────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _skyAnim,
              builder: (_, __) => RepaintBoundary(
                child: CustomPaint(
                  size: screenSize,
                  painter: _BackgroundPainter(
                    t: _skyAnim.value,
                    ambientStars: _ambientStars,
                    canvasSize: screenSize,
                  ),
                ),
              ),
            ),
          ),

          // ── 2) Idle view ──────────────────────────────────────────
          if (!_isActive)
            Positioned.fill(
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Month header row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.chevron_left_rounded, color: Colors.white54),
                          onPressed: () => setState(() {
                            _viewingAllTime = false;
                            _viewingMonth = DateTime(_viewingMonth.year, _viewingMonth.month - 1);
                          }),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _viewingAllTime = !_viewingAllTime;
                              if (!_viewingAllTime) _viewingMonth = DateTime(now.year, now.month);
                            }),
                            child: Column(children: [
                              Text(
                                _viewingAllTime ? 'ALL TIME' : DateFormat('MMMM yyyy').format(_viewingMonth).toUpperCase(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700,
                                    fontSize: 12, letterSpacing: 1.5),
                              ),
                              Text(
                                _viewingAllTime ? 'tap for this month' : 'tap for all time',
                                style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 10),
                              ),
                            ]),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(Icons.chevron_right_rounded,
                              color: canGoFwd ? Colors.white54 : Colors.transparent),
                          onPressed: canGoFwd ? () => setState(() =>
                              _viewingMonth = DateTime(_viewingMonth.year, _viewingMonth.month + 1)) : null,
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(Icons.tune_rounded, color: Colors.white.withOpacity(0.35), size: 20),
                          onPressed: _showResetMenu,
                        ),
                      ]),
                    ),

                    // ── Stats row
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        _statItem('$bright', 'earned'),
                        _vDivider(),
                        _statItem('$dead', 'faded'),
                        _vDivider(),
                        _statItem('${(mins / 60.0).toStringAsFixed(1)}h', 'focused'),
                      ]),
                    ),

                    // ── Star grid (scrollable, fills available space)
                    Expanded(
                      child: visibleSessions.isEmpty
                          ? Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.nights_stay_outlined, color: Colors.white.withOpacity(0.15), size: 40),
                          const SizedBox(height: 12),
                          Text('Complete a session to earn your first star',
                              style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 13),
                              textAlign: TextAlign.center),
                        ]),
                      )
                          : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: AnimatedBuilder(
                          animation: _skyAnim,
                          builder: (_, __) => _StarGrid(
                            sessions: visibleSessions,
                            t: _skyAnim.value,
                          ),
                        ),
                      ),
                    ),

                    // ── Duration wheel + Start button
                    Padding(
                      padding: EdgeInsets.only(bottom: bottomPad + 20),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        SizedBox(
                          height: 80,
                          child: ListWheelScrollView.useDelegate(
                            itemExtent: 40,
                            diameterRatio: 1.4,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (i) => setState(() {
                              _selectedMinutes = (i + 1) * 5;
                              _secondsRemaining = _selectedMinutes * 60;
                            }),
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: 24,
                              builder: (_, i) {
                                final m = (i + 1) * 5;
                                final sel = m == _selectedMinutes;
                                return Center(child: Text('$m min', style: TextStyle(
                                  fontWeight: sel ? FontWeight.w700 : FontWeight.w300,
                                  fontSize: sel ? 24 : 16,
                                  color: sel ? Colors.white : Colors.white24,
                                )));
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: _startTimer,
                          child: Container(
                            width: 170,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [BoxShadow(
                                  color: Colors.white.withOpacity(0.2), blurRadius: 16, spreadRadius: 1)],
                            ),
                            alignment: Alignment.center,
                            child: const Text('ENGAGE FOCUS', style: TextStyle(
                              color: Colors.black, fontWeight: FontWeight.w800,
                              fontSize: 12, letterSpacing: 1.5,
                            )),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _injectDemoData,
                          icon: Icon(Icons.auto_awesome, size: 12, color: Colors.white.withOpacity(0.2)),
                          label: Text('Generate Demo',
                              style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 11)),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
            ),

          // ── 3) Active timer overlay ────────────────────────────
          if (_isActive)
            Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (widget.taskName != null) ...[
                Text('FOCUSING ON', style: TextStyle(
                    color: Colors.white.withOpacity(0.4), fontSize: 10, letterSpacing: 2)),
                const SizedBox(height: 4),
                Text(widget.taskName!.toUpperCase(), style: const TextStyle(
                    color: Colors.white, fontSize: 14, letterSpacing: 1.2)),
                const SizedBox(height: 24),
              ] else ...[
                Text('FORMING YOUR STAR', style: TextStyle(
                    color: Colors.white.withOpacity(0.35), fontSize: 11, letterSpacing: 2)),
                const SizedBox(height: 24),
              ],
              SizedBox(
                width: 220,
                height: 220,
                child: Stack(alignment: Alignment.center, children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: 1 - _secondsRemaining / (_selectedMinutes * 60),
                      strokeWidth: 2,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Text(_timerString, style: const TextStyle(
                    color: Colors.white, fontSize: 52,
                    fontWeight: FontWeight.w200,
                    fontFeatures: [FontFeature.tabularFigures()],
                  )),
                ]),
              ),
              const SizedBox(height: 40),
              TextButton(
                onPressed: _giveUp,
                child: Text('Give Up', style: TextStyle(
                    color: Colors.white.withOpacity(0.3), fontSize: 14)),
              ),
            ])),
        ]),
      ),
    );
  }

  Widget _statItem(String value, String label) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: Column(children: [
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 10)),
    ]),
  );

  Widget _vDivider() => Container(width: 1, height: 22, color: Colors.white12);
}

// ─────────────────────────────────────────────────────────────────
//  Star Grid — wraps session stars in rows, each is a 5-point star
// ─────────────────────────────────────────────────────────────────
class _StarGrid extends StatelessWidget {
  final List<FocusSession> sessions;
  final double t; // 0..1 from AnimationController

  const _StarGrid({required this.sessions, required this.t});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Wrap(
        spacing: 14,
        runSpacing: 14,
        alignment: WrapAlignment.center,
        children: sessions.asMap().entries.map((e) {
          final i = e.key;
          final s = e.value;
          return SizedBox(
            width: 36,
            height: 36,
            child: CustomPaint(
              painter: _StarPainter(
                t: t,
                phase: (i * 0.37) % 1.0,  // stagger each star's flicker
                completed: s.status == 'completed',
                rating: s.rating,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Single Star Painter — draws a 5-pointed star shape with glow
// ─────────────────────────────────────────────────────────────────
class _StarPainter extends CustomPainter {
  final double t;      // global animation time 0..1
  final double phase;  // per-star phase offset
  final bool completed;
  final int rating;

  const _StarPainter({
    required this.t,
    required this.phase,
    required this.completed,
    required this.rating,
  });

  // Build a 5-pointed star Path centred at (cx, cy)
  static Path _starPath(double cx, double cy, double outerR, double innerR) {
    final path = Path();
    const points = 5;
    const step = math.pi * 2 / points;
    const halfStep = step / 2;
    const startAngle = -math.pi / 2; // point up

    for (int i = 0; i < points; i++) {
      final outerX = cx + outerR * math.cos(startAngle + step * i);
      final outerY = cy + outerR * math.sin(startAngle + step * i);
      final innerX = cx + innerR * math.cos(startAngle + halfStep + step * i);
      final innerY = cy + innerR * math.sin(startAngle + halfStep + step * i);

      if (i == 0) {
        path.moveTo(outerX, outerY);
      } else {
        path.lineTo(outerX, outerY);
      }
      path.lineTo(innerX, innerY);
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const tau = math.pi * 2;

    if (completed) {
      // Organic flicker: two sine waves combined
      final f1 = 0.5 + 0.5 * math.sin(t * tau * 0.8 + phase * tau);
      final f2 = 0.5 + 0.5 * math.sin(t * tau * 1.3 + phase * tau * 1.7);
      final flicker = 0.55 + 0.45 * (0.6 * f1 + 0.4 * f2);

      // Star size scales slightly with rating (1,2,3)
      final outerR = 13.0 + rating * 1.5;
      final innerR = outerR * 0.42;

      final starPath = _starPath(cx, cy, outerR, innerR);

      // Glow halo
      canvas.drawPath(starPath, Paint()
        ..color = Colors.white.withOpacity(0.08 * flicker)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * flicker));

      // Mid glow
      canvas.drawPath(
        _starPath(cx, cy, outerR * 1.2, innerR * 1.2),
        Paint()..color = Colors.white.withOpacity(0.12 * flicker),
      );

      // Main star body
      canvas.drawPath(starPath, Paint()
        ..color = Colors.white.withOpacity(0.7 + 0.3 * flicker));

      // Bright core highlight
      canvas.drawPath(
        _starPath(cx, cy, outerR * 0.45, innerR * 0.45),
        Paint()..color = Colors.white,
      );
    } else {
      // Dead / faded star — same shape but dim red-grey, no flicker, partially transparent
      final outerR = 11.0;
      final innerR = outerR * 0.42;
      final starPath = _starPath(cx, cy, outerR, innerR);

      // Soft red glow
      canvas.drawPath(starPath, Paint()
        ..color = const Color(0xFFFF4444).withOpacity(0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));

      // Faded red star outline
      canvas.drawPath(starPath, Paint()
        ..color = const Color(0xFFFF6666).withOpacity(0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2);

      // Very dim fill
      canvas.drawPath(starPath, Paint()
        ..color = const Color(0xFF882222).withOpacity(0.18));
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter old) =>
      old.t != t || old.completed != completed;
}

// ─────────────────────────────────────────────────────────────────
//  Background Painter — sky gradient + boy + telescope + ambient stars
// ─────────────────────────────────────────────────────────────────
class _BackgroundPainter extends CustomPainter {
  final double t;
  final List<_AmbientStar> ambientStars;
  final Size canvasSize;

  const _BackgroundPainter({
    required this.t,
    required this.ambientStars,
    required this.canvasSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Sky gradient
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF040610),
          Color(0xFF0A0F22),
          Color(0xFF12193A),
          Color(0xFF1A2550),
        ],
        stops: [0.0, 0.35, 0.65, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Subtle Milky Way smear
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h * 0.7),
      Paint()..shader = RadialGradient(
        center: const Alignment(0.1, -0.2),
        radius: 1.1,
        colors: [Colors.indigo.withOpacity(0.06), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.7)),
    );

    // Ambient twinkling background stars
    const tau = math.pi * 2;
    const tints = [
      Color(0xFFC8D8FF),
      Color(0xFFFFEECC),
      Color(0xFFFFFFFF),
      Color(0xFFDDE8FF),
      Color(0xFFFFF5E0),
    ];
    final starPaint = Paint()..style = PaintingStyle.fill;
    final spikePaint = Paint()..style = PaintingStyle.stroke;

    for (int idx = 0; idx < ambientStars.length; idx++) {
      final s = ambientStars[idx];
      final cx = s.x * w;
      final cy = s.y * h;

      final tw1 = 0.5 + 0.5 * math.sin(t * tau * s.speed + s.phase);
      final tw2 = 0.5 + 0.5 * math.sin(t * tau * s.speed * 1.37 + s.phase * 2.1);
      final brightness = 0.20 + 0.80 * (0.55 * tw1 + 0.45 * tw2).clamp(0.0, 1.0);
      final tint = tints[idx % tints.length];

      if (s.radius > 0.8) {
        starPaint
          ..color = tint.withOpacity(0.04 * brightness)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s.radius * 2.5);
        canvas.drawCircle(Offset(cx, cy), s.radius * 3 * brightness, starPaint);
        starPaint.maskFilter = null;
      }

      starPaint.color = tint.withOpacity(brightness * 0.95);
      canvas.drawCircle(Offset(cx, cy), s.radius * brightness, starPaint);

      if (s.radius > 1.2) {
        final twinkle = (0.55 * tw1 + 0.45 * tw2).clamp(0.0, 1.0);
        final arm = s.radius * (3.0 + 4.5 * twinkle);
        spikePaint
          ..color = tint.withOpacity(0.30 * twinkle)
          ..strokeWidth = 0.5;
        canvas.drawLine(Offset(cx - arm, cy), Offset(cx + arm, cy), spikePaint);
        canvas.drawLine(Offset(cx, cy - arm), Offset(cx, cy + arm), spikePaint);
      }
    }

    // Ground hill
    final groundPath = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.77)
      ..cubicTo(w * 0.10, h * 0.74, w * 0.25, h * 0.70, w * 0.40, h * 0.715)
      ..cubicTo(w * 0.52, h * 0.73, w * 0.60, h * 0.755, w * 0.72, h * 0.745)
      ..cubicTo(w * 0.82, h * 0.735, w * 0.91, h * 0.75, w, h * 0.76)
      ..lineTo(w, h)
      ..close();

    canvas.drawPath(groundPath, Paint()..color = const Color(0xFF060A18));

    // Edge highlight
    final edgePath = Path()
      ..moveTo(0, h * 0.77)
      ..cubicTo(w * 0.10, h * 0.74, w * 0.25, h * 0.70, w * 0.40, h * 0.715)
      ..cubicTo(w * 0.52, h * 0.73, w * 0.60, h * 0.755, w * 0.72, h * 0.745)
      ..cubicTo(w * 0.82, h * 0.735, w * 0.91, h * 0.75, w, h * 0.76);

    canvas.drawPath(edgePath, Paint()
      ..color = Colors.white.withOpacity(0.035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0);

    // Boy + telescope silhouette
    _drawObserver(canvas, w, h);
  }

  void _drawObserver(Canvas canvas, double w, double h) {
    final bx = w * 0.26;
    final by = h * 0.718;
    final dark = const Color(0xFF060A18);
    final fill = Paint()..color = dark..style = PaintingStyle.fill;
    final stroke = Paint()..color = dark..strokeWidth = 2.2..style = PaintingStyle.stroke;

    // Tripod legs
    canvas.drawLine(Offset(bx - 6, by - 26), Offset(bx - 18, by), stroke);
    canvas.drawLine(Offset(bx - 6, by - 26), Offset(bx + 4, by), stroke);
    canvas.drawLine(Offset(bx - 6, by - 26), Offset(bx - 9, by), stroke);

    // Telescope tube at 45°
    const angle = -math.pi / 4;
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);
    const tl = 42.0, tw = 4.5;
    Offset rot(double dx, double dy) =>
        Offset(bx - 6 + dx * cosA - dy * sinA, by - 28 + dx * sinA + dy * cosA);

    final scope = Path()
      ..moveTo(rot(0, -tw / 2).dx, rot(0, -tw / 2).dy)
      ..lineTo(rot(tl, -tw / 2.3).dx, rot(tl, -tw / 2.3).dy)
      ..lineTo(rot(tl, tw / 2.3).dx, rot(tl, tw / 2.3).dy)
      ..lineTo(rot(0, tw / 2).dx, rot(0, tw / 2).dy)
      ..close();
    canvas.drawPath(scope, fill);
    canvas.drawCircle(rot(1.5, 0), 3.2, fill);
    canvas.drawCircle(rot(tl, 0), 4.0, fill);

    // Body
    final torso = Path()
      ..moveTo(bx - 2, by)
      ..lineTo(bx, by - 16)
      ..lineTo(bx + 2, by - 30)
      ..lineTo(bx - 1, by - 36)
      ..lineTo(bx - 8, by - 20)
      ..close();
    canvas.drawPath(torso, fill);

    // Arm
    final arm = Path()
      ..moveTo(bx, by - 26)
      ..quadraticBezierTo(bx - 8, by - 30, bx - 10, by - 28)
      ..lineTo(bx - 9, by - 28)
      ..close();
    canvas.drawPath(arm, fill);

    // Head
    canvas.drawOval(Rect.fromCenter(center: Offset(bx - 1, by - 40), width: 11, height: 13), fill);

    // Hair
    final hair = Path()
      ..moveTo(bx - 5, by - 46)
      ..cubicTo(bx - 4, by - 50, bx + 2, by - 50, bx + 3, by - 46);
    canvas.drawPath(hair, Paint()..color = dark..strokeWidth = 2..style = PaintingStyle.stroke);

    // Tiny bright eye
    canvas.drawCircle(Offset(bx - 3, by - 40), 1, Paint()..color = Colors.white.withOpacity(0.5));
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter old) => old.t != t;
}
