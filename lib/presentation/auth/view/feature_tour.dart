import 'package:flutter/material.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_motion.dart';
import 'package:financial_recording/shared/widget/motion/motion.dart';

class _Card {
  const _Card(this.label, this.title, this.body, this.meta);
  final String label;
  final String title;
  final String body;
  final String meta;
}

class _Topic {
  const _Topic(this.tab, this.icon, this.line, this.cards);
  final String tab;
  final IconData icon;
  final String line;
  final List<_Card> cards;
}

const _topics = [
  _Topic('Catat', Icons.edit_note_rounded, 'Catat dalam tiga ketukan', [
    _Card('Cepat', 'Templat satu ketuk', 'Kopi pagi, bensin, parkir: simpan sekali, catat berikutnya cukup satu ketukan.', 'Templat cepat'),
    _Card('Tepat', 'Kalkulator di kolom nominal', 'Hitung bagi tagihan, diskon, dan pajak langsung di kolom nominal, lalu pakai hasilnya.', 'Kalkulator ekspresi'),
    _Card('Lengkap', 'Struk jadi transaksi', 'Foto struk belanja; nominal dan rincian barang terbaca otomatis.', 'Pindai struk'),
    _Card('Rapi', 'Berulang tanpa lupa', 'Gaji, cicilan, dan langganan tercatat sendiri tiap jatuh tempo.', 'Transaksi berulang'),
  ]),
  _Topic('Keluarga', Icons.diversity_3_rounded, 'Satu buku kas untuk serumah', [
    _Card('Undang', 'Kode undangan keluarga', 'Buat keluarga, bagikan kode 8 huruf, dan pasangan Anda langsung melihat buku kas yang sama.', 'Akun keluarga'),
    _Card('Langsung', 'Tersinkron seketika', 'Belanja yang dicatat di satu ponsel muncul di ponsel lain dalam hitungan detik.', 'Sinkron realtime'),
    _Card('Jelas', 'Siapa mencatat apa', 'Setiap transaksi menyimpan nama pencatatnya, dan laporan dirinci per anggota.', 'Atribusi anggota'),
    _Card('Aman', 'Hak akses per keluarga', 'Hanya anggota keluarga yang bisa membaca buku kas. Pemilik bisa mengganti kode kapan saja.', 'Row Level Security'),
  ]),
  _Topic('Laporan', Icons.insights_rounded, 'Laporan yang menjelaskan dirinya', [
    _Card('Ringkas', 'Ringkasan dalam kalimat', 'Setiap bulan Wallet menulis ringkasan: naik-turun belanja, kategori terbesar, dan sisa aman per hari.', 'Narasi otomatis'),
    _Card('Waspada', 'Deteksi lonjakan', 'Kategori yang melonjak jauh di atas rata-rata tiga bulan langsung ditandai.', 'Anomali kategori'),
    _Card('Proyeksi', 'Perkiraan akhir bulan', 'Laju belanja hari ini diproyeksikan ke akhir bulan, jadi Anda tahu sebelum terlambat.', 'Proyeksi arus kas'),
    _Card('Langganan', 'Langganan terdeteksi', 'Pembayaran yang berulang dengan nominal serupa dikenali sebagai langganan.', 'Deteksi berulang'),
  ]),
  _Topic('Keamanan', Icons.lock_outline_rounded, 'Privat sejak awal', [
    _Card('Kunci', 'PIN aplikasi', 'Kunci Wallet dengan PIN setiap kali dibuka.', 'PIN lokal'),
    _Card('Akun', 'Wajib masuk', 'Data hanya terbuka setelah Anda masuk, dan terhapus dari perangkat saat Anda keluar.', 'Autentikasi Supabase'),
    _Card('Cadangan', 'Ekspor kapan saja', 'Unduh seluruh data sebagai JSON atau CSV untuk Excel dan Google Sheets.', 'Backup & CSV'),
    _Card('Luring', 'Tetap jalan tanpa sinyal', 'Catat saat offline; sinkronisasi berjalan otomatis begitu tersambung.', 'Offline-first'),
  ]),
];

