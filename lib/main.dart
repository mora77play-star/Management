// ملاحظة مهمة: لازم تضيف المكتبة دي في ملف pubspec.yaml (مش هنا):
//
// dependencies:
//   flutter:
//     sdk: flutter
//   shared_preferences: ^2.2.2
//
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kBase = Color(0xFF0B1020);
const kCard = Color(0xFF141A30);

// ===================== التخزين (حفظ تلقائي) =====================
class Store {
  static late SharedPreferences sp;
  static Map<String, dynamic> d = {};

  static Map<String, dynamic> def() {
    final raw = [
      ['الصف الأول الابتدائي', 300, 'p'], ['الصف الثاني الابتدائي', 300, 'p'], ['الصف الثالث الابتدائي', 300, 'p'],
      ['الصف الرابع الابتدائي', 350, 'p'], ['الصف الخامس الابتدائي', 350, 'p'], ['الصف السادس الابتدائي', 350, 'p'],
      ['الصف الأول الإعدادي', 400, 'e'], ['الصف الأول الإعدادي (أزهر)', 450, 'e'], ['الصف الثاني الإعدادي', 400, 'e'],
      ['الصف الثاني الإعدادي (أزهر)', 450, 'e'], ['الصف الثالث الإعدادي', 450, 'e'], ['الصف الثالث الإعدادي (أزهر)', 500, 'e'],
    ];
    final cl = <Map<String, dynamic>>[];
    for (var i = 0; i < raw.length; i++) {
      cl.add({'id': i + 1, 'name': raw[i][0], 'price': raw[i][1], 'stage': raw[i][2]});
    }
    return {
      'pass': '123456', 'center': 'إدارة السنتر', 'classes': cl, 'students': [], 'teachers': [],
      'pays': [], 'sessions': [], 'att': {}, 'seq': 100,
    };
  }

  static Future<void> init() async {
    sp = await SharedPreferences.getInstance();
    final raw = sp.getString('db');
    if (raw != null) {
      try {
        d = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      } catch (_) {}
    }
    def().forEach((k, v) => d.putIfAbsent(k, () => v));
  }

  static Future<void> save() => sp.setString('db', jsonEncode(d));
  static List get classes => d['classes'];
  static List get students => d['students'];
  static List get teachers => d['teachers'];
  static List get pays => d['pays'];
  static List get sessions => d['sessions'];
  static Map get att => d['att'];
  static int nid() {
    d['seq'] = (d['seq'] as int) + 1;
    return d['seq'];
  }
}

// ===================== دوال مساعدة =====================
String fmt(DateTime n) => '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
String today() => fmt(DateTime.now());
String money(num n) {
  final s = n.round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return '$b ج.م';
}

Map cls(dynamic id) => Store.classes.firstWhere((c) => c['id'] == id,
    orElse: () => {'id': 0, 'name': '—', 'price': 0, 'stage': ''}) as Map;

Map? paidOf(dynamic sid, String m) {
  for (final p in Store.pays) {
    if (p['sid'] == sid && p['month'] == m) return p as Map;
  }
  return null;
}

Color hc(num i, [double s = .6, double v = .95]) => HSVColor.fromAHSV(1, ((i * 47) % 360).toDouble(), s, v).toColor();
Color shift(Color c, double d) {
  final h = HSVColor.fromColor(c);
  return h.withHue((h.hue + d) % 360).toColor();
}

LinearGradient pg(BuildContext c, [double d = 0]) {
  final cs = Theme.of(c).colorScheme;
  return LinearGradient(
      begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [shift(cs.primary, d), shift(cs.secondary, d)]);
}

void toast(BuildContext c, String m) {
  final s = ScaffoldMessenger.of(c);
  s.hideCurrentSnackBar();
  s.showSnackBar(SnackBar(
      content: Text(m, textAlign: TextAlign.center),
      behavior: SnackBarBehavior.floating,
      backgroundColor: kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))));
}

Future<bool> ask(BuildContext c, String t) async =>
    (await showDialog<bool>(
        context: c,
        builder: (x) => AlertDialog(backgroundColor: kCard, title: Text(t), actions: [
              TextButton(onPressed: () => Navigator.pop(x, false), child: const Text('لأ')),
              ElevatedButton(onPressed: () => Navigator.pop(x, true), child: const Text('أيوه')),
            ]))) ??
    false;

Future<void> sheet(BuildContext c, Widget Function(BuildContext) b) => showModalBottomSheet(
    context: c,
    isScrollControlled: true,
    backgroundColor: kCard,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
    builder: (x) => Padding(
        padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(x).viewInsets.bottom + 18),
        child: SingleChildScrollView(child: b(x))));

InputDecoration deco(String l, IconData i) => InputDecoration(
    labelText: l,
    prefixIcon: Icon(i),
    filled: true,
    fillColor: Colors.white.withOpacity(.07),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none));

Widget pop(int i, Widget child) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.0, end: 1.0),
    duration: Duration(milliseconds: 450 + min(i, 10) * 70),
    curve: Curves.easeOutBack,
    builder: (_, v, ch) =>
        Opacity(opacity: v.clamp(0.0, 1.0).toDouble(), child: Transform.translate(offset: Offset(0, 30 * (1 - v)), child: ch)),
    child: child);

Widget gbtn(BuildContext c, String t, IconData ic, VoidCallback f) => Material(
    color: Colors.transparent,
    child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: f,
        child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
                gradient: pg(c),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Theme.of(c).colorScheme.primary.withOpacity(.4), blurRadius: 14, offset: const Offset(0, 5))]),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(ic, color: kBase),
              const SizedBox(width: 8),
              Text(t, style: const TextStyle(color: kBase, fontWeight: FontWeight.bold, fontSize: 16)),
            ]))));

class Bg extends StatefulWidget {
  final Widget child;
  const Bg({super.key, required this.child});
  @override
  State<Bg> createState() => _BgS();
}

