import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/vehicle.dart';
import '../../state/app_scope.dart';

/// Kare araç görseli: kullanıcı fotoğrafı veya kategori ikonu.
class VehicleAvatar extends StatelessWidget {
  const VehicleAvatar({super.key, required this.vehicle, this.size = 56});

  final Vehicle vehicle;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.28);
    final photo = vehicle.photoPath;
    final fallback = _CategoryTile(vehicle: vehicle, size: size, radius: radius);
    if (photo == null) return fallback;
    final path = AppScope.read(context).photoStore.resolve(photo);
    return ClipRRect(
      borderRadius: radius,
      child: Image.file(
        File(path),
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: (size * 3).round(),
        errorBuilder: (context, error, stackTrace) => fallback,
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.vehicle, required this.size, required this.radius});

  final Vehicle vehicle;
  final double size;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3155), Color(0xFF0E192D)],
        ),
        border: Border.all(color: const Color(0x66FF7A1A)),
      ),
      child: Icon(vehicle.category.icon, color: AppColors.orange, size: size * 0.5),
    );
  }
}

/// Panel ve detay sayfasındaki geniş araç görseli.
class VehicleHeroArt extends StatelessWidget {
  const VehicleHeroArt({super.key, required this.vehicle, this.height = 150});

  final Vehicle vehicle;
  final double height;

  @override
  Widget build(BuildContext context) {
    final photo = vehicle.photoPath;
    final art = _GeneratedArt(vehicle: vehicle, height: height);
    if (photo == null) return art;
    final path = AppScope.read(context).photoStore.resolve(photo);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(path),
            fit: BoxFit.cover,
            cacheWidth: 1400,
            errorBuilder: (context, error, stackTrace) => art,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00060A12), Color(0xCC060A12)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GeneratedArt extends StatelessWidget {
  const _GeneratedArt({required this.vehicle, required this.height});

  final Vehicle vehicle;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -40,
            child: Container(
              width: height * 1.4,
              height: height * 1.4,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [Color(0x40FF7A1A), Color(0x00FF7A1A)]),
              ),
            ),
          ),
          Positioned(
            right: 24,
            bottom: 8,
            child: Icon(vehicle.category.icon, size: height * 0.72, color: const Color(0x2EFFFFFF)),
          ),
          Positioned(
            left: 20,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0x33FF7A1A),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0x66FF7A1A)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(vehicle.category.icon, size: 14, color: AppColors.orange),
                  const SizedBox(width: 6),
                  Text(
                    vehicle.category.label,
                    style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
