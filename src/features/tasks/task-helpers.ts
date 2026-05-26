import { Task, TaskDraft } from "@/features/tasks/types";

export function createTaskId() {
  return crypto.randomUUID();
}

export function parseTags(input: string) {
  return input
    .split(",")
    .map((tag) => tag.trim())
    .filter(Boolean);
}

export function buildDueAt(draft: TaskDraft) {
  if (!draft.dueDate) {
    return { dueAt: null, dueDateOnly: false };
  }

  if (!draft.dueTime) {
    return { dueAt: draft.dueDate, dueDateOnly: true };
  }

  return { dueAt: `${draft.dueDate}T${draft.dueTime}`, dueDateOnly: false };
}

export function buildTaskFromDraft(draft: TaskDraft): Task {
  const now = new Date().toISOString();
  const { dueAt, dueDateOnly } = buildDueAt(draft);

  return {
    id: createTaskId(),
    title: draft.title.trim(),
    description: draft.description.trim(),
    tags: parseTags(draft.tags),
    status: draft.status,
    dueAt,
    dueDateOnly,
    createdAt: now,
    updatedAt: now,
    completedAt: draft.status === "done" ? now : null,
    deletedAt: null,
    lastSyncedAt: null
  };
}

export function patchTaskWithDraft(task: Task, draft: TaskDraft): Task {
  const now = new Date().toISOString();
  const { dueAt, dueDateOnly } = buildDueAt(draft);
  const isDone = draft.status === "done";

  return {
    ...task,
    title: draft.title.trim(),
    description: draft.description.trim(),
    tags: parseTags(draft.tags),
    status: draft.status,
    dueAt,
    dueDateOnly,
    updatedAt: now,
    completedAt: isDone ? task.completedAt ?? now : null,
    lastSyncedAt: null
  };
}

export function draftFromTask(task: Task): TaskDraft {
  const [dueDate = "", dueTime = ""] = splitDue(task.dueAt, task.dueDateOnly);

  return {
    title: task.title,
    description: task.description,
    tags: task.tags.join(", "),
    status: task.status,
    dueDate,
    dueTime
  };
}

export function splitDue(dueAt: string | null, dueDateOnly: boolean) {
  if (!dueAt) {
    return ["", ""];
  }

  if (dueDateOnly) {
    return [dueAt, ""];
  }

  const [date, time] = dueAt.split("T");
  return [date ?? "", time?.slice(0, 5) ?? ""];
}

export function formatDue(task: Task) {
  if (!task.dueAt) {
    return "No due date";
  }

  if (task.dueDateOnly) {
    return new Intl.DateTimeFormat(undefined, {
      month: "short",
      day: "numeric",
      year: "numeric"
    }).format(new Date(`${task.dueAt}T00:00:00`));
  }

  return new Intl.DateTimeFormat(undefined, {
    month: "short",
    day: "numeric",
    hour: "numeric",
    minute: "2-digit"
  }).format(new Date(task.dueAt));
}

export function isOverdue(task: Task) {
  if (!task.dueAt || task.status === "done" || task.status === "cancelled") {
    return false;
  }

  const comparisonTarget = task.dueDateOnly ? `${task.dueAt}T23:59:59` : task.dueAt;
  return new Date(comparisonTarget).getTime() < Date.now();
}
