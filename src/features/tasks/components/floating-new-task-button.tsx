import { Plus } from "lucide-react";

export function FloatingNewTaskButton({
  onClick
}: {
  onClick: () => void;
}) {
  return (
    <button
      aria-label="Create a new task"
      className="fixed bottom-5 right-5 z-30 inline-flex h-16 w-16 items-center justify-center rounded-full bg-ink-950 text-white shadow-[0_16px_35px_rgba(34,32,29,0.24)] transition hover:scale-[1.03] hover:bg-moss-600 sm:bottom-8 sm:right-8"
      onClick={onClick}
      type="button"
    >
      <Plus className="h-6 w-6" />
    </button>
  );
}