class _BgS extends State<Bg> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(seconds: 24))..repeat();
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(fit: StackFit.expand, children: [
      Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [
        Color.alphaBlend(cs.primary.withOpacity(.30), kBase),
        kBase,
        Color.alphaBlend(cs.secondary.withOpacity(.30), kBase),
      ]))),
      AnimatedBuilder(animation: c, builder: (_, __) => CustomPaint(painter: _Dots(c.value, cs.primary, cs.secondary))),
      widget.child,
    ]);
  }
}

class _Dots extends CustomPainter {
  final double t;
  final Color a, b;
  _Dots(this.t, this.a, this.b);
  @override
  void paint(Canvas cv, Size s) {
    for (var i = 0; i < 14; i++) {
      final k1 = 1 + i % 3, k2 = 1 + (i + 1) % 3;
      final x = (sin(t * 2 * pi * k1 + i * 1.7) * .45 + .5) * s.width;
      final y = (cos(t * 2 * pi * k2 + i * 2.3) * .45 + .5) * s.height;
      final pt = Paint()
        ..color = (i.isEven ? a : b).withOpacity(.10 + .04 * (i % 3))
        ..style = i % 4 == 0 ? PaintingStyle.stroke : PaintingStyle.fill
        ..strokeWidth = 2.5;
      cv.drawCircle(Offset(x, y), 14.0 + (i % 5) * 9, pt);
    }
  }

  @override
  bool shouldRepaint(covariant _Dots o) => true;
}

class Glass extends StatelessWidget {
  final Widget child;
  final EdgeInsets pad;
  final Gradient? g;
  final VoidCallback? onTap;
  const Glass({super.key, required this.child, this.pad = const EdgeInsets.all(14), this.g, this.onTap});
  @override
  Widget build(BuildContext c) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
          color: Colors.transparent,
          child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: onTap,
              child: Ink(
                  padding: pad,
                  decoration: BoxDecoration(
                      gradient: g ?? LinearGradient(colors: [Colors.white.withOpacity(.11), Colors.white.withOpacity(.04)]),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white.withOpacity(.12))),
                  child: child))));
}

Widget seg(List<List<String>> o, String sel, void Function(String) f) => Row(children: [
      for (final e in o)
        Expanded(
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: ChoiceChip(
                    label: SizedBox(width: double.infinity, child: Text(e[1], textAlign: TextAlign.center)),
                    selected: sel == e[0],
                    onSelected: (_) => f(e[0])))),
    ]);

Widget foot() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 22),
    child: Text('جميع الحقوق محفوظة لـ عمر ✘ ©\nالمطور: عمر ✘',
        textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 12.5, height: 1.7)));

// ===================== التطبيق =====================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.init();
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});
  @override
  State<App> createState() => _AppS();
}

class _AppS extends State<App> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(seconds: 40))..repeat();
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: c,
      builder: (_, __) {
        final h = c.value * 360;
        final p = HSVColor.fromAHSV(1, h, .62, .98).toColor();
        final s = HSVColor.fromAHSV(1, (h + 70) % 360, .60, .98).toColor();
        return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'إدارة السنتر',
            builder: (ctx, ch) => Directionality(textDirection: TextDirection.rtl, child: ch!),
            theme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.dark,
                colorScheme: ColorScheme.dark(
                    primary: p,
                    secondary: s,
                    primaryContainer: p,
                    onPrimaryContainer: kBase,
                    secondaryContainer: s.withOpacity(.30),
                    onSecondaryContainer: Colors.white,
                    surface: kCard,
                    onPrimary: kBase),
                scaffoldBackgroundColor: Colors.transparent,
                appBarTheme: const AppBarTheme(
                    backgroundColor: Colors.transparent, elevation: 0, centerTitle: true),
                navigationBarTheme: NavigationBarThemeData(
                    backgroundColor: kCard.withOpacity(.96), indicatorColor: p.withOpacity(.35))),
            home: const Login());
      });
}

// ===================== الشعار =====================
class SpinLogo extends StatefulWidget {
  final double size;
  const SpinLogo({super.key, this.size = 150});
  @override
  State<SpinLogo> createState() => _SpinLogoS();
}

class _SpinLogoS extends State<SpinLogo> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    return AnimatedBuilder(
        animation: c,
        builder: (_, __) => Transform.translate(
            offset: Offset(0, sin(c.value * 2 * pi * 2) * 6),
            child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: CustomPaint(painter: _LogoP(cs.primary, cs.secondary, c.value)))));
  }
}

class _LogoP extends CustomPainter {
  final Color a, b;
  final double t;
  _LogoP(this.a, this.b, this.t);
  @override
  void paint(Canvas cv, Size s) {
    final r = s.width / 2, cx = r, cy = r;
    cv.drawCircle(Offset(cx, cy), r * .88,
        Paint()..color = a.withOpacity(.35 + .15 * sin(t * 2 * pi * 3))..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22));
    cv.drawCircle(Offset(cx, cy), r * .9, Paint()..color = const Color(0xFF0A1630));
    cv.save();
    cv.translate(cx, cy);
    cv.rotate(t * 2 * pi);
    final rect = Rect.fromCircle(center: Offset.zero, radius: r * .9);
    cv.drawArc(rect, 0, 2 * pi, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * .07
          ..shader = SweepGradient(colors: [a, b, a.withOpacity(.1), a]).createShader(rect));
    cv.restore();
    cv.drawCircle(Offset(cx, cy), r * .78,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * .015
          ..color = b.withOpacity(.5));
    final white = Paint()..color = Colors.white;
    final blue = Paint()..color = const Color(0xFF5AA9FF);
    for (final d in [-1.0, 1.0]) {
      cv.drawCircle(Offset(cx + d * r * .3, cy - r * .02), r * .1, blue);
      cv.drawArc(Rect.fromCenter(center: Offset(cx + d * r * .3, cy + r * .3), width: r * .4, height: r * .45), pi, pi, true, blue);
    }
    cv.drawCircle(Offset(cx, cy - r * .08), r * .17, Paint()..color = const Color(0xFFDCE9FF));
    cv.drawArc(Rect.fromCenter(center: Offset(cx, cy + r * .34), width: r * .62, height: r * .6), pi, pi, true, white);
    final cap = Path()
      ..moveTo(cx - r * .34, cy - r * .26)
      ..lineTo(cx, cy - r * .42)
      ..lineTo(cx + r * .34, cy - r * .26)
      ..lineTo(cx, cy - r * .12)
      ..close();
    cv.drawPath(cap, white);
    final gold = Paint()
      ..color = const Color(0xFFFFC857)
      ..strokeWidth = r * .02;
    cv.drawLine(Offset(cx + r * .34, cy - r * .26), Offset(cx + r * .34, cy - r * .1), gold);
    cv.drawCircle(Offset(cx + r * .34, cy - r * .08), r * .03, gold);
    final cols = [const Color(0xFF2F6BFF), const Color(0xFF4A8BFF), const Color(0xFF7FB0FF)];
    for (var i = 0; i < 3; i++) {
      cv.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(cx + r * .38 + i * r * .02, cy + r * .06 + i * r * .1, r * .3, r * .08), Radius.circular(r * .02)),
          Paint()..color = cols[i]);
    }
    cv.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - r * .72, cy + r * .02, r * .3, r * .22), Radius.circular(r * .025)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * .025
          ..color = const Color(0xFF9CC4FF));
    final ln = Paint()
      ..color = b
      ..strokeWidth = r * .02;
    cv.drawLine(Offset(cx - r * .66, cy + r * .1), Offset(cx - r * .5, cy + r * .1), ln);
    cv.drawLine(Offset(cx - r * .66, cy + r * .16), Offset(cx - r * .54, cy + r * .16), ln);
  }

  @override
  bool shouldRepaint(covariant _LogoP o) => true;
}

