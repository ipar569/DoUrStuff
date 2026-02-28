/**
 * Task type per docs/prd.md §3.1 (no feature logic yet — dummy data only).
 */
export type Task = {
  id: string;
  title: string;
  description: string;
  tags: string[];
  startDate: string | null;
  endDate: string | null;
  isCompleted: boolean;
  isRecurring: boolean;
  recurrenceRule: string;
  updatedAt: string;
};

export const dummyTasks: Task[] = [
  {
    id: "a1b2c3d4-e5f6-7890-abcd-ef1111111111",
    title: "Review PRD and AI prompts",
    description: "Read through docs/prd.md and docs/ai-prompts.md.",
    tags: ["docs", "planning"],
    startDate: null,
    endDate: null,
    isCompleted: true,
    isRecurring: false,
    recurrenceRule: "",
    updatedAt: "2025-02-28T10:00:00.000Z",
  },
  {
    id: "a1b2c3d4-e5f6-7890-abcd-ef2222222222",
    title: "Set up Dexie.js for offline storage",
    description: "Initialize IndexedDB and define tasks schema.",
    tags: ["dev", "offline"],
    startDate: "2025-03-01T09:00:00.000Z",
    endDate: null,
    isCompleted: false,
    isRecurring: false,
    recurrenceRule: "",
    updatedAt: "2025-02-28T11:00:00.000Z",
  },
  {
    id: "a1b2c3d4-e5f6-7890-abcd-ef3333333333",
    title: "Weekly sync check",
    description: "",
    tags: ["recurring", "sync"],
    startDate: "2025-03-03T14:00:00.000Z",
    endDate: "2025-03-03T15:00:00.000Z",
    isCompleted: false,
    isRecurring: true,
    recurrenceRule: "WEEKLY",
    updatedAt: "2025-02-28T12:00:00.000Z",
  },
];
