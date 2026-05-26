import { TaskFilters } from "@/features/tasks/components/task-filters";
import { TaskList } from "@/features/tasks/components/task-list";
import type { TaskFilterId } from "@/features/tasks/hooks/use-tasks";
import type { Task } from "@/features/tasks/types";

export function TaskBoard({
  currentFilter,
  filters,
  tasks,
  onEdit,
  onFilterChange
}: {
  currentFilter: TaskFilterId;
  filters: ReadonlyArray<{ id: TaskFilterId; label: string }>;
  tasks: Task[];
  onEdit: (task: Task) => void;
  onFilterChange: (filter: TaskFilterId) => void;
}) {
  return (
    <div className="glass-panel rounded-[2rem] p-4 sm:p-6">
      <div className="flex flex-wrap items-center justify-between gap-3 border-b border-black/5 pb-4">
        <div>
          <h2 className="text-xl font-semibold text-ink-950">Task board</h2>
          <p className="text-sm text-ink-700">The main working view for capturing, sorting, and updating tasks.</p>
        </div>
        <TaskFilters currentFilter={currentFilter} filters={filters} onFilterChange={onFilterChange} />
      </div>

      <TaskList tasks={tasks} onEdit={onEdit} />
    </div>
  );
}
