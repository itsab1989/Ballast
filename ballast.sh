#!/bin/bash
#
# Ballast — drop the dead weight macOS Messages stows in your hold.
#
# https://github.com/itsab1989/Ballast
#
# Messages copies every attachment you send or receive into a temporary staging
# folder and never cleans it up. Most of those copies are APFS clones that share
# blocks with the real attachment, so deleting them frees nothing. But once the
# original is gone from Messages, the staged copy becomes the last holder of
# those blocks — and deleting it frees real space.
#
# This script only ever touches the staging folder below. It never touches
# ~/Library/Messages/Attachments, where the real attachments live.
#
# Usage:
#   ./ballast.sh          # dry run — shows what would go, deletes nothing
#   ./ballast.sh --apply  # actually delete
#
set -euo pipefail

STAGING="$HOME/Library/Containers/com.apple.MobileSMS/Data/tmp/TemporaryItems"
ATTACHMENTS="$HOME/Library/Messages/Attachments"

APPLY=0
[ "${1:-}" = "--apply" ] && APPLY=1

# Refuse to run against anything that isn't the Messages staging folder.
case "$STAGING" in
  */com.apple.MobileSMS/Data/tmp/TemporaryItems) ;;
  *) echo "Refusing: unexpected staging path: $STAGING" >&2; exit 1 ;;
esac

if [ ! -d "$STAGING" ]; then
  echo "Nothing to do — staging folder does not exist."
  exit 0
fi

# Messages rewrites this folder while running; deleting underneath it can make
# in-flight sends fail.
if pgrep -x Messages >/dev/null 2>&1; then
  echo "Messages is running. Quit it first (Cmd-Q), then run this again." >&2
  exit 1
fi

free_mb() { df -k / | awk 'NR==2{print int($4/1024)}'; }

count=$(find "$STAGING" -type f 2>/dev/null | wc -l | tr -d ' ')
apparent=$(du -sh "$STAGING" 2>/dev/null | cut -f1)

echo "Staging folder : $STAGING"
echo "Files          : $count"
echo "Apparent size  : $apparent  (much of this is shared with real attachments)"
echo

if [ "$count" -eq 0 ]; then
  echo "Already empty. Nothing to do."
  exit 0
fi

if [ "$APPLY" -eq 0 ]; then
  echo "10 largest staged files:"
  # `awk NR<=10` rather than `head -10`: head exits early, which kills the
  # upstream writer with SIGPIPE and pipefail would treat that as fatal.
  find "$STAGING" -type f -exec stat -f '%z	%N' {} \; 2>/dev/null \
    | sort -rn \
    | awk -F'\t' 'NR<=10 { printf "  %6d MB  %s\n", $1/1048576, $2 }' \
    | sed 's#/.*/##'
  echo
  echo "DRY RUN — nothing deleted. Re-run with --apply to delete."
  exit 0
fi

before=$(free_mb)

# Delete contents, not the folder itself — Messages expects it to exist.
find "$STAGING" -mindepth 1 -delete 2>/dev/null || true

sync
sleep 3
after=$(free_mb)

echo "Done. Freed $(( after - before )) MB."
echo

# The whole point is that the real attachments are untouched. Prove it.
if [ -d "$ATTACHMENTS" ]; then
  echo "Attachments intact: $(find "$ATTACHMENTS" -type f 2>/dev/null | wc -l | tr -d ' ') files, $(du -sh "$ATTACHMENTS" 2>/dev/null | cut -f1)"
fi
