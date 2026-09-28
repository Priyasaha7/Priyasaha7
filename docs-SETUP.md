# Github_Automation

> This repo is now named `Priyasaha7` so it doubles as the GitHub **profile
> repository**. The root `README.md` is the styled profile card that renders on
> the profile page; these setup notes live here in `docs-SETUP.md`.

Daily activity commits plus a styled GitHub profile README.

## 1. Rotate your credentials first

Your password was exposed in plain text. Before anything else:

1. https://github.com/settings/security -> change password
2. Enable two-factor authentication
3. https://github.com/settings/tokens -> revoke anything you don't recognise

Nothing in this repo needs your password. GitHub removed password
authentication for Git operations in August 2021 — an account password will be
rejected outright. Authentication uses a Personal Access Token.

## 2. Create your .env

```powershell
Copy-Item .env.example .env
notepad .env
```

Get a token at https://github.com/settings/tokens -> **Fine-grained tokens** ->
*Generate new token*. Scope it to just this repository and grant
**Contents: Read and write**. Nothing else. Paste it as `GITHUB_TOKEN`.

`.env` is gitignored, so it will not be committed. Verify any time with:

```powershell
git check-ignore -v .env      # prints a .gitignore rule = safely ignored
```

A token is safer than a password: it is scoped to one repo, it expires, and you
can revoke it without changing your login. If you set an expiry, the daily push
will start failing when it lapses — check `logs/daily-commit.log` and issue a
new token.

## 3. Push this repo

The repo is already initialised with a `main` branch and a first commit. Create
an empty `Github_Automation` repo on GitHub (no README, no .gitignore), then:

```powershell
cd d:\GithubAutomate
git add .
git commit -m "feat: token auth via .env"
git remote add origin https://github.com/Priyasaha7/Github_Automation.git
git push -u origin main
```

This first push uses Git Credential Manager and opens a browser to sign in. The
`.env` token is used by the daily script from then on.

## 4. Daily commits

Two independent options. **Pick one** so you don't get duplicate commits.

### Option A — GitHub Actions (recommended)

[.github/workflows/daily-commit.yml](.github/workflows/daily-commit.yml) runs at
03:30 UTC daily. No machine needs to be switched on. Trigger a test run from the
repo's **Actions** tab via *Run workflow*.

Scheduled workflows are paused after 60 days of repository inactivity — the
daily commit itself counts as activity, so this self-sustains.

### Option B — Windows Task Scheduler

```powershell
cd d:\GithubAutomate
.\scripts\daily-commit.ps1 -NoPush     # dry run, keeps commit local
.\scripts\install-schedule.ps1 -At 09:30
```

Manage it afterwards:

```powershell
Start-ScheduledTask       -TaskName GithubDailyCommit
Get-ScheduledTaskInfo     -TaskName GithubDailyCommit
Unregister-ScheduledTask  -TaskName GithubDailyCommit -Confirm:$false
```

Runs are appended to `logs/daily-commit.log`. The script is idempotent: a second
run on the same day does nothing.

If you use Option B, delete the workflow file.

## 5. Style your profile

The green squares only fill in for commits to a repo GitHub counts as a
contribution, so keep the repo public (Settings -> General -> Change visibility)
or enable *Include private contributions* under
https://github.com/settings/profile.

To install the profile README:

1. Create a **public** repo named exactly `Priyasaha7` — GitHub shows a special
   "you found a secret" banner when the name matches your username
2. Copy [profile-readme/README.md](profile-readme/README.md) into it as `README.md`
3. Commit and push — it renders at the top of your profile

Also worth doing on https://github.com/settings/profile: add a bio, location,
and profile picture. Then pin your best 6 repos from your profile page.

## A note on artificial activity

These commits are real commits to a real repo, but they are not real work.
Recruiters look at project quality far more than square colour. Treat the
streak as a habit tracker, not a portfolio.
