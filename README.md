# GithubAutomate

Daily activity commits plus a styled GitHub profile README.

## 1. Rotate your credentials first

Your password was exposed in plain text. Before anything else:

1. https://github.com/settings/security -> change password
2. Enable two-factor authentication
3. https://github.com/settings/tokens -> revoke anything you don't recognise

Nothing in this repo needs your password. Authentication uses either your
existing Git Credential Manager login, an SSH key, or a fine-grained
Personal Access Token.

## 2. Push this repo

```powershell
cd d:\GithubAutomate
git init
git add .
git commit -m "chore: initial commit"
git branch -M main
git remote add origin https://github.com/Priyasaha7/GithubAutomate.git
git push -u origin main
```

Create the empty `GithubAutomate` repo on GitHub first (no README, no
.gitignore). On the first push, Git Credential Manager will open a browser
window — sign in there instead of typing a password into the terminal.

## 3. Daily commits

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

## 4. Style your profile

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
