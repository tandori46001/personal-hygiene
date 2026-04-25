# Branch protection

Documentation of the intended protection rules for `main`. Apply these via repo Settings → Branches, or via the `gh` CLI snippet below.

> ⚠️ **Free-tier limitation (verified 2026-04-25):** Branch protection rules AND repository rulesets both require **GitHub Pro** when the repo is private. Both API endpoints return `403: Upgrade to GitHub Pro or make this repository public`. Until the repo goes public or upgrades to Pro, formal protection is NOT enforced — rely on Git client discipline (no `--force`, no branch delete on `main`).

---

## Rules for `main`

- ✅ Require a pull request before merging
- ✅ Require approvals — minimum 1 (self-approval allowed for solo maintainer)
- ✅ Dismiss stale pull request approvals when new commits are pushed
- ✅ Require status checks to pass before merging
  - Required checks:
    - `Repo hygiene`
    - `Lint Swift` (when applicable)
    - `Build + test (iOS)` (when applicable)
- ✅ Require branches to be up to date before merging
- ✅ Require conversation resolution before merging
- ✅ Require signed commits (recommended once GPG / SSH signing is set up)
- ✅ Require linear history (squash-merge only)
- ❌ Do NOT allow force pushes
- ❌ Do NOT allow deletions
- ✅ Restrict who can push to matching branches — only `tandori46001` (the maintainer)

---

## Quick-setup via `gh` CLI

```bash
gh api -X PUT \
  /repos/tandori46001/personal-hygiene/branches/main/protection \
  --input - <<'JSON'
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["Repo hygiene"]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true
  },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_conversation_resolution": true
}
JSON
```

After Phase 0 ships the Xcode project, add `Lint Swift` and `Build + test (iOS)` to `required_status_checks.contexts`.

---

## Notes

- **Solo maintainer note:** GitHub allows the repo owner to bypass the "require PR review" rule by default. Toggle "Include administrators" in branch protection settings if you want the rules to apply to yourself too — useful as a guardrail against accidental direct push to `main`.
- **Signed commits:** set up SSH signing via `git config --global gpg.format ssh` + add the key to your GitHub profile under "SSH and GPG keys" → "Signing key".
