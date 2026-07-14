# Planning Views Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `All`, `Today`, `Upcoming`, `Overdue`, and `Done` planning tabs that filter both the task board and calendar using local-time task bucket rules.

**Architecture:** Keep the existing Next.js, React, Dexie, and Tailwind structure. Add a focused task planning domain module that owns planning view IDs, labels, filtering, counts, and date bucket helpers. Wire the existing hook and presentational components to that domain module without changing task persistence, schema, service worker behavior, or task editor behavior.

**Tech Stack:** Next.js App Router, React 19, TypeScript, Tailwind CSS, Dexie, dexie-react-hooks, Vitest, Testing Library.

## Global Constraints

- No framework change.
- No schema change.
- No backend work.
- No account sync.
- No reminders.
- No recurring tasks.
- No natural language date parsing.
- No tag filtering.
- No release/version bump.
- Planning calculations use the user's local browser time.
- Keep repository ordering: newest updated first.
- Use `npm.cmd` for local verification on Windows PowerShell.
- Do not run release scripts, create tags, or push without explicit user approval.

---

## File Structure

- Create `src/features/tasks/task-planning.ts`: owns planning view constants, types, filter rules, counts, local date helpers, and empty-state copy.
- Create `src/features/tasks/task-planning.test.ts`: unit tests for planning view logic and edge cases.
- Modify `src/features/tasks/hooks/use-tasks.ts`: replace old `Everything/Open/Done` filter state with planning view state derived from `task-planning.ts`.
- Rename or replace `src/features/tasks/components/task-filters.tsx` with `src/features/tasks/components/task-planning-tabs.tsx`: render the five planning tabs and counts.
- Modify `src/features/tasks/components/task-board.tsx`: consume planning tab props and pass the selected empty state to `TaskList`.
- Modify `src/features/tasks/components/task-list.tsx`: accept view-aware empty state copy while preserving the existing default.
- Modify `src/features/tasks/components/task-app.tsx`: pass planning view props from `useTasks` into `TaskBoard` and pass `visibleTasks` to `TaskCalendar`.
- Modify `src/features/tasks/components/task-list.test.tsx`: update or add tests for view-aware empty states.
- Modify `README.md`: mention planning tabs in the current feature list.
- Modify `CHANGELOG.md`: add an `Unreleased` note for planning views.

---

### Task 1: Add Planning Domain Module

**Files:**
- Create: `src/features/tasks/task-planning.ts`
- Create: `src/features/tasks/task-planning.test.ts`

**Interfaces:**
- Consumes: `Task` from `src/features/tasks/types.ts`
- Produces:
  - `PLANNING_VIEWS: ReadonlyArray<{ id: TaskPlanningViewId; label: string }>`
  - `type TaskPlanningViewId = "all" | "today" | "upcoming" | "overdue" | "done"`
  - `type PlanningViewCounts = Record<TaskPlanningViewId, number>`
  - `getTasksForPlanningView(tasks: Task[], viewId: TaskPlanningViewId, now?: Date): Task[]`
  - `getPlanningViewCounts(tasks: Task[], now?: Date): PlanningViewCounts`
  - `getPlanningEmptyState(viewId: TaskPlanningViewId): { title: string; description: string }`

- [ ] **Step 1: Write the failing planning tests**

Create `src/features/tasks/task-planning.test.ts`:

