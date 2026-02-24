#!/bin/bash

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "error: not in git repository" >&1
  exit 1
fi

if [ -z "$1" ]; then
  echo "Missing branch name argument" >&1
  exit 1
fi

branch_name=$1

branch_verify() {
  local branch_name=$1

  git rev-parse --verify "$branch_name" >/dev/null 2>&1
}

on_branch() {
  local branch_name=$1

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
  local branch_name=$1

  git rev-parse --verify "$branch_name@{upstream}" >/dev/null 2>&1
}

stash_push_changes() {
  if ! has_changes; then
    echo "No changes to stash"
  else
    git stash push --quiet --include-untracked --message "$(date '+%d-%m.%H:%M')"

    echo "Changes have been stashed"
  fi
}

stash_apply_changes() {
  local branch_name=$1

  local last_stash_id=$(git stash list | grep "\s$branch_name:" -m 1 | grep -oE "stash@{\d+}" | grep -oE "\d+")

  if [ -z "$last_stash_id" ]; then
    echo "No stashed changes available"
  else
    local n_changes=$(git stash show --include--untracked $last_stash_id | sed '$!d' | grep -oE "\d+\sfile(s)?\schanged")

    echo $'\e[1;33m!\e[0m'" You have $n_changes changes in your last stash"
    git stash show --include-untracked $last_stash_id | sed '$d'

    read -p $'\e[1;32m?\e[0m'" Apply last stashed changes? [Y/n] " yn
    case "$yn" in
      [Nn]*)
        ;;
      [Yy]*)
        git stash apply --quiet $last_stash_id
        ;;
    esac
  fi
}

sync_branch() {
  local branch_name=$1

  if ! has_upstream $branch_name; then
    git switch $branch_name

    echo $'\e[1;33m!\e[0m'" Your branch has no upstream configured"
  else
    local message=$(git switch $branch_name | sed '2d' | sed -E 's/(\,.+$|\.$)//')

    echo $'\e[1;36m!\e[0m'"$message"

    local status_count=$(git rev-list --left-right --count HEAD...@{upstream})
    local ahead_count behind_count
    read ahead_count behind_count <<< "$status_count"

    if [ $behind_count -ne 0 ]; then
      read -p $'\e[1;32m?\e[0m'" Pull commits from remote? [Y/n] " yn
      case "$yn" in
        [Nn*])
          return
          ;;
        [Yy*])
          git pull --quiet
          ;;
      esac
    fi

    if [ $ahead_count -ne 0 ]; then
      read -p $'\e[1;32m?\e[0m'" Push commits to remote? [Y/n] " yn
      case "$yn" in
        [Nn*])
          return
          ;;
        [Yy*])
          git push --quiet
          ;;
      esac
    fi
  fi
}

git fetch --quiet --all

if on_branch $branch_name; then
  echo "Already on '$branch_name'"
  exit 0
fi

if ! branch_verify $branch_name; then
  read -p $'\e[1;32m?\e[0m'" Create a new branch named '"$'\e[1;37m'"$branch_name"$'\e[0m'"'? [Y/n] " yn
  case "$yn" in
    [Nn]*)
      echo "Aborting" >&2
      exit 2
      ;;
    [Yy]*)
      stash_push_changes

      git switch --create $branch_name --no-track origin/HEAD
      ;;
  esac
else
  stash_push_changes

  sync_branch $branch_name

  stash_apply_changes $branch_name
fi
