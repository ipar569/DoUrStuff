"use client";

export default function TaskInput() {
  return (
    <section className="rounded border-2 border-black bg-white p-4 dark:border-white dark:bg-black">
      <h2 className="mb-3 text-sm font-semibold uppercase tracking-wider opacity-80">
        Add task
      </h2>
      <div className="flex flex-col gap-3">
        <input
          type="text"
          placeholder="Task title"
          className="rounded border-2 border-black bg-transparent px-3 py-2 placeholder:opacity-50 focus:outline-none focus:ring-2 focus:ring-black dark:border-white dark:focus:ring-white"
          readOnly
          disabled
        />
        <textarea
          placeholder="Description (optional)"
          rows={2}
          className="rounded border-2 border-black bg-transparent px-3 py-2 placeholder:opacity-50 focus:outline-none focus:ring-2 focus:ring-black dark:border-white dark:focus:ring-white"
          readOnly
          disabled
        />
        <div className="flex flex-wrap gap-2">
          <button
            type="button"
            className="rounded border-2 border-black px-3 py-1.5 text-sm font-medium hover:bg-black hover:text-white focus:outline-none focus:ring-2 focus:ring-black dark:border-white dark:hover:bg-white dark:hover:text-black dark:focus:ring-white"
            disabled
          >
            + Add task
          </button>
        </div>
      </div>
    </section>
  );
}
