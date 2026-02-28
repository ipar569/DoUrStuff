# Product Requirements Document (PRD) - DoUrStuff

| Project | DoUrStuff |
| :--- | :--- |
| **Objective** | Cross-platform Task Management Ecosystem |
| **Platform** | Web (Next.js PWA), Android (Installed PWA) |
| **Status** | Planning |

---

## 1. Executive Summary
**DoUrStuff** is a minimalist, offline-first task management application designed for speed and seamless synchronization. It bridges the gap between on-the-go mobile task capture (Android) and heavy-duty desktop management (Mac/Windows).

---

## 2. Target Audience
* **Solo Users:** Individuals looking for a personalized, fast, and reliable way to manage daily tasks without complex project management overhead.

---

## 3. Core Requirements & Features (MVP)

### 3.1. Task Lifecycle & Structure
Tasks must contain the following data structure:
* **ID:** UUID (Client-generated for offline support)
* **Title:** String
* **Description:** Text (plain text with optional Markdown for MVP; rich-text editor post-MVP)
* **Tags:** Array of strings (For categorization)
* **Start Date:** DateTime (Optional)
* **End Date:** DateTime (Optional)
* **Is Completed:** Boolean
* **Is Recurring:** Boolean
* **Recurrence Rule:** String (e.g., "DAILY", "WEEKLY", "CRON_FORMAT")
* **Updated At:** DateTime (For conflict resolution)

### 3.2. Offline-First Capability (Android Focus)
* The application must function without an internet connection.
* Data must be saved immediately to `IndexedDB` (using `dexie.js`) upon task creation or edit.
* The UI must reflect local changes immediately ("Optimistic UI").

### 3.3. Cross-Device Synchronization
* Data must sync with `Supabase` (PostgreSQL) when an internet connection is available.
* **Conflict Resolution:** Last-Write-Wins based on `updated_at` timestamp. If `updated_at` is equal, prefer the server version for determinism.
* **Sync Logic:** Local `IndexedDB` acts as the source of truth for the device; Supabase acts as the centralized source of truth for all devices. Sync is per-user (Supabase Auth); users only see and sync their own tasks.

### 3.4. Notifications (Android)
* Push notifications for upcoming tasks (`start_date`).
* Requires `Service Worker` to manage push events when the application is closed.

---

## 4. User Flows

### 4.1. Add Task (Offline)
1. User opens DoUrStuff on Android (Airplane mode).
2. User clicks "+" and enters task details.
3. Task is saved to local `IndexedDB`.
4. Task appears in the local list immediately.
5. Service worker queues the sync request.

### 4.2. Sync Task (Online)
1. User enters Wi-Fi coverage.
2. Service worker detects connection.
3. Local `IndexedDB` data is pushed to Supabase.
4. Supabase Realtime pushes changes to connected Desktop sessions (Mac/Windows).

---

## 5. Technical Architecture

| Layer | Technology |
| :--- | :--- |
| **Frontend** | Next.js (React) |
| **Styling** | Tailwind CSS |
| **Local DB** | Dexie.js (IndexedDB wrapper) |
| **Backend/Cloud** | Supabase (PostgreSQL) |
| **Auth** | Supabase Auth (Email or Social) |
| **Notifications** | Web Push API + Supabase Edge Functions |

---

## 6. Non-Functional Requirements
* **Performance:** UI interactions must be under 100ms.
* **Responsiveness:** Mobile-first design, adaptive layout for desktop.
* **Security:** Supabase Row Level Security (RLS) must be enabled to ensure users only see their own data.

---

## 7. Future Considerations (Post-MVP)
* AI-powered task parsing (e.g., "Buy milk tomorrow 5pm" parsing into dates).
* Data visualization/analytics based on tags.
* Export functionality (JSON/CSV).