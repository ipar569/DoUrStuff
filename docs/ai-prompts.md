# AI Prompt Sequence - DoUrStuff Development

This document outlines the step-by-step prompts to use with your AI coding tool to build **DoUrStuff** in the correct order to ensure offline capability and sync functionality work from the start.

## 1. Project Initialization & Structure
> "Please initialize a new Next.js project using Tailwind CSS. Based on the requirements in `docs/prd.md`, set up the project folder structure. Do not write feature logic yet, just set up the basic layout (Navbar, Main Content Area, Task Input area) with dummy data."

## 2. Local Database Setup (Offline-First)
> "We need to set up `dexie.js` for local storage in the browser (IndexedDB). Initialize the database connection. Define the `tasks` table schema in Dexie according to the structure in `docs/prd.md`. Create a custom hook (e.g. `useLocalTasks` or `useTasks`) to fetch and store tasks locally."

## 3. Core UI & Task Entry
> "Create a task input component that allows the user to enter a title, description, tags, and pick start/end dates. When the user submits, save this task to `dexie.js` immediately. Ensure the task appears in the list instantly using React state, even before syncing."

## 4. Backend & Sync Setup (Supabase)
> "Set up the Supabase client in the project. Set up Supabase Auth (e.g. email or magic link) so sync is per-user. Create a `tasks` table in Supabase matching the structure in `docs/prd.md`. Define Row Level Security (RLS) policies so each user can only read and write their own tasks. Implement a sync function that takes tasks from Dexie and updates the Supabase table, and vice-versa. Ensure conflict resolution uses last-write-wins via the `updated_at` field."

## 5. PWA & Service Worker
> "Configure this project as a Progressive Web App (PWA). Use `next-pwa` or a maintained alternative (e.g. `@ducanh2912/next-pwa`) and ensure a service worker is generated to cache assets so the app works offline."

## 6. Notifications (Web Push API)
> "Implement Web Push Notifications.
> 1. Set up a VAPID key pair.
> 2. Create a frontend function to request permission and subscribe to push notifications.
> 3. Create a `subscriptions` table in Supabase to store the user's subscription object.
> 4. Implement logic in the service worker to receive a push event and show a notification on the Android device.
> 5. Add a Supabase Edge Function (or scheduled job) that sends push messages to stored subscriptions for upcoming tasks (e.g. based on `start_date`)."