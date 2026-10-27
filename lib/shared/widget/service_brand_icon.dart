import 'package:flutter/material.dart';

/// Local, offline service identities from the shared Irsyads icon family.
class ServiceBrandIcon extends StatelessWidget {
  const ServiceBrandIcon({
    super.key,
    required this.service,
    this.size = 40,
    this.label,
  });
  final String service;
  final double size;
  final String? label;
  static const _aliases = {
    'ruang': 'toolkit',
    'masjidku': 'mosque',
    'apma': 'lessoncraft',
    'hadis': 'hadith',
  };
  static const _known = {
    'site',
    'wallet',
    'id',
    'academy',
    'studio',
    'library',
    'toolkit',
    'curriculum',
    'lessoncraft',
    'mosque',
    'letters',
    'verify',
    'cbt',
    'smart',
    'upload',
    'nota',
    'quran',
    'hadith',
  };
  static String? assetFor(String service) {
    final id = _aliases[service] ?? service;
    return _known.contains(id) ? 'assets/brand_icons/services/$id.png' : null;
  }

  @override
  Widget build(BuildContext context) {
    final asset = assetFor(service);
    if (asset == null) {
      return Icon(Icons.apps_outlined, size: size, semanticLabel: label);
    }
    return Image.asset(
      asset,
      width: size,
      height: size,
      semanticLabel: label,
      excludeFromSemantics: label == null,
    );
  }
}
