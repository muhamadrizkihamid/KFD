#!/usr/bin/env bash
# .agent-squad/lib/git-remote.sh — centralized push logic
# Usage: source .agent-squad/lib/git-remote.sh
# Reads from .env.local: GIT_REMOTE, GIT_DEFAULT_BRANCH, GITLAB_URL

set -euo pipefail

if [ -z "${GIT_REMOTE:-}" ]; then
  source .env.local
fi

BRANCH="${GIT_DEFAULT_BRANCH:-main}"

git_push_all() {
  case "${GIT_REMOTE:-origin}" in
    both)
      git push origin "$BRANCH" || { echo "ERROR: push to origin (GitHub) failed"; return 1; }
      GIT_SSL_NO_VERIFY=true git push gitlab "$BRANCH" || { echo "ERROR: push to gitlab failed"; return 1; }
      echo "Pushed to: GitHub (origin) + GitLab"
      ;;
    gitlab)
      GIT_SSL_NO_VERIFY=true git push gitlab "$BRANCH" || { echo "ERROR: push to gitlab failed"; return 1; }
      echo "Pushed to: GitLab"
      ;;
    *)
      git push origin "$BRANCH" || { echo "ERROR: push to origin (GitHub) failed"; return 1; }
      echo "Pushed to: GitHub (origin)"
      ;;
  esac
}

git_remote_label() {
  case "${GIT_REMOTE:-origin}" in
    both)   echo "GitHub + GitLab" ;;
    gitlab) echo "GitLab" ;;
    *)      echo "GitHub" ;;
  esac
}
