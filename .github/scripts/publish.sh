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
  "$directory/SpaceRangersHD-linux-x86_64-$short.tar.gz"
  "$directory/SpaceRangersHD-linux-x86_64-$short-build.txt"
  "$directory/SpaceRangersHD-android-arm64-$short.apk"
  "$directory/SpaceRangersHD-android-arm64-$short-symbols.tar.gz"
  "$directory/SpaceRangersHD-android-arm64-$short-build.txt"
)
for asset in "${assets[@]}"; do
  test -s "$asset"
done
(cd "$directory" && sha256sum ./*.apk ./*.tar.gz ./*-build.txt > SHA256SUMS)
assets+=("$directory/SHA256SUMS")

notes=build/release-notes.md
{
  git show -s --format=%s HEAD
  echo
  printf 'Commit: [%s](%s/%s/commit/%s) · [Build log](%s/%s/actions/runs/%s)\n\n' "$short" "$GITHUB_SERVER_URL" "$GITHUB_REPOSITORY" "$revision" "$GITHUB_SERVER_URL" "$GITHUB_REPOSITORY" "$GITHUB_RUN_ID"
  echo '- **Linux x86_64:** Ubuntu 24.04 / glibc 2.39+; x86-64-v2 CPU. Extract the archive and follow README.txt.'
  echo '- **Android ARM64:** Android 8.0+. Install the APK, then select your game folder in the launcher. AVI cinematics are not supported.'
  echo
  echo 'Original game data is required and is not included. Symbol archives are for crash diagnostics; build.txt files identify the source and compiler revisions. SHA256SUMS covers all downloads.'
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