Future<void> showFeatureTour(BuildContext context, {int initialTopic = 0, VoidCallback? onStart}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Tutup',
    barrierColor: Colors.black.withValues(alpha: 0.5),
    transitionDuration: AppMotion.of(context, const Duration(milliseconds: 520)),
    pageBuilder: (ctx, _, _) => Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 1240, maxHeight: MediaQuery.sizeOf(ctx).height * 0.94),
        child: Material(
          color: ctx.colors.surfaceAlt,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: _FeatureTour(initialTopic: initialTopic, onStart: onStart),
        ),
      ),
    ),
    transitionBuilder: (ctx, anim, _, child) => SlideTransition(
      position: Tween(begin: const Offset(0, 1), end: Offset.zero)
          .animate(CurvedAnimation(parent: anim, curve: AppMotion.emphasized, reverseCurve: Curves.easeInCubic)),
      child: child,
    ),
  );
}

class _FeatureTour extends StatefulWidget {
  const _FeatureTour({required this.initialTopic, this.onStart});
  final int initialTopic;
  final VoidCallback? onStart;

  @override
  State<_FeatureTour> createState() => _FeatureTourState();
}

class _FeatureTourState extends State<_FeatureTour> {
  late int _topic = widget.initialTopic;
  int _active = 1;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final w = MediaQuery.sizeOf(context).width;
    final topic = _topics[_topic];
    final compact = w < 720;
    final theme = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(compact ? 16 : 40, 16, compact ? 16 : 40, 32),
        child: Column(
          crossAxisAlignment: compact ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: WIconButton(icon: Icons.close_rounded, tooltip: 'Tutup', onPressed: () => Navigator.of(context).maybePop()),
            ),
            Text(
              'Keuangan yang Anda pahami',
              textAlign: compact ? TextAlign.start : TextAlign.center,
              style: theme.displaySmall?.copyWith(fontSize: compact ? 32 : 46),
            ),
            AnimatedSwitcher(
              duration: AppMotion.of(context, AppMotion.slow),
              switchInCurve: AppMotion.emphasized,
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(position: Tween(begin: const Offset(0, 0.25), end: Offset.zero).animate(a), child: child),
              ),
              child: Text(
                topic.line,
                key: ValueKey(_topic),
                textAlign: compact ? TextAlign.start : TextAlign.center,
                style: theme.displaySmall?.copyWith(fontSize: compact ? 32 : 46, color: c.textTertiary),
              ),
            ),
            const SizedBox(height: 28),
            PillTabs<int>(
              tabs: [for (var i = 0; i < _topics.length; i++) PillTab(i, _topics[i].tab, icon: _topics[i].icon)],
              value: _topic,
              onChanged: (v) => setState(() {
                _topic = v;
                _active = 1;
              }),
            ),
            const SizedBox(height: 28),
            if (compact)
              SizedBox(
                height: 360,
                child: PageView.builder(
                  controller: PageController(viewportFraction: 0.84, initialPage: _active),
                  padEnds: false,
                  onPageChanged: (i) => setState(() => _active = i),
                  itemCount: topic.cards.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _InsightCard(
                      key: ValueKey('$_topic-$i'),
                      card: topic.cards[i],
                      index: i,
                      active: _active == i,
                      onActivate: () => setState(() => _active = i),
                    ),
                  ),
                ),
              )
            else
              LayoutBuilder(builder: (context, box) {
                final cols = box.maxWidth >= 1000 ? 4 : 2;
                final cardW = (box.maxWidth - 16 * (cols - 1)) / cols;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (var i = 0; i < topic.cards.length; i++)
                      SizedBox(
                        width: cardW,
                        height: 380,
                        child: Reveal(
                          key: ValueKey('$_topic-$i'),
                          index: i,
                          child: _InsightCard(
                            card: topic.cards[i],
                            index: i,
                            active: _active == i,
                            onActivate: () => setState(() => _active = i),
                          ),
                        ),
                      ),
                  ],
                );
              }),
            const SizedBox(height: 28),
            if (widget.onStart != null)
              WButton(
                label: 'Buat akun gratis',
                arrow: true,
                size: WButtonSize.large,
                onPressed: () {
                  Navigator.of(context).maybePop();
                  widget.onStart!();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({super.key, required this.card, required this.index, required this.active, required this.onActivate});
  final _Card card;
  final int index;
  final bool active;
  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const ease = AppMotion.standard;
    const d = Duration(milliseconds: 450);
    final fg = active ? const Color(0xFFF1F0E6) : c.textPrimary;
    final fgMuted = active ? const Color(0xFFC9CDC4) : c.textSecondary;

    return MouseRegion(
      onEnter: (_) => onActivate(),
      child: Focus(
        onFocusChange: (f) {
          if (f) onActivate();
        },
        child: Pressable(
          onTap: onActivate,
          semanticLabel: card.title,
          hoverLift: 0,
          borderRadius: BorderRadius.circular(12),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: active ? 1 : 0),
            duration: AppMotion.of(context, d),
            curve: ease,
            builder: (context, t, _) => Transform.translate(
              offset: Offset(0, -5 * t),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Color.lerp(c.surface, const Color(0xFF1C2B2A), t),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.border.withValues(alpha: 1 - t)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04 + 0.14 * t),
                      blurRadius: 8 + 28 * t,
                      offset: Offset(0, 2 + 14 * t),
                    ),
                  ],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Opacity(opacity: t, child: _BlurredArt(seed: index, animate: active)),
                    Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(card.label.toUpperCase(),
                              style: TextStyle(fontSize: 11.5, letterSpacing: 0.8, fontWeight: FontWeight.w600, color: fgMuted)),
                          const SizedBox(height: 14),
                          Text(card.title,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: fg, fontSize: 24, height: 1.1)),
                          const SizedBox(height: 12),
                          Text(card.body, style: TextStyle(color: fgMuted, fontSize: 14, height: 1.45)),
                          const Spacer(),
                          Row(
                            children: [
                              Expanded(
                                child: Text('Fitur 0${index + 1} · ${card.meta}',
                                    style: TextStyle(fontSize: 12, color: fgMuted), overflow: TextOverflow.ellipsis),
                              ),
                              Icon(Icons.north_east_rounded, size: 16, color: fgMuted),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Out-of-focus "editorial photograph" made from layered radial gradients:
/// dark green-grey base, muted blue-grey and warm brown pools, slowly
/// breathing while the card is active.
class _BlurredArt extends StatefulWidget {
  const _BlurredArt({required this.seed, required this.animate});
  final int seed;
  final bool animate;

  @override
  State<_BlurredArt> createState() => _BlurredArtState();
}

class _BlurredArtState extends State<_BlurredArt> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 9));

  @override
  void didUpdateWidget(covariant _BlurredArt old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  void _sync() {
    if (widget.animate && !AppMotion.reduced(context)) {
      if (!_c.isAnimating) _c.repeat(reverse: true);
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.seed;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_c.value);
        return Transform.scale(
          scale: 1.08 + 0.06 * t,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.6 + 0.3 * s / 3 + 0.1 * t, -0.7),
                radius: 1.1,
                colors: const [Color(0xFF5E7488), Color(0x005E7488)],
              ),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.7 - 0.2 * t, 0.5 - 0.15 * s / 3),
                  radius: 0.9,
                  colors: const [Color(0xB08A6A4C), Color(0x008A6A4C)],
                ),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(-0.2 + 0.15 * t, 1.1),
                    radius: 1.0,
                    colors: const [Color(0xCC2D4A40), Color(0x002D4A40)],
                  ),
                ),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x33000000), Color(0x8C0E1614)],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
