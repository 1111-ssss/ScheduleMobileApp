import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:schedule_app/data/repositories/shared_prefs_store.dart';
import 'package:schedule_app/main.dart';
import 'package:schedule_app/presentation/state/app_scope.dart';

void main() {
  test('SharedPrefsStore сохраняет и читает состояние', () async {
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    final store = SharedPrefsStore(sp);

    await store.saveMode(isGroupMode: false);
    await store.saveScheduleSelection(
        specialty: 'БуАиК', group: 'БУ11', teacher: 'Иванова И.И.');
    await store.saveScheduleWeekMode(false);
    await store.saveFavoritesWeekMode(true);
    await store.saveTab(1);

    final s = await store.load();
    expect(s.isGroupMode, isFalse);
    expect(s.specialty, 'БуАиК');
    expect(s.group, 'БУ11');
    expect(s.teacher, 'Иванова И.И.');
    expect(s.scheduleWeekMode, isFalse);
    expect(s.favoritesWeekMode, isTrue);
    expect(s.tab, 1);
  });

  testWidgets('Приложение стартует и показывает неделю группы', (t) async {
    SharedPreferences.setMockInitialValues({});
    final deps = await AppDependencies.create();
    await t.pumpWidget(AppScope(deps: deps, child: const ScheduleApp()));
    // Seed читается из assets настоящим I/O, поэтому даём загрузке время
    // вне fake-async: пока данные грузятся, на экране спиннер,
    // из-за которого pumpAndSettle без этого не дожидается контента.
    await t.runAsync(() => Future<void>.delayed(const Duration(seconds: 1)));
    await t.pumpAndSettle();

    expect(find.text('Расписание колледжа'), findsOneWidget);
    expect(find.textContaining('Понедельник'), findsWidgets);
  });
}