```ts
import {
  getPlanningEmptyState,
  getPlanningViewCounts,
  getTasksForPlanningView,
  PLANNING_VIEWS,
  type TaskPlanningViewId
} from "@/features/tasks/task-planning";
import type { Task, TaskStatus } from "@/features/tasks/types";

function makeTask(overrides: Partial<Task> & { id: string; title?: string }): Task {
  return {
    id: overrides.id,
    title: overrides.title ?? overrides.id,
    description: "",
    tags: [],
    status: "todo",
    dueAt: null,
    dueDateOnly: false,
    createdAt: "2026-07-13T00:00:00.000Z",
    updatedAt: "2026-07-13T00:00:00.000Z",
    completedAt: null,
    deletedAt: null,
    lastSyncedAt: null,
    ...overrides
  };
}

describe("task planning", () => {
  const now = new Date("2026-07-14T10:30:00");

  it("defines the planning views in display order", () => {
    expect(PLANNING_VIEWS.map((view) => view.id)).toEqual(["all", "today", "upcoming", "overdue", "done"]);
    expect(PLANNING_VIEWS.map((view) => view.label)).toEqual(["All", "Today", "Upcoming", "Overdue", "Done"]);
  });

  it("includes every active task in All, including done and cancelled", () => {
    const tasks = [
      makeTask({ id: "todo", status: "todo" }),
      makeTask({ id: "progress", status: "in_progress" }),
      makeTask({ id: "done", status: "done", completedAt: "2026-07-14T09:00:00.000Z" }),
      makeTask({ id: "cancelled", status: "cancelled" })
    ];

    expect(getTasksForPlanningView(tasks, "all", now).map((task) => task.id)).toEqual([
      "todo",
      "progress",
      "done",
      "cancelled"
    ]);
  });

  it("classifies date-only and date-time tasks due today", () => {
    const tasks = [
      makeTask({ id: "date-only-today", dueAt: "2026-07-14", dueDateOnly: true }),
      makeTask({ id: "date-time-today", dueAt: "2026-07-14T22:00", dueDateOnly: false }),
      makeTask({ id: "future", dueAt: "2026-07-15", dueDateOnly: true }),
      makeTask({ id: "done-today", status: "done", dueAt: "2026-07-14", dueDateOnly: true })
    ];

    expect(getTasksForPlanningView(tasks, "today", now).map((task) => task.id)).toEqual([
      "date-only-today",
      "date-time-today"
    ]);
  });

  it("classifies open tasks due after today as upcoming", () => {
    const tasks = [
      makeTask({ id: "tomorrow-date-only", dueAt: "2026-07-15", dueDateOnly: true }),
      makeTask({ id: "tomorrow-date-time", dueAt: "2026-07-15T08:00", dueDateOnly: false }),
      makeTask({ id: "today", dueAt: "2026-07-14T23:00", dueDateOnly: false }),
      makeTask({ id: "undated", dueAt: null }),
      makeTask({ id: "cancelled-future", status: "cancelled", dueAt: "2026-07-15", dueDateOnly: true })
    ];

    expect(getTasksForPlanningView(tasks, "upcoming", now).map((task) => task.id)).toEqual([
      "tomorrow-date-only",
      "tomorrow-date-time"
    ]);
  });

  it("classifies overdue date-only tasks after end of day and date-time tasks after exact time", () => {
    const tasks = [
      makeTask({ id: "yesterday-date-only", dueAt: "2026-07-13", dueDateOnly: true }),
      makeTask({ id: "today-past-time", dueAt: "2026-07-14T09:00", dueDateOnly: false }),
      makeTask({ id: "today-date-only", dueAt: "2026-07-14", dueDateOnly: true }),
      makeTask({ id: "today-future-time", dueAt: "2026-07-14T22:00", dueDateOnly: false }),
      makeTask({ id: "done-late", status: "done", dueAt: "2026-07-13", dueDateOnly: true })
    ];

    expect(getTasksForPlanningView(tasks, "overdue", now).map((task) => task.id)).toEqual([
      "yesterday-date-only",
      "today-past-time"
    ]);
  });

  it("includes only completed tasks in Done", () => {
    const tasks = [
      makeTask({ id: "done", status: "done", completedAt: "2026-07-14T09:00:00.000Z" }),
      makeTask({ id: "cancelled", status: "cancelled" }),
      makeTask({ id: "todo", status: "todo" })
    ];

    expect(getTasksForPlanningView(tasks, "done", now).map((task) => task.id)).toEqual(["done"]);
  });

  it("calculates counts with the same rules as visible tasks", () => {
    const tasks = [
      makeTask({ id: "today", dueAt: "2026-07-14", dueDateOnly: true }),
      makeTask({ id: "upcoming", dueAt: "2026-07-15", dueDateOnly: true }),
      makeTask({ id: "overdue", dueAt: "2026-07-13", dueDateOnly: true }),
      makeTask({ id: "done", status: "done", dueAt: "2026-07-14", dueDateOnly: true, completedAt: "2026-07-14T09:00:00.000Z" }),
      makeTask({ id: "cancelled", status: "cancelled" })
    ];

    expect(getPlanningViewCounts(tasks, now)).toEqual({
      all: 5,
      today: 1,
      upcoming: 1,
      overdue: 1,
      done: 1
    });
  });

  it("ignores malformed due values in date bucket views", () => {
    const malformed = makeTask({ id: "bad-date", dueAt: "not-a-date", dueDateOnly: false });

    (["today", "upcoming", "overdue"] satisfies TaskPlanningViewId[]).forEach((viewId) => {
      expect(getTasksForPlanningView([malformed], viewId, now)).toEqual([]);
    });
  });

  it("provides view-aware empty states", () => {
    expect(getPlanningEmptyState("all").title).toBe("Nothing here yet");
    expect(getPlanningEmptyState("today").title).toBe("Nothing due today");
    expect(getPlanningEmptyState("upcoming").title).toBe("Nothing coming up");
    expect(getPlanningEmptyState("overdue").title).toBe("Nothing overdue");
    expect(getPlanningEmptyState("done").title).toBe("No completed tasks yet");
  });
});
```

