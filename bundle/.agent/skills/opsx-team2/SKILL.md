---
name: opsx-team2
description: >-
  Multi-agent OpenSpec implementation for all open changes via TDD with the
  OpenCode Go model routing matrix. Detects file/capability conflicts, automatically
  skips any change marked with STOP or СТОП, routes changes to backend
  (DeepSeek V4 Pro), frontend (Qwen3.7 Plus / MiniMax M3), and fast test-fix
  (DeepSeek V4 Flash / GLM-5.3-Flash) subagents, then coordinates code review,
  e2e tests, and final status. Use when applying multiple OpenSpec changes,
  opsx-team2, team apply, or parallel opsx-apply.
---

# opsx-team2 — мультиагентная реализация OpenSpec (OpenCode Go routing)

Координатор (основной агент) реализует открытые changes из `openspec/changes/` (кроме `archive/` и изменений с маркером **STOP / СТОП**). Модель координатора — базовая модель основного окна (`opencode-go/gpt-5.6-luna` или `opencode-go/glm-5.2`) и **не меняется**.

Реализация каждого change **всегда** выполняется через субагента (tier-маршрутизация OpenCode Go), даже если задача мелкая — координатор сам код не пишет.

## Роутинг моделей (матрица OpenCode Go)

| Роль | Субагент | Модель | Назначение |
|------|----------|--------|------------|
| Бэкенд + TDD | `opsx2-worker-backend` | `opencode-go/deepseek-v4-pro` (фолбек `opencode-go/minimax-m3`) | Бэкенд-логика, сложный TDD-цикл (Red-Green-Refactor), схемы БД, API-контракты |
| Фронтенд + UI | `opsx2-worker-front` | `opencode-go/qwen3.7-plus` (или `opencode-go/minimax-m3`) | UI-компоненты, стили, клиентские типы/хуки, интеграция API |
| Быстрый TDD-цикл | `opsx2-test-runner` | `opencode-go/glm-5.3-flash` (фолбек `opencode-go/deepseek-v4-flash`) | Прогон `npm test`/`pytest`/`cargo test`, локализация упавших ассертов, мелкий фикс синтаксиса |

Выбор субагента для change (по маркерам в названии/содержимом):

| Условие | Субагент |
|---------|----------|
| В названии change есть `фронт` / `front` / `ui` / `ui-` (и т.п. маркеры фронтенд-задачи) | `opsx2-worker-front` |
| В названии change есть `бэк` / `back` / `backend` / `api` / `db` / `schema` / `core` (и т.п. бэкенд-маркеры) | `opsx2-worker-backend` |
| Все остальные changes (по умолчанию) | `opsx2-worker-backend` |

После реализации — если требуется итеративный прогон/фикс упавших тестов без архитектурных правок — координатор делегирует `opsx2-test-runner`.

Определения субагентов: `.opencode/agent/opsx2-worker-backend.md`, `.opencode/agent/opsx2-worker-front.md`, `.opencode/agent/opsx2-test-runner.md`.

## Предусловия

1. Прочитать `.agent/skills/openspec-apply-change/SKILL.md` и `.agent/skills/tdd/SKILL.md`.
2. Следовать `AGENTS.md`: capability-заголовки в owner-файлах и строгие правила агентов.
3. **Строгий фильтр STOP / СТОП**: любые changes, содержащие слово `STOP` или `СТОП` (в любом регистре: `STOP`, `СТОП`, `[STOP]`, `stop`, `стоп` и т.д.) в названии папки/change, в `proposal.md` или `tasks.md`, либо дисклеймер о запрете автоматической реализации, считаются замороженными/отложенными. Их **категорически запрещено** брать в работу.

## Фаза 1: Инвентаризация

```bash
openspec list --json
```

Для каждого активного change (не в archive):

1. **Проверка STOP / СТОП (СТОП-фильтр)**:
   - Проверить имя change на наличие `STOP` или `СТОП` (case-insensitive).
   - Проверить файлы `proposal.md` и `tasks.md` change на наличие слова `STOP`, `СТОП` или явного дисклеймера о запрете автоматической реализации.
   - **Если маркер STOP / СТОП обнаружен**: change **НЕМЕДЛЕННО ИСКЛЮЧАЕТСЯ** из дальнейшей работы. Не запрашивать для него apply instructions, не включать в конфликтный анализ Фазы 2, не запускать subagent. В итоговый отчёт занести в список пропущенных `Changes skipped (STOP / СТОП)`.

