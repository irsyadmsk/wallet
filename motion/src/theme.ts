// Mirrors lib/shared/theme/app_colors.dart (Wallet / ARUS refresh).
export const c = {
  paper: '#F5F6F0',
  surface: '#FFFFFF',
  border: '#E1E6DC',
  ink: '#192E28',
  deep: '#0F1F1B',
  secondary: '#54645C',
  forest: '#0C6C58',
  sage: '#86B6A9',
  ochre: '#9C6F1C',
  honey: '#D9A441',
  clay: '#B4452A',
  mist: '#C8D6CF',
};

export const font = "'Plus Jakarta Sans', system-ui, sans-serif";
export const fps = 30;

/// cubic-bezier(0.16, 1, 0.3, 1) — AppMotion.emphasized.
export const emphasized = [0.16, 1, 0.3, 1] as const;

const idr = new Intl.NumberFormat('id-ID');
/// Synthetic figures only; never a real budget.
export const rupiah = (n: number) => `Rp ${idr.format(Math.round(n))}`;