// ===================== تسجيل الدخول =====================
class Login extends StatefulWidget {
  const Login({super.key});
  @override
  State<Login> createState() => _LoginS();
}

class _LoginS extends State<Login> with TickerProviderStateMixin {
  final pw = TextEditingController();
  bool hide = true, busy = false;
  late final AnimationController sh = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  late final AnimationController sm = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  @override
  void dispose() {
    sh.dispose();
    sm.dispose();
    pw.dispose();
    super.dispose();
  }

  Future<void> enter() async {
    if (busy) return;
    if (pw.text == Store.d['pass']) {
      setState(() => busy = true);
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      Navigator.pushReplacement(
          context,
          PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 700),
              pageBuilder: (_, __, ___) => const Shell(),
              transitionsBuilder: (_, a, __, ch) => FadeTransition(
                  opacity: a, child: ScaleTransition(scale: Tween<double>(begin: .9, end: 1.0).animate(a), child: ch))));
    } else {
      HapticFeedback.heavyImpact();
      sh.forward(from: 0);
      pw.clear();
      toast(context, 'الباسورد غلط');
    }
  }

  @override
  Widget build(BuildContext c) {
    final cs = Theme.of(c).colorScheme;
    return Bg(
        child: Scaffold(
            body: SafeArea(
                child: Center(
                    child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                        child: Column(children: [
                          pop(0, const SpinLogo(size: 200)),
                          const SizedBox(height: 6),
                          pop(
                              1,
                              AnimatedBuilder(
                                  animation: sm,
                                  builder: (_, __) => ShaderMask(
                                      shaderCallback: (r) => LinearGradient(
                                              begin: Alignment(-1 + 2 * sm.value, -.3),
                                              end: Alignment(1 + 2 * sm.value, .3),
                                              tileMode: TileMode.mirror,
                                              colors: [cs.primary, Colors.white, cs.secondary])
                                          .createShader(r),
                                      child: const Text('إدارة السنتر',
                                          style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: Colors.white))))),
                          pop(2, const Text('إدارة أسهل .. لنتائج أفضل', style: TextStyle(color: Colors.white70, fontSize: 15))),
                          const SizedBox(height: 26),
                          pop(
                              3,
                              AnimatedBuilder(
                                  animation: sh,
                                  builder: (_, ch) =>
                                      Transform.translate(offset: Offset(sin(sh.value * pi * 8) * 14 * (1 - sh.value), 0), child: ch),
                                  child: Glass(
                                      pad: const EdgeInsets.all(20),
                                      child: Column(children: [
                                        const Row(children: [
                                          Icon(Icons.shield_rounded),
                                          SizedBox(width: 8),
                                          Text('تسجيل الدخول', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                        ]),
                                        const SizedBox(height: 16),
                                        TextField(
                                            controller: pw,
                                            obscureText: hide,
                                            keyboardType: TextInputType.number,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontSize: 22, letterSpacing: 8),
                                            onSubmitted: (_) => enter(),
                                            decoration: deco('الباسورد', Icons.lock_rounded).copyWith(
                                                suffixIcon: IconButton(
                                                    icon: Icon(hide ? Icons.visibility_off : Icons.visibility),
                                                    onPressed: () => setState(() => hide = !hide)))),
                                        const SizedBox(height: 18),
                                        busy
                                            ? const SizedBox(height: 48, child: Center(child: CircularProgressIndicator()))
                                            : gbtn(c, 'دخول', Icons.login_rounded, enter),
                                      ])))),
                          const SizedBox(height: 6),
                          pop(
                              4,
                              TextButton.icon(
                                  onPressed: () => Navigator.push(c, MaterialPageRoute(builder: (_) => const DevPage())),
                                  icon: const Icon(Icons.code_rounded),
                                  label: const Text('المطور وطريقة التواصل'))),
                          foot(),
                        ]))))));
  }
}

