import React from 'react';
import { AbsoluteFill, interpolate, staticFile, useCurrentFrame, useVideoConfig, Img } from 'remotion';
import { c, font, rupiah } from './theme';
import { Bar, Card, Dot, Label, Money, Rise, useRise } from './ui';

export const SCENE = 165; // 5.5 s
export const INTRO = 90;
export const OUTRO = 120;

/// Caption beside (landscape) or above (portrait) one product mock-up.
const Stage: React.FC<{ step: string; title: string; line: string;
  children: React.ReactNode }> = ({ step, title, line, children }) => {
  const { width, height, durationInFrames } = useVideoConfig();
  const frame = useCurrentFrame();
  const portrait = height > width;
  const out = interpolate(frame, [SCENE - 14, SCENE], [1, 0], {
    extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  void durationInFrames;
  return (
    <AbsoluteFill style={{ background: c.paper, fontFamily: font, color: c.ink,
      opacity: out, flexDirection: portrait ? 'column' : 'row', alignItems: 'center',
      justifyContent: 'center', gap: portrait ? 70 : 80,
      padding: portrait ? '110px 70px' : '0 100px' }}>
      <div style={{ width: portrait ? '100%' : 660, flex: 'none' }}>
        <Rise at={0}>
          <div style={{ fontSize: 24, fontWeight: 600, color: c.forest,
            letterSpacing: 2.5, textTransform: 'uppercase' }}>{step}</div>
        </Rise>
        <Rise at={5}>
          <div style={{ fontSize: portrait ? 84 : 76, fontWeight: 600, lineHeight: 1.06,
            letterSpacing: -2.2, margin: '18px 0 22px' }}>{title}</div>
        </Rise>
        <Rise at={11}>
          <div style={{ fontSize: portrait ? 36 : 32, lineHeight: 1.4, color: c.secondary }}>
            {line}</div>
        </Rise>
      </div>
      {/* zoom, not transform: the enlarged mock-up must take its real space. */}
      <div style={{ width: 800, flex: 'none', zoom: portrait ? 1.16 : 1.2 }}>{children}</div>
    </AbsoluteFill>
  );
};

const parts = [
  { name: 'Tetap', value: 3600000, color: c.forest },
  { name: 'Langganan', value: 358150, color: c.ink },
  { name: 'Tabungan', value: 2700000, color: c.sage },
  { name: 'Dana bergulir', value: 1500000, color: c.ochre },
  { name: 'Sisa', value: 841850, color: c.border },
];
const total = parts.reduce((s, p) => s + p.value, 0);

export const ScenePlan: React.FC = () => {
  const grow = useRise(40, 45);
  return (
    <Stage step="Rencana Bulanan" title="Lihat ke mana uang mengalir"
      line="Gaji, bonus, langganan, tabungan, dan dana bergulir dalam satu arus.">
      <Rise at={14}>
        <Card dark>
          <Label color={c.mist}>Dana tersedia</Label>
          <Money value={9000000} at={18} size={64} color="#fff" />
        </Card>
      </Rise>
      <Rise at={26} style={{ marginTop: 18 }}>
        <Card>
          <div style={{ fontSize: 26, fontWeight: 600, marginBottom: 18 }}>Arus alokasi</div>
          <div style={{ display: 'flex', gap: 5, height: 30 }}>
            {parts.map((p) => (
              <div key={p.name} style={{ width: `${(p.value / total) * grow * 100}%`,
                background: p.color, borderRadius: 9 }} />
            ))}
          </div>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: '14px 26px', marginTop: 24 }}>
            {parts.map((p, i) => (
              <Rise key={p.name} at={52 + i * 6} by={14}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                  <Dot color={p.color} />
                  <span style={{ fontSize: 22, fontWeight: 600 }}>{p.name}</span>
                  <span style={{ fontSize: 22, color: c.secondary,
                    fontVariantNumeric: 'tabular-nums' }}>{rupiah(p.value)}</span>
                </div>
              </Rise>
            ))}
          </div>
        </Card>
      </Rise>
    </Stage>
  );
};

