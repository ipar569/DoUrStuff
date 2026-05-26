import React from "react";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { TaskList } from "@/features/tasks/components/task-list";
import type { Task } from "@/features/tasks/types";
import * as taskRepository from "@/features/tasks/task-repository";

describe("TaskList", () => {
  afterEach(() => {
    vi.restoreAllMocks();
  });

  it("renders the empty state", () => {
    render(<TaskList onEdit={vi.fn()} tasks={[]} />);

    expect(screen.getByText("Nothing here yet")).toBeInTheDocument();
    expect(screen.getByText(/IndexedDB and stays available offline/i)).toBeInTheDocument();
  });

  it("renders task details and forwards actions", async () => {
    const user = userEvent.setup();
    const editSpy = vi.fn();
    const completeSpy = vi.spyOn(taskRepository, "updateTaskStatus").mockResolvedValue(1);
    const deleteSpy = vi.spyOn(taskRepository, "softDeleteTask").mockResolvedValue(1);

    const task: Task = {
      id: "task-1",
      title: "Plan launch",
      description: "Outline tasks for the launch checklist",
      tags: ["release", "planning"],
      status: "todo",
      dueAt: "2026-05-24T10:00",
      dueDateOnly: false,
      createdAt: "2026-05-23T08:00:00.000Z",
      updatedAt: "2026-05-23T08:00:00.000Z",
      completedAt: null,
      deletedAt: null,
      lastSyncedAt: null
    };

    render(<TaskList onEdit={editSpy} tasks={[task]} />);

    expect(screen.getByText("Plan launch")).toBeInTheDocument();
    expect(screen.getByText("#release")).toBeInTheDocument();
    expect(screen.getByText("#planning")).toBeInTheDocument();

    await user.click(screen.getByRole("button", { name: /mark complete/i }));
    expect(completeSpy).toHaveBeenCalledWith(task, "done");

    await user.click(screen.getByRole("button", { name: /edit task/i }));
    expect(editSpy).toHaveBeenCalledWith(task);

    await user.click(screen.getByRole("button", { name: /delete task/i }));
    expect(deleteSpy).toHaveBeenCalledWith(task);
  });
});
