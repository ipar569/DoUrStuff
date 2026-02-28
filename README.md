# DoUrStuff

A minimalist, offline-first, cross-platform task manager designed for speed and seamless synchronization between mobile and desktop environments.

## 🌟 Objective
To create a high-performance task ecosystem where tasks can be entered instantly on an Android device (even while offline) and synchronized automatically to MacBook and Windows desktop environments for analysis and management.

## 🏗️ Technical Architecture

| Component | Technology | Role |
| :--- | :--- | :--- |
| **Framework** | Next.js (React) | UI and Frontend Logic |
| **Styling** | Tailwind CSS | Brutalist, mobile-responsive design |
| **Database/Sync** | Supabase (PostgreSQL) | Cloud data storage, Authentication, and Realtime sync |
| **Offline Sync** | Dexie.js (IndexedDB) | Local browser storage for offline-first capability |
| **State Management**| TanStack Query | Managing server state and cache |
| **Notifications** | Web Push API | Background notifications on Android |

## 📂 Project Structure

```text
DoUrStuff/
├── docs/                # Product Requirements and Technical Docs
│   ├── prd.md
│   └── ai-prompts.md    # Step-by-step AI prompts for development
├── src/
│   ├── components/      # UI Atoms (Input, TaskItem, DatePicker)
│   ├── hooks/           # Custom hooks (useTasks, useSync)
│   ├── lib/             # Supabase & Dexie client setup
│   └── (sw generated)   # Service Worker for PWA & Notifications (e.g. next-pwa)
├── public/              # Icons and PWA manifest
└── README.md
```

## 🚀 Getting Started

**Prerequisites:** Node.js 18+, npm or pnpm

```bash
git clone <repo-url>
cd DoUrStuff
npm install
```

Create a `.env.local` with your Supabase credentials:

```env
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
```

```bash
npm run dev
```