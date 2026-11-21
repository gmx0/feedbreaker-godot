# Feedbreaker: Doomscrolling

A little 2D typing shooter set in a fictional offline feed. Posts are stages, hostile tags are targets, comments fire one letter at a time, and reactions buy time. Clear four posts before your focus hits zero.

## Play

Open `project.godot` in Godot 4.6.3 and press **F5**. Type the highlighted word (start with **MUTE**), without the hash or Enter. Correct characters lock in; mistakes on hostile posts cost one focus but keep your progress. An unattended hostile post also costs focus when its timer fills. The practice post is untimed and mistakes are free.

**Space** or click **Freeze reaction** to pause incoming pressure for four seconds. You get two reactions per run and can keep typing while frozen. **F2** or **Restart run** resets everything. If the window loses focus, pressure pauses until you return. Keyboard required: held-key repeats and clipboard shortcuts do not fire.

## Exports & tests

Install matching Godot templates for the Linux and Web presets. For a Web export, extract all files into one folder and run `python -m http.server 8000 --bind 127.0.0.1` in that folder, then open `http://127.0.0.1:8000` in a WebGL 2 browser. Do not double-click the HTML. For Linux, run the x86-64 executable.

Run `godot --headless --path . -- --smoke` to test real viewport input and a controlled timer: first-character feedback, focus return, repeat and shortcut rejection, loss, restart during transition and freeze, and a full win.

This Godot version is written from scratch. The posts and abstract signal art are original; no custom fonts, audio, platform branding, third-party game assets, or network features are included. See `GODOT_NOTICES.txt` for the engine and embedded dependency notices.
