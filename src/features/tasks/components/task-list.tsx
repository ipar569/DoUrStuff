"use client";

import { Check, Clock3, Pencil, Trash2, X } from "lucide-react";
import { formatDue, isOverdue } from "@/features/tasks/task-helpers";
import { softDeleteTask, updateTaskStatus } from "@/features/tasks/task-repository";
import { cn } from "@/lib/utils";
import type { Task } from "@/features/tasks/types";

export function TaskList({
  tasks,
  onEdit
}: {
  tasks: Task[];
  onEdit: (task: Task) => void;
}) {
  if (!tasks.length) {
    return (
      <div className="flex min-h-72 flex-col items-center justify-center rounded-[1.5rem] border border-dashed border-black/10 bg-white/55 p-8 text-center">
        <p className="text-lg font-medium text-ink-950">Nothing here yet</p>
        <p className="mt-2 max-w-sm text-sm leading-6 text-ink-700">
          Add your first task to start testing the local-first foundation. Everything you save here lives in
          IndexedDB and stays available offline after the first load.
        </p>
      </div>
    );
  }

  return (
    <div className="mt-5 space-y-3">
      {tasks.map((task) => {
        const overdue = isOverdue(task);

        return (
          <article
            key={task.id}
            className="rounded-[1.5rem] border border-black/5 bg-white/85 p-4 transition hover:border-moss-500/40"
          >
            <div className="flex flex-wrap items-start justify-between gap-4">
              <div className="min-w-0 flex-1">
                <div className="flex flex-wrap items-center gap-2">
                  <span
                    className={cn(
                      "rounded-full px-2.5 py-1 text-xs font-medium uppercase tracking-[0.18em]",
                      task.status === "done" && "bg-moss-500/15 text-moss-600",
                      task.status === "in_progress" && "bg-gold-400/20 text-ink-950",
                      task.status === "todo" && "bg-sand-100 text-ink-700",
                      task.status === "cancelled" && "bg-coral-500/15 text-coral-500"
                    )}
                  >
                    {task.status.replaceAll("_", " ")}
                  </span>
                  {overdue ? (
                    <span className="rounded-full bg-coral-500/12 px-2.5 py-1 text-xs font-medium uppercase tracking-[0.18em] text-coral-500">
                      Overdue
                    </span>
                  ) : null}
                </div>

                <h3 className="mt-3 text-lg font-semibold text-ink-950">{task.title}</h3>

                {task.description ? (
                  <p className="mt-2 whitespace-pre-wrap text-sm leading-6 text-ink-700">{task.description}</p>
                ) : null}

                <div className="mt-4 flex flex-wrap items-center gap-2 text-sm text-ink-700">
                  <span className="inline-flex items-center gap-2 rounded-full bg-sand-100 px-3 py-1.5">
                    <Clock3 className="h-3.5 w-3.5" />
                    {formatDue(task)}
                  </span>
                  {task.tags.map((tag) => (
                    <span key={tag} className="rounded-full border border-black/5 bg-white px-3 py-1.5">
                      #{tag}
                    </span>
                  ))}
                </div>
              </div>

              <div className="flex flex-wrap items-center gap-2">
                <IconButton
                  label={task.status === "done" ? "Reopen task" : "Mark complete"}
                  onClick={() => updateTaskStatus(task, task.status === "done" ? "todo" : "done")}
                >
                  {task.status === "done" ? <X className="h-4 w-4" /> : <Check className="h-4 w-4" />}
                </IconButton>
                <IconButton label="Edit task" onClick={() => onEdit(task)}>
                  <Pencil className="h-4 w-4" />
                </IconButton>
                <IconButton label="Delete task" onClick={() => softDeleteTask(task)}>
                  <Trash2 className="h-4 w-4" />
                </IconButton>
              </div>
            </div>
          </article>
        );
      })}
    </div>
  );
}

function IconButton({
  children,
  label,
  onClick
}: {
  children: React.ReactNode;
  label: string;
  onClick: () => void | Promise<unknown>;
}) {
  return (
    <button
      aria-label={label}
      className="rounded-full border border-black/10 bg-white p-2.5 text-ink-700 transition hover:border-moss-500 hover:text-ink-950"
      onClick={() => void onClick()}
      type="button"
    >
      {children}
    </button>
  );
}
