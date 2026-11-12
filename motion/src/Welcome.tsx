import React from 'react';
import { AbsoluteFill, useCurrentFrame, useVideoConfig } from 'remotion';
import { c } from './theme';

/// A quiet, seamless loop for the welcome hero: currents of money drifting
/// one way. No text — the app lays its own wordmark and buttons on top, so
/// the picture stays dark and low-contrast behind them.
const lines = Array.from({ length: 16 }, (_, k) => {
  const r = (n: number) => {
    const x = Math.sin((k + 1) * 12.9898 + n * 78.233) * 43758.5453;
    return x - Math.floor(x);
  };
  return {
    base: 0.08 + (k / 15) * 0.84,
    amp: 0.025 + r(1) * 0.05,
    waves: 1 + Math.floor(r(2) * 3),
    // Whole cycles per loop, so the last frame meets the first.
    turns: 1 + Math.floor(r(3) * 2),
    phase: r(4) * Math.PI * 2,
    width: 1.5 + r(5) * 5,
    color: [c.forest, c.sage, c.honey, c.mist][Math.floor(r(6) * 4)],
    alpha: 0.16 + r(7) * 0.3,
  };
});

export const Welcome: React.FC = () => {
  const frame = useCurrentFrame();
  const { width, height, durationInFrames } = useVideoConfig();
  const t = frame / durationInFrames;
  const steps = 160;
  return (
    <AbsoluteFill style={{ background: c.deep }}>
      <AbsoluteFill style={{
        background: `radial-gradient(60% 70% at ${50 + 14 * Math.sin(2 * Math.PI * t)}% ${
          46 + 8 * Math.cos(2 * Math.PI * t)}%, rgba(12,108,88,0.55), rgba(15,31,27,0) 70%)`,
      }} />
      <svg width={width} height={height} viewBox={`0 0 ${width} ${height}`}>
        {lines.map((l, k) => {
          let d = '';
          for (let i = 0; i <= steps; i++) {
            const x = i / steps;
            const y = l.base
              + l.amp * Math.sin(2 * Math.PI * (l.waves * x - l.turns * t) + l.phase)
              + l.amp * 0.4 * Math.sin(2 * Math.PI * (2 * l.waves * x + l.turns * t) + l.phase * 1.7);
            d += `${i === 0 ? 'M' : 'L'}${(x * width).toFixed(1)},${(y * height).toFixed(1)}`;
          }
          return <path key={k} d={d} fill="none" stroke={l.color} strokeOpacity={l.alpha}
            strokeWidth={l.width} strokeLinecap="round" />;
        })}
      </svg>
      <AbsoluteFill style={{
        background: 'linear-gradient(180deg, rgba(15,31,27,0.55) 0%, rgba(15,31,27,0.05) 35%, rgba(15,31,27,0.7) 100%)',
      }} />
    </AbsoluteFill>
  );
};
