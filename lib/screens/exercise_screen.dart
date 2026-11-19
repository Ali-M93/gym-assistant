import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../theme.dart';

class ExerciseScreen extends StatefulWidget {
  final Exercise exercise;
  const ExerciseScreen({super.key, required this.exercise});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  Timer? _timer;
  int _frame = 0;
  bool _showEnglish = false;

  Exercise get e => widget.exercise;

  @override
  void initState() {
    super.initState();
    // Alternate between the start/end photos so the movement is visible.
    if (e.images.length > 1) {
      _timer = Timer.periodic(const Duration(milliseconds: 900), (_) {
        setState(() => _frame = (_frame + 1) % e.images.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tags = [e.level, e.equipment, e.category, e.mechanic, e.force]
        .whereType<String>()
        .toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SpaceBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _photos(),
              const SizedBox(height: 16),
              Text(
                e.nameAr,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              Text(
                e.nameEn,
                style: const TextStyle(fontSize: 14, color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < tags.length; i++)
                    Tag(tags[i],
                        color: i.isEven ? AppColors.purple : AppColors.pink),
                ],
              ),
              const SizedBox(height: 20),
              const _SectionTitle('العضلات'),
              Glass(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _muscleRow('أساسية', e.primary, AppColors.pink),
                    if (e.secondary.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _muscleRow('مساندة', e.secondary, AppColors.purple),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const _SectionTitle('طريقة الأداء'),
              _steps(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photos() {
    if (e.images.isEmpty) {
      return const Glass(
        child: SizedBox(
          height: 160,
          child: Center(
            child: Icon(Icons.fitness_center, size: 48, color: AppColors.muted),
          ),
        ),
      );
    }
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: ColoredBox(
              color: Colors.white,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  for (var i = 0; i < e.images.length; i++)
                    AnimatedOpacity(
                      opacity: i == _frame ? 1 : 0,
                      duration: const Duration(milliseconds: 350),
                      child: CachedNetworkImage(
                        imageUrl: e.images[i],
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                        errorWidget: (_, __, ___) => const Center(
                          child: Icon(Icons.wifi_off, color: Colors.black38),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (e.images.length > 1)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'الصور تتبدل حتى توضح الحركة',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ),
      ],
    );
  }

  Widget _muscleRow(String label, List<String> muscles, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 62,
          child: Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        ),
        Expanded(child: Text(muscles.isEmpty ? '—' : muscles.join('، '))),
      ],
    );
  }

  Widget _steps() {
    final steps = _showEnglish ? e.stepsEn : e.stepsAr;
    if (e.stepsAr.isEmpty) {
      return const Glass(
        child: Text('ماكو خطوات مكتوبة لهذا التمرين، اعتمد على الصور.',
            style: TextStyle(color: AppColors.muted)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Glass(
          child: Directionality(
            textDirection:
                _showEnglish ? TextDirection.ltr : TextDirection.rtl,
            child: Column(
              children: [
                for (var i = 0; i < steps.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                        bottom: i == steps.length - 1 ? 0 : 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 13,
                          backgroundColor: AppColors.purple,
                          child: Text('${i + 1}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(steps[i],
                              style: const TextStyle(height: 1.6)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (e.stepsEn.isNotEmpty)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () => setState(() => _showEnglish = !_showEnglish),
              child: Text(_showEnglish ? 'رجوع للعربي' : 'عرض النص الإنكليزي'),
            ),
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.pink,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(text,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
