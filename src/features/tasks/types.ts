export const TASK_STATUSES = ["todo", "in_progress", "done", "cancelled"] as const;

export type TaskStatus = (typeof TASK_STATUSES)[number];

export type Task = {
  id: string;
  title: string;
  description: string;
  tags: string[];
  status: TaskStatus;
  dueAt: string | null;
  dueDateOnly: boolean;
  createdAt: string;
  updatedAt: string;
  completedAt: string | null;
  deletedAt: string | null;
  lastSyncedAt: string | null;
};

export type TaskDraft = {
  title: string;
  description: string;
  tags: string;
  status: TaskStatus;
  dueDate: string;
  dueTime: string;
};

export const EMPTY_TASK_DRAFT: TaskDraft = {
  title: "",
  description: "",
  tags: "",
  status: "todo",
  dueDate: "",
  dueTime: ""
};
