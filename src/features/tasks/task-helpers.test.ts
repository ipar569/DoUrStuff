import {
  buildDueAt,
  buildTaskFromDraft,
  formatDue,
  isOverdue,
  parseTags,
  patchTaskWithDraft
} from "@/features/tasks/task-helpers";
import type { Task } from "@/features/tasks/types";

describe("task helpers", () => {
  it("normalizes comma-separated tags", () => {
    expect(parseTags(" finance, home, , urgent ")).toEqual(["finance", "home", "urgent"]);
  });

  it("builds due values for date-only and date-time drafts", () => {
    expect(buildDueAt({ title: "", description: "", tags: "", status: "todo", dueDate: "", dueTime: "" })).toEqual({
      dueAt: null,
      dueDateOnly: false
    });

    expect(
      buildDueAt({
        title: "",
        description: "",
        tags: "",
        status: "todo",
        dueDate: "2026-05-30",
        dueTime: ""
      })
    ).toEqual({
      dueAt: "2026-05-30",
      dueDateOnly: true
    });

    expect(
      buildDueAt({
        title: "",
        description: "",
        tags: "",
        status: "todo",
        dueDate: "2026-05-30",
        dueTime: "09:15"
      })
    ).toEqual({
      dueAt: "2026-05-30T09:15",
      dueDateOnly: false
    });
  });

  it("creates tasks from a draft with trimmed fields", () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date("2026-05-23T10:00:00.000Z"));

    const task = buildTaskFromDraft({
      title: "  Pay bill  ",
      description: "  online  ",
      tags: " finance, home ",
      status: "done",
      dueDate: "2026-05-24",
      dueTime: "08:30"
    });

    expect(task.title).toBe("Pay bill");
    expect(task.description).toBe("online");
    expect(task.tags).toEqual(["finance", "home"]);
    expect(task.completedAt).toBe("2026-05-23T10:00:00.000Z");
    expect(task.dueAt).toBe("2026-05-24T08:30");

    vi.useRealTimers();
  });

  it("patches an existing task and preserves first completion timestamp", () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date("2026-05-23T11:00:00.000Z"));

    const original: Task = {
      id: "task-1",
      title: "Original",
      description: "",
      tags: [],
      status: "done",
      dueAt: null,
      dueDateOnly: false,
      createdAt: "2026-05-22T10:00:00.000Z",
      updatedAt: "2026-05-22T10:00:00.000Z",
      completedAt: "2026-05-22T12:00:00.000Z",
      deletedAt: null,
      lastSyncedAt: "2026-05-22T12:30:00.000Z"
    };

    const patched = patchTaskWithDraft(original, {
      title: " Updated ",
      description: " Notes ",
      tags: "one, two",
      status: "done",
      dueDate: "2026-05-24",
      dueTime: ""
    });

    expect(patched.title).toBe("Updated");
    expect(patched.description).toBe("Notes");
    expect(patched.tags).toEqual(["one", "two"]);
    expect(patched.completedAt).toBe("2026-05-22T12:00:00.000Z");
    expect(patched.lastSyncedAt).toBeNull();
    expect(patched.dueDateOnly).toBe(true);

    vi.useRealTimers();
  });

  it("detects overdue tasks and formats due labels", () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date("2026-05-23T12:00:00.000Z"));

    const overdueTask: Task = {
      id: "task-2",
      title: "Late task",
      description: "",
      tags: [],
      status: "todo",
      dueAt: "2026-05-22T09:00",
      dueDateOnly: false,
      createdAt: "",
      updatedAt: "",
      completedAt: null,
      deletedAt: null,
      lastSyncedAt: null
    };

    expect(isOverdue(overdueTask)).toBe(true);
    expect(formatDue(overdueTask)).toContain("May");

    vi.useRealTimers();
  });
});
