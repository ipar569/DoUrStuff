import { dummyTasks } from "@/lib/dummy-data";

export default function MainContent() {
  return (
    <section className="rounded border-2 border-black bg-white dark:border-white dark:bg-black">
      <h2 className="border-b-2 border-black px-4 py-3 text-sm font-semibold uppercase tracking-wider opacity-80 dark:border-white">
        Tasks
      </h2>
      <ul className="divide-y-2 divide-black dark:divide-white">
        {dummyTasks.map((task) => (
          <li
            key={task.id}
            className="flex items-start gap-3 px-4 py-3 transition-colors hover:bg-black/5 dark:hover:bg-white/5"
          >
            <input
              type="checkbox"
              checked={task.isCompleted}
              readOnly
              className="mt-1 size-4 rounded border-2 border-black dark:border-white"
            />
            <div className="min-w-0 flex-1">
              <span
                className={
                  task.isCompleted
                    ? "text-opacity-60 line-through"
                    : "font-medium"
                }
              >
                {task.title}
              </span>
              {task.description && (
                <p className="mt-0.5 text-sm opacity-70">{task.description}</p>
              )}
              {task.tags.length > 0 && (
                <div className="mt-1.5 flex flex-wrap gap-1">
                  {task.tags.map((tag) => (
                    <span
                      key={tag}
                      className="rounded bg-black px-2 py-0.5 text-xs text-white dark:bg-white dark:text-black"
                    >
                      {tag}
                    </span>
                  ))}
                </div>
              )}
            </div>
          </li>
        ))}
      </ul>
    </section>
  );
}
