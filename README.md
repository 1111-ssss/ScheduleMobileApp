# Расписание колледжа (schedule_app)

Flutter-приложение для просмотра расписания групп и преподавателей.
Внешний вид — по макетам из `demo_app_screenshots`.

## Запуск

```bash
flutter pub get
flutter run
```

Seed покрывает неделю **03.11–08.11.2025** — приложение стартует с неё,
чтобы сразу были данные. Стрелки у диапазона дат ходят по любым неделям
(пустые недели показывают «Расписание не найдено», как в макете).

Поведение вкладок:

- **Неделя** — дни разворачиваются/сворачиваются по нажатию на заголовок.
- **День** — чипы дней + только выбранная группа/преподаватель, таблица
  видна всегда (без сворачивания); при первом переходе открывается день
  недели, соответствующий сегодняшнему.
- **Избранное / День** — день выбирается один раз чипами сверху и
  применяется ко всем избранным сразу.
- **Общее расписание** — сетка «группы × пары» на выбранный день,
  зум колесом мыши и щипком на мобильных.

## Архитектура: Clean + SOLID, без внешних пакетов

```text
lib/
  core/            # тема, палитра, Failure, date-хелперы (без intl — YAGNI)
  domain/          # сущности + интерфейсы репозиториев + тонкие use case-ы
    entities/      # Lesson, DaySchedule, Favorite
    repositories/  # DirectoryRepository, ScheduleRepository, FavoritesRepository (ISP)
    usecases/      # GetGroups, GetGroupWeek, GetTeacherWeek, GetFullDay, ...
  data/            # реализации поверх абстракции ScheduleApi
    models/        # LessonDto, DayScheduleDto (+ toEntity)
    datasources/   # ScheduleApi (интерфейс), LocalJsonScheduleApi, HttpScheduleApi
    repositories/  # impl-репозитории + InMemoryFavoritesRepository
  presentation/
    state/         # AppDependencies (composition root), ScheduleController,
                   # FavoritesController (ChangeNotifier — KISS, без Bloc)
    screens/       # ScheduleView (Неделя/День), FavoritesView
    widgets/       # ScheduleTable, GroupScheduleCard, FilterBar, DayChips,
                   # AppMenuDrawer, AddFavoriteDialog, FullScheduleSheet, BottomPills
assets/seed/       # teachers.json, groups.json, group/teacher/full_schedules.json
```

Принципы:

- **DIP** — presentation зависит от `domain/repositories` (интерфейсы),
  data зависит от `ScheduleApi`. Контроллеры не знают про JSON/HTTP.
- **SRP / ISP** — узкие репозитории (`Directory` / `Schedule` / `Favorites`),
  один use case = одна задача, один виджет = один кусок макета.
- **OCP** — новый источник данных = новая реализация `ScheduleApi`, остальное
  не меняется.
- **DRY** — один `ScheduleTable` на просмотр/избранное/общее расписание,
  один `DaySchedule` на все эндпоинты `Schedule/*`, общий `_guard` ошибок.
- **KISS / YAGNI** — `ChangeNotifier` вместо Bloc, `dart:io HttpClient` вместо
  пакетов, строки `"X / Y"` для подгрупп вместо отдельной модели,
  избранное in-memory за интерфейсом (позже — SharedPreferences без смены API).

## Состояние между запусками (SharedPreferences)

Приложение запоминает и восстанавливает:

- режим отображения Группа/Преподаватель;
- последние выбранные специальность/группу/преподавателя (проверяются
  по свежим справочникам — пропавшие из API сбрасываются на первые доступные);
- режим День/Неделя **независимо** для страниц просмотра и избранного;
- последнюю открытую страницу (Просмотр/Избранное);
- весь список избранного.

Слой: `domain/entities/app_settings.dart` (`StoredState`) +
`domain/repositories/prefs_store.dart` (`PrefsStore`, гранулярные ключи —
каждый экран пишет только своё) + `data/repositories/shared_prefs_store.dart`
(`SharedPrefsStore`, `SharedPrefsFavoritesRepository`).
Старт асинхронный: `main()` ждёт `AppDependencies.create()`.

## API: как подключить реальный бэкенд

Контракт зафиксирован в `lib/data/datasources/schedule_api.dart`
и повторяет эндпоинты из ТЗ 1-в-1:

| Метод интерфейса | HTTP |
|---|---|
| `getTeachers()` | `GET /api/data/teachers` |
| `getGroups()` | `GET /api/data/groups` |
| `getTeacherWeek()` | `GET Schedule/teacher/week` |
| `getTeacherDay()` | `GET Schedule/teacher/day` |
| `getGroupDay()` | `GET Schedule/group/day` |
| `getGroupWeek()` | `GET Schedule/group/week` |
| `getFullSchedule()` | `GET Schedule` |

Переключение — одна строка в `presentation/state/app_scope.dart`:

```dart
// было:
ScheduleApi api = LocalJsonScheduleApi();
// станет:
ScheduleApi api = HttpScheduleApi(baseUrl: 'https://example.com');
```

Допущения (в ТЗ даны только пути, без query-параметров и схемы DTO):

1. Query-параметры: `?teacher=&from=yyyy-MM-dd&days=`, `?group=&date=` —
   правятся только в `http_schedule_api.dart`.
2. `DayScheduleDTO = {date, weekday, group?, teacher?, lessons[]}`,
   пара = `{order, startTime, endTime, subject, teacher, classroom}` —
   `fromJson` терпим к альтернативным ключам (`start_time`, `room`, `pairs`...).
   Подгруппы («Предмет / Предмет») — plain-строки, как в макете.

## Экраны (по макетам)

- **Просмотр**: шапка, фильтры (специальность/группа или поиск преподавателя),
  toggle Неделя/День, навигация по неделе + календарь. Неделя — секции дней
  с таблицами; День — чипы дней + карточки групп с кнопкой «Общее расписание».
- **Избранное**: «Добавить в избранное» (диалог Группа/Преподаватель),
  карточки целей с «Удалить», строки дней «Понедельник [03.11] · N пары».
- **Меню** (drawer): переключатель Группа/Преподаватель + подпись колледжа.
- Нижняя навигация-пилюли: Просмотр расписания / Избранное.
