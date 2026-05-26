import { database } from "@/db/app-db";
import { buildTaskFromDraft, patchTaskWithDraft } from "@/features/tasks/task-helpers";
import type { Task, TaskDraft, TaskStatus } from "@/features/tasks/types";

export async function listActiveTasks() {
  const tasks = (await database.tasks.toArray()).filter((task) => task.deletedAt === null);
  return tasks.sort((left, right) => right.updatedAt.localeCompare(left.updatedAt));
}

export async function createTask(draft: TaskDraft) {
  return database.tasks.add(buildTaskFromDraft(draft));
}

export async function updateTask(task: Task, draft: TaskDraft) {
  return database.tasks.put(patchTaskWithDraft(task, draft));
}

export async function updateTaskStatus(task: Task, status: TaskStatus) {
  const now = new Date().toISOString();
  return database.tasks.update(task.id, {
    status,
    updatedAt: now,
    completedAt: status === "done" ? task.completedAt ?? now : null,
    lastSyncedAt: null
  });
}

export async function softDeleteTask(task: Task) {
  const now = new Date().toISOString();
  return database.tasks.update(task.id, {
    deletedAt: now,
    updatedAt: now,
    lastSyncedAt: null
  });
}
