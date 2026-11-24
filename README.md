# <img width="64" height="64" alt="logo_small" src="https://github.com/user-attachments/assets/c4bc7c57-65e0-4ea3-941d-4c4d848e87fe" /> SimpleNotepad




An in-game notepad for notes, reminders, and useful links.

**Clients:** Retail, Classic Era (Hardcore/SoD), TBC Anniversary, Mists Classic, and Forever.

<img width="800" height="349" alt="111" src="https://github.com/user-attachments/assets/e5c7eb9c-053b-4e3d-95d8-fa556fdb20f1" />


## Installation

1. **[CurseForge](https://www.curseforge.com/wow/addons/simplenotepad):** Install via the app.
2. **Manual:** Download the ZIP and extract the `SimpleNotepad` folder into your WoW client's `Interface/AddOns/` directory. Enable **SimpleNotepad** in the game's AddOns list.

## Features

- **Named notes** with tab navigation.
- Character-only notes by default, **global notes** via globe toggle.
- **Share notes** with party and raid members, with a preview and accept/reject controls.
- **Undo/redo, copy/paste**, and clickable **WoW links**.
- **Text coloring** and optional automatic **bullet lists**.
- Reopen, rename, or delete notes through the all-notes list.
- Long-press and drag tabs to sort them.
- **Search notes** and text.
- **Movable**, resizable window down to one text line, with saved layout.
- **Minimize** to a draggable icon button.
- Optional draggable minimap icon and configurable key bindings.
- Languages: English, German, French, Spanish, Portuguese, Italian, Russian, Korean, and Chinese.

## Settings

- **Style:** Modern or WoW.
- **Colors:** Custom background and accent colors for each style; reset available.
- **Opacity:** 10-100%; default **90%**.
- **Scale:** 65-150%; default **100%**.
- **Window lock:** Lock window position, size, and minimized button.
- **Auto-hide:** Hide toolbar and tabs; hover at the top to reveal them.
- **Previous/next buttons:** Show note navigation in the toolbar; off by default.
- **Minimap icon:** Show/hide.
- **Minimized button:** Addon icon or SNP text.
- **Note Footer:** Show lines, characters, and storage usage below the note.

## Controls

- `/snp`, `/sn`, `/simplenotepad`: Show/hide.
- `/snp search`: Toggle search.
- **Ctrl+F / Ctrl+N:** Search / new note.
- **Ctrl+Z / Ctrl+Y:** Undo / redo.
- **Ctrl+R:** Apply the currently selected text color to selected text.
- **Tab:** Insert four spaces.
- **Enter:** Next search match / save note name.
- **Escape:** Close search / cancel dialog / release text focus.
- **+**: Create a named note.

## Sharing notes

Both players need SimpleNotepad 0.5.0 or newer and must be in the same party or raid. Open Sharing with the chain-link button.

1. **Recipient:** Open **Receive** and click **Start receiving** before the note is sent.
2. **Sender:** Open **Send**, select a note, and send it to the group.
3. **Recipient:** Preview the note and choose **Accept** to save a copy or **Reject** to discard it.

## Storage

- Notes, open tabs, and the selected note are saved per character.
- Toggle the globe next to a note in **All notes** to share it across characters on the same account and client. A highlighted globe means shared; a dim globe means character-only.
- Turning sharing off keeps the note on the current character and removes it from other characters on their next login. Deleting a shared note deletes it for all characters.
- Existing shared notes are imported once for each character; the original shared copy is preserved.
- Appearance settings remain shared across characters on the same account and client.
- Saved on logout or `/reload`; undo/redo lasts for the current session.

Cheers,
sAks/eusi

## Limits

- **Notes:** 50 per character, including shared notes and closed tabs. Existing notes are kept.
- **Text:** 32 KiB per note (~16 pages), 2 MiB per character (~1,000 pages). Formatting and special characters use more space.
- **Titles:** 128 bytes (up to 128 characters).
- **Incoming:** Five pending notes, two simultaneous transfers.
- **Undo:** 20 steps; 1 MiB per note, 8 MiB total. Resets on `/reload` or restart.
- **Sending:** 35 seconds between sends. Notes over 20 lines or 2 KiB show a time estimate; sending can take longer than five seconds.
