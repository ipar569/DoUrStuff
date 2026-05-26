import { ChevronLeft, ChevronRight } from "lucide-react";
import { cn } from "@/lib/utils";
import type { Task } from "@/features/tasks/types";

const WEEKDAY_LABELS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

export function TaskCalendar({
  monthDate,
  tasks,
  onMonthChange,
  onTaskSelect
}: {
  monthDate: Date;
  tasks: Task[];
  onMonthChange: (nextMonth: Date) => void;
  onTaskSelect: (task: Task) => void;
}) {
  const monthLabel = new Intl.DateTimeFormat(undefined, {
    month: "long",
    year: "numeric"
  }).format(monthDate);

  const calendarDays = buildCalendarDays(monthDate, tasks);
  const undatedTasks = tasks.filter((task) => !task.dueAt);

  return (
    <section className="glass-panel rounded-[2rem] p-4 sm:p-6">
      <div className="flex flex-wrap items-center justify-between gap-3 border-b border-black/5 pb-4">
        <div>
          <h2 className="text-xl font-semibold text-ink-950">Calendar</h2>
          <p className="text-sm text-ink-700">See due work by day and jump straight into editing.</p>
        </div>

        <div className="flex items-center gap-2 rounded-full border border-black/8 bg-white/80 p-1.5">
          <MonthButton
            label="Previous month"
            onClick={() => onMonthChange(addMonths(monthDate, -1))}
          >
            <ChevronLeft className="h-4 w-4" />
          </MonthButton>
          <div className="min-w-36 px-2 text-center text-sm font-medium text-ink-950">{monthLabel}</div>
          <MonthButton
            label="Next month"
            onClick={() => onMonthChange(addMonths(monthDate, 1))}
          >
            <ChevronRight className="h-4 w-4" />
          </MonthButton>
        </div>
      </div>

      <div className="mt-5 grid grid-cols-7 gap-2">
        {WEEKDAY_LABELS.map((label) => (
          <div key={label} className="px-2 py-1 text-center text-xs font-medium uppercase tracking-[0.22em] text-ink-500">
            {label}
          </div>
        ))}

        {calendarDays.map((day) => (
          <div
            key={day.isoDate}
            className={cn(
              "min-h-32 rounded-[1.35rem] border p-3",
              day.isCurrentMonth ? "border-black/5 bg-white/80" : "border-transparent bg-white/35"
            )}
          >
            <div className="flex items-center justify-between">
              <span
                className={cn(
                  "text-sm font-medium",
                  day.isToday ? "rounded-full bg-ink-950 px-2.5 py-1 text-white" : "text-ink-950",
                  !day.isCurrentMonth && "text-ink-500"
                )}
              >
                {day.date.getDate()}
              </span>
              {day.tasks.length ? (
                <span className="rounded-full bg-moss-500/12 px-2 py-1 text-[0.7rem] font-medium uppercase tracking-[0.18em] text-moss-600">
                  {day.tasks.length}
                </span>
              ) : null}
            </div>

            <div className="mt-3 space-y-2">
              {day.tasks.slice(0, 3).map((task) => (
                <button
                  key={task.id}
                  className="w-full rounded-2xl bg-sand-100 px-3 py-2 text-left text-xs text-ink-950 transition hover:bg-sand-200"
                  onClick={() => onTaskSelect(task)}
                  type="button"
                >
                  <span className="block truncate font-medium">{task.title}</span>
                  <span className="mt-1 block text-[0.7rem] uppercase tracking-[0.16em] text-ink-500">
                    {task.status.replaceAll("_", " ")}
                  </span>
                </button>
              ))}
              {day.tasks.length > 3 ? (
                <div className="px-1 text-xs text-ink-500">+{day.tasks.length - 3} more</div>
              ) : null}
            </div>
          </div>
        ))}
      </div>

      {undatedTasks.length ? (
        <div className="mt-5 rounded-[1.5rem] border border-dashed border-black/10 bg-white/55 p-4">
          <div className="flex flex-wrap items-center gap-2">
            <span className="text-sm font-medium text-ink-950">No due date yet</span>
            <span className="text-sm text-ink-500">{undatedTasks.length} task{undatedTasks.length === 1 ? "" : "s"}</span>
          </div>
          <div className="mt-3 flex flex-wrap gap-2">
            {undatedTasks.slice(0, 6).map((task) => (
              <button
                key={task.id}
                className="rounded-full border border-black/8 bg-white px-3 py-2 text-sm text-ink-700 transition hover:border-moss-500"
                onClick={() => onTaskSelect(task)}
                type="button"
              >
                {task.title}
              </button>
            ))}
          </div>
        </div>
      ) : null}
    </section>
  );
}

function MonthButton({
  children,
  label,
  onClick
}: {
  children: React.ReactNode;
  label: string;
  onClick: () => void;
}) {
  return (
    <button
      aria-label={label}
      className="rounded-full border border-black/8 bg-white p-2 text-ink-700 transition hover:border-moss-500 hover:text-ink-950"
      onClick={onClick}
      type="button"
    >
      {children}
    </button>
  );
}

function buildCalendarDays(monthDate: Date, tasks: Task[]) {
  const startOfMonth = new Date(monthDate.getFullYear(), monthDate.getMonth(), 1);
  const startDay = (startOfMonth.getDay() + 6) % 7;
  const gridStart = new Date(startOfMonth);
  gridStart.setDate(startOfMonth.getDate() - startDay);

  return Array.from({ length: 42 }, (_, index) => {
    const date = new Date(gridStart);
    date.setDate(gridStart.getDate() + index);
    const isoDate = toIsoDate(date);

    return {
      date,
      isoDate,
      isCurrentMonth: date.getMonth() === monthDate.getMonth(),
      isToday: isoDate === toIsoDate(new Date()),
      tasks: tasks.filter((task) => task.dueAt && task.dueAt.slice(0, 10) === isoDate)
    };
  });
}

function addMonths(date: Date, delta: number) {
  return new Date(date.getFullYear(), date.getMonth() + delta, 1);
}

function toIsoDate(date: Date) {
  return [
    date.getFullYear(),
    String(date.getMonth() + 1).padStart(2, "0"),
    String(date.getDate()).padStart(2, "0")
  ].join("-");
}
