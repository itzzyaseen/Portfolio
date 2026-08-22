#!/usr/bin/env bash
# Sets up git with the correct author (itzzyaseen) and pushes to your GitHub repo.
# Usage:  ./push.sh https://github.com/itzzyaseen/yaseen-portfolio.git
set -e

REMOTE="${1:-}"
if [ -z "$REMOTE" ]; then
  echo "Usage: ./push.sh <your-github-repo-url>"
  echo "Example: ./push.sh https://github.com/itzzyaseen/yaseen-portfolio.git"
  exit 1
fi

# Author every commit as itzzyaseen (change the email to your GitHub email if you like)
git config user.name  "itzzyaseen"
git config user.email "itzzyaseen@users.noreply.github.com"

# Initialise only if this isn't already a repo
if [ ! -d .git ]; then
  git init
fi

git add -A
git commit -m "Portfolio site" || echo "Nothing new to commit."
git branch -M main

if git remote | grep -q origin; then
  git remote set-url origin "$REMOTE"
else
  git remote add origin "$REMOTE"
fi

git push -u origin main
echo "Pushed to $REMOTE as itzzyaseen. Now connect the repo at https://vercel.com/new"
