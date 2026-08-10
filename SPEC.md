# AutoLISP → AutoCAD .NET Migration Skill

## Problem

Visual LISP (`vlax-*`, `vla-*`, COM/ActiveX calls) does not run in Design Automation — the COM runtime is absent from headless `accoreconsole`. Basic AutoLISP (`entget`, `ssget`, `entmod`) does run in DA, but most real-world LISP plugins use Visual LISP COM calls and are blocked from the cloud. Migrating to the typed .NET API is the only path to Design Automation for those plugins — and it removes the C# syntax barrier for LISP developers making that jump.

## What This Is

A Claude Code skill (`/lisp-to-dotnet`) that reads an AutoLISP file, builds a structured analysis of every pattern it uses (the **Discovery Table**), then generates a complete, production-ready AutoCAD .NET C# plugin for **Design Automation** — and only Design Automation. There is no desktop/interactive output; every migrated command is a parameterized, non-interactive entry point. This scope decision (made after the initial multi-target version, preserved on the `desktop` git branch) removes the ambiguity of trying to serve two shapes of output from one project and keeps every migration consistent.

It is **not** a fixed template for one entity type — the Discovery Table procedure is generic, so it adapts to whatever the LISP file actually contains (selection sets, DXF group codes, VLA/COM calls, file I/O, symbol table access, etc.) rather than assuming a specific shape.

## Architecture

