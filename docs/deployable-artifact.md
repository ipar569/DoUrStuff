# Deployable GitHub Actions Artifact

This project includes a GitHub Actions workflow at [`.github/workflows/build-test-artifact.yml`](C:/Projects/DoUrStuff/.github/workflows/build-test-artifact.yml) that validates the app and produces a downloadable deployment bundle.

## What the workflow does

On `push` to `main`, on every `pull_request`, or when manually started with `workflow_dispatch`, the workflow:

1. Checks out the repository
2. Sets up `Node.js 20`
3. Installs dependencies with `npm ci`
4. Runs `npm run typecheck`
5. Runs `npm run test:run`
6. Runs `npm run build`
7. Packages the standalone production server into a single downloadable archive
8. Uploads the archive as the `dourstuff-deployable` artifact

## Downloading the artifact

1. Open the repository on GitHub.
2. Go to the `Actions` tab.
3. Open a completed run of `Build, Test, and Package App`.
4. Download the artifact named `dourstuff-deployable`.

The downloaded file is a `.tar.gz` archive containing the production-ready standalone server output plus required static and public assets.

## Running the artifact

Requirements:

- `Node.js 20` or newer

Steps:

1. Extract the `dourstuff-deployable.tar.gz` archive.
2. Open a terminal in the extracted folder.
3. Start the server:

```bash
node server.js
```

By default, the app listens on port `3000`.

If your hosting platform requires a different port, set `PORT` before starting:

```bash
PORT=8080 node server.js
```

On Windows PowerShell:

```powershell
$env:PORT = "8080"
node server.js
```

## What is inside the bundle

The workflow assembles the artifact from:

- `.next/standalone`
- `.next/static`
- `public`

This matches the standard deployable output for a standalone Next.js server build.

## When to use this artifact

Use the GitHub Actions artifact when:

- you want a tested CI-produced bundle
- you do not want the target server to run `npm install` and `npm run build`
- you want a downloadable build output attached to each workflow run

Use a platform like Vercel when you want a more fully managed Next.js deployment flow.
