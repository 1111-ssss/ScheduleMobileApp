import 'dart:async';

import 'package:flutter/material.dart';

import 'presentation/state/app_scope.dart';
import 'presentation/state/favorites_controller.dart';
import 'presentation/state/schedule_controller.dart';
import 'presentation/screens/favorites_view.dart';
import 'presentation/screens/schedule_view.dart';
import 'presentation/widgets/menu_and_dialog.dart';
import 'presentation/widgets/overlays.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final deps = await AppDependencies.create();
  runApp(AppScope(deps: deps, child: const ScheduleApp()));
}

/// Корень приложения. Контроллеры создаются здесь один раз
/// и живут, пока живёт приложение (простейший DI без пакетов).
final class ScheduleApp extends StatefulWidget {
  const ScheduleApp({super.key});
  @override
  State<ScheduleApp> createState() => _ScheduleAppState();
}

final class _ScheduleAppState extends State<ScheduleApp> {
  late final ScheduleController schedule;
  late final FavoritesController favorites;
  late final AppDependencies _deps;
  int _tab = 0;
  bool _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_ready) {
      final deps = AppScope.of(context);
      _deps = deps;
      schedule = deps.scheduleController();
      favorites = deps.favoritesController();
      // Последняя открытая страница восстанавливается из настроек.
      _tab = deps.initial.tab.clamp(0, 1);
      // Scaffold (drawer с переключателем режима) сам контроллер не слушает,
      // поэтому обновляем его вручную — иначе selection в меню не переключится.
      schedule.addListener(_refresh);
      _ready = true;
      schedule.init();
      favorites.init();
    }
  }

  @override
  void dispose() {
    schedule.removeListener(_refresh);
    schedule.dispose();
    favorites.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  void _selectTab(int i) {
    setState(() => _tab = i);
    unawaited(_deps.prefs.saveTab(i));
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Расписание колледжа',
        theme: buildAppTheme(),
        home: _ready
            ? Scaffold(
                appBar: AppBar(
                  title: const Text('Расписание колледжа'),
                ),
                drawer: AppMenuDrawer(
                  isGroupMode: schedule.mode == ScheduleMode.group,
                  onModeChanged: (isGroup) => schedule.setMode(
                      isGroup ? ScheduleMode.group : ScheduleMode.teacher),
                ),
                body: _tab == 0
                    ? ScheduleView(
                        controller: schedule,
                        onOpenFavorites: () => _selectTab(1),
                      )
                    : FavoritesView(
                        controller: favorites,
                        schedule: schedule,
                      ),
                bottomNavigationBar: BottomPills(
                  index: _tab,
                  onChanged: _selectTab,
                ),
              )
            : const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
      );
}
