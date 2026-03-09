#!/bin/bash

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Not in a git repository" >&1
  exit 1
fi

if [ -z "$1" ]; then
  echo "Missing branch name argument" >&1
  exit 1
fi

branch_name="$1"

branch_exists() {
  git rev-parse --verify $branch_name >/dev/null 2>&1
}

on_branch() {
  git branch --show-current | grep -oE "^$branch_name$" >/dev/null 2>&1
}

has_changes() {
  git diff --quiet
  local unstaged=$?

  [ $unstaged -ne 0 ] && return 0

  git diff --quiet --cached
  local staged=$?

  [ $staged -ne 0 ] && return 0

  local untracked=$(git ls-files --others --exclude-standard)

  [ -n "$untracked" ] && return 0

  return 1
}

has_upstream() {
  git rev-parse --verify $branch_name@{upstream} >/dev/null 2>&1
}

stash_push_changes() {
  if ! has_changes; then
    echo "Nothing to stash"
  else
    git stash push --quiet --include-untracked --message "$(date '+%d-%m.%H:%M')"
    echo "Changes stashed"
  fi
}

stash_apply_changes() {
  local last_stash_id=$(git stash list | grep "\s$branch_name:" -m 1 | grep -oE "stash@{\d+}")

  if [ -z "$last_stash_id" ]; then
    echo "No stash found"
  else
    local changes_message=$(
      git --no-pager stash show --include-untracked $last_stash_id |\
        sed '$!d' | grep -oE "\d+\sfile(s)?\schanged"
    )

    echo ": Found $changes_message in stash"
    git --no-pager stash show --name-status --include-untracked $last_stash_id

    read -p ": Apply? [Y/n] " yn

    local n_changes=$(echo $changes_message | grep -oE "\d+")
    clear_lines $((n_changes+2))

    case "$yn" in
      [Nn]*)
        echo "Stash kept"
        ;;
      *)
        git stash apply --quiet $last_stash_id
        echo "Stash applied"
        ;;
    esac
  fi
}

sync_branch() {
  local status=$(git rev-list --left-right --count HEAD...@{upstream})
  local n_ahead n_behind
  read n_ahead n_behind <<< $status

  if [ $n_behind -ne 0 ]; then
    read -p "Pull from remote? [Y/n] " yn
    clear_lines
    case "$yn" in
      [Nn*])
        return
        ;;
      *)
        git pull --quiet
        ;;
    esac
  fi

  if [ $n_ahead -ne 0 ]; then
    read -p "Push to remote? [Y/n] " yn
    clear_lines
    case "$yn" in
      [Nn*])
        return
        ;;
      *)
        git push --quiet
        ;;
    esac
  fi
}

clear_lines() {
  local n="${1:-1}"
  local codes="\033[A\033[2K\r"

  for ((i=0;i<n;i++)); do
    echo -en $codes
  done
}

git fetch --quiet --all

if on_branch; then
  echo "Already on '$branch_name'"
  exit 0
fi

if ! branch_exists; then
  echo "Branch '$branch_name' not found"
  read -p "Create a new branch? [Y/n] " yn
  clear_lines 2
  case "$yn" in
    [Nn]*)
      echo "Aborting" >&2
      exit 2
      ;;
    *)
      stash_push_changes
      git switch --create $branch_name --no-track origin/HEAD
      ;;
  esac
else
  stash_push_changes

  if ! has_upstream; then
    git switch $branch_name
    echo "No upstream configured"
  else
    echo $(git switch $branch_name | sed '2d' | sed -E 's/(\,.+$|\.$)//')
    sync_branch
  fi

  stash_apply_changes
fi