- [ ] **Step 2: Run the new tests to verify they fail**

Run:

```powershell
npm.cmd run test:run -- src/features/tasks/task-planning.test.ts
```

Expected: FAIL because `src/features/tasks/task-planning.ts` does not exist.

- [ ] **Step 3: Implement the planning module**

Create `src/features/tasks/task-planning.ts`:

```ts
import type { Task } from "@/features/tasks/types";

export const PLANNING_VIEWS = [
  { id: "all", label: "All" },
  { id: "today", label: "Today" },
  { id: "upcoming", label: "Upcoming" },
  { id: "overdue", label: "Overdue" },
  { id: "done", label: "Done" }
] as const;

export type TaskPlanningViewId = (typeof PLANNING_VIEWS)[number]["id"];
export type PlanningViewCounts = Record<TaskPlanningViewId, number>;

export type PlanningEmptyState = {
  title: string;
  description: string;
};

const EMPTY_STATES: Record<TaskPlanningViewId, PlanningEmptyState> = {
  all: {
    title: "Nothing here yet",
    description:
      "Add your first task to start testing the local-first foundation. Everything you save here lives in IndexedDB and stays available offline after the first load."
  },
  today: {
    title: "Nothing due today",
    description: "Tasks with due dates for today will appear here."
  },
  upcoming: {
    title: "Nothing coming up",
    description: "Future dated tasks will appear here when there is something to plan for."
  },
  overdue: {
    title: "Nothing overdue",
    description: "Tasks only appear here after their due date or due time has passed."
  },
  done: {
    title: "No completed tasks yet",
    description: "Completed tasks will appear here after you mark them done."
  }
};

export function getTasksForPlanningView(tasks: Task[], viewId: TaskPlanningViewId, now = new Date()) {
  if (viewId === "all") {
    return tasks;
  }

  if (viewId === "done") {
    return tasks.filter((task) => task.status === "done");
  }

  return tasks.filter((task) => {
    if (!isOpenTask(task)) {
      return false;
    }

    if (viewId === "today") {
      return isDueToday(task, now);
    }

    if (viewId === "upcoming") {
      return isUpcoming(task, now);
    }

    return isPlanningOverdue(task, now);
  });
}

export function getPlanningViewCounts(tasks: Task[], now = new Date()): PlanningViewCounts {
  return PLANNING_VIEWS.reduce(
    (counts, view) => ({
      ...counts,
      [view.id]: getTasksForPlanningView(tasks, view.id, now).length
    }),
    {} as PlanningViewCounts
  );
}

export function getPlanningEmptyState(viewId: TaskPlanningViewId) {
  return EMPTY_STATES[viewId];
}

function isOpenTask(task: Task) {
  return task.status === "todo" || task.status === "in_progress";
}

function isDueToday(task: Task, now: Date) {
  const dueDate = getLocalDueDate(task);

  if (!dueDate) {
    return false;
  }

  return toLocalDateKey(dueDate) === toLocalDateKey(now);
}

function isUpcoming(task: Task, now: Date) {
  const dueDate = getLocalDueDate(task);

  if (!dueDate) {
    return false;
  }

  return startOfLocalDay(dueDate).getTime() > startOfLocalDay(now).getTime();
}

function isPlanningOverdue(task: Task, now: Date) {
  if (!task.dueAt) {
    return false;
  }

  const comparisonDate = task.dueDateOnly ? endOfLocalDateOnly(task.dueAt) : parseLocalDate(task.dueAt);

  if (!comparisonDate) {
    return false;
  }

  return comparisonDate.getTime() < now.getTime();
}

function getLocalDueDate(task: Task) {
  if (!task.dueAt) {
    return null;
  }

  return task.dueDateOnly ? parseLocalDate(`${task.dueAt}T00:00`) : parseLocalDate(task.dueAt);
}

function parseLocalDate(value: string) {
  const date = new Date(value);

  if (Number.isNaN(date.getTime())) {
    return null;
  }

  return date;
}

function endOfLocalDateOnly(value: string) {
  const date = parseLocalDate(`${value}T23:59:59`);

  if (!date) {
    return null;
  }

  return date;
}

function startOfLocalDay(date: Date) {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate());
}

function toLocalDateKey(date: Date) {
  return [
    date.getFullYear(),
    String(date.getMonth() + 1).padStart(2, "0"),
    String(date.getDate()).padStart(2, "0")
  ].join("-");
}
```

