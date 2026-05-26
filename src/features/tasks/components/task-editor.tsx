"use client";

import { useEffect, useState } from "react";
import { CalendarDays, Clock3, PencilLine, Sparkles, X } from "lucide-react";
import { draftFromTask } from "@/features/tasks/task-helpers";
import { createTask, updateTask } from "@/features/tasks/task-repository";
import type { TaskComposerMode } from "@/features/tasks/hooks/use-tasks";
import { EMPTY_TASK_DRAFT, TASK_STATUSES, type Task, type TaskDraft } from "@/features/tasks/types";

export function TaskEditor({
  mode,
  initialDraft = EMPTY_TASK_DRAFT,
  task,
  onClose
}: {
  mode: TaskComposerMode;
  initialDraft?: TaskDraft;
  task: Task | null;
  onClose: () => void;
}) {
  const [draft, setDraft] = useState<TaskDraft>(initialDraft);
  const [isSaving, setIsSaving] = useState(false);

  useEffect(() => {
    if (task) {
      setDraft(draftFromTask(task));
      return;
    }

    setDraft(initialDraft);
  }, [initialDraft, task]);

  if (!mode) {
    return null;
  }

  async function onSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();

    if (!draft.title.trim()) {
      return;
    }

    setIsSaving(true);

    try {
      if (task) {
        await updateTask(task, draft);
      } else {
        await createTask(draft);
      }

      setDraft(EMPTY_TASK_DRAFT);
      onClose();
    } finally {
      setIsSaving(false);
    }
  }

  return (
    <div
      aria-labelledby="task-editor-title"
      aria-modal="true"
      className="fixed inset-0 z-50 flex items-end justify-center bg-ink-950/28 p-0 backdrop-blur-[4px] sm:items-center sm:p-6"
      role="dialog"
    >
      <button
        aria-label="Close task editor"
        className="absolute inset-0"
        onClick={onClose}
        type="button"
      />

      <section className="glass-panel relative w-full max-w-2xl rounded-t-[2rem] p-4 sm:rounded-[2rem] sm:p-6">
        <div className="mx-auto mb-3 h-1.5 w-14 rounded-full bg-black/10 sm:hidden" />

        <div className="flex items-start justify-between gap-4 border-b border-black/5 pb-4">
          <div>
            <div className="inline-flex items-center gap-2 rounded-full bg-moss-500/10 px-3 py-1.5 text-xs font-medium uppercase tracking-[0.18em] text-moss-600">
              <Sparkles className="h-3.5 w-3.5" />
              {task ? "Edit task" : "New task"}
            </div>
            <h2 className="mt-3 text-xl font-semibold text-ink-950 sm:text-2xl" id="task-editor-title">
              {task ? "Refine the details" : "Capture what needs doing"}
            </h2>
            <p className="mt-2 text-sm leading-6 text-ink-700">
              {task
                ? "Update the task and close when it feels right."
                : "A simple capture box: start with the title, then add time or more detail only if you need it."}
            </p>
          </div>

          <button
            aria-label="Close"
            className="rounded-full border border-black/10 p-2 text-ink-700 transition hover:bg-white/80"
            onClick={onClose}
            type="button"
          >
            <X className="h-4 w-4" />
          </button>
        </div>

        <form className="mt-5 space-y-4" onSubmit={onSubmit}>
          <label className="block">
            <span className="mb-2 block text-sm font-medium text-ink-950">Title</span>
            <input
              autoFocus
              className="w-full rounded-[1.4rem] border border-black/10 bg-white/95 px-4 py-4 text-base outline-none ring-0 transition focus:border-moss-500"
              onChange={(event) => setDraft((current) => ({ ...current, title: event.target.value }))}
              placeholder="Pay electricity bill"
              required
              value={draft.title}
            />
          </label>

          <div className="grid gap-4 sm:grid-cols-2">
            <label className="block">
              <span className="mb-2 block text-sm font-medium text-ink-950">Due date</span>
              <div className="relative">
                <CalendarDays className="pointer-events-none absolute left-4 top-1/2 h-4 w-4 -translate-y-1/2 text-ink-500" />
                <input
                  className="w-full rounded-[1.25rem] border border-black/10 bg-white/90 py-3 pl-11 pr-4 text-sm outline-none transition focus:border-moss-500"
                  onChange={(event) => setDraft((current) => ({ ...current, dueDate: event.target.value }))}
                  type="date"
                  value={draft.dueDate}
                />
              </div>
            </label>

            <label className="block">
              <span className="mb-2 block text-sm font-medium text-ink-950">Due time</span>
              <div className="relative">
                <Clock3 className="pointer-events-none absolute left-4 top-1/2 h-4 w-4 -translate-y-1/2 text-ink-500" />
                <input
                  className="w-full rounded-[1.25rem] border border-black/10 bg-white/90 py-3 pl-11 pr-4 text-sm outline-none transition focus:border-moss-500"
                  onChange={(event) => setDraft((current) => ({ ...current, dueTime: event.target.value }))}
                  type="time"
                  value={draft.dueTime}
                />
              </div>
            </label>
          </div>

          <details className="rounded-[1.4rem] border border-black/8 bg-white/60 p-4">
            <summary className="cursor-pointer list-none text-sm font-medium text-ink-950">More details</summary>

            <div className="mt-4 space-y-4">
              <label className="block">
                <span className="mb-2 block text-sm font-medium text-ink-950">Description</span>
                <textarea
                  className="min-h-28 w-full rounded-[1.25rem] border border-black/10 bg-white/90 px-4 py-3 text-sm outline-none transition focus:border-moss-500"
                  onChange={(event) => setDraft((current) => ({ ...current, description: event.target.value }))}
                  placeholder="Anything worth remembering later"
                  value={draft.description}
                />
              </label>

              <label className="block">
                <span className="mb-2 block text-sm font-medium text-ink-950">Tags</span>
                <input
                  className="w-full rounded-[1.25rem] border border-black/10 bg-white/90 px-4 py-3 text-sm outline-none transition focus:border-moss-500"
                  onChange={(event) => setDraft((current) => ({ ...current, tags: event.target.value }))}
                  placeholder="finance, home"
                  value={draft.tags}
                />
              </label>

              <label className="block">
                <span className="mb-2 block text-sm font-medium text-ink-950">Status</span>
                <div className="relative">
                  <PencilLine className="pointer-events-none absolute left-4 top-1/2 h-4 w-4 -translate-y-1/2 text-ink-500" />
                  <select
                    className="w-full appearance-none rounded-[1.25rem] border border-black/10 bg-white/90 py-3 pl-11 pr-4 text-sm outline-none transition focus:border-moss-500"
                    onChange={(event) =>
                      setDraft((current) => ({
                        ...current,
                        status: event.target.value as TaskDraft["status"]
                      }))
                    }
                    value={draft.status}
                  >
                    {TASK_STATUSES.map((status) => (
                      <option key={status} value={status}>
                        {status.replaceAll("_", " ")}
                      </option>
                    ))}
                  </select>
                </div>
              </label>
            </div>
          </details>

          <div className="flex gap-3 pt-2">
            <button
              className="flex-1 rounded-full border border-black/10 bg-white px-5 py-3 text-sm font-medium text-ink-700 transition hover:bg-sand-100"
              onClick={onClose}
              type="button"
            >
              Cancel
            </button>
            <button
              className="flex-1 rounded-full bg-ink-950 px-5 py-3 text-sm font-medium text-white transition hover:bg-ink-900 disabled:cursor-wait disabled:opacity-70"
              disabled={isSaving}
              type="submit"
            >
              {isSaving ? "Saving..." : task ? "Save changes" : "Create task"}
            </button>
          </div>
        </form>
      </section>
    </div>
  );
}
