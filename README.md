# Configs!

This repository contains various application configurations I want to keep track of/don't want to lose, mostly for convenience sake. Some apps aren't documented very well. Some apps are just a pain in the butt to reconfigure. Some apps, I went deep down some rabbit holes and have no intention of doing so again (read: if it ain't broke, don't fix it).


## Dots!

This repository also includes my take on dotfiles. I've minimized the mess and repetition as much as possible, but only so much can be done, being a Bash-on-Windows user and frequenting a couple of Linux boxes of my own.


## Considerations

These are mostly personal reminders.

Sensitive files are encrypted with git-crypt.

Configs stored in this repo should use hardlinks or junctions wherever possible. Many already do. Doing so provides multiple benefits:
- Changes I make here should, in most cases, be picked up by the application automatically.
- Changes I make in applications should, in most cases, be picked up by git automatically.
- No more manual syncing (in comparison to how I was tracking configs in the past).