- [ ] **Step 4: Run the planning tests to verify they pass**

Run:

```powershell
npm.cmd run test:run -- src/features/tasks/task-planning.test.ts
```

Expected: PASS, with all `task planning` tests green.

- [ ] **Step 5: Commit Task 1**

Run:

```powershell
git add src/features/tasks/task-planning.ts src/features/tasks/task-planning.test.ts
git commit -m "Add task planning domain logic"
```

Expected: commit succeeds.

---

### Task 2: Wire Planning Views Into Hook And Board

**Files:**
- Modify: `src/features/tasks/hooks/use-tasks.ts`
- Create: `src/features/tasks/components/task-planning-tabs.tsx`
- Modify: `src/features/tasks/components/task-board.tsx`
- Modify: `src/features/tasks/components/task-app.tsx`
- Delete after replacement: `src/features/tasks/components/task-filters.tsx`

**Interfaces:**
- Consumes from Task 1:
  - `PLANNING_VIEWS`
  - `TaskPlanningViewId`
  - `getTasksForPlanningView(tasks, viewId)`
  - `getPlanningViewCounts(tasks)`
  - `getPlanningEmptyState(viewId)`
- Produces:
  - `useTasks()` returns `planningViews`, `currentPlanningView`, `visibleTasks`, `planningViewCounts`, `planningEmptyState`, and `setPlanningView`
  - `TaskPlanningTabs` renders planning view buttons with counts

- [ ] **Step 1: Update the hook**

Replace the filter logic in `src/features/tasks/hooks/use-tasks.ts` with:

