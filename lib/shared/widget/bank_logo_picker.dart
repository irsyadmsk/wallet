import 'package:flutter/material.dart';
import 'package:financial_recording/shared/theme/app_colors.dart';
import 'package:financial_recording/shared/theme/app_spacing.dart';

const bankLogoAssets = <String>[
  'bca', 'mandiri', 'bri', 'bni', 'bank syariah indonesia', 'jago', 'cimb',
  'danamon', 'permata', 'panin', 'btn', 'bjb', 'bukopin', 'mega', 'maybank',
  'uob', 'ocbc', 'hsbc', 'citi', 'anz', 'digibank', 'standard chartered',
  'jenius', 'gopay', 'ovo', 'dana', 'linkaja', 'shopeepay', 'kredivo',
  'akulaku', 'homecredit', 'bareksa', 'bibit', 'pluang', 'visa',
  'mastercard', 'jcb', 'amex', 'paypal', 'applepay', 'gpay', 'flip',
  'xendit', 'midtrans', 'doku', 'uangku', 'paytren', 'cashbac', 'cashlez',
  'payfazz', 'paypro', 'dhuha', 'kudo', 'bluepay', 'bi',
];

String bankLogoPath(String key) => 'assets/icon_pack/bank_logo/$key.png';

/// Grid picker over the bundled bank/e-wallet logos, used when editing an
/// account. Selecting "Tanpa logo" clears [selected] back to null so the
/// account falls back to its plain color+icon avatar.
class BankLogoPicker extends StatelessWidget {
  const BankLogoPicker({super.key, required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _LogoTile(
            selected: selected == null,
            onTap: () => onSelected(null),
            child: const Icon(Icons.block, color: Color(0xFF8D99AD)),
          ),
          for (final key in bankLogoAssets)
            _LogoTile(
              selected: selected == bankLogoPath(key),
              onTap: () => onSelected(bankLogoPath(key)),
              // Cover, no padding: these assets are pre-rendered little
              // cards with their own flat background, so let each one fill
              // the tile edge to edge instead of floating inside a second,
              // differently-colored frame.
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.md - 1),
                child: SizedBox.expand(
                  child: Image.asset(bankLogoPath(key), fit: BoxFit.cover),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LogoTile extends StatelessWidget {
  const _LogoTile({required this.selected, required this.onTap, required this.child});
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: onTap,
        child: Container(
          width: 72,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF6F7F9),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: selected ? colors.primary : Colors.black.withValues(alpha: 0.06), width: selected ? 2 : 0.8),
            boxShadow: selected
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: child,
        ),
      ),
    );
  }
}
