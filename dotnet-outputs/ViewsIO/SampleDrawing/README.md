# CreateSampleDrawing.scr

Builds a test drawing for manually verifying `ViewsIO` (LISP vs .NET) side by side.

**Run it:** open a new blank drawing in AutoCAD 2027 desktop, type `SCRIPT`, browse to `CreateSampleDrawing.scr`.

**What it does, line by line** (`.scr` files have no comment syntax — every line is fed to the command line as if typed, so this can't live inside the script itself):

1. `FILEDIA 0` — suppress file dialogs so `SAVEAS` stays command-line driven
2. `ERASE ALL` — clear the blank drawing (harmless first run, useful on re-run)
3. Three `BOX` solids at `(0,0,0)`, `(50,0,0)`, `(100,0,0)`, each 10×10×10
4. Three named views, each isolating one box with a distinct visual style:
   - `BoxA_Conceptual` — Conceptual style, zoomed to the first box
   - `BoxB_Wireframe` — 3D Wireframe style, zoomed to the second box
   - `BoxC_Realistic` — Realistic style, zoomed to the third box
5. Zoom to extents, reset to 2D Wireframe, `SAVEAS` → `ViewsIODemo.dwg` in this folder

**Known risk:** `.scr` command prompts are AutoCAD-version-sensitive (exact wording/keyword sets for `-VIEW` and `VSCURRENT` can shift between releases). This hasn't been run in a real AutoCAD session — verify it completes cleanly on first use. If any line causes an "Unknown command" or unexpected prompt, note which line and I'll adjust the sequence.

## Comparing LISP vs .NET on the same drawing

**Do not load both in the same session.** The .NET commands intentionally reuse the exact same names as the LISP ones (`ExportViews`, `ImportViews`, `-ExportViews`, `-ImportViews`) — that's correct, since a migration should be a drop-in replacement. But it means loading both at once is ambiguous: whichever registers second either fails outright (duplicate command name) or silently shadows the first, so you can never be certain which implementation actually ran. Test them in two separate sessions instead:

**Session 1 — LISP baseline:**
```
Open ViewsIODemo.dwg (fresh copy, or restore views if previously modified)
(load "D:/Projects/2026/lisp-to-dotnet-skill/lisps/viewsIO.lsp")
EXPORTVIEWS  → save as views_lisp.txt
Close the drawing WITHOUT saving (so the .NET session below starts from the same unmodified state)
```

**Session 2 — .NET, fresh drawing, LISP never loaded:**
```
Open ViewsIODemo.dwg again
NETLOAD  → browse to ViewsIO.dll
EXPORTVIEWS  → save as views_dotnet.json
```

Formats differ (LISP writes its own text-list format, .NET writes JSON) — compare that both capture the same 3 views with the same visual style links, then test `IMPORTVIEWS`/`-VIEW Delete *` round-trips on each, again in separate sessions.