```ts
"use client";

import { useMemo, useState } from "react";
import { useLiveQuery } from "dexie-react-hooks";
import {
  getPlanningEmptyState,
  getPlanningViewCounts,
  getTasksForPlanningView,
  PLANNING_VIEWS,
  type TaskPlanningViewId
} from "@/features/tasks/task-planning";
import { listActiveTasks } from "@/features/tasks/task-repository";
import type { Task } from "@/features/tasks/types";

export type TaskComposerMode = "create" | "edit" | null;

export function useTasks() {
  const tasks = useLiveQuery(() => listActiveTasks(), [], []);
  const [currentPlanningView, setPlanningView] = useState<TaskPlanningViewId>("all");
  const [editingTask, setEditingTask] = useState<Task | null>(null);
  const [composerMode, setComposerMode] = useState<TaskComposerMode>(null);
  const [calendarMonth, setCalendarMonth] = useState(() => new Date());

  const visibleTasks = useMemo(
    () => getTasksForPlanningView(tasks, currentPlanningView),
    [currentPlanningView, tasks]
  );

  const planningViewCounts = useMemo(() => getPlanningViewCounts(tasks), [tasks]);
  const planningEmptyState = getPlanningEmptyState(currentPlanningView);

  const doneCount = tasks.filter((task) => task.status === "done").length;
  const openCount = tasks.filter((task) => task.status !== "done" && task.status !== "cancelled").length;

  function openCreateEditor() {
    setEditingTask(null);
    setComposerMode("create");
  }

  function openEditEditor(task: Task) {
    setEditingTask(task);
    setComposerMode("edit");
  }

  function closeEditor() {
    setComposerMode(null);
    setEditingTask(null);
  }

  return {
    counts: {
      total: tasks.length,
      done: doneCount,
      open: openCount
    },
    calendarMonth,
    closeEditor,
    composerMode,
    currentPlanningView,
    editingTask,
    planningEmptyState,
    planningViewCounts,
    planningViews: PLANNING_VIEWS,
    visibleTasks,
    openCreateEditor,
    openEditEditor,
    setCalendarMonth,
    setPlanningView
  };
}
```

- [ ] **Step 2: Add the planning tabs component**

Create `src/features/tasks/components/task-planning-tabs.tsx`:

```tsx
import type { PlanningViewCounts, TaskPlanningViewId } from "@/features/tasks/task-planning";

export function TaskPlanningTabs({
  currentView,
  counts,
  views,
  onViewChange
}: {
  currentView: TaskPlanningViewId;
  counts: PlanningViewCounts;
  views: ReadonlyArray<{ id: TaskPlanningViewId; label: string }>;
  onViewChange: (viewId: TaskPlanningViewId) => void;
}) {
  return (
    <div className="flex max-w-full gap-1 overflow-x-auto rounded-full bg-sand-100 p-1">
      {views.map((item) => (
        <button
          key={item.id}
          className={`inline-flex items-center gap-2 whitespace-nowrap rounded-full px-4 py-2 text-sm transition ${
            currentView === item.id ? "bg-white text-ink-950 shadow-sm" : "text-ink-700"
          }`}
          onClick={() => onViewChange(item.id)}
          type="button"
        >
          <span>{item.label}</span>
          <span className="rounded-full bg-black/5 px-2 py-0.5 text-xs font-medium">{counts[item.id]}</span>
        </button>
      ))}
    </div>
  );
}
```

- [ ] **Step 3: Update the board component**

Replace `src/features/tasks/components/task-board.tsx` with:

