import React from 'react';
import { Easing, interpolate, staticFile, useCurrentFrame } from 'remotion';
import { c, emphasized, font, rupiah } from './theme';

export const Fonts: React.FC = () => (
  <style>{`
    @font-face { font-family: 'Plus Jakarta Sans'; font-weight: 400;
      src: url(${staticFile('brand_fonts/PlusJakartaSans-Regular.ttf')}) format('truetype'); }
    @font-face { font-family: 'Plus Jakarta Sans'; font-weight: 600;
      src: url(${staticFile('brand_fonts/PlusJakartaSans-SemiBold.ttf')}) format('truetype'); }
  `}</style>
);

const ease = Easing.bezier(...emphasized);

/// 0 → 1 over [from, from + over], eased like the app's entrances.
export const useRise = (from: number, over = 24) => {
  const f = useCurrentFrame();
  return interpolate(f, [from, from + over], [0, 1], {
    extrapolateLeft: 'clamp', extrapolateRight: 'clamp', easing: ease,
  });
};

export const Rise: React.FC<{ at: number; by?: number; children: React.ReactNode;
  style?: React.CSSProperties }> = ({ at, by = 28, children, style }) => {
  const t = useRise(at);
  return (
    <div style={{ opacity: t, transform: `translateY(${(1 - t) * by}px)`, ...style }}>
      {children}
    </div>
  );
};

export const Card: React.FC<{ children: React.ReactNode; dark?: boolean;
  style?: React.CSSProperties }> = ({ children, dark, style }) => (
  <div style={{
    background: dark ? c.ink : c.surface, color: dark ? '#fff' : c.ink,
    border: dark ? 'none' : `1.5px solid ${c.border}`, borderRadius: 28,
    padding: 28, boxSizing: 'border-box', ...style,
  }}>{children}</div>
);

export const Money: React.FC<{ value: number; at: number; size: number;
  color?: string }> = ({ value, at, size, color }) => {
  const t = useRise(at, 36);
  return (
    <div style={{ fontSize: size, fontWeight: 600, letterSpacing: -size * 0.025,
      fontVariantNumeric: 'tabular-nums', color, lineHeight: 1.1 }}>
      {rupiah(value * t)}
    </div>
  );
};

export const Bar: React.FC<{ value: number; at: number; color: string;
  track?: string; height?: number }> = ({ value, at, color, track = c.border, height = 12 }) => {
  const t = useRise(at, 30);
  return (
    <div style={{ height, borderRadius: height, background: track, overflow: 'hidden' }}>
      <div style={{ width: `${value * t * 100}%`, height: '100%', background: color,
        borderRadius: height }} />
    </div>
  );
};

export const Label: React.FC<{ children: React.ReactNode; color?: string;
  size?: number }> = ({ children, color = c.secondary, size = 20 }) => (
  <div style={{ fontSize: size, color, fontFamily: font }}>{children}</div>
);

export const Dot: React.FC<{ color: string; size?: number }> = ({ color, size = 14 }) => (
  <span style={{ display: 'inline-block', width: size, height: size, borderRadius: 4,
    background: color, flex: 'none' }} />
);