const wallets = [
  { name: 'Dompet harian', mono: 'DH', color: '#00AED6', value: 850000 },
  { name: 'Tabungan utama', mono: 'TU', color: '#0060AF', value: 12500000 },
  { name: 'Uang transportasi', mono: 'UT', color: '#C8102E', value: 240000 },
];

export const SceneWallets: React.FC = () => (
  <Stage step="Dompet Digital" title="Semua saldo, satu tempat"
    line="Bank dan dompet digital punya kelompoknya sendiri, lengkap dengan pilihan cepat.">
    <Rise at={14}>
      <Card>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 12 }}>
          <div style={{ fontSize: 26, fontWeight: 600 }}>Dompet Digital</div>
          <Money value={13590000} at={22} size={26} />
        </div>
        {wallets.map((w, i) => (
          <Rise key={w.name} at={26 + i * 10} by={18}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 20, padding: '18px 0',
              borderTop: `1.5px solid ${c.border}` }}>
              <div style={{ width: 62, height: 62, borderRadius: 20, background: w.color,
                color: '#fff', fontSize: 24, fontWeight: 600, display: 'flex',
                alignItems: 'center', justifyContent: 'center' }}>{w.mono}</div>
              <div style={{ flex: 1, fontSize: 28, fontWeight: 600 }}>{w.name}</div>
              <Money value={w.value} at={32 + i * 10} size={28} />
            </div>
          </Rise>
        ))}
      </Card>
    </Rise>
    <Rise at={66} style={{ marginTop: 18, display: 'flex', gap: 12, flexWrap: 'wrap' }}>
      {['Dompet digital', 'Bank', 'Kartu', 'Tunai', 'Emas'].map((t, i) => (
        <span key={t} style={{ fontSize: 22, fontWeight: 600, padding: '12px 22px',
          borderRadius: 999, background: i === 0 ? c.ink : c.surface,
          color: i === 0 ? '#fff' : c.ink, border: `1.5px solid ${i === 0 ? c.ink : c.border}` }}>
          {t}</span>
      ))}
    </Rise>
  </Stage>
);

const marks: Record<number, string[]> = { 12: [c.forest, c.clay], 13: [c.clay], 20: [c.clay], 25: ['#53679A'] };

export const SceneCalendar: React.FC = () => {
  const pick = useRise(58, 16);
  return (
    <Stage step="Kalender tagihan" title="Tahu sebelum jatuh tempo"
      line="Tagihan berulang, utang, dan kartu tampil di satu kalender, dengan pengingat sehari sebelumnya.">
      <Rise at={14}>
        <Card>
          <div style={{ fontSize: 26, fontWeight: 600 }}>November 2026</div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', marginTop: 14,
            rowGap: 6 }}>
            {['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'].map((d) => (
              <div key={d} style={{ textAlign: 'center', fontSize: 18, fontWeight: 600,
                color: c.secondary, paddingBottom: 6 }}>{d}</div>
            ))}
            {Array.from({ length: 36 }, (_, i) => {
              const day = i - 5;
              if (day < 1 || day > 30) return <div key={i} />;
              const on = day === 12;
              return (
                <div key={i} style={{ height: 62, borderRadius: 16, display: 'flex',
                  flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
                  gap: 5, background: on ? `rgba(25,46,40,${pick})` : 'transparent',
                  color: on && pick > 0.5 ? '#fff' : c.ink }}>
                  <span style={{ fontSize: 22, fontWeight: marks[day] ? 600 : 400,
                    fontVariantNumeric: 'tabular-nums' }}>{day}</span>
                  <span style={{ display: 'flex', gap: 4, height: 8 }}>
                    {(marks[day] ?? []).map((m, k) => (
                      <span key={k} style={{ width: 8, height: 8, borderRadius: 8,
                        background: on && pick > 0.5 ? '#fff' : m }} />
                    ))}
                  </span>
                </div>
              );
            })}
          </div>
        </Card>
      </Rise>
      <Rise at={74} style={{ marginTop: 18 }}>
        <Card style={{ display: 'flex', alignItems: 'center', gap: 18 }}>
          <Dot color={c.clay} size={18} />
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 26, fontWeight: 600 }}>Internet rumah</div>
            <div style={{ fontSize: 20, color: c.ochre, fontWeight: 600 }}>Besok · tercatat otomatis</div>
          </div>
          <div style={{ fontSize: 26, fontWeight: 600, fontVariantNumeric: 'tabular-nums' }}>
            −{rupiah(350000)}</div>
        </Card>
      </Rise>
    </Stage>
  );
};