2. Для изменений, прошедших фильтр:
```bash
openspec status --change "<name>" --json
openspec instructions apply --change "<name>" --json
```

Собрать:
- список pending tasks;
- множество файлов из proposal/design/tasks;
- затронутые capabilities.

## Фаза 2: Анализ конфликтов

Построить матрицу пересечений файлов между changes.

| Условие | Стратегия |
|---------|-----------|
| Нет общих файлов и нет зависимости по данным/API | **Параллельно** — по одному subagent на change |
| Есть общие файлы или одна change зависит от другой | **Последовательно** — порядок: меньше файлов / foundation first |
| Неясно | Спросить пользователя |

Зафиксировать решение:

```text
## Conflict analysis
- Changes: [list]
- Overlap: none | files: [...] | capability: [...]
- Strategy: parallel | sequential (order: A → B)
```

## Фаза 3: Распределение работы

### Параллельный режим

Запустить **одновременно** (один message, несколько Task), выбирая `subagent_type` по таблице роутинга моделей:

```
Task(subagent_type=opsx2-worker-front):    opsx-apply <change-A>   # фронтенд-задача
Task(subagent_type=opsx2-worker-backend):  opsx-apply <change-B>   # бэкенд/остальные
```

Каждый subagent получает:
- полный prompt с change name, contextFiles, tasks;
- инструкцию следовать TDD (RED → GREEN → REFACTOR);
- запрет трогать файлы других changes;
- отметку tasks `- [x]` по завершении каждой задачи.

### Последовательный режим

Запускать subagents по одному. Следующий стартует только после GREEN-тестов предыдущего.

## Фаза 4: TDD для каждого change

На **каждую** задачу с изменением поведения:

1. **RED** — один сфокусированный тест, `python3 -m pytest path::test -q` (или соответствующий раннер проекта)
2. **GREEN** — минимальная реализация
3. **REFACTOR** — при необходимости, тесты зелёные

Исключения: чистый HTML/CSS без логики, конфиг-словари без поведения — тест после интеграции.

Subagent отчитывается циклами:

```text
### TDD cycle: <behavior>
- RED / GREEN / REFACTOR
- Tests run: <command>
```

Если в процессе нужен итеративный прогон упавших тестов — координатор делегирует `opsx2-test-runner`.

## Фаза 5: Синхронизация (координатор)

После завершения всех subagents:

1. `git status` — проверить неожиданные конфликты
2. `python3 -m pytest` — полный прогон
3. `openspec validate --changes` — валидация артефактов
4. E2E (если есть): advisor endpoint, chat billing, `/v1/models`

При падениях — координатор чинит через `opsx2-test-runner` или перезапускает затронутый change.

## Фаза 6: Code review

Координатор проводит review всего diff:

- [ ] Соответствие spec delta и design
- [ ] CAPABILITY/SPEC заголовки в owner-файлах
- [ ] TDD: тесты покрывают новое поведение
- [ ] Нет scope creep
- [ ] Tasks.md: все пункты `[x]`

Критичные замечания — исправить до финального отчёта.

## Фаза 7: Итоговый статус

```markdown
## opsx-team2: Final Status

### Changes applied
| Change | Tasks | Strategy | Tests |

### Changes skipped (STOP / СТОП)
| Change | Reason |
|--------|--------|

### Conflict analysis
<strategy and rationale>

### Code review
- Critical: ...
- Suggestions: ...

### Verification
- pytest: pass/fail
- openspec validate: pass/fail
- e2e: ...

### Next steps
- `/opsx-archive <name>` для завершённых changes
```

## Guardrails

- **СТОП-фильтр (железное правило)**: Координатор и субагенты **никогда не берут в работу** changes со словом `STOP` или `СТОП` (в любом регистре) в названии папки, заголовках или тексте артефактов (`proposal.md`, `tasks.md`, `design.md`), либо с дисклеймерами о запрете автоматической реализации. Даже если change не в `archive/`, он безусловно пропускается.
- Координатор **не** дублирует работу subagents — только конфликты, review, финальные тесты.
- Tier-модели не перерасходуются на рутину: тяжёлые `deepseek-v4-pro`/`qwen3.7-plus` — на реализацию, `deepseek-v4-flash`/`glm-5.3-flash` — на прогон/фикс тестов.
- Subagents **не** коммитят без явного запроса пользователя.
- При блокере subagent → координатор решает или эскалирует пользователю.
- Удалённые/untracked файлы вне scope change — не трогать без явного указания.