```tsx
import { TaskPlanningTabs } from "@/features/tasks/components/task-planning-tabs";
import { TaskList } from "@/features/tasks/components/task-list";
import type {
  PlanningEmptyState,
  PlanningViewCounts,
  TaskPlanningViewId
} from "@/features/tasks/task-planning";
import type { Task } from "@/features/tasks/types";

export function TaskBoard({
  currentPlanningView,
  emptyState,
  planningViewCounts,
  planningViews,
  tasks,
  onEdit,
  onPlanningViewChange
}: {
  currentPlanningView: TaskPlanningViewId;
  emptyState: PlanningEmptyState;
  planningViewCounts: PlanningViewCounts;
  planningViews: ReadonlyArray<{ id: TaskPlanningViewId; label: string }>;
  tasks: Task[];
  onEdit: (task: Task) => void;
  onPlanningViewChange: (viewId: TaskPlanningViewId) => void;
}) {
  return (
    <div className="glass-panel rounded-[2rem] p-4 sm:p-6">
      <div className="flex flex-wrap items-center justify-between gap-3 border-b border-black/5 pb-4">
        <div>
          <h2 className="text-xl font-semibold text-ink-950">Task board</h2>
          <p className="text-sm text-ink-700">Plan what needs attention today, soon, or after it slips.</p>
        </div>
        <TaskPlanningTabs
          currentView={currentPlanningView}
          counts={planningViewCounts}
          views={planningViews}
          onViewChange={onPlanningViewChange}
        />
      </div>

      <TaskList emptyState={emptyState} tasks={tasks} onEdit={onEdit} />
    </div>
  );
}
```

- [ ] **Step 4: Update the app wiring**

In `src/features/tasks/components/task-app.tsx`, replace the destructuring and `TaskBoard`/`TaskCalendar` props with this complete component:

```tsx
"use client";

import { CalendarRange } from "lucide-react";
import { FloatingNewTaskButton } from "@/features/tasks/components/floating-new-task-button";
import { TaskBoard } from "@/features/tasks/components/task-board";
import { TaskCalendar } from "@/features/tasks/components/task-calendar";
import { TaskEditor } from "@/features/tasks/components/task-editor";
import { TaskLogo } from "@/features/tasks/components/task-logo";
import { useTasks } from "@/features/tasks/hooks/use-tasks";
import { EMPTY_TASK_DRAFT } from "@/features/tasks/types";

export function TaskApp() {
  const {
    calendarMonth,
    closeEditor,
    composerMode,
    counts,
    currentPlanningView,
    editingTask,
    planningEmptyState,
    planningViewCounts,
    planningViews,
    visibleTasks,
    openCreateEditor,
    openEditEditor,
    setCalendarMonth,
    setPlanningView
  } = useTasks();

  return (
    <>
      <main className="mx-auto flex min-h-screen w-full max-w-6xl flex-col gap-6 px-4 pb-28 pt-5 sm:px-6 lg:px-8 lg:pb-12">
        <section className="glass-panel rounded-[2rem] p-4 sm:p-6">
          <div className="flex flex-wrap items-start justify-between gap-4">
            <TaskLogo />
            <div className="flex flex-wrap gap-3">
              <MetricPill label="Open" value={counts.open} />
              <MetricPill label="Done" value={counts.done} />
              <MetricPill label="Total" value={counts.total} />
            </div>
          </div>
        </section>

        <TaskBoard
          currentPlanningView={currentPlanningView}
          emptyState={planningEmptyState}
          planningViewCounts={planningViewCounts}
          planningViews={planningViews}
          onEdit={openEditEditor}
          onPlanningViewChange={setPlanningView}
          tasks={visibleTasks}
        />

        <section className="glass-panel rounded-[2rem] p-4 sm:p-6">
          <div className="flex items-center gap-3 border-b border-black/5 pb-4">
            <div className="flex h-11 w-11 items-center justify-center rounded-[1.2rem] bg-moss-500/12 text-moss-600">
              <CalendarRange className="h-5 w-5" />
            </div>
            <div>
              <h2 className="text-xl font-semibold text-ink-950">Calendar planning</h2>
              <p className="text-sm text-ink-700">See what is due this month and edit tasks straight from the calendar.</p>
            </div>
          </div>

          <div className="mt-5">
            <TaskCalendar
              monthDate={calendarMonth}
              onMonthChange={setCalendarMonth}
              onTaskSelect={openEditEditor}
              tasks={visibleTasks}
            />
          </div>
        </section>
      </main>

      <TaskEditor
        mode={composerMode}
        initialDraft={editingTask ? undefined : EMPTY_TASK_DRAFT}
        task={editingTask}
        onClose={closeEditor}
      />

      <FloatingNewTaskButton onClick={openCreateEditor} />
    </>
  );
}

function MetricPill({
  label,
  value
}: {
  label: string;
  value: number;
}) {
  return (
    <div className="rounded-full border border-black/8 bg-white/80 px-4 py-2 text-sm text-ink-700">
      <span className="font-medium text-ink-950">{value}</span> {label}
    </div>
  );
}
```