1. **Guardrail check** — scans for DCL dialogs first. If found, the skill refuses to generate broken UI code and instead flags the dialog logic as an explicit v2 TODO, migrating everything else. DCL/WPF replacement is out of scope for v1 by design (needs its own design session).
2. **Design Automation Guardrail** — applies to *every* command, always: any interactive input (`getpoint`/`getstring`/`getfiled`/`getkword`/etc.) becomes a field on a `Models/<CommandName>Input.cs` record read from `params.json`, never an interactive prompt. A DA Activity has no display, no message pump, no live console — code that silently relies on interactive input hangs or fails inside a cloud worker rather than erroring cleanly at build time.
3. **Discovery Table** — every command, helper, entity access, DXF read/write, and COM call in the file is catalogued with its .NET equivalent before any code is written.
4. **Scaffold** — a `dotnet new` template (`acad-lisp-migration`) generates the full project structure (csproj, test projects, bundle manifest, DA deployment scripts) with the correct AutoCAD version, TFM, and NuGet version already resolved — no hand-editing of boilerplate. One package everywhere: `AutoCAD.NET.Core` (never the full `AutoCAD.NET`, which crashes both `accoreconsole` and the real DA engine with `0xC0000005` — there's no desktop target to justify it).
5. **Code generation** — Claude fills the generated stubs with the actual migrated logic, split into pure/testable model code and AutoCAD-dependent service code. Command output/logging uses `Editor.WriteMessage`, never `Console.WriteLine` — the real DA cloud engine isn't guaranteed to capture bare stdout the way `accoreconsole` does locally, and `WriteMessage` is what actually lands in the downloadable WorkItem report.
6. **Tests** — two tiers: xUnit for pure logic (no AutoCAD host needed), and NUnit + ExtentReports self-hosted inside `accoreconsole` for anything touching the database (following the [coreconsolerunner](https://github.com/ADN-DevTech/coreconsolerunner) pattern — commands write, tests only read). A dev-only seed-generation command (e.g. `HBSEED`) plus a headless `accoreconsole` script (no `/i`, `FILEDIA 0`, scripted `QSAVE`) lets a developer produce a real seed `.dwg` for DA testing without ever opening AutoCAD desktop.
7. **Bundle + real DA deployment** — `PackageContents.xml` and a bundle-assembly script produce a DA-ready `.bundle`, per the Autodesk Autoloader spec used by APS AppBundles. `da/Deploy-And-Test-DA.ps1` deploys the bundle + activity to real APS Design Automation and submits an actual WorkItem — not a simulation. Credentials never pass through Claude or the conversation: `da/.env` (gitignored; `.env.example` tracked) holds `APS_CLIENT_ID`/`APS_CLIENT_SECRET`/`APS_NICKNAME`, loaded by `Import-DotEnv` at the top of every DA script, and the developer runs the deployment scripts themselves.

**A real APS quirk worth documenting because it cost real debugging time:** `GET /forgeapps/me` returns your raw `APS_CLIENT_ID` as the identity when no custom nickname has ever been registered — not `null`/blank. A naive truthiness check misreads that default as "already has a nickname." `Resolve-DANickname` (in `da/APS-Common.ps1`) compares against `$env:APS_CLIENT_ID` explicitly, and every downstream reference (bundle, activity, WorkItem) is qualified as `<nickname>.<id>+<alias>` — bare IDs only work for direct-ownership calls, not cross-references. `da/Reset-APSApp.ps1 -Confirm` is the deliberate, warning-gated clean-slate reset for when resource state gets confused across runs.

8. **Machine-readable params contract** — every migration with a `Models/<CommandName>Input.cs` record also emits `da/params.schema.json`, a plain JSON Schema mirror of it (field name, type, default, description). Lets any non-.NET consumer — a hand-built HTML form, a different tool — know the `params.json` contract without parsing C#. First use case: a planned v2 pattern mapping LISP DCL dialogs to a static HTML form that feeds this schema.

## Validated So Far

**The eval suite (`evals/evals.json`) is the primary quality gate** — 3 fixed cases run by spawning an isolated subagent that genuinely invokes the Skill tool (not an improvised walkthrough), graded against concrete filesystem/build assertions:

| Case | File | Focus | Result |
|---|---|---|---|
| 1 | `gpmain.lsp` | Basic commands, parameterized point/distance input, `(alert...)` correctly not mistaken for DCL | **6/6 assertions pass**, plus a real `accoreconsole` run (6/6 NUnit tests), a real bundle built, and a genuine `CS0234` bug (`Application` vs `Core.Application`) self-found and self-fixed in the template *and* SKILL.md during the run |
| 2 | `HATCHB.lsp` | VLA-heavy: `vla-AddLine/Circle/Arc/Ellipse`, `addLightweightPolyline`+bulge, `pedit`/`ucs`/`UNDO` macro sequences correctly flagged as v2 TODOs, area computation via typed try/catch | Automated subagent run stopped early (cost management); **manually completed and validated end-to-end instead — see HatchBDA below** |
| 3 | `mstxt.lsp` | Real DCL (`load_dialog`/`new_dialog`) — must refuse before generating any code | **4/4 assertions pass** — refusal fires before scaffolding, explicit out-of-scope statement, path forward offered |

**HatchBDA is the deepest validation this skill has had — a real, live APS Design Automation WorkItem, not just a local build.** Starting from `HATCHB.lsp` (Jimmy Bergmark/JTB World — recreates HATCH boundaries as typed line/arc/circle/ellipse/polyline entities), the migration was carried all the way through:
- `dotnet build` clean, 0 errors, all 5 `vla-Add*` calls mapped to typed entity creation
- A real APS app, deployed via `da/Deploy-And-Test-DA.ps1`: AppBundle uploaded, Activity created, a real WorkItem (`59ce1bdb...`) submitted against the actual cloud engine and returned `status: success` in ~10 seconds
- `result.dwg` downloaded and manually opened — **boundary entities confirmed created correctly**, not just "the API returned success"

Getting there surfaced (and fixed, in both the instance and the template — self-maintaining-skill convention) real APS integration bugs that only show up against the live service, not in any local test: unqualified `activityId` references, the `GET /forgeapps/me` default-identity gotcha above, and an `.env`-loading ordering bug in the deployment script's own parameter defaults. This is the strongest evidence so far that the skill's output is genuinely DA-deployable, not just DA-shaped.

`dotnet-outputs/GardenPath` and `dotnet-outputs/ViewsIO` predate the DA-only pivot and reflect the old desktop-oriented shape — kept for historical reference, not as current expected output. `dotnet-outputs/HatchBDA` is the current DA-only worked example.

**Two more independent real APS Design Automation successes since HatchBDA**, run against real customer LISP (Gil Cordle, LJA): `AcresDA` (from `Gil_Cordle_ACRES.lsp`) and `FlangeDA` (from `Flange.lsp`'s non-dialog logic, `mode=pat` hole-pattern branch) each submitted a real WorkItem and got a result back. AcresDA's testing surfaced two generalizable AutoCAD .NET Core native-crash gotchas (now in `SKILL.md`'s Known Edge Cases): a `Region`/`using` double-free, and `Hatch.AppendLoop` needing `HatchLoopTypes.External`. Three independent real deploys now, not one.

**Tier 1 corpus sweep (2026-08-04):** a Discovery-Table-only dry run (no scaffolding) across all 62 non-fixture files in `lisps/` — 62/62 produced a table, no silent skips. Surfaced real corpus data-quality issues (several files with genuinely corrupted/truncated source, verified against actual bytes, not hallucinated) and out-of-scope-beyond-DCL edge cases (e.g. a file driving an external `CAO.dbConnect` COM server, not core AutoCAD). Full migration (Tier 2) and real-deploy (Tier 3) passes on a representative sample are next.

**Repo is now on GitHub (internal visibility):** [github.com/autodesk-platform-services/aps-lisp-dotnet-skill](https://github.com/autodesk-platform-services/aps-lisp-dotnet-skill), with a WIP `README.md` and before/after demo media.

**Explored and ruled out:** AutoCAD's built-in Action Recorder (`ACTRECORD`/`ACTSTOP`/playback via macro name) was tested as a way to record LISP command interactions once and replay them against migrated .NET commands for automated equivalence checking. Not viable — Action Recorder macros are bound to the *provenance* of the command they were recorded against (LISP vs. compiled/managed), not just its name; replaying against a same-named .NET command fails with "Lisp Command Missing." Not applicable to DA-only migrations anyway, since there's no interactive session to record against.

## Known Gaps

- **Sample breadth — in progress.** Tier 1 (Discovery-Table dry run, all 62 corpus files) is done; Tier 2 (full migration on a representative sample) and Tier 3 (real DA deploy on a subset) are next.
- **Eval case 2 needs a from-scratch automated re-run** to confirm the skill alone (no manual intervention) reproduces the HatchBDA result end-to-end — the current validation combined an automated subagent run with manual completion.
- **A shared DA deployment CLI was considered and explicitly deferred.** Per-migration PowerShell scripts (`da/*.ps1`) stay the mechanism: when a real APS bug surfaces, the fix is a direct, visible edit to a script the developer already has open, not a separate CLI build/release cycle.

## Bottom Line

The core pipeline — analyze, scaffold, generate, test, package, **deploy to real APS Design Automation and get a successful WorkItem back** — works end-to-end, verified three times independently against the actual Autodesk cloud service (HatchBDA, AcresDA, FlangeDA), not just local builds. A corpus-wide dry run (62 files) confirms the analysis step generalizes beyond hand-picked samples. What's left is depth on that breadth (Tier 2/3 full migrations + deploys) rather than fixing the core mechanism.