// ===================== قسم المطور =====================
class DevPage extends StatelessWidget {
  const DevPage({super.key});
  static const phone = '01288330550';
  static const wa = 'https://wa.me/201288330550';
  @override
  Widget build(BuildContext c) => Bg(
      child: Scaffold(
          appBar: AppBar(title: const Text('المطور', style: TextStyle(fontWeight: FontWeight.w900))),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            pop(0, const Center(child: SpinLogo(size: 180))),
            pop(
                1,
                Center(
                    child: ShaderMask(
                        shaderCallback: (r) => pg(c).createShader(r),
                        child: const Text('عمر ✘', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white))))),
            pop(2, const Center(child: Text('مطور التطبيق', style: TextStyle(color: Colors.white70, fontSize: 16)))),
            const SizedBox(height: 18),
            pop(
                3,
                Glass(
                    pad: const EdgeInsets.all(18),
                    child: Column(children: [
                      Row(children: [
                        Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(shape: BoxShape.circle, gradient: pg(c)),
                            child: const Icon(Icons.chat_rounded, color: kBase)),
                        const SizedBox(width: 14),
                        const Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('تواصل واتساب', style: TextStyle(fontSize: 13, color: Colors.white60)),
                          SizedBox(height: 2),
                          Text(phone,
                              textDirection: TextDirection.ltr, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        ])),
                      ]),
                      const SizedBox(height: 16),
                      gbtn(c, 'نسخ الرقم', Icons.copy_rounded, () {
                        Clipboard.setData(const ClipboardData(text: phone));
                        toast(c, 'تم نسخ الرقم');
                      }),
                      const SizedBox(height: 10),
                      SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                              onPressed: () {
                                Clipboard.setData(const ClipboardData(text: wa));
                                toast(c, 'تم نسخ رابط واتساب');
                              },
                              icon: const Icon(Icons.link_rounded),
                              label: const Text('نسخ رابط واتساب'))),
                    ]))),
            pop(
                4,
                const Glass(
                    child: Row(children: [
                  Icon(Icons.verified_rounded, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                      child: Text('تطبيق إدارة سنتر متكامل: طلاب ومدفوعات وحضور ومدرسين، وحفظ تلقائي على الجهاز.',
                          style: TextStyle(height: 1.6))),
                ]))),
            foot(),
          ])));
}

// ===================== الهيكل الرئيسي =====================
class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellS();
}

class _ShellS extends State<Shell> {
  int i = 0, key = 0;
  String q = '', stage = '';
  void go(int t, {String q = '', String stage = ''}) => setState(() {
        i = t;
        this.q = q;
        this.stage = stage;
        key++;
      });

  Widget page() {
    switch (i) {
      case 0:
        return Home(go: go);
      case 1:
        return Students(key: ValueKey('s$key'), stage: stage, onPay: (n) => go(2, q: n));
      case 2:
        return Pays(key: ValueKey('p$key'), q: q);
      case 3:
        return const Attend(key: ValueKey('a'));
      default:
        return const Teachers(key: ValueKey('t'));
    }
  }

  @override
  Widget build(BuildContext c) => Bg(
      child: Scaffold(
          appBar: AppBar(
              title: Text(Store.d['center'], style: const TextStyle(fontWeight: FontWeight.w900)),
              actions: [
                IconButton(
                    icon: const Icon(Icons.code_rounded),
                    onPressed: () => Navigator.push(c, MaterialPageRoute(builder: (_) => const DevPage()))),
                IconButton(
                    icon: const Icon(Icons.settings_rounded),
                    onPressed: () async {
                      await Navigator.push(c, MaterialPageRoute(builder: (_) => const Settings()));
                      setState(() {});
                    })
              ]),
          body: SafeArea(
              child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 380),
                  transitionBuilder: (w, a) => FadeTransition(
                      opacity: a,
                      child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, .04), end: Offset.zero).animate(a), child: w)),
                  child: page())),
          bottomNavigationBar: NavigationBar(selectedIndex: i, onDestinationSelected: (t) => go(t), destinations: const [
            NavigationDestination(icon: Icon(Icons.home_rounded), label: 'الرئيسية'),
            NavigationDestination(icon: Icon(Icons.school_rounded), label: 'الطلاب'),
            NavigationDestination(icon: Icon(Icons.payments_rounded), label: 'المدفوعات'),
            NavigationDestination(icon: Icon(Icons.fact_check_rounded), label: 'الحضور'),
            NavigationDestination(icon: Icon(Icons.person_pin_rounded), label: 'المدرسين'),
          ])));
}

// ===================== الرئيسية =====================
class Home extends StatelessWidget {
  final void Function(int, {String q, String stage}) go;
  const Home({super.key, required this.go});

  Widget stage(BuildContext c, int i, String t, IconData e, int n, String st, double d) => Expanded(
      child: pop(
          i,
          Glass(
              onTap: () => go(1, stage: st),
              g: pg(c, d),
              pad: const EdgeInsets.symmetric(vertical: 26),
              child: Column(children: [
                Icon(e, size: 46, color: kBase),
                Text('$n', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: kBase)),
                Text(t, style: const TextStyle(fontWeight: FontWeight.bold, color: kBase)),
                const Text('عدد الطلاب المسجلين', style: TextStyle(fontSize: 12, color: Colors.black54)),
              ]))));

  Widget stat(BuildContext c, int i, IconData e, String v, String t, double d, [VoidCallback? f]) => pop(
      i,
      Glass(
          onTap: f,
          g: pg(c, d),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(e, size: 30, color: kBase),
            const SizedBox(height: 4),
            FittedBox(
                child: Text(v, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: kBase))),
            Text(t, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.black87)),
          ])));

  @override
  Widget build(BuildContext c) {
    final m = today().substring(0, 7);
    int p = 0, e = 0;
    for (final s in Store.students) {
      if (cls(s['cls'])['stage'] == 'p') {
        p++;
      } else {
        e++;
      }
    }
    double paidM = 0, tot = 0, dues = 0;
    for (final x in Store.pays) {
      tot += (x['amount'] as num).toDouble();
      if (x['month'] == m) paidM += (x['amount'] as num).toDouble();
    }
    for (final x in Store.sessions) {
      if (x['done'] != true) dues += (x['price'] as num).toDouble();
    }
    final unpaid = Store.students.where((s) => paidOf(s['id'], m) == null).length;
    final dn = DateTime.now();
    final days = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
    return ListView(padding: const EdgeInsets.all(14), children: [
      pop(0, Glass(child: Row(children: [
        const Icon(Icons.dashboard_customize_rounded, size: 38),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('أهلاً بك', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          Text('${days[dn.weekday - 1]} • ${fmt(dn)}', style: const TextStyle(color: Colors.white60)),
        ])),
      ]))),
      const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text('اختر المرحلة الدراسية', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
      Row(children: [
        stage(c, 1, 'المرحلة الابتدائية', Icons.menu_book_rounded, p, 'p', 0),
        const SizedBox(width: 10),
        stage(c, 2, 'المرحلة الإعدادية', Icons.school_rounded, e, 'e', 90),
      ]),
      GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.35,
          children: [
            stat(c, 3, Icons.account_balance_wallet_rounded, money(paidM), 'إيرادات الشهر الحالي', 140),
            stat(c, 4, Icons.hourglass_bottom_rounded, '$unpaid', 'لم يدفعوا هذا الشهر', 200, () => go(2)),
            stat(c, 5, Icons.savings_rounded, money(tot), 'إجمالي المدفوعات', 260),
            stat(c, 6, Icons.person_pin_rounded, money(dues), 'مستحقات المدرسين', 320, () => go(4)),
          ]),
      foot(),
    ]);
  }
}

