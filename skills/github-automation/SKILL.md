---
name: github-automation
description: "Automate GitHub operations: repo creation/deletion, file push/pull, issue/PR management, release publishing, organization control, and GitHub Actions workflow triggers. Use `gh` CLI and REST API."
---

# GitHub Automation Skill

Use `gh` CLI and GitHub REST API to automate all GitHub operations. Authentication via `gh auth` (already configured with `zengbaocheng1`).

## Authentication Check

Always verify auth is working:
```bash
gh auth status
```

If not logged in, check `~/.config/gh/hosts.yml` and ensure token is present.

## Repository Operations

### Create Repository
```bash
gh repo create <name> --public --source=/path/to/dir --push
```

Or via API:
```bash
curl -s -X POST "https://api.github.com/user/repos" \
  -H "Authorization: token $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"repo-name","description":"...","public":true}'
```

### Clone Repository
```bash
gh repo clone owner/repo [/local/path]
```
Or with token:
```bash
git clone https://x-access-token:$TOKEN@github.com/owner/repo.git
```

### Delete Repository
```bash
gh repo delete owner/repo --yes
```

### Update Repo Metadata
```bash
curl -s -X PATCH "https://api.github.com/repos/owner/repo" \
  -H "Authorization: token $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"description":"...","topics":["topic1","topic2"]}'
```

## File Operations

### Push Files to Repo
```bash
git clone https://x-access-token:$TOKEN@github.com/owner/repo.git /tmp/repo-work
# copy files, commit, push
cd /tmp/repo-work && git add -A && git commit -m "message" && git push origin main
```

### Download Single File
```bash
gh api repos/owner/repo/contents/path/to/file --jq '.content' | base64 -d
```

### Upload File (create or update)
```bash
# Get current SHA if updating
SHA=$(gh api repos/owner/repo/contents/path --jq '.sha')
curl -s -X PUT "https://api.github.com/repos/owner/repo/contents/path" \
  -H "Authorization: token $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"message\":\"commit msg\",\"content\":\"$(base64 -w0 /tmp/file)\",\"sha\":\"$SHA\"}"
```

## Issues

```bash
# List issues
gh issue list --repo owner/repo --state open --limit 20

# Create issue
gh issue create --repo owner/repo --title "Bug: ..." --body "Description" --label bug

# Close issue
gh issue close <number> --repo owner/repo

# Add comment
gh issue comment <number> --repo owner/repo --body "Comment text"
```

## Pull Requests

```bash
# List PRs
gh pr list --repo owner/repo --state open

# Create PR
gh pr create --repo owner/repo --title "Feature: ..." --body "Description" --base main

# View PR checks
gh pr checks <pr-number> --repo owner/repo

# Merge PR
gh pr merge <pr-number> --repo owner/repo --squash
```

## Releases

```bash
# Create release
gh release create v1.0.0 --repo owner/repo --title "v1.0.0" --notes "Release notes"

# List releases
gh release list --repo owner/repo
```

## Organization Operations

```bash
# List org repos
gh repo list org-name --limit 50

# Create org repo
gh repo create org-name/repo-name --public
```

## Workflow / Actions

```bash
# Trigger workflow
gh workflow run workflow-name.yml --repo owner/repo -f param=value

# List runs
gh run list --repo owner/repo --limit 10

# View run status
gh run view <run-id> --repo owner/repo

# Watch run until done
gh run watch <run-id> --repo owner/repo

# Download run logs
gh run download <run-id> --repo owner/repo -D /tmp/logs
```

## Git Configuration

Set up git user for commits:
```bash
git config --global user.name "username"
git config --global user.email "email@users.noreply.github.com"
git config --global credential.helper store
```

Store credentials:
```bash
echo "https://username:$TOKEN@github.com" > ~/.git-credentials
chmod 600 ~/.git-credentials
```

## Tips

- Always specify `--repo owner/repo` when not inside a git directory
- Use `gh api --paginate` for large result sets
- Use `--jq '.field'` to filter JSON output
- Use `--json field1,field2` for structured output
- Token stored in `~/.config/gh/hosts.yml` under `oauth_token`