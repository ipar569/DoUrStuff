# DoUrStuff

DoUrStuff is a local-first task manager built with `Next.js`, `React`, `Tailwind CSS`, and `Dexie` for offline storage. It is designed to work well on desktop and mobile, keep task data available offline, and be installable on phones as a Progressive Web App (PWA).

## Current status

The app already includes:

- a responsive task UI for mobile and desktop
- local task storage with `IndexedDB`
- offline support via a service worker
- a web app manifest so it can be installed as a PWA

The project does not currently ship as a native Android or iOS app. Mobile installation today is done through the browser as an installable PWA.

## Tech stack

- `Next.js 15`
- `React 19`
- `TypeScript`
- `Tailwind CSS`
- `Dexie` for `IndexedDB`
- `Vitest` + Testing Library

## Prerequisites

Install these before running the project locally:

- `Node.js` 20 or newer
- `npm` 10 or newer

To confirm your versions:

```bash
node -v
npm -v
```

## Local setup

1. Clone the repository.
2. Move into the project folder.
3. Install dependencies.

```bash
npm install
```

## Run locally

Start the development server:

```bash
npm run dev
```

Then open:

```text
http://localhost:3000
```

The app uses the default Next.js development port unless that port is already taken.

## Available scripts

- `npm run dev` starts the local development server
- `npm run build` creates a production build
- `npm run start` runs the production build locally
- `npm run test:run` runs the test suite once
- `npm run test` starts Vitest in watch mode
- `npm run typecheck` runs TypeScript checks

## Recommended local verification

Before deploying, run:

```bash
npm run typecheck
npm run test:run
npm run build
```

This gives a quick check that the app type-checks, tests pass, and the production build succeeds.

## How offline support works

- Tasks are stored in the browser with `IndexedDB`
- The service worker caches the app shell and fetched assets
- After the first successful load, the app should reopen even when the device is offline

Important notes:

- Offline data is browser-local right now
- If you clear browser storage, local tasks will be removed
- Cross-device sync is planned, but not implemented yet

## Production run locally

If you want to test the production build on your machine:

1. Build the app:

```bash
npm run build
```

2. Start the production server:

```bash
npm run start
```

3. Open `http://localhost:3000`

This is the best way to test installability and production behavior before deploying.

## Deploying

The simplest deployment target for this app is `Vercel`, because this is a standard `Next.js` application.

### GitHub Actions build artifact

This repository includes a GitHub Actions workflow at [`.github/workflows/build-test-artifact.yml`](C:/Projects/DoUrStuff/.github/workflows/build-test-artifact.yml).

The workflow:

- installs dependencies with `npm ci`
- runs `npm run typecheck`
- runs `npm run test:run`
- runs `npm run build`
- packages a deployable standalone Node bundle
- uploads that bundle as a downloadable Actions artifact named `dourstuff-deployable`

For full usage steps, see [docs/deployable-artifact.md](C:/Projects/DoUrStuff/docs/deployable-artifact.md).

### Deploy with Vercel

1. Push the repository to GitHub.
2. Import the repository into [Vercel](https://vercel.com/).
3. Keep the default framework setting as `Next.js`.
4. Build command: `npm run build`
5. Output setting: leave it as Vercel's default for Next.js
6. Deploy

At the moment, this project does not require any environment variables for the current local-first feature set.

### Deploy to another Node host

You can also deploy it anywhere that supports `Next.js`:

1. Install dependencies with `npm install`
2. Build with `npm run build`
3. Start with `npm run start`

The host must support running a Node server for Next.js.

### Deploy from the GitHub Actions artifact

If you want a prebuilt bundle from CI instead of building on the server:

1. Open the completed GitHub Actions run.
2. Download the `dourstuff-deployable` artifact.
3. Extract the archive on a machine with `Node.js 20` or newer.
4. Start the app with:

```bash
node server.js
```

By default, the server listens on port `3000`. Set `PORT` if your host requires a different port.

## Installing on mobile devices

This app is installed on phones as a PWA, not from an app store package.

### iPhone or iPad

1. Open the deployed app URL in `Safari`
2. Tap the `Share` button
3. Tap `Add to Home Screen`
4. Confirm the name and add it

After that, the app should launch from the home screen in a standalone app-like window.

### Android

1. Open the deployed app URL in `Chrome`
2. Open the browser menu
3. Tap `Install app` or `Add to Home screen`
4. Confirm the installation

Android wording varies slightly by device and browser version, but the flow is usually close to the steps above.

## Important install limitations

- The app must usually be served over `https` in production for full PWA behavior
- Some install prompts behave differently across browsers
- iOS PWA support is more limited than Android in areas like background behavior and notifications
- This project currently supports browser-based installation, not App Store or Google Play submission

## If install does not appear

Check these first:

- the app is opened from a deployed URL, not just a local network page
- the site is using `https`
- the page has fully loaded at least once
- you are using a supported browser such as `Safari` on iPhone or `Chrome` on Android

## Project structure

```text
src/
  app/                Next.js app router files
  components/         shared UI and PWA setup
  db/                 local IndexedDB layer
  features/tasks/     task domain logic, hooks, tests, and components
public/
  icons/              PWA icons
  sw.js               service worker
docs/
  architecture-plan.md
  deployable-artifact.md
```

## Architecture notes

- Product and architecture plan: [docs/architecture-plan.md](C:/Projects/DoUrStuff/docs/architecture-plan.md)

## Future roadmap

Planned areas that are not fully implemented yet:

- account sign-in
- cloud sync across devices
- reminders and recurring tasks
- backup and sharing features
- AI-assisted task creation

## Troubleshooting

### Port 3000 is already in use

Stop the other local server using port `3000`, or run Next.js on another port.

### Changes are not reflected in the installed app

PWAs may continue using cached assets for a short time. Try:

- refreshing the page
- closing and reopening the installed app
- clearing site data if you need a clean local reset

### Local tasks disappeared

The app currently stores tasks in browser-local storage through `IndexedDB`. If browser storage is cleared, that data is lost until sync is added in a future version.
