import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/favorite.dart';

/// Боковое меню из макета: переключатель Группа/Преподаватель + подпись колледжа.
final class AppMenuDrawer extends StatelessWidget {
  final bool isGroupMode;
  final ValueChanged<bool> onModeChanged;
  const AppMenuDrawer(
      {super.key, required this.isGroupMode, required this.onModeChanged});

  @override
  Widget build(BuildContext context) => Drawer(
        width: 250,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
              color: AppColors.teal,
              child: const Text('Меню',
                  style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.tealPale.withAlpha(160),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Отображение расписания для:',
                        style: TextStyle(fontSize: 13)),
                    const SizedBox(height: 8),
                    _ModeTile(
                      label: 'Группа',
                      selected: isGroupMode,
                      onTap: () {
                        onModeChanged(true);
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 6),
                    _ModeTile(
                      label: 'Преподаватель',
                      selected: !isGroupMode,
                      onTap: () {
                        onModeChanged(false);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.school, color: AppColors.tealDark),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'ПОЛОЦКИЙ ГОСУДАРСТВЕННЫЙ ЭКОНОМИЧЕСКИЙ КОЛЛЕДЖ',
                      style: TextStyle(
                          fontSize: 10,
                          color: AppColors.tealDark,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

final class _ModeTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeTile(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.teal,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500)),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.grey.shade400,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ],
          ),
        ),
      );
}

/// Диалог "Добавить в избранное" из макета: табы Группа/Преподаватель.
final class AddFavoriteDialog extends StatefulWidget {
  final List<String> specialties;
  final String? initialSpecialty;
  final List<String> groups;
  final List<String> teachers;
  const AddFavoriteDialog({
    super.key,
    required this.specialties,
    required this.initialSpecialty,
    required this.groups,
    required this.teachers,
  });

  @override
  State<AddFavoriteDialog> createState() => _AddFavoriteDialogState();
}

final class _AddFavoriteDialogState extends State<AddFavoriteDialog> {
  late bool _groupTab = true;
  late String? _specialty = widget.initialSpecialty;
  String? _group;
  String? _teacher;

  @override
  Widget build(BuildContext context) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.teal,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Row(
                children: [
                  _Tab(
                      label: 'Группа',
                      active: _groupTab,
                      onTap: () => setState(() => _groupTab = true)),
                  _Tab(
                      label: 'Преподаватель',
                      active: !_groupTab,
                      onTap: () => setState(() => _groupTab = false)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: _groupTab ? _groupForm() : _teacherForm(),
            ),
          ],
        ),
      );

  Widget _groupForm() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Lbl('Специальность'),
          _Box(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: const Text('Выберите специальность',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                value: _specialty,
                items: [
                  for (final s in widget.specialties)
                    DropdownMenuItem(value: s, child: Text(s)),
                ],
                onChanged: (v) =>
                    setState(() { _specialty = v; _group = null; }),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const _Lbl('Группа'),
          _Box(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: const Text('Выберите группу',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                value: _group,
                items: [
                  for (final g in widget.groups)
                    DropdownMenuItem(value: g, child: Text(g)),
                ],
                onChanged: (v) => setState(() => _group = v),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _Submit(
            enabled: _group != null,
            onTap: () => Navigator.pop(
                context,
                Favorite(
                    id: 'g:$_group',
                    kind: FavoriteKind.group,
                    specialty: _specialty,
                    group: _group)),
          ),
        ],
      );

  Widget _teacherForm() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Lbl('Преподаватель'),
          _Box(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: const Text('Выберите преподавателя',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                value: _teacher,
                items: [
                  for (final t in widget.teachers)
                    DropdownMenuItem(value: t, child: Text(t)),
                ],
                onChanged: (v) => setState(() => _teacher = v),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _Submit(
            enabled: _teacher != null,
            onTap: () => Navigator.pop(
                context,
                Favorite(
                    id: 't:$_teacher',
                    kind: FavoriteKind.teacher,
                    teacher: _teacher)),
          ),
        ],
      );
}

final class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(label,
              style: TextStyle(
                  color: active ? AppColors.tealDark : Colors.white,
                  fontWeight: FontWeight.w600)),
        ),
      );
}

final class _Lbl extends StatelessWidget {
  final String text;
  const _Lbl(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.tealDark,
                fontWeight: FontWeight.w600)),
      );
}

final class _Box extends StatelessWidget {
  final Widget child;
  const _Box({required this.child});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.teal.withAlpha(140)),
        ),
        child: child,
      );
}

final class _Submit extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;
  const _Submit({required this.enabled, required this.onTap});
  @override
  Widget build(BuildContext context) => ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: const Text('Добавить в избранное'),
      );
}
