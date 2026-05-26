export function TaskLogo() {
  return (
    <div className="flex items-center gap-3">
      <div className="relative flex h-12 w-12 items-center justify-center overflow-hidden rounded-[1.35rem] bg-ink-950 shadow-calm">
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_top,rgba(212,174,104,0.42),transparent_45%),radial-gradient(circle_at_bottom_right,rgba(105,130,107,0.4),transparent_40%)]" />
        <div className="relative h-7 w-7 rounded-[0.9rem] border border-white/25 bg-white/10">
          <span className="absolute left-1.5 top-1.5 h-1.5 w-3.5 rounded-full bg-white/90" />
          <span className="absolute left-1.5 top-4 h-1.5 w-4.5 rounded-full bg-gold-400" />
        </div>
      </div>

      <div>
        <p className="text-[0.72rem] font-medium uppercase tracking-[0.28em] text-ink-500">DoUrStuff</p>
        <h1 className="text-xl font-semibold tracking-tight text-ink-950 sm:text-2xl">Tasks that stay tidy</h1>
      </div>
    </div>
  );
}
