# Changelog

## v1.0.0

First release.

Ballast throws overboard the dead weight macOS Messages stows in your hold.

- Clears the macOS Messages attachment staging folder
  (`~/Library/Containers/com.apple.MobileSMS/Data/tmp/TemporaryItems`), which
  Messages fills with a copy of every attachment you send or receive and never
  cleans up.
- **Dry run by default** — lists the ten largest staged files and deletes
  nothing until you pass `--apply`.
- **Never touches your attachments.** Deletion is scoped to the staging folder
  alone; `~/Library/Messages/Attachments` is only ever read, and the script
  prints its file count and size afterwards so you can see it's intact.
- Refuses to run while Messages is open, and refuses to run at all if the
  staging path isn't what it expects.
- Honest about the payoff: much of the staging folder consists of APFS clones
  that share blocks with attachments you still have, so deleting them frees
  nothing. The space comes from orphans, whose originals are gone. Measured on
  the machine this was written for, a folder reporting 59 GB gave back 27 GB —
  under half. The README explains why the two numbers differ, and why the real
  figure can't be known before you run it.
- This script is free and always will be — if it bought you back some disk
  space, a coffee on [Ko-fi](https://ko-fi.com/itsab1989) is a kind way to say
  thanks.
