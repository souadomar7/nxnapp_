import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

ImageProvider? getMarketplaceImageProvider(String? imagePath) {
  if (imagePath == null) return null;
  final clean = imagePath.trim();
  if (clean.isEmpty) return null;

  // Base64 Data URI or raw Base64
  if (clean.startsWith('data:image/') && clean.contains('base64,')) {
    try {
      final b64 = clean.split('base64,').last.replaceAll('\n', '').replaceAll('\r', '').trim();
      final bytes = base64Decode(b64);
      return MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }

  // Network URL
  if (clean.startsWith('http://') || clean.startsWith('https://')) {
    return NetworkImage(clean);
  }

  // Local File path
  if (clean.startsWith('/') || clean.startsWith('file://')) {
    final filePath = clean.startsWith('file://') ? clean.substring(7) : clean;
    final file = File(filePath);
    if (file.existsSync()) {
      return FileImage(file);
    }
  }

  // Raw base64 string without data: prefix
  if (clean.length > 100 && !clean.contains(' ') && !clean.contains('/')) {
    try {
      final bytes = base64Decode(clean);
      return MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }

  return null;
}

class MarketplaceImage extends StatelessWidget {
  final String? imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final IconData defaultIcon;

  const MarketplaceImage({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.defaultIcon = Icons.inventory_2_outlined,
  });

  @override
  Widget build(BuildContext context) {
    Widget buildPlaceholder() {
      return placeholder ??
          Center(
            child: Icon(
              defaultIcon,
              size: (width != null && width! < 60) ? 24 : 36,
              color: Colors.grey.shade400,
            ),
          );
    }

    if (imagePath == null || imagePath!.trim().isEmpty) {
      return buildPlaceholder();
    }

    final clean = imagePath!.trim();
    Widget imageWidget;

    if (clean.startsWith('data:image/') && clean.contains('base64,')) {
      try {
        final b64 = clean.split('base64,').last.replaceAll('\n', '').replaceAll('\r', '').trim();
        final bytes = base64Decode(b64);
        imageWidget = Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => buildPlaceholder(),
        );
      } catch (_) {
        imageWidget = buildPlaceholder();
      }
    } else if (clean.startsWith('http://') || clean.startsWith('https://')) {
      imageWidget = Image.network(
        clean,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => buildPlaceholder(),
      );
    } else if (clean.startsWith('/') || clean.startsWith('file://')) {
      final filePath = clean.startsWith('file://') ? clean.substring(7) : clean;
      final file = File(filePath);
      if (file.existsSync()) {
        imageWidget = Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => buildPlaceholder(),
        );
      } else {
        imageWidget = buildPlaceholder();
      }
    } else {
      try {
        final bytes = base64Decode(clean);
        imageWidget = Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => buildPlaceholder(),
        );
      } catch (_) {
        imageWidget = buildPlaceholder();
      }
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
