# <img width="64" height="64" alt="logo_small" src="https://github.com/user-attachments/assets/c4bc7c57-65e0-4ea3-941d-4c4d848e87fe" /> SimpleNotepad




An in-game notepad for notes, reminders, and useful links.

**Clients:** Retail, Classic Era (Hardcore/SoD), TBC Anniversary, Mists Classic, and Forever.

<img width="800" height="349" alt="111" src="https://github.com/user-attachments/assets/e5c7eb9c-053b-4e3d-95d8-fa556fdb20f1" />


## Installation

1. **[CurseForge](https://www.curseforge.com/wow/addons/simplenotepad):** Install via the app.
2. **Manual:** Download the ZIP and extract the `SimpleNotepad` folder into your WoW client's `Interface/AddOns/` directory. Enable **SimpleNotepad** in the game's AddOns list.

## Features

- Named notes with tabs and previous/next navigation.
- Character-only notes by default, global notes via globe toggle.
- Reopen, rename, or delete notes through the all-notes list.
- Close tabs without deleting notes; new and reopened tabs appear last.
- Long-press and drag tabs to sort them.
- Search titles and text; press Enter to cycle through matches.
- Undo/redo, copy/paste, and clickable WoW links.
- Shift-click inventory or chat item links into the focused note.
- Movable, resizable window down to one text line, with saved layout.
- Minimize to a draggable icon button.
- Optional draggable minimap icon and configurable key bindings.
- Languages: English, German, French, Spanish, Portuguese, Italian, Russian, Korean, and Chinese.

## Settings

- **Style:** Modern or WoW.
- **Colors:** Custom background and accent colors; reset available.
- **Opacity:** 10-100%; default **90%**.
- **Scale:** 65-150%.
- **Window lock:** Lock window position, size, and minimized button.
- **Auto-hide:** Hide toolbar and tabs; hover at the top to reveal them.
- **Minimap icon:** Show/hide.
- **Minimized button:** Addon icon or SNP text.

## Controls

- `/snp`, `/sn`, `/simplenotepad`: Show/hide.
- `/snp search`: Toggle search.
- **Ctrl+F / Ctrl+N:** Search / new note.
- **Ctrl+Z / Ctrl+Y:** Undo / redo.
- **Tab:** Insert four spaces.
- **Enter:** Next search match / save note name.
- **Escape:** Close search / cancel dialog / release text focus.
- **+**: Create a named note.

## Storage

- Notes, open tabs, and the selected note are saved per character.
- Toggle the globe next to a note in **All notes** to share it across characters on the same account and client. A highlighted globe means shared; a dim globe means character-only.
- Turning sharing off keeps the note on the current character and removes it from other characters on their next login. Deleting a shared note deletes it for all characters.
- Existing shared notes are imported once for each character; the original shared copy is preserved.
- Appearance settings remain shared across characters on the same account and client.
- Saved on logout or `/reload`; undo/redo lasts for the current session.
