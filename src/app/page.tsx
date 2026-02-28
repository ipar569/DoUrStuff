import MainContent from "@/components/MainContent";
import TaskInput from "@/components/TaskInput";

export default function Home() {
  return (
    <div className="flex flex-col gap-8 pt-6">
      <TaskInput />
      <MainContent />
    </div>
  );
}
