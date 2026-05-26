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
    editingTask,
    filter,
    filteredTasks,
    filters,
    openCreateEditor,
    openEditEditor,
    setCalendarMonth,
    setFilter
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
          currentFilter={filter}
          filters={filters}
          onEdit={openEditEditor}
          onFilterChange={setFilter}
          tasks={filteredTasks}
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
              tasks={filteredTasks}
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
