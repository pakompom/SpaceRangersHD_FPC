#!/usr/bin/env bash
set -euo pipefail

revision=$(git rev-parse HEAD)
short=${revision:0:12}
tag="build-$short"
date=$(git show -s --format=%cs HEAD)
title="Build $date · $short"
directory=build/release

# Require every platform before exposing a release. Never upload staging trees.
assets=(
  "$directory/SpaceRangersHD-Linux-x86_64.tar.gz"
  "$directory/SpaceRangersHD-Android-arm64.apk"
)
for asset in "${assets[@]}"; do
  test -s "$asset"
done
notes=build/release-notes.md
{
  git show -s --format=%s HEAD
  echo
  printf '[Commit %s](%s/%s/commit/%s) · [Build](%s/%s/actions/runs/%s)\n' "$short" "$GITHUB_SERVER_URL" "$GITHUB_REPOSITORY" "$revision" "$GITHUB_SERVER_URL" "$GITHUB_REPOSITORY" "$GITHUB_RUN_ID"
} > "$notes"

# Reruns leave published releases intact and can finish an interrupted draft.
if draft=$(gh release view "$tag" --json isDraft --jq .isDraft); then
  if [[ "$draft" == false ]]; then
    echo "Release $tag is already published."
    exit 0
  fi
else
  gh release create "$tag" --target "$revision" --title "$title" --notes-file "$notes" --draft
fi
gh release upload "$tag" "${assets[@]}" --clobber
gh release edit "$tag" --title "$title" --notes-file "$notes" --draft=false