// ===================== الطلاب =====================
class Students extends StatefulWidget {
  final String stage;
  final void Function(String) onPay;
  const Students({super.key, required this.stage, required this.onPay});
  @override
  State<Students> createState() => _StudentsS();
}

class _StudentsS extends State<Students> {
  String q = '';
  int fc = 0;

  void add() {
    final n = TextEditingController(), ph = TextEditingController();
    String g = 'm';
    final opts = widget.stage.isEmpty ? Store.classes : Store.classes.where((x) => x['stage'] == widget.stage).toList();
    int cid = opts.first['id'];
    sheet(context, (x) => StatefulBuilder(builder: (x, ss) => Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('إضافة طالب', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          TextField(controller: n, decoration: deco('اسم الطالب', Icons.person_rounded)),
          const SizedBox(height: 10),
          TextField(controller: ph, keyboardType: TextInputType.phone, decoration: deco('رقم التليفون', Icons.phone_rounded)),
          const SizedBox(height: 10),
          seg([['m', 'بنين'], ['f', 'بنات']], g, (v) => ss(() => g = v)),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
              value: cid,
              dropdownColor: kCard,
              decoration: deco('الصف', Icons.class_rounded),
              items: [for (final k in opts) DropdownMenuItem<int>(value: k['id'], child: Text(k['name']))],
              onChanged: (v) => ss(() => cid = v!)),
          const SizedBox(height: 14),
          gbtn(x, 'حفظ الطالب', Icons.check_rounded, () {
            if (n.text.trim().isEmpty) {
              toast(x, 'اكتب اسم الطالب');
              return;
            }
            Store.students.add({'id': Store.nid(), 'name': n.text.trim(), 'phone': ph.text.trim(), 'gender': g, 'cls': cid, 'date': today()});
            Store.save();
            Navigator.pop(x);
            setState(() {});
            toast(context, 'تم إضافة الطالب');
          }),
        ])));
  }

  @override
  Widget build(BuildContext c) {
    final l = Store.students
        .where((s) =>
            (widget.stage.isEmpty || cls(s['cls'])['stage'] == widget.stage) &&
            (fc == 0 || s['cls'] == fc) &&
            (q.isEmpty || s['name'].toString().contains(q) || s['phone'].toString().contains(q)))
        .toList();
    final opts = widget.stage.isEmpty ? Store.classes : Store.classes.where((x) => x['stage'] == widget.stage).toList();
    return Scaffold(
        floatingActionButton: FloatingActionButton.extended(
            onPressed: add,
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('طالب جديد', style: TextStyle(fontWeight: FontWeight.bold))),
        body: ListView(padding: const EdgeInsets.fromLTRB(14, 6, 14, 90), children: [
          Text('الطلاب ${widget.stage == 'p' ? '— الابتدائية' : widget.stage == 'e' ? '— الإعدادية' : ''}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          TextField(onChanged: (v) => setState(() => q = v), decoration: deco('بحث بالاسم أو التليفون', Icons.search_rounded)),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
              value: fc,
              dropdownColor: kCard,
              decoration: deco('الصف', Icons.filter_list_rounded),
              items: [
                const DropdownMenuItem<int>(value: 0, child: Text('كل الصفوف')),
                for (final k in opts) DropdownMenuItem<int>(value: k['id'], child: Text(k['name'])),
              ],
              onChanged: (v) => setState(() => fc = v!)),
          const SizedBox(height: 8),
          Text('العدد: ${l.length}', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          if (l.isEmpty) const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('مفيش طلاب'))),
          for (var i = 0; i < l.length; i++)
            pop(
                i,
                Glass(
                    child: Row(children: [
                  CircleAvatar(
                      radius: 24,
                      backgroundColor: hc(l[i]['cls']).withOpacity(.85),
                      child: Icon(l[i]['gender'] == 'f' ? Icons.face_retouching_natural_rounded : Icons.face_rounded, color: kBase, size: 26)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l[i]['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('${cls(l[i]['cls'])['name']} • ${l[i]['phone'] == '' ? 'بدون رقم' : l[i]['phone']}',
                        style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  ])),
                  IconButton(
                      icon: const Icon(Icons.payments_rounded, color: Colors.greenAccent),
                      onPressed: () => widget.onPay(l[i]['name'])),
                  IconButton(
                      icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                      onPressed: () async {
                        if (!await ask(context, 'حذف الطالب وكل مدفوعاته؟')) return;
                        final id = l[i]['id'];
                        Store.students.removeWhere((s) => s['id'] == id);
                        Store.pays.removeWhere((p) => p['sid'] == id);
                        Store.save();
                        setState(() {});
                      }),
                ]))),
        ]));
  }
}

// ===================== المدفوعات =====================
class Pays extends StatefulWidget {
  final String q;
  const Pays({super.key, this.q = ''});
  @override
  State<Pays> createState() => _PaysS();
}

class _PaysS extends State<Pays> {
  String month = today().substring(0, 7);
  late String q = widget.q;
  late final tc = TextEditingController(text: widget.q);
  int fs = 0, fc = 0;

