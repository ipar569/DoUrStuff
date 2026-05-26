import { database } from "@/db/app-db";
import {
  createTask,
  listActiveTasks,
  softDeleteTask,
  updateTask,
  updateTaskStatus
} from "@/features/tasks/task-repository";

describe("task repository", () => {
  beforeEach(async () => {
    await database.tasks.clear();
  });

  it("creates and lists active tasks in newest-first order", async () => {
    await createTask({
      title: "First",
      description: "",
      tags: "",
      status: "todo",
      dueDate: "",
      dueTime: ""
    });

    await createTask({
      title: "Second",
      description: "",
      tags: "",
      status: "todo",
      dueDate: "",
      dueTime: ""
    });

    const createdTasks = await database.tasks.toArray();
    const firstTask = createdTasks.find((task) => task.title === "First");
    const secondTask = createdTasks.find((task) => task.title === "Second");

    await database.tasks.update(firstTask?.id ?? "", {
      updatedAt: "2026-05-23T09:00:00.000Z"
    });
    await database.tasks.update(secondTask?.id ?? "", {
      updatedAt: "2026-05-23T10:00:00.000Z"
    });

    const tasks = await listActiveTasks();
    expect(tasks.map((task) => task.title)).toEqual(["Second", "First"]);
  });

  it("updates status and soft-deletes tasks", async () => {
    await createTask({
      title: "Review PR",
      description: "",
      tags: "",
      status: "todo",
      dueDate: "",
      dueTime: ""
    });

    const [createdTask] = await listActiveTasks();
    await updateTaskStatus(createdTask, "done");

    let tasks = await listActiveTasks();
    expect(tasks[0]?.status).toBe("done");
    expect(tasks[0]?.completedAt).not.toBeNull();

    await updateTask(tasks[0], {
      title: "Review PR carefully",
      description: "Include mobile flows",
      tags: "work, review",
      status: "in_progress",
      dueDate: "2026-05-24",
      dueTime: "14:00"
    });

    tasks = await listActiveTasks();
    expect(tasks[0]?.title).toBe("Review PR carefully");
    expect(tasks[0]?.status).toBe("in_progress");

    await softDeleteTask(tasks[0]);
    expect(await listActiveTasks()).toEqual([]);
  });
});
