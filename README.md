<h1 align="center">Ballast</h1>

<p align="center">
  <strong>Drop the dead weight macOS Messages quietly stows in your hold.</strong>
</p>

<p align="center">
  <img alt="Version" src="https://img.shields.io/badge/version-1.0.0-7c5cff">
  <img alt="Platform" src="https://img.shields.io/badge/platform-macOS-2a9d8f">
  <img alt="License" src="https://img.shields.io/badge/license-GPLv3-blue">
</p>

Messages copies every attachment you send or receive into a staging folder
inside its app container, and never cleans it up. Over years that folder grows
to tens of gigabytes of cargo you never agreed to carry. Ballast is a single
shell script that throws it overboard — safely, and without touching a single
real attachment.

> [!NOTE]
> **Most of that folder is not what it looks like.** Read
> [How much will I actually get back?](#how-much-will-i-actually-get-back)
> before you judge the result — `du` will tell you the folder is far bigger
> than the space you can actually reclaim, and that's not a bug.

<p align="center">
  <a href="https://ko-fi.com/itsab1989"><img src="https://ko-fi.com/img/githubbutton_sm.svg" alt="Support Ballast on Ko-fi" height="36"></a>
  <br>
  <sub>Ballast is free and always will be. If it bought you back some disk space, a coffee is a kind way to say thanks — completely optional.</sub>
</p>

---

## Usage

```bash
git clone https://github.com/itsab1989/Ballast.git
cd Ballast
chmod +x ballast.sh

./ballast.sh           # dry run — lists the 10 largest files, deletes nothing
./ballast.sh --apply   # actually delete
```

Quit Messages first. Ballast refuses to run while it's open.

## What it touches

It deletes the **contents** of exactly one folder:

```
~/Library/Containers/com.apple.MobileSMS/Data/tmp/TemporaryItems
```

That is a temporary staging area. It is **not** where your attachments live —
those are in `~/Library/Messages/Attachments`, which Ballast never deletes
from. It only reads that folder, to count your attachments afterwards and show
you they're still there.

Your conversations, your attachments, and `chat.db` are all untouched.

## How much will I actually get back?

Less than `du` claims, and the reason is worth understanding.

macOS uses **APFS clones** for these staged copies. A clone is a second name
pointing at the *same physical blocks* as the original — it costs almost no
disk space, but tools like `du` and Finder count its full size again anyway. So
a staging folder that reports 59 GB might only be holding a fraction of that in
blocks of its own.

That splits the staged files into two kinds:

| Kind | What it is | Freed by deleting |
|---|---|---|
| **Clone** | The real attachment still exists in `Attachments` | Nothing — the blocks are shared, and the original keeps them alive |
| **Orphan** | The original is long gone from Messages | Its full size — the staged copy was the last thing holding those blocks |

Deleting is safe in both cases. Removing a clone never affects the file it was
cloned from. The orphans are where your space actually comes back.

On the machine Ballast was written for, a folder reporting 59 GB gave back
roughly 46 GB — the rest were clones of attachments still in Messages. Expect
the same shape of result: a real win, but not the headline number.

One wrinkle worth knowing: orphans are usually staged **twice** (once under
`Media/`, once under `LinkedFiles/`) as clones of each other. Deleting only one
of the pair frees nothing, because the other still holds the blocks. Ballast
clears the whole folder, so this takes care of itself — but it's why deleting a
single file by hand can look like it did nothing.

## Safety

- Runs against one hardcoded path, and aborts if that path isn't the expected
  Messages staging folder.
- Aborts if Messages is running — deleting underneath a live app can break
  in-flight sends.
- Dry run is the default. Deletion needs an explicit `--apply`.
- Never deletes from `~/Library/Messages/Attachments`, and prints that folder's
  file count and size afterwards so you can confirm it's intact.

The folder itself is preserved (only its contents are removed), because
Messages expects it to exist. It refills as you use Messages — re-run whenever
you like.

## Will Messages recreate this?

Yes. Ballast is a cleanup, not a fix — the staging folder starts filling again
the next time you send or receive an attachment. Running it once or twice a
year is plenty.

If your disk is filling steadily, this is worth doing once, but check your
photo and video libraries too. Those are usually the real story; this folder is
a one-time win.

## License

GPLv3 — see [LICENSE](LICENSE).