export const SceneLinks: React.FC = () => {
  const spent = useRise(46, 50);
  return (
    <Stage step="Rencana dan buku kas" title="Rencana bertemu kenyataan"
      line="Tautkan pos ke kategori: pengeluaran yang tercatat langsung tampil di samping rencananya.">
      <Rise at={14}>
        <Card>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
            <div style={{ fontSize: 30, fontWeight: 600 }}>Belanja dapur</div>
            <div style={{ fontSize: 30, fontWeight: 600, fontVariantNumeric: 'tabular-nums' }}>
              {rupiah(1000000)}</div>
          </div>
          <Label>Dana bergulir · dibawa ke bulan berikutnya</Label>
          <div style={{ background: c.paper, borderRadius: 20, padding: 22, marginTop: 20 }}>
            <div style={{ fontSize: 22, color: c.secondary, marginBottom: 12 }}>
              Buku kas: Dapur terpakai{' '}
              <b style={{ color: c.ink, fontWeight: 600 }}>{rupiah(640000 * spent)}</b>
              {' '}dari {rupiah(1000000)}
            </div>
            <Bar value={0.64} at={46} color={c.forest} height={14} />
          </div>
          <Rise at={84} by={12} style={{ marginTop: 22 }}>
            <span style={{ display: 'inline-flex', alignItems: 'center', gap: 12, fontSize: 24,
              fontWeight: 600, color: '#fff', background: c.forest, padding: '14px 26px',
              borderRadius: 999 }}>+ Catat transaksi</span>
          </Rise>
        </Card>
      </Rise>
      <Rise at={62} style={{ marginTop: 18 }}>
        <Card style={{ display: 'flex', alignItems: 'center', gap: 18 }}>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 24, fontWeight: 600 }}>Tujuan: Dana darurat</div>
            <div style={{ marginTop: 12 }}><Bar value={0.45} at={66} color={c.sage} /></div>
          </div>
          <div style={{ fontSize: 30, fontWeight: 600, color: c.forest }}>45%</div>
        </Card>
      </Rise>
    </Stage>
  );
};

const Mark: React.FC<{ size: number }> = ({ size }) => (
  <Img src={staticFile('brand_icons/wallet.svg')} style={{ width: size, height: size,
    borderRadius: size * 0.24 }} />
);

export const Intro: React.FC<{ line: string }> = ({ line }) => {
  const frame = useCurrentFrame();
  const out = interpolate(frame, [INTRO - 14, INTRO], [1, 0], {
    extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  return (
    <AbsoluteFill style={{ background: c.ink, color: '#fff', fontFamily: font, opacity: out,
      alignItems: 'center', justifyContent: 'center', textAlign: 'center', padding: 80 }}>
      <Rise at={0}><Mark size={150} /></Rise>
      <Rise at={8}>
        <div style={{ fontSize: 120, fontWeight: 600, letterSpacing: -4, marginTop: 30 }}>
          Wallet</div>
      </Rise>
      <Rise at={18}>
        <div style={{ fontSize: 40, color: c.mist, marginTop: 10, maxWidth: 900,
          lineHeight: 1.35 }}>{line}</div>
      </Rise>
    </AbsoluteFill>
  );
};

export const Outro: React.FC<{ line: string }> = ({ line }) => (
  <AbsoluteFill style={{ background: c.ink, color: '#fff', fontFamily: font,
    alignItems: 'center', justifyContent: 'center', textAlign: 'center', padding: 80 }}>
    <Rise at={0}><Mark size={120} /></Rise>
    <Rise at={8}>
      <div style={{ fontSize: 76, fontWeight: 600, letterSpacing: -2.4, marginTop: 34,
        maxWidth: 1000, lineHeight: 1.1 }}>{line}</div>
    </Rise>
    <Rise at={20}>
      <div style={{ fontSize: 36, color: c.sage, marginTop: 30, fontWeight: 600 }}>
        wallet.irsyads.com</div>
    </Rise>
  </AbsoluteFill>
);
