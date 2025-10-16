#!/usr/bin/env bash

title=${1}

if [ -z "$title" ]; then
  echo "Usage: $0 '<PR title>'"
  exit 1
fi

forgejo_token=$(gopass show home/forgejo/jan)

current_branch=$(git branch --show-current)

if [ "$current_branch" = "main" ]; then
  echo "Error: Cannot create PR from main branch"
  exit 1
fi

# Check if PR description file exists
if [ ! -f "/tmp/PR_DESCRIPTION.md" ]; then
  echo "Error: PR description file not found at /tmp/PR_DESCRIPTION.md"
  exit 1
fi

pr_body=$(cat /tmp/PR_DESCRIPTION.md)

# Get repository name from git remote URL
repo_name=$(git config --get remote.origin.url | sed -E 's/.*[:/]([^/]+)\/([^/.]+)(\.git)?$/\2/')

# Escape JSON properly
json_body=$(jq -n \
  --arg title "$title" \
  --arg head "$current_branch" \
  --arg base "main" \
  --arg body "$pr_body" \
  '{title: $title, head: $head, base: $base, body: $body}')

if curl -f -s -X POST "https://forgejo.home.janbaer.de/api/v1/repos/jan/${repo_name}/pulls" \
  -H "Authorization: token $forgejo_token" \
  -H "Content-Type: application/json" \
  -d "$json_body" > /tmp/pr-response.json; then
  echo "✅ Pull request created successfully!"
  jq -r '"PR URL: " + .html_url' /tmp/pr-response.json
  exit 0
else
  echo "❌ Failed to create pull request"
  cat /tmp/pr-response.json 2>/dev/null || echo "No response received"
  exit 1
fi