  void mv(int d) {
    final p = month.split('-');
    var y = int.parse(p[0]), m = int.parse(p[1]) + d;
    if (m > 12) {
      m = 1;
      y++;
    }
    if (m < 1) {
      m = 12;
      y--;
    }
    setState(() => month = '$y-${m.toString().padLeft(2, '0')}');
  }

  void pay(Map s) {
    final t = TextEditingController(text: '${cls(s['cls'])['price']}');
    showDialog(
        context: context,
        builder: (x) => AlertDialog(
                backgroundColor: kCard,
                title: Text('دفع ${s['name']}'),
                content: TextField(controller: t, keyboardType: TextInputType.number, decoration: deco('المبلغ', Icons.payments_rounded)),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(x), child: const Text('إلغاء')),
                  ElevatedButton(
                      onPressed: () {
                        final a = double.tryParse(t.text);
                        if (a == null || a < 0) return;
                        final id = Store.nid();
                        Store.pays.add({'id': id, 'sid': s['id'], 'month': month, 'amount': a, 'date': today()});
                        Store.save();
                        Navigator.pop(x);
                        setState(() {});
                        receipt(id);
                      },
                      child: const Text('تأكيد الدفع')),
                ]));
  }

  void receipt(int id) {
    final p = Store.pays.firstWhere((x) => x['id'] == id) as Map;
    final s = Store.students.firstWhere((x) => x['id'] == p['sid'], orElse: () => {'name': '—', 'cls': 0}) as Map;
    final txt = 'إيصال #${p['id']}\nالطالب: ${s['name']}\nالصف: ${cls(s['cls'])['name']}\nالشهر: ${p['month']}\nالمبلغ: ${money(p['amount'])}\nالتاريخ: ${p['date']}';
    showDialog(
        context: context,
        builder: (x) => AlertDialog(
                backgroundColor: kCard,
                title: Text('إيصال #${p['id']}', textAlign: TextAlign.center),
                content: Text(txt.split('\n').skip(1).join('\n'), style: const TextStyle(height: 1.9, fontSize: 16)),
                actions: [
                  TextButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: txt));
                        toast(context, 'تم نسخ الإيصال');
                      },
                      child: const Text('نسخ')),
                  ElevatedButton(onPressed: () => Navigator.pop(x), child: const Text('تمام')),
                ]));
  }

  @override
  Widget build(BuildContext c) {
    final l = Store.students
        .where((s) =>
            (fc == 0 || s['cls'] == fc) &&
            (q.isEmpty || s['name'].toString().contains(q)) &&
            (fs == 0 || (fs == 1) == (paidOf(s['id'], month) != null)))
        .toList();
    double tp = 0;
    int pc = 0;
    for (final s in l) {
      final p = paidOf(s['id'], month);
      if (p != null) {
        tp += (p['amount'] as num).toDouble();
        pc++;
      }
    }
    return ListView(padding: const EdgeInsets.fromLTRB(14, 6, 14, 20), children: [
      const Text('المدفوعات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
      const SizedBox(height: 10),
      Glass(
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        IconButton(icon: const Icon(Icons.chevron_right_rounded, size: 32), onPressed: () => mv(-1)),
        Text('$month', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
        IconButton(icon: const Icon(Icons.chevron_left_rounded, size: 32), onPressed: () => mv(1)),
      ])),
      TextField(controller: tc, onChanged: (v) => setState(() => q = v), decoration: deco('اسم الطالب', Icons.search_rounded)),
      const SizedBox(height: 8),
      DropdownButtonFormField<int>(
          value: fc,
          dropdownColor: kCard,
          decoration: deco('الصف', Icons.filter_list_rounded),
          items: [
            const DropdownMenuItem<int>(value: 0, child: Text('كل الصفوف')),
            for (final k in Store.classes) DropdownMenuItem<int>(value: k['id'], child: Text(k['name'])),
          ],
          onChanged: (v) => setState(() => fc = v!)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, children: [
        for (var i = 0; i < 3; i++)
          ChoiceChip(label: Text(['الكل', 'مدفوع', 'غير مدفوع'][i]), selected: fs == i, onSelected: (_) => setState(() => fs = i)),
      ]),
      const SizedBox(height: 8),
      Wrap(spacing: 8, children: [
        Chip(avatar: const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 18), label: Text('$pc')),
        Chip(avatar: const Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 18), label: Text('${l.length - pc}')),
        Chip(avatar: const Icon(Icons.payments_rounded, size: 18), label: Text(money(tp))),
      ]),
      const SizedBox(height: 8),
      if (l.isEmpty) const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('مفيش بيانات'))),
      for (var i = 0; i < l.length; i++) _row(c, i, l[i] as Map),
    ]);
  }

  Widget _row(BuildContext c, int i, Map s) {
    final p = paidOf(s['id'], month);
    return pop(
        i,
        Glass(
            child: Row(children: [
          Container(width: 6, height: 44, decoration: BoxDecoration(color: hc(s['cls']), borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 12),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('${cls(s['cls'])['name']} • المطلوب ${money(cls(s['cls'])['price'])}',
                style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ])),
          if (p != null) ...[
            Text('✓ ${money(p['amount'])}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.receipt_long_rounded), onPressed: () => receipt(p['id'])),
            IconButton(
                icon: const Icon(Icons.undo_rounded, color: Colors.redAccent),
                onPressed: () async {
                  if (!await ask(context, 'إلغاء هذه الدفعة؟')) return;
                  Store.pays.removeWhere((x) => x['id'] == p['id']);
                  Store.save();
                  setState(() {});
                }),
          ] else
            ElevatedButton.icon(onPressed: () => pay(s), icon: const Icon(Icons.payments_rounded), label: const Text('دفع')),
        ])));
  }
}

// ===================== الحضور والغياب =====================
class Attend extends StatefulWidget {
  const Attend({super.key});
  @override
  State<Attend> createState() => _AttendS();
}

class _AttendS extends State<Attend> {
  DateTime day = DateTime.now();
  int cid = 0;
  String get key => '${fmt(day)}|$cid';

  void mark(dynamic id, int v) {
    final m = Store.att.putIfAbsent(key, () => <String, dynamic>{}) as Map;
    m['$id'] = v;
    Store.save();
    setState(() {});
  }

  @override
  Widget build(BuildContext c) {
    final l = Store.students.where((s) => s['cls'] == cid).toList();
    final a = (Store.att[key] ?? {}) as Map;
    final pr = l.where((s) => a['${s['id']}'] == 1).length;
    final ab = l.where((s) => a['${s['id']}'] == 0).length;
    return ListView(padding: const EdgeInsets.fromLTRB(14, 6, 14, 20), children: [
      const Text('الحضور والغياب', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
      const SizedBox(height: 10),
      Glass(
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        IconButton(icon: const Icon(Icons.chevron_right_rounded, size: 32), onPressed: () => setState(() => day = day.subtract(const Duration(days: 1)))),
        Text('${fmt(day)}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
        IconButton(icon: const Icon(Icons.chevron_left_rounded, size: 32), onPressed: () => setState(() => day = day.add(const Duration(days: 1)))),
      ])),
      DropdownButtonFormField<int>(
          value: cid,
          dropdownColor: kCard,
          decoration: deco('الصف', Icons.class_rounded),
          items: [
            const DropdownMenuItem<int>(value: 0, child: Text('— اختر الصف —')),
            for (final k in Store.classes) DropdownMenuItem<int>(value: k['id'], child: Text(k['name'])),
          ],
          onChanged: (v) => setState(() => cid = v!)),
      const SizedBox(height: 8),
      if (cid != 0) Wrap(spacing: 8, children: [Chip(label: Text('حاضر: $pr')), Chip(label: Text('غايب: $ab')), Chip(label: Text('العدد: ${l.length}'))]),
      if (cid == 0) const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('اختر الصف الأول'))),
      if (cid != 0 && l.isEmpty) const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('مفيش طلاب في الصف'))),
      for (var i = 0; i < l.length; i++)
        pop(
            i,
            Glass(
                child: Row(children: [
              Expanded(child: Text(l[i]['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              _ab(a['${l[i]['id']}'] == 1, 'حاضر', Colors.green, () => mark(l[i]['id'], 1)),
              const SizedBox(width: 6),
              _ab(a['${l[i]['id']}'] == 0, 'غايب', Colors.red, () => mark(l[i]['id'], 0)),
            ]))),
    ]);
  }

  Widget _ab(bool on, String t, Color col, VoidCallback f) => AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(color: on ? col : Colors.white12, borderRadius: BorderRadius.circular(14)),
      child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: f,
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9), child: Text(t, style: TextStyle(fontWeight: FontWeight.bold, color: on ? Colors.white : Colors.white60)))));
}

// ===================== المدرسين =====================
class Teachers extends StatefulWidget {
  const Teachers({super.key});
  @override
  State<Teachers> createState() => _TeachersS();
}

class _TeachersS extends State<Teachers> {
  void add() {
    final n = TextEditingController(), j = TextEditingController(), p = TextEditingController();
    String st = 'e';
    sheet(context, (x) => StatefulBuilder(builder: (x, ss) => Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('إضافة مدرس', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          TextField(controller: n, decoration: deco('اسم المدرس', Icons.person_rounded)),
          const SizedBox(height: 10),
          TextField(controller: j, decoration: deco('المادة', Icons.menu_book_rounded)),
          const SizedBox(height: 10),
          TextField(controller: p, keyboardType: TextInputType.number, decoration: deco('سعر الحصة (ج.م)', Icons.payments_rounded)),
          const SizedBox(height: 10),
          seg([['p', 'ابتدائية'], ['e', 'إعدادية']], st, (v) => ss(() => st = v)),
          const SizedBox(height: 14),
          gbtn(x, 'حفظ المدرس', Icons.check_rounded, () {
            final pr = double.tryParse(p.text);
            if (n.text.trim().isEmpty || pr == null) {
              toast(x, 'اكتب الاسم وسعر الحصة');
              return;
            }
            Store.teachers.add({'id': Store.nid(), 'name': n.text.trim(), 'subj': j.text.trim(), 'stage': st, 'price': pr});
            Store.save();
            Navigator.pop(x);
            setState(() {});
          }),
        ])));
  }

  @override
  Widget build(BuildContext c) => Scaffold(
      floatingActionButton: FloatingActionButton.extended(
          onPressed: add,
          icon: const Icon(Icons.add_rounded),
          label: const Text('مدرس جديد', style: TextStyle(fontWeight: FontWeight.bold))),
      body: ListView(padding: const EdgeInsets.fromLTRB(14, 6, 14, 90), children: [
        const Text('المدرسين والحصص', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        if (Store.teachers.isEmpty) const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('مفيش مدرسين'))),
        for (var i = 0; i < Store.teachers.length; i++) _card(i, Store.teachers[i] as Map),
      ]));

  Widget _card(int i, Map t) {
    final open = Store.sessions.where((x) => x['tid'] == t['id'] && x['done'] != true).toList();
    double due = 0;
    for (final x in open) {
      due += (x['price'] as num).toDouble();
    }
    return pop(
        i,
        Glass(
            child: Column(children: [
          Row(children: [
            CircleAvatar(backgroundColor: hc(t['id']), child: const Icon(Icons.person_pin_rounded, color: kBase)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('${t['subj'] == '' ? '—' : t['subj']} • ${t['stage'] == 'p' ? 'ابتدائية' : 'إعدادية'} • الحصة ${money(t['price'])}',
                  style: const TextStyle(color: Colors.white60, fontSize: 12)),
            ])),
          ]),
          const SizedBox(height: 8),
          Text('حصص لم تُصفّى: ${open.length} — المستحق: ${money(due)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            ElevatedButton.icon(
                onPressed: () {
                  Store.sessions.add({'id': Store.nid(), 'tid': t['id'], 'price': t['price'], 'date': today(), 'done': false});
                  Store.save();
                  setState(() {});
                  toast(context, 'تم تسجيل حصة');
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('حصة')),
            OutlinedButton.icon(
                onPressed: () async {
                  if (open.isEmpty) {
                    toast(context, 'مفيش مستحقات');
                    return;
                  }
                  if (!await ask(context, 'تصفية ${open.length} حصة بمبلغ ${money(due)}؟')) return;
                  for (final x in open) {
                    x['done'] = true;
                  }
                  Store.save();
                  setState(() {});
                },
                icon: const Icon(Icons.price_check_rounded),
                label: const Text('تصفية')),
            IconButton(
                icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                onPressed: () async {
                  if (!await ask(context, 'حذف المدرس؟')) return;
                  Store.teachers.removeWhere((x) => x['id'] == t['id']);
                  Store.sessions.removeWhere((x) => x['tid'] == t['id']);
                  Store.save();
                  setState(() {});
                }),
          ]),
        ])));
  }
}

