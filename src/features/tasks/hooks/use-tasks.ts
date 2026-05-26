"use client";

import { useMemo, useState } from "react";
import { useLiveQuery } from "dexie-react-hooks";
import { listActiveTasks } from "@/features/tasks/task-repository";
import type { Task } from "@/features/tasks/types";

const FILTERS = [
  { id: "all", label: "Everything" },
  { id: "open", label: "Open" },
  { id: "done", label: "Done" }
] as const;

export type TaskFilterId = (typeof FILTERS)[number]["id"];
export type TaskComposerMode = "create" | "edit" | null;

export function useTasks() {
  const tasks = useLiveQuery(() => listActiveTasks(), [], []);
  const [filter, setFilter] = useState<TaskFilterId>("all");
  const [editingTask, setEditingTask] = useState<Task | null>(null);
  const [composerMode, setComposerMode] = useState<TaskComposerMode>(null);
  const [calendarMonth, setCalendarMonth] = useState(() => new Date());

  const filteredTasks = useMemo(() => {
    if (filter === "open") {
      return tasks.filter((task) => task.status !== "done" && task.status !== "cancelled");
    }

    if (filter === "done") {
      return tasks.filter((task) => task.status === "done");
    }

    return tasks;
  }, [filter, tasks]);

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
    composerMode,
    editingTask,
    filter,
    filters: FILTERS,
    filteredTasks,
    calendarMonth,
    closeEditor,
    openCreateEditor,
    openEditEditor,
    setCalendarMonth,
    setFilter
  };
}
