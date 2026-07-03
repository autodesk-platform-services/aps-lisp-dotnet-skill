# AutoLISP → AutoCAD .NET Migration Skill

**Status as of 2026-07-03** — prepared for Cyrille Fauvel, AU 2026 planning

---

## Problem

Visual LISP (`vlax-*`, `vla-*`, COM/ActiveX calls) does not run in Design Automation — the COM runtime is absent from headless `accoreconsole`. Basic AutoLISP (`entget`, `ssget`, `entmod`) does run in DA, but most real-world LISP plugins use Visual LISP COM calls and are blocked from the cloud. Migrating to the typed .NET API is the only path to Design Automation for those plugins — and it removes the C# syntax barrier for LISP developers making that jump.

## What This Is

A Claude Code skill (`/lisp-to-dotnet`) that reads an AutoLISP file, builds a structured analysis of every pattern it uses (the **Discovery Table**), then generates a complete, production-ready AutoCAD .NET C# plugin: source code, unit tests, `accoreconsole` integration tests, and an AppStore-deployable `.bundle`.

It is **not** a fixed template for one entity type — the Discovery Table procedure is generic, so it adapts to whatever the LISP file actually contains (selection sets, DXF group codes, VLA/COM calls, file I/O, symbol table access, etc.) rather than assuming a specific shape.

## How It Works

1. **Guardrail check** — scans for DCL dialogs first. If found, the skill refuses to generate broken UI code and instead flags the dialog logic as an explicit v2 TODO, migrating everything else. DCL/WPF replacement is out of scope for v1 by design (needs its own design session).
2. **Discovery Table** — every command, helper, entity access, DXF read/write, and COM call in the file is catalogued with its .NET equivalent before any code is written.
3. **Scaffold** — a `dotnet new` template (`acad-lisp-migration`) generates the full project structure (csproj, test projects, bundle manifest) with the correct AutoCAD version, TFM, and NuGet versions already resolved — no hand-editing of boilerplate.
4. **Code generation** — Claude fills the generated stubs with the actual migrated logic, split into pure/testable model code and AutoCAD-dependent service code.
5. **Tests** — two tiers: xUnit for pure logic (no AutoCAD host needed), and NUnit + ExtentReports self-hosted inside `accoreconsole` for anything touching the database (following the [coreconsolerunner](https://github.com/ADN-DevTech/coreconsolerunner) pattern — commands write, tests only read).
6. **Bundle** — `PackageContents.xml` and a bundle-assembly script produce an AppStore-ready `.bundle`, per the Autodesk Autoloader spec.

## Validated So Far

**Garden Path (Lesson 3) is the planned AU 2026 demo sample.** ViewsIO is a separate, harder real-world file used to stress-test the skill's generality — it is not itself a demo candidate, but proof that the skill isn't overfit to Garden Path.

| Example | Role | Source LISP patterns exercised | Result |
|---|---|---|---|
| **Garden Path** (Lesson 3) | **AU 2026 demo sample** | Basic commands, polyline creation | Full build + `accoreconsole` run — **10/10 tests passing** |
| **ViewsIO** (`viewsIO.lsp`, real-world) | Internal validation only, not for demo | `entget`/`entmod`/`entmake`/`entmakex`, VLA dictionary access, symbol table iteration, `getfiled` GUI dialogs | Full run via the actual `/lisp-to-dotnet` command (not a manual walkthrough) — DCL check → Discovery Table → scaffold → code → **4/4 xUnit tests passing** → integration tests compiling cleanly → bundle built and loaded live via `NETLOAD` from the actual `.bundle\Contents\Win64\` path |

The ViewsIO run is the more important proof point: it's a second, independently-chosen file with a materially different pattern mix, run through the skill exactly as an end user would invoke it — and it succeeded without hand-holding beyond answering the standard setup questions (AutoCAD path, SDK path, deployment target).

**Manual output cross-validation.** On a hand-built sample drawing (3 named views, each with a distinct visual style), the original LISP and migrated .NET commands were run in separate AutoCAD sessions and their exported outputs compared directly: same 3 views, same height/width/target geometry, same visual style names. A real logic defect was also found and fixed in the process — the original `-ExportViews` LISP command gates its write on `(findfile ...)`, which only succeeds for files that already exist, so it could never create a new export file, only overwrite one. The .NET migration initially reproduced this defect faithfully; it's now fixed (export unconditionally, only gate the overwrite *confirmation* on file existence) and captured as a general rule in the skill: not every LISP pattern is intentional, and logic that blocks the common case is usually a bug worth fixing, not preserving.

**Explored and ruled out:** AutoCAD's built-in Action Recorder (`ACTRECORD`/`ACTSTOP`/playback via macro name) was tested as a way to record LISP command interactions once and replay them against the migrated .NET commands for automated equivalence checking. Confirmed not viable — Action Recorder macros are bound to the *provenance* of the command they were recorded against (LISP vs. compiled/managed), not just its name. Replaying a macro recorded against a LISP command fails with "Lisp Command Missing" when only a same-named .NET command is registered, even though the name is identical. Useful for regression-testing repeatable inputs within one implementation; not usable across a migration boundary. The direct approach (same typed inputs in two isolated sessions, diff the output files) remains the validated method.

## Known Gaps Before a Full AU 2026 Demo

- **Design Automation target untested end-to-end, and now has a known open design question.** Both validated examples targeted desktop/AppStore only. Confirmed today: `AutoCAD.NET.Core` (not `AutoCAD.NET`) is required for the actual DA-deployed plugin assembly, not just test projects — the DA execution engine is architecturally the same headless core as `accoreconsole`, so a plugin referencing the full `AutoCAD.NET` package would crash there the same way it does in `accoreconsole`. This means `--target both` needs two separate plugin projects (one per package), not one shared project — the `dotnet new` scaffold template doesn't yet generate this split. Desktop-only migrations (the AU 2026 demo path) are unaffected.
- **DCL guardrail refusal path untested.** The skill's logic for detecting and refusing DCL-containing files is written but hasn't been run against an actual `.lsp` with dialogs to confirm the refusal message and partial-migration fallback behave as designed.
- **Sample breadth.** Two migrations validate the approach; a broader sweep of the `lisps/` corpus (64 real-world files) would raise confidence further before a live audience.

## Bottom Line

The core pipeline — analyze, scaffold, generate, test, package — works end-to-end on real LISP code, driven entirely by the skill's own procedure rather than manual intervention. What's left is breadth (more sample files, DA path, DCL refusal) rather than fixing the core mechanism.