// ===================== الإعدادات =====================
class Settings extends StatefulWidget {
  const Settings({super.key});
  @override
  State<Settings> createState() => _SettingsS();
}

class _SettingsS extends State<Settings> {
  final nm = TextEditingController(text: Store.d['center']);
  final op = TextEditingController(), np = TextEditingController();
  final kn = TextEditingController(), kp = TextEditingController();
  String ks = 'e';

  Widget box(String t, List<Widget> ch) => Glass(
      pad: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(t, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...ch,
      ]));

  @override
  Widget build(BuildContext c) => Bg(
      child: Scaffold(
          appBar: AppBar(title: const Text('الإعدادات', style: TextStyle(fontWeight: FontWeight.w900))),
          body: ListView(padding: const EdgeInsets.all(14), children: [
            pop(
                0,
                Glass(
                    onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => const DevPage())),
                    child: const Row(children: [
                      Icon(Icons.code_rounded, size: 30),
                      SizedBox(width: 12),
                      Expanded(child: Text('المطور وطريقة التواصل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                      Icon(Icons.chevron_left_rounded),
                    ]))),
            box('اسم التطبيق', [
              TextField(controller: nm, decoration: deco('الاسم', Icons.edit_rounded)),
              const SizedBox(height: 10),
              gbtn(c, 'حفظ', Icons.check_rounded, () {
                if (nm.text.trim().isNotEmpty) Store.d['center'] = nm.text.trim();
                Store.save();
                toast(c, 'تم الحفظ');
              }),
            ]),
            box('تغيير الباسورد', [
              TextField(controller: op, obscureText: true, decoration: deco('الباسورد الحالي', Icons.lock_open_rounded)),
              const SizedBox(height: 8),
              TextField(controller: np, obscureText: true, decoration: deco('الباسورد الجديد', Icons.lock_rounded)),
              const SizedBox(height: 10),
              gbtn(c, 'تغيير', Icons.key_rounded, () {
                if (op.text != Store.d['pass']) {
                  toast(c, 'الباسورد الحالي غلط');
                  return;
                }
                if (np.text.length < 4) {
                  toast(c, 'الباسورد قصير');
                  return;
                }
                Store.d['pass'] = np.text;
                Store.save();
                op.clear();
                np.clear();
                toast(c, 'تم تغيير الباسورد');
              }),
            ]),
            box('إضافة صف جديد', [
              TextField(controller: kn, decoration: deco('اسم الصف', Icons.class_rounded)),
              const SizedBox(height: 8),
              TextField(controller: kp, keyboardType: TextInputType.number, decoration: deco('المصروفات الشهرية', Icons.payments_rounded)),
              const SizedBox(height: 8),
              seg([['p', 'ابتدائية'], ['e', 'إعدادية']], ks, (v) => setState(() => ks = v)),
              const SizedBox(height: 10),
              gbtn(c, 'إضافة الصف', Icons.add_rounded, () {
                final p = double.tryParse(kp.text);
                if (kn.text.trim().isEmpty || p == null) {
                  toast(c, 'اكتب الاسم والمصروفات');
                  return;
                }
                Store.classes.add({'id': Store.nid(), 'name': kn.text.trim(), 'price': p, 'stage': ks});
                Store.save();
                kn.clear();
                kp.clear();
                toast(c, 'تم إضافة الصف');
              }),
            ]),
            box('نسخة احتياطية', [
              const Text('الحفظ تلقائي على الجهاز. النسخة الاحتياطية لنقل البيانات لجهاز تاني.', style: TextStyle(color: Colors.white60, fontSize: 12.5)),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: jsonEncode(Store.d)));
                    toast(c, 'تم نسخ البيانات');
                  },
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('نسخ البيانات')),
              const SizedBox(height: 8),
              OutlinedButton.icon(onPressed: restore, icon: const Icon(Icons.paste_rounded), label: const Text('استرجاع من نسخة')),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                  onPressed: () async {
                    if (!await ask(context, 'مسح كل البيانات نهائياً؟')) return;
                    Store.d = Store.def();
                    await Store.save();
                    if (!mounted) return;
                    toast(context, 'تم المسح');
                    setState(() => nm.text = Store.d['center']);
                  },
                  icon: const Icon(Icons.warning_rounded),
                  label: const Text('مسح كل البيانات')),
            ]),
            foot(),
          ])));

  void restore() {
    final t = TextEditingController();
    showDialog(
        context: context,
        builder: (x) => AlertDialog(
                backgroundColor: kCard,
                title: const Text('الصق النسخة هنا'),
                content: TextField(controller: t, maxLines: 5, decoration: deco('البيانات', Icons.data_object_rounded)),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(x), child: const Text('إلغاء')),
                  ElevatedButton(
                      onPressed: () {
                        try {
                          final m = Map<String, dynamic>.from(jsonDecode(t.text) as Map);
                          if (m['students'] == null || m['classes'] == null) throw 0;
                          Store.d = m;
                          Store.def().forEach((k, v) => Store.d.putIfAbsent(k, () => v));
                          Store.save();
                          Navigator.pop(x);
                          toast(context, 'تم الاسترجاع');
                        } catch (_) {
                          toast(context, 'بيانات غير صالحة');
                        }
                      },
                      child: const Text('استرجاع')),
                ]));
  }
}
