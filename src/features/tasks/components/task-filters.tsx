import type { TaskFilterId } from "@/features/tasks/hooks/use-tasks";

export function TaskFilters({
  currentFilter,
  filters,
  onFilterChange
}: {
  currentFilter: TaskFilterId;
  filters: ReadonlyArray<{ id: TaskFilterId; label: string }>;
  onFilterChange: (filter: TaskFilterId) => void;
}) {
  return (
    <div className="flex rounded-full bg-sand-100 p-1">
      {filters.map((item) => (
        <button
          key={item.id}
          className={`rounded-full px-4 py-2 text-sm transition ${
            currentFilter === item.id ? "bg-white text-ink-950 shadow-sm" : "text-ink-700"
          }`}
          onClick={() => onFilterChange(item.id)}
          type="button"
        >
          {item.label}
        </button>
      ))}
    </div>
  );
}
