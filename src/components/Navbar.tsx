export default function Navbar() {
  return (
    <header className="border-b-2 border-black bg-white px-4 py-3 dark:border-white dark:bg-black">
      <div className="container mx-auto flex items-center justify-between">
        <h1 className="text-xl font-bold tracking-tight">DoUrStuff</h1>
        <nav className="flex gap-4 text-sm">
          <span className="opacity-70">Tasks</span>
        </nav>
      </div>
    </header>
  );
}
