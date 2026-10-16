import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../domain/entities/day_schedule.dart';

/// Оверлей "Общее расписание": сетка дня — колонки групп, строки пар.
/// Масштабирование: щипок двумя пальцами на мобильных + колесо мыши
/// на десктопе (Listener ловит PointerScrollEvent и крутит матрицу
/// InteractiveViewer вручную — из коробки он зумит только щипком).
final class FullScheduleSheet extends StatefulWidget {
  final DateTime date;
  final List<DaySchedule> schedules;
  const FullScheduleSheet(
      {super.key, required this.date, required this.schedules});

  static Future<void> show(
      BuildContext context, DateTime date, Future<List<DaySchedule>> loader) {
    return showDialog(
      context: context,
      builder: (_) => FutureBuilder<List<DaySchedule>>(
        future: loader,
        builder: (_, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Dialog(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 12),
                    Text('Загрузка...'),
                  ],
                ),
              ),
            );
          }
          return FullScheduleSheet(
              date: date, schedules: snap.data ?? const []);
        },
      ),
    );
  }

  @override
  State<FullScheduleSheet> createState() => _FullScheduleSheetState();
}

final class _FullScheduleSheetState extends State<FullScheduleSheet> {
  final TransformationController _zoom = TransformationController();

  static const double _timeCol = 64;
  static const double _groupCol = 170;
  static const double _headerH = 36;
  static const double _rowH = 104;
  static const double _minScale = 0.5;
  static const double _maxScale = 4.0;

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  /// Зум колесом мыши вокруг курсора.
  void _onWheel(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    final factor = event.scrollDelta.dy > 0 ? 0.9 : 1.1;
    final current = _zoom.value.getMaxScaleOnAxis();
    final clamped = (current * factor).clamp(_minScale, _maxScale);
    final k = clamped / current;
    final focal = event.localPosition;
    final m = _zoom.value.clone()
      ..translateByDouble(focal.dx, focal.dy, 0, 1)
      ..scaleByDouble(k, k, k, 1)
      ..translateByDouble(-focal.dx, -focal.dy, 0, 1);
    setState(() => _zoom.value = m);
  }

  @override
  Widget build(BuildContext context) {
    final groups = widget.schedules;
    final maxRows =
        groups.map((g) => g.lessons.length).fold(0, (a, b) => a > b ? a : b);
    final width = _timeCol + _groupCol * groups.length.clamp(1, 99);
    final height = _headerH + _rowH * maxRows.clamp(1, 99);

    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: const BoxDecoration(
                color: AppColors.tealPale,
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(DateUtilsX.fullTitle(widget.date),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            if (groups.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Расписание не найдено'),
              )
            else
              Expanded(
                child: Listener(
                  onPointerSignal: _onWheel,
                  child: InteractiveViewer(
                    transformationController: _zoom,
                    constrained: false,
                    minScale: _minScale,
                    maxScale: _maxScale,
                    child: SizedBox(
                      width: width,
                      height: height,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _cell('', _timeCol, _headerH, header: true),
                              for (final g in groups)
                                _cell('Группа ${g.group ?? ''}',
                                    _groupCol, _headerH,
                                    header: true),
                            ],
                          ),
                          for (var r = 0; r < maxRows; r++)
                            Row(
                              children: [
                                _cell(_timeOf(groups, r), _timeCol, _rowH,
                                    header: true),
                                for (final g in groups)
                                  _cell(_lessonText(g, r), _groupCol, _rowH),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Время пары: берём из первой группы, у которой есть такая строка.
  static String _timeOf(List<DaySchedule> groups, int row) {
    for (final g in groups) {
      if (row < g.lessons.length) {
        final l = g.lessons[row];
        return '${l.startTime}\n${l.endTime}';
      }
    }
    return '';
  }

  static String _lessonText(DaySchedule g, int row) {
    if (row >= g.lessons.length) return '';
    final l = g.lessons[row];
    return '${l.subject}\n${l.teacher}\n${l.classroom}';
  }

  static Widget _cell(String text, double w, double h,
      {bool header = false}) {
    return Container(
      width: w,
      height: h,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: header ? AppColors.headerCell : Colors.white,
        border: Border.all(color: Colors.grey.shade400, width: 0.7),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: header ? 12 : 10,
            fontWeight: header ? FontWeight.w600 : FontWeight.normal),
        maxLines: 6,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Нижняя навигация из макета: две пилюли.
final class BottomPills extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const BottomPills({super.key, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                _pill('Просмотр расписания', 0),
                _pill('Избранное', 1),
              ],
            ),
          ),
        ),
      );

  Widget _pill(String label, int i) => Expanded(
        child: GestureDetector(
          onTap: () => onChanged(i),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color:
                  index == i ? AppColors.teal : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    color: index == i
                        ? Colors.white
                        : AppColors.tealDark)),
          ),
        ),
      );
}
