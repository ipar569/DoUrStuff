import Dexie, { type EntityTable } from "dexie";
import type { Task } from "@/features/tasks/types";

const database = new Dexie("dourstuff") as Dexie & {
  tasks: EntityTable<Task, "id">;
};

database.version(1).stores({
  tasks: "id, status, updatedAt, dueAt, deletedAt"
});

export { database };
