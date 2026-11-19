import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../theme.dart';
import 'exercise_screen.dart';

const _levels = ['مبتدئ', 'متوسط', 'متقدم'];

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<Exercise> _all = const [];
  List<String> _muscles = const [];
  List<String> _equipment = const [];
  bool _loading = true;

  String _query = '';
  String? _muscle;
  String? _equip;
  String? _level;

  @override
  void initState() {
    super.initState();
    ExerciseRepo.load().then((list) {
      final muscles = <String>{for (final e in list) ...e.primary}.toList()
        ..sort();
      final equipment = <String>{
        for (final e in list)
          if (e.equipment != null) e.equipment!
      }.toList()
        ..sort();
      if (!mounted) return;
      setState(() {
        _all = list;
        _muscles = muscles;
        _equipment = equipment;
        _loading = false;
      });
    });
  }

  List<Exercise> get _filtered {
    final q = _query.trim().toLowerCase();
    return _all.where((e) {
      if (_muscle != null && !e.primary.contains(_muscle)) return false;
      if (_equip != null && e.equipment != _equip) return false;
      if (_level != null && e.level != _level) return false;
      if (q.isEmpty) return true;
      return e.nameAr.toLowerCase().contains(q) ||
          e.nameEn.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return Scaffold(
      body: SpaceBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(items.length),
              _searchField(),
              const SizedBox(height: 10),
              _muscleChips(),
              _dropdowns(),
              Expanded(child: _list(items)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset('assets/app_icon.png', width: 46, height: 46),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'مساعد الجم',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              Text(
                _loading ? 'جاري التحميل...' : '$count تمرين',
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        onChanged: (v) => setState(() => _query = v),
        decoration: InputDecoration(
          hintText: 'ابحث عن تمرين (عربي أو إنكليزي)...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.08),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _muscleChips() {
    final options = <String?>[null, ..._muscles];
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final m = options[i];
          final selected = _muscle == m;
          return ChoiceChip(
            label: Text(m ?? 'كل العضلات'),
            selected: selected,
            showCheckmark: false,
            selectedColor: AppColors.purple.withValues(alpha: 0.55),
            backgroundColor: Colors.white.withValues(alpha: 0.06),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
            onSelected: (_) => setState(() => _muscle = m),
          );
        },
      ),
    );
  }

  Widget _dropdowns() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Row(
        children: [
          Expanded(
            child: _FilterButton(
              icon: Icons.fitness_center,
              label: 'الأداة',
              value: _equip,
              options: _equipment,
              onChanged: (v) => setState(() => _equip = v),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _FilterButton(
              icon: Icons.bar_chart,
              label: 'المستوى',
              value: _level,
              options: _levels,
              onChanged: (v) => setState(() => _level = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(List<Exercise> items) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (items.isEmpty) {
      return const Center(
        child: Text('ماكو تمارين بهالبحث',
            style: TextStyle(color: AppColors.muted)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _ExerciseCard(items[i]),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const _FilterButton({
    required this.icon,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: const Color(0xFF1C1530),
      onSelected: (v) => onChanged(v.isEmpty ? null : v),
      itemBuilder: (_) => [
        PopupMenuItem(value: '', child: Text('كل $label')),
        for (final o in options) PopupMenuItem(value: o, child: Text(o)),
      ],
      child: Glass(
        radius: 14,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: value == null ? AppColors.muted : AppColors.pink),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value ?? label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: value == null ? AppColors.muted : AppColors.text,
                ),
              ),
            ),
            const Icon(Icons.expand_more, size: 18, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final Exercise e;
  const _ExerciseCard(this.e);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ExerciseScreen(exercise: e)),
        ),
        child: Glass(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 78,
                  height: 78,
                  child: e.images.isEmpty
                      ? const _ImagePlaceholder()
                      : CachedNetworkImage(
                          imageUrl: e.images.first,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const _ImagePlaceholder(),
                          errorWidget: (_, __, ___) =>
                              const _ImagePlaceholder(),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.nameAr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      e.nameEn,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (e.primary.isNotEmpty) Tag(e.primary.first),
                        if (e.level != null)
                          Tag(e.level!, color: AppColors.pink),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withValues(alpha: 0.08),
      child: const Icon(Icons.fitness_center, color: AppColors.muted),
    );
  }
}