- [ ] **Step 5: Remove the old filter component**

Delete `src/features/tasks/components/task-filters.tsx` after confirming no imports remain:

```powershell
rg "task-filters|TaskFilters|TaskFilterId|filteredTasks|setFilter|currentFilter" src
```

Expected before deletion: no active references except the old file if it still exists.

- [ ] **Step 6: Run focused checks**

Run:

```powershell
npm.cmd run typecheck
npm.cmd run test:run -- src/features/tasks/task-planning.test.ts
```

Expected: typecheck passes and planning tests pass.

- [ ] **Step 7: Commit Task 2**

Run:

```powershell
git add src/features/tasks/hooks/use-tasks.ts src/features/tasks/components/task-planning-tabs.tsx src/features/tasks/components/task-board.tsx src/features/tasks/components/task-app.tsx src/features/tasks/components/task-filters.tsx
git commit -m "Wire planning views into task board"
```

Expected: commit succeeds. If `git add` reports the deleted `task-filters.tsx`, that is expected.

---

### Task 3: Add View-Aware Empty State Tests

**Files:**
- Modify: `src/features/tasks/components/task-list.tsx`
- Modify: `src/features/tasks/components/task-list.test.tsx`

**Interfaces:**
- Consumes from Task 1:
  - `PlanningEmptyState`
- Produces:
  - `TaskList` accepts optional `emptyState?: PlanningEmptyState`

- [ ] **Step 1: Write the failing empty-state test**

Add this test to `src/features/tasks/components/task-list.test.tsx` after the existing empty state test:

```tsx
  it("renders a custom planning empty state", () => {
    render(
      <TaskList
        emptyState={{
          title: "Nothing due today",
          description: "Tasks with due dates for today will appear here."
        }}
        onEdit={vi.fn()}
        tasks={[]}
      />
    );

    expect(screen.getByText("Nothing due today")).toBeInTheDocument();
    expect(screen.getByText("Tasks with due dates for today will appear here.")).toBeInTheDocument();
  });
```

- [ ] **Step 2: Run the component test to verify it fails**

Run:

```powershell
npm.cmd run test:run -- src/features/tasks/components/task-list.test.tsx
```

Expected: FAIL because `TaskList` does not accept `emptyState` yet.

- [ ] **Step 3: Update TaskList to accept custom empty state copy**

Modify the imports and component signature in `src/features/tasks/components/task-list.tsx`:

```tsx
"use client";

import { Check, Clock3, Pencil, Trash2, X } from "lucide-react";
import { formatDue, isOverdue } from "@/features/tasks/task-helpers";
import { softDeleteTask, updateTaskStatus } from "@/features/tasks/task-repository";
import { cn } from "@/lib/utils";
import type { PlanningEmptyState } from "@/features/tasks/task-planning";
import type { Task } from "@/features/tasks/types";

const DEFAULT_EMPTY_STATE: PlanningEmptyState = {
  title: "Nothing here yet",
  description:
    "Add your first task to start testing the local-first foundation. Everything you save here lives in IndexedDB and stays available offline after the first load."
};

export function TaskList({
  emptyState = DEFAULT_EMPTY_STATE,
  tasks,
  onEdit
}: {
  emptyState?: PlanningEmptyState;
  tasks: Task[];
  onEdit: (task: Task) => void;
}) {
  if (!tasks.length) {
    return (
      <div className="flex min-h-72 flex-col items-center justify-center rounded-[1.5rem] border border-dashed border-black/10 bg-white/55 p-8 text-center">
        <p className="text-lg font-medium text-ink-950">{emptyState.title}</p>
        <p className="mt-2 max-w-sm text-sm leading-6 text-ink-700">{emptyState.description}</p>
      </div>
    );
  }

  return (
    <div className="mt-5 space-y-3">
      {tasks.map((task) => {
        const overdue = isOverdue(task);
```

