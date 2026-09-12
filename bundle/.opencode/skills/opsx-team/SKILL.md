---
name: opsx-team
description: >-
  Multi-agent OpenSpec implementation for all open changes via TDD. Detects
  file/capability conflicts, automatically skips any change marked with STOP or СТОП,
  runs parallel subagents when safe or sequential when not, then coordinates code
  review, e2e tests, and final status. Use when applying multiple OpenSpec changes,
  opsx-team, team apply, or parallel opsx-apply.
---

# opsx-team — мультиагентная реализация OpenSpec

Координатор (основной агент) реализует открытые changes из `openspec/changes/` (кроме `archive/` и изменений с маркером **STOP / СТОП**).

## Предусловия

1. Прочитать `.opencode/skills/openspec-apply-change/SKILL.md` и `.opencode/skills/tdd/SKILL.md`.
2. Следовать `AGENTS.md`: capability-заголовки в owner-файлах и строгие правила агентов.
3. **Строгий фильтр STOP / СТОП**: любые changes, содержащие слово `STOP` или `СТОП` (в любом регистре: `STOP`, `СТОП`, `[STOP]`, `stop`, `стоп` и т.д.) в названии папки/change, в `proposal.md` или `tasks.md`, либо дисклеймер о запрете автоматической реализации, считаются замороженными/отложенными. Их **категорически запрещено** брать в работу.

## Роутинг моделей

Координатор **всегда** работает на базовой модели основного агентного окна — модель координатора не меняется.

Реализация каждого change **всегда** выполняется через субагента, даже если задача мелкая (одна правка) — координатор сам код не пишет.

Выбор субагента для каждого change:

| Условие | Субагент | Модель |
|---------|----------|--------|
| В названии change есть `фронт` / `front` / `ui` (и т.п. маркеры фронтенд-задачи) | `opsx-worker-front` | Kimi K3 (`opencode-go/kimi-k3`) |
| Все остальные changes (по умолчанию) | `opsx-worker` | GLM-5.3 Flash (`opencode-go/glm-5.3-flash`) |

Определения субагентов: `.opencode/agent/opsx-worker-front.md` и `.opencode/agent/opsx-worker.md`.

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
Task(subagent_type=opsx-worker-front): opsx-apply <change-A>   # фронтенд-задача
Task(subagent_type=opsx-worker):       opsx-apply <change-B>   # остальные
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

1. **RED** — один сфокусированный тест, `python3 -m pytest path::test -q`
2. **GREEN** — минимальная реализация
3. **REFACTOR** — при необходимости, тесты зелёные

Исключения: чистый HTML/CSS без логики, конфиг-словари без поведения — тест после интеграции.

Subagent отчитывается циклами:

```text
### TDD cycle: <behavior>
- RED / GREEN / REFACTOR
- Tests run: <command>
```

## Фаза 5: Синхронизация (координатор)

После завершения всех subagents:

1. `git status` — проверить неожиданные конфликты
2. `python3 -m pytest` — полный прогон
3. `openspec validate --changes` — валидация артефактов
4. E2E (если есть): advisor endpoint, chat billing, `/v1/models`

При падениях — координатор чинит или перезапускает затронутый change.

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
## opsx-team: Final Status

### Changes applied
| Change | Tasks | Strategy | Tests |
|--------|-------|----------|-------|

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
- Subagents **не** коммитят без явного запроса пользователя.
- При блокере subagent → координатор решает или эскалирует пользователю.
- Удалённые/untracked файлы вне scope change — не трогать без явного указания.