Keep the rest of the file unchanged after the shown opening block.

- [ ] **Step 4: Run the task list tests to verify they pass**

Run:

```powershell
npm.cmd run test:run -- src/features/tasks/components/task-list.test.tsx
```

Expected: PASS.

- [ ] **Step 5: Run all tests**

Run:

```powershell
npm.cmd run test:run
```

Expected: PASS for all test files.

- [ ] **Step 6: Commit Task 3**

Run:

```powershell
git add src/features/tasks/components/task-list.tsx src/features/tasks/components/task-list.test.tsx
git commit -m "Add planning empty states"
```

Expected: commit succeeds.

---

### Task 4: Update Documentation And Verify

**Files:**
- Modify: `README.md`
- Modify: `CHANGELOG.md`

**Interfaces:**
- Consumes: user-facing behavior from Tasks 1-3
- Produces: updated docs and final verification signal

- [ ] **Step 1: Update README current status**

In `README.md`, under `The app already includes:`, change:

```md
- a responsive task UI for mobile and desktop
```

to:

```md
- a responsive task UI for mobile and desktop
- planning tabs for all, today, upcoming, overdue, and completed tasks
```

- [ ] **Step 2: Update README project structure only if files changed**

If `README.md` already says `features/tasks/` contains task domain logic, hooks, tests, and components, leave that section unchanged. It already covers `task-planning.ts`.

- [ ] **Step 3: Update the changelog**

In `CHANGELOG.md`, under `## [Unreleased]` and `### Added`, add this bullet:

```md
- Planning tabs for all, today, upcoming, overdue, and completed tasks.
```

- [ ] **Step 4: Run full verification**

Run:

```powershell
npm.cmd run typecheck
npm.cmd run test:run
npm.cmd run build
```

Expected:

- typecheck passes
- all Vitest tests pass
- Next production build completes successfully

- [ ] **Step 5: Check git status**

Run:

```powershell
git status --short --branch
```

Expected: only README and changelog are modified before commit. If `tsconfig.typecheck.tsbuildinfo` changes from typecheck, restore it before committing:

```powershell
git restore -- tsconfig.typecheck.tsbuildinfo
```

- [ ] **Step 6: Commit Task 4**

Run:

```powershell
git add README.md CHANGELOG.md
git commit -m "Document planning views"
```

Expected: commit succeeds.

---

## Final Review Checklist

- [ ] `src/features/tasks/task-planning.ts` owns all planning view IDs, labels, filtering, counts, and empty-state copy.
- [ ] `useTasks` exposes planning view state and no longer exposes `filter`, `filters`, `filteredTasks`, or `setFilter`.
- [ ] `TaskBoard` renders five planning tabs with counts.
- [ ] `TaskCalendar` receives the same visible task list as the board.
- [ ] `TaskList` shows view-aware empty states.
- [ ] Cancelled tasks appear only in `All`.
- [ ] Date-only tasks become overdue only after the end of their local due date.
- [ ] Date-time tasks become overdue after their exact local due time.
- [ ] No reminders, recurrence, sync, schema changes, tag filtering, release scripts, tags, or version bumps were added.
- [ ] `npm.cmd run typecheck` passed.
- [ ] `npm.cmd run test:run` passed.
- [ ] `npm.cmd run build` passed.
