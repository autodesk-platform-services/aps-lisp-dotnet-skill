---
name: lisp-to-dotnet
description: "AutoLISP to AutoCAD .NET migration skill for Design Automation (DA). Analyzes .lsp files, maps LISP patterns to .NET equivalents, generates a single DA-ready C# plugin — every command becomes a parameterized, non-interactive entry point — with unit tests, accoreconsole integration tests, and a DA-deployable bundle. AutoLISP does not run in Design Automation; this skill is the migration path."
argument-hint: "Path to .lsp file (e.g., 'convert gpmain.lsp to a Design Automation plugin')"
disable-model-invocation: false
user-invocable: true
---

# AutoLISP → AutoCAD .NET Migration Skill (Design Automation)

Converts AutoLISP routines into a production-ready AutoCAD .NET C# plugin for **Design Automation**. This is the sole target — there is no desktop/interactive output. Every migrated command is a parameterized, non-interactive entry point, never a dialog or a command-line prompt.

**Core motivation:** Visual LISP (the COM/ActiveX API — `vlax-*`, `vla-*`, `vlax-invoke-method`) does not work in Design Automation. The COM runtime is absent in headless accoreconsole. Basic AutoLISP (`entget`, `ssget`, `entmod`) does run in DA, but most real-world LISP plugins use Visual LISP COM calls and are therefore blocked. Migration to .NET typed API is the only path to cloud automation for those plugins. This skill removes the C# syntax barrier for LISP developers making that jump — and removes the ambiguity of trying to support both desktop and DA from one project: DA-only keeps every generated command to a single, consistent shape.

---

## Environment Setup

**Before generating any code, ask for the three paths below if they have not been provided.** All generated files (csproj, RunIntegrationTests.ps1, PackageContents.xml, bundle scripts) must use the actual paths — never hardcode defaults into output files.

Ask once, remember for the whole session:

| # | Prompt | Used for |
|---|--------|----------|
| 1 | **AutoCAD install folder?** | Derives `accoreconsole.exe` path; SDK NuGet version to target |
| 2 | **LISP project folder?** (folder containing the `.lsp` files to convert) | Source to read; determines output folder name |
| 3 | **ARX SDK folder?** (ObjectARX / AutoCAD .NET SDK root) | Reference samples in `<sdk>\samples\dotNet\`; confirms correct API surface |

**Example prompt to user:**

> Before I start the migration, I need three paths:
> 1. AutoCAD install folder (e.g. `D:\ACAD\AutoCAD 2027`)
> 2. The folder containing the LISP files to convert
> 3. ARX SDK root (e.g. `D:\Sdks\Arx2027`)

**Derived values** (compute automatically once paths are known — do not re-ask):

```
accoreconsole  = <autocad_folder>\accoreconsole.exe
sdk_dotnet     = <sdk_folder>\samples\dotNet\
```

Infer `serial`, `nuget_version`, `da_engine`, and `tfm` from the AutoCAD year:

| AutoCAD year | serial (R-prefix) | nuget_version | da_engine               | tfm             |
|--------------|-------------------|---------------|-------------------------|-----------------|
| 2027         | R26.0             | 26.0.0        | `Autodesk.AutoCAD+26_0` | net10.0-windows |
| 2026         | R25.1             | 25.1.0        | `Autodesk.AutoCAD+25_1` | net8.0-windows  |
| 2025         | R25.0             | 25.0.0        | `Autodesk.AutoCAD+25_0` | net8.0-windows  |

- **serial** → `SeriesMin`/`SeriesMax` in `PackageContents.xml`
- **da_engine** → `engine` field in APS Design Automation activity JSON
- **nuget_version** → `AutoCAD.NET.Core` version in `.csproj` (the only package this skill ever references — see Design Automation Guardrail)
- **tfm** → `TargetFramework` in `.csproj`

If the user has already provided any path in the argument, accept it and only ask for the missing ones.

## Conversion Target

There is exactly one target: **Design Automation.** No `--target` flag, no per-migration choice — every migration produces one DA-ready plugin project and one DA bundle. See the Design Automation Guardrail below: no interactive input surface (dialogs or command-line prompts) belongs anywhere in the generated code, since there's no desktop counterpart to defer them to.

## Execution Mode — Ask Once, Never Re-Ask

Side-effecting steps in this procedure (`dotnet new` scaffold, `dotnet build`, `dotnet test`, `RunIntegrationTests.ps1`, `New-Bundle.ps1`) can be run two ways. **Ask which mode the user wants during Step 0, alongside the environment paths — then follow it silently for the rest of the migration. Do not ask again per-step; that produces exactly the ambiguous mid-flow interruptions this section exists to prevent.**

| Mode | Behavior |
|------|----------|
| **Auto** | Claude invokes `dotnet new`, `dotnet build`, `dotnet test`, and the PS1 scripts directly via its own tool calls. The end user's Claude Code permission settings still govern whether each tool call needs approval — this skill has no ability to change that. Choosing Auto only means Claude *attempts* the call instead of handing over text. |
| **Pair-programming** (default, matches this project's own CLAUDE.md convention) | Claude generates the exact command and asks the user to run it in their own shell. No tool call is attempted, so no permission prompt occurs — but the user must copy/paste and report results back. |

**Example prompt to user (fold into the Step 0 paths question):**

> One more thing: should I run the scaffold/build/test/bundle commands myself (**auto**), or generate them for you to run in your own shell (**pair-programming**, default)?

If the user wants fewer permission prompts under Auto mode, that is a change to *their own* Claude Code settings (e.g. allowlisting `dotnet build`/`dotnet test`/`dotnet new` in `.claude/settings.json`) — point them to the `update-config` or `fewer-permission-prompts` skill for that. Do not attempt to suppress or bypass permission prompts from within this skill's own instructions.

## DCL Guardrail — Evaluate Before Starting

**Scan the .lsp file(s) for DCL usage before doing anything else.** If DCL is detected, stop immediately and respond with a refusal message. Do not generate any code.

DCL detection patterns:
```
(load_dialog ...)
(new_dialog ...)
(done_dialog ...)
(action_tile ...)
(start_dialog ...)
(set_tile ...)
(mode_tile ...)
(term_dialog)
(unload_dialog ...)
```
Also check for a `.dcl` file with the same base name in the same folder.

**Refusal response when DCL detected:**

> This LISP project uses DCL dialog boxes (`load_dialog` / `new_dialog` detected).
> DCL migration is **out of scope for v1** — replacing DCL with WPF/Palette requires a design session to decide layout, data binding, and user flow.
>
> **What you can do now:**
> - Extract the non-dialog logic (commands, entity ops, file I/O) and I'll migrate those to .NET.
> - Flag DCL calls as `// TODO v2: replace with WPF dialog` stubs in the output.
>
> Reply "migrate non-dialog code only" to proceed with partial migration, or wait for v2.

If the user explicitly says "migrate non-dialog code only", proceed but replace every DCL call with a `// TODO v2` stub — never generate DCL-equivalent C# for dialog code.

## Design Automation Guardrail — Applies to Every Command, Always

**Since DA is the only target, this checklist applies to every `[CommandMethod]` in every migration — there is no separate desktop path to defer an interactive command to.** A DA Activity has no display, no message pump, and no live console — a command that silently relies on any interactive input will not error cleanly at build time; it will hang or fail inside an Autodesk-hosted cloud worker, which is far harder to debug than a desktop crash. Treat this with the same seriousness as the DCL Guardrail, not as a footnote.

For every `[CommandMethod]`, check for and eliminate:

- `getfiled` → `OpenFileDialog`/`SaveFileDialog` — any GUI dialog. **Zero tolerance.**
- `getstring`/`getkword`/`getpoint`/`getdist`/`getreal`/`getint`/`getangle` → `ed.GetString`/`ed.GetKeywords`/`ed.GetPoint`/etc. Even though these *can* be driven via a `.scr` with pre-supplied answers (used for `accoreconsole` testing elsewhere in this skill), a real DA Activity does not feed a script of typed answers — its inputs are pre-mapped parameter files. Any reliance on these is a defect, not a testing inconvenience.
- Anything requiring on-screen entity selection (`ssget` with no filter, "select objects:" prompts) with no non-interactive fallback (e.g. "select all of type X" is fine — typed/filtered `ssget` patterns translate directly to `OfType<T>()`; open-ended interactive pick prompts do not).

**Remediation — every one of these becomes a parameter, never gets dropped.** Whatever the original LISP asked the user for interactively (a point, a distance, a filename, a keyword choice), the migrated command reads the same value as a method argument or from a fixed, DA-parameter-mapped JSON file (see `GardenPath`'s `GPathDaInput`/`params.json` pattern for the template). Nothing about the original command's *capability* is lost — only the mechanism for supplying its inputs changes, from "ask interactively" to "read from parameters." Reuse the same Helpers/service logic split out from the parameter-reading `Commands.cs` methods (Step 3's Helpers/ derivation rule exists partly for this reason).

**Package rule — always `AutoCAD.NET.Core`, one project, no exceptions.** The DA execution engine is architecturally the same headless core as `accoreconsole` — [`AutoCAD.NET`](https://www.nuget.org/packages/AutoCAD.NET) (full package, includes `AcMgd.dll`, the desktop UI layer) crashes it the same way it crashes `accoreconsole` with `0xC0000005`. Since there is no desktop target to justify referencing `AutoCAD.NET`, this skill never generates a project that does — [`AutoCAD.NET.Core`](https://www.nuget.org/packages/AutoCAD.NET.Core) is the only package reference for the main plugin project, matching the test projects (Step 4). One project, one package, no split.

**Deploying and testing against real APS Design Automation:** the `dotnet new acad-lisp` scaffold includes `da/APS-Common.ps1` (generic REST helpers — auth, AppBundle/Activity/WorkItem lifecycle, OSS upload/download — no per-migration edits needed), `da/Deploy-And-Test-DA.ps1` (deploys the bundle + activity, submits a test WorkItem against the DA entry point, downloads the result; reads its shape from `da/activity.json`/`da/params.example.json`), and `da/Reset-APSApp.ps1` (deliberate escape hatch — see below). Claude still authors `da/activity.json` and `da/params.example.json` per migration in Step 5 — they contain the actual DA command name and parameter fields, which are migration-specific and can't be templated generically. Requires `$env:APS_CLIENT_ID`/`$env:APS_CLIENT_SECRET` (an APS app with Design Automation + Data Management scopes) and a real seed `.dwg` to submit.

**Fully-qualify every DA reference — bare IDs only work for resources you own directly.** A real, confirmed bug from the first live WorkItem test: `POST /workitems` needs `activityId` as `<nickname>.<activityId>+<alias>` (e.g. `madcad.HatchBDaActivity+dev`), not the bare activity id — DA returned `BadRequest: "Cannot parse id."` / `"could not be found"` until this was fixed. The `appbundles` array inside an Activity body needs the same full qualification (`<nickname>.<bundleName>+<alias>`). `APS-Common.ps1`'s `Submit-WorkItem` and `Deploy-And-Test-DA.ps1` already build these correctly — if hand-editing DA REST calls, always qualify.

**APS forgeapps nicknames are set-once, and the "unset" default is not blank.** `GET /forgeapps/me` returns `{ "id": "<value>" }` — but when no custom nickname has ever been registered, `<value>` defaults to the raw `APS_CLIENT_ID` itself, not `null`/empty. Checking truthiness alone (`if ($current.id)`) misreads the default identity as "already has a real nickname." The correct check compares against `$env:APS_CLIENT_ID` (`APS-Common.ps1`'s `Resolve-DANickname` does this) — if they're equal, no nickname exists yet and it's safe to register one from user input; if they differ, a real nickname is already registered and must be used as-is (PATCHing again once the app owns any bundle/activity fails with `"already has resources"`, whether or not the new value matches the old one). Never trust a `-Owner`/typed nickname over what `Resolve-DANickname` actually resolves.

**Root-caused and fixed — two layered bugs, not one. Nickname resolution is the first call in the whole DA workflow, so get it right before anything downstream is trusted.**

1. `GET /forgeapps/me` was assumed to return `{ "id": "<value>" }`, but the observed response is a **bare JSON string** (`"<value>"`) — `Invoke-RestMethod` deserializes that to a plain .NET string with no `.id` property. Every caller reading `$result.id` on a plain string gets `$null` **silently, with no error**. Confirmed by piping `Get-DANickname $token | ConvertTo-Json` and getting a bare quoted string back, not a JSON object. Fixed: `Get-DANickname` normalizes — returns the bare string directly if that's what it got, or falls back to `.id` if the response ever does come back as an object. This alone likely explains the original "misfire" mystery from earlier in this project's history.
2. Even after fixing (1), a second `Get-DANickname` call made immediately after a failed `Set-DANickname` PATCH attempt was still resolving empty — a second, separate flakiness, not fully root-caused. **The actual fix needed no second API call at all**: `$current` (fetched *before* the PATCH attempt) is still accurate whenever the PATCH fails, since nothing changed — there's nothing to re-fetch. `Set-DANickname` now returns `$true`/`$false` instead of swallowing the result, and `Resolve-DANickname` branches on that directly: PATCH succeeded → return the requested nickname; PATCH failed → return the already-known `$current`. Simpler, and avoids whatever was wrong with the redundant second GET.

Algorithm now: get the current identity once; if it's already a real nickname (≠ `$env:APS_CLIENT_ID`), use it, ignore any requested value; otherwise attempt to PATCH the requested nickname, and use it *only if the PATCH actually reported success* — otherwise fall back to the already-known current identity. `-Owner <known real nickname>` still works as a fast manual override, but shouldn't be routinely necessary anymore.

**`GET /appbundles`/`GET /activities` return the public catalog, not "mine," and only one page at a time.** They list every publicly-published activity across all of APS — including other teams'/products' official entries (`AutoCAD.PlotSheetsetToPDF`, `Fusion.helloFusion`, etc., observed on a shared internal test `APS_CLIENT_ID`) — not resources scoped to the caller. A single call also only returns one page (`{ data: [...], paginationToken: "..." }`, ~20 items observed); use `Get-DAAllPages` (loops on `paginationToken` until absent) rather than a raw `Invoke-DA` call whenever completeness matters. To find what's actually *yours*, filter the full list client-side for IDs prefixed with your resolved identity (`"$Owner."`) — `Reset-APSApp.ps1`'s pre-delete banner does this so its counts reflect what `DELETE /forgeapps/me` will actually remove, not an unrelated public-catalog snapshot. `DELETE /forgeapps/me` itself is correctly scoped to "me" regardless of what the list endpoints show — the list endpoints being public doesn't make the delete unsafe, it just made the banner's counts misleading before this fix.

**Resolve every user-supplied file path parameter (e.g. `-InputDwg`) to absolute before it reaches raw .NET file I/O.** A real bug: `Upload-ToOSS` uses `[System.IO.FileStream]`, which resolves relative paths against .NET's `Environment.CurrentDirectory` — **not** PowerShell's `$PWD`. The two silently diverge (`cd` in PowerShell doesn't move .NET's own CWD), so a bare relative `-InputDwg seed.dwg` can resolve against a totally different directory (observed: it resolved to the shell's original startup folder, not the `da\` folder the user had `cd`'d into) and fail with a confusing "Could not find file" pointing at the wrong path. Fix: `Test-Path` the param (this uses PowerShell's own path resolution correctly), then `$InputDwg = (Resolve-Path $InputDwg).Path` before it's used anywhere downstream. `Deploy-And-Test-DA.ps1` does this for both `-InputDwg` and `-ParamsJson`, the two user-overridable path params that flow into `Upload-ToOSS`.

**If DA resource state gets confused across runs (mismatched owner prefixes, a corrupted nickname), `da/Reset-APSApp.ps1 -Confirm` is the clean-slate escape hatch** — `DELETE /forgeapps/me`, wiping every AppBundle/Activity/nickname for that `APS_CLIENT_ID`. It prints a warning banner with exact counts and requires typing `DELETE` before proceeding, and enforces a ~100s wait afterward (server-side deletion is not instant — racing it with an immediate `Deploy-And-Test-DA.ps1` run risks stale-state errors). This is a deliberate, rarely-needed reset, never part of the normal deploy/test flow.

**Generating a seed `.dwg` when the developer doesn't have one (no AutoCAD desktop needed):** add a small dev-only `[CommandMethod]` (e.g. `HBSEED`) to the main plugin that builds whatever minimal entity the migrated command needs directly via the Database API (see `HatchBDA`'s `HbSeed()` — a bare 10×5 `Hatch` via `AppendLoop`/`EvaluateHatch`, no dependency on the command under test). Then drive `accoreconsole` with **no `/i`** at all (it opens its own default blank drawing) and a script that sets `FILEDIA 0` before `QSAVE` so the "Save Drawing As" prompt is answered on the command line instead of popping a (nonexistent, headless) dialog:
```
FILEDIA
0
SECURELOAD
0
NETLOAD
<absolute path>\<ProjectName>.dll
HBSEED
QSAVE
<absolute path>\seed.dwg
QUIT
Y
```
**Every path handed to `accoreconsole.exe` must be absolute — the `NETLOAD` target inside the script, and the `/s <script>`/`/i <dwg>` command-line arguments themselves.** `accoreconsole.exe` is a separate process from the shell that invoked it — same class of CWD-divergence bug as the `Upload-ToOSS`/`-InputDwg` one above, just hitting the console executable's own argument/script resolution instead of a PowerShell param or a raw .NET FileStream. Resolve every one of these with `(Resolve-Path ...).Path` before use: `& accoreconsole.exe /s (Resolve-Path seed.scr).Path`, and the `.dll` path written into the script's `NETLOAD` line. Label the seed command clearly as dev/test-only, not part of the migrated LISP surface, and never wire it into `PackageContents.xml`'s `<Commands>` list.

**Skip this entirely if the migrated command builds geometry from scratch and never reads pre-existing entities** (e.g. a form-driven generator like a parametric part-drawing command — inputs are all in `params.json`, nothing depends on what's already in the drawing). In that case any blank drawing works as input; just run `accoreconsole` with no `/i` directly against the real command, no dev-only seed command needed at all. Only build a seed command when the migrated command's Discovery Table shows it reads/selects/computes against entities that must already exist (AcresDA, HatchBDA) — not when it only writes new ones (Flange).

**Author `outputFile` to reuse the input's `localName`, not a new `SAVEAS` name.** `activity.json`'s `outputFile` parameter can deliberately share `localName` with `inputFile` (e.g. both `"input.dwg"`) — the command line's final `QSAVE` (no filename) then writes back to the file `accoreconsole` already has open, which DA uploads as the result. This avoids an untested `SAVEAS <newname>` scripting step and is the safer default unless the migration genuinely needs a differently-named output.

---

## Scope

### In Scope (v1 — AU 2026)
- AutoLISP command functions (`defun C:CMD`)
- Selection sets (`ssget`, `ssname`, `sslength`)
- Entity operations (`entget`, `entmod`, `entdel`, `entmake`)
- Property access via DXF group codes (`assoc`)
- VLA-Object / ActiveX (`vlax-ename->vla-object`, `vla-get-*`, `vla-put-*`)
- File I/O (`open`, `write-line`, `close`)
- String / math utilities (`strcat`, `itoa`, `rtos`, `atof`)
- Unit tests for all commands
- Design Automation bundle + activity deployment

### Out of Scope (v2)
- DCL dialog box UI migration (CUIX/WPF replacement — needs design session)
- `(command ...)` sequences that depend on **live, mid-command user interaction** (e.g. `pause` inside a `command` call waiting on cursor drag, or a genuine multi-step wizard that can't be pre-supplied) — these have no DA equivalent at all, not even a parameter, since the "input" is continuous interaction, not a discrete value
- Complex reactor chains
- AutoLISP reactor / event-driven code

**Not out of scope, despite first appearances:** `(command ...)` sequences that just construct or edit entities from already-known values (`circle`, `line`, `ellipse`, `array`, `layer`, `change`, `mtext`, `rotate` with a fixed angle) almost always have a direct typed API equivalent — build the entities directly via `AppendEntity`/`Transaction`, compute array/polar points yourself instead of calling the `ARRAY` command macro, use `Entity.TransformBy(Matrix3d.Rotation(...))` instead of an interactive `ROTATE ... pause`. Confirmed across two real migrations (AcresDA, Flange) where *zero* `(command ...)` calls survived into the final C# — every one had a typed replacement. Only the genuinely-interactive subset above stays out of scope.

---

## Pattern Mapping Reference

Detailed AutoLISP → C# mapping tables (Selection Sets, DXF Group Codes, VLA-Object/COM, File I/O, String/Math, Command Registration) live in [references/patterns.md](references/patterns.md) — load it when Step 1's Discovery Table needs a specific mapping not already obvious from context.

---

## Migration Procedure

### Step 0 — Confirm environment paths

If not already provided, ask for the three paths (see **Environment Setup** above).
Resolve derived values before proceeding:

```
autocad_folder = <user answer 1>       e.g. D:\ACAD\AutoCAD 2027
accoreconsole  = <autocad_folder>\accoreconsole.exe
lisp_folder    = <user answer 2>       e.g. D:\MyProject\lisp
sdk_folder     = <user answer 3>       e.g. D:\Sdks\Arx2027
sdk_dotnet     = <sdk_folder>\samples\dotNet
nuget_version  = derived from AutoCAD year
tfm            = derived from AutoCAD year
```

Use these variables in every generated file — do not hardcode paths.

### Step 1 — Analyze the .lsp file

Read every line. Build a **Discovery Table** — this drives every decision in Steps 3 and 4.

| Category | What to find | .NET mapping |
|----------|-------------|--------------|
| **Commands** | Every `(defun C:NAME ...)` | `[CommandMethod("NAME")] public void Name()` |
| **Helpers** | Every `(defun name ...)` without `C:` prefix | `internal static ReturnType Name(params)` |
| **Globals** | Top-level `(setq *VAR* ...)` | Class-level field `private T _var` |
| **Entity types** | `ssget` filter lists, `(cdr (assoc 0 ...))` checks | `OfType<Line>()`, `OfType<Hatch>()`, etc. |
| **DXF reads** | `(assoc N entdata)` for any group code N | Look up typed property from the pattern table |
| **DXF writes** | `(entmod ...)` with `(cons N val)` | `entity.Property = value` after `UpgradeOpen()` |
| **COM calls** | `vlax-invoke-method`, `vla-get-*`, `vla-put-*` | Typed .NET equivalent from the pattern table |
| **User input** | `(getpoint)`, `(getreal)`, `(getstring)`, `(getdist)`, `(getfiled)` | **Never** `ed.GetPoint()`/`ed.GetString()`/dialogs — becomes a field on the DA parameter record (e.g. `GPathDaInput`), read from `params.json`. See Design Automation Guardrail. |
| **File I/O** | `(open ...)`, `(write-line ...)`, `(close ...)` | `StreamWriter` / `JsonSerializer` |
| **Math/String** | `(sin)`, `(cos)`, `(strcat)`, `(itoa)`, `(atof)` etc. | Direct C# / `Math.*` / string interpolation |
| **DCL** | `load_dialog`, `new_dialog`, `action_tile` | OUT OF SCOPE — v2 TODO stub |

**Unknown patterns:** If a LISP function or group code is not in the pattern table, reason from context:
- Unknown DXF group codes → look up in the AutoCAD DXF Reference (entity type → code → typed property)
- Unknown `vlax-invoke-method` → find the equivalent method on the managed wrapper class
- Unknown `getenv`/`setenv` → use `Environment.GetEnvironmentVariable` / `SetEnvironmentVariable`
- When genuinely ambiguous, emit a `// TODO: verify — original LISP: (form)` comment and continue

The Discovery Table is the contract between Step 1 and Steps 3–4. Every row in it becomes a specific piece of generated code.

### Step 2 — Scaffold .NET project

The `acad-lisp-migration` dotnet new template generates the full project structure. Claude fills the migration-specific code into the generated stubs in Steps 3–4.

**One-time install** (not per-migration) — check first with `dotnet new uninstall` (list mode) whether `acad-lisp-migration` is already registered, then in the chosen Execution Mode:

```powershell
dotnet new install <skill-folder>/templates/acad-lisp-migration
```

(`<skill-folder>` is the folder this SKILL.md lives in — e.g. `~/.claude/skills/lisp-to-dotnet` once deployed. `templates/` is a direct sibling of `SKILL.md`, not nested under another `skill/`.)

**Per-migration scaffold:**

```powershell
dotnet new acad-lisp -n <ProjectName> --AutoCADVersion <year> -o <ProjectName>
```

(`--AutoCADVersion` is auto-derived from the template's symbol name by the `dotnet new` engine — case-sensitive, PascalCase, not kebab-case. Shorthand `-A <year>` also works.)

Where `<year>` is `2025`, `2026`, or `2027` resolved from Step 0.

**Auto mode:** run both commands directly. **Pair-programming mode:** print both commands and wait for the user to confirm they ran the scaffold command before reading generated files in the next step.

The template produces a complete scaffold with TFM, NuGet versions, and `PackageContents.xml` serial pre-resolved for the chosen AutoCAD version. **This does not include the actual accoreconsole filesystem path** — `RunIntegrationTests.ps1`'s `-Accore` default is the standard Autodesk installer location (`C:\Program Files\Autodesk\AutoCAD <year>\accoreconsole.exe`), which is correct for most customers but is still a template placeholder, not this specific customer's confirmed path. Before handing the file to the user (or running it in Auto mode), replace the default with the actual `accoreconsole` path resolved from Step 0's answer if it differs — this skill must work in the customer's environment, not just the one it was authored on.

```
<ProjectName>/
  <ProjectName>.csproj                  ← correct TFM + AutoCAD.NET.Core version (only package used)
  App.cs                                ← IExtensionApplication stub
  Commands.cs                           ← [CommandMethod] stub  ← Claude fills (Step 3)
  PackageContents.xml                   ← correct SeriesMin/Max
  Tests/<ProjectName>.Tests/
    <ProjectName>.Tests.csproj          ← xUnit + AutoCAD.NET.Model
    CommandTests.cs                     ← placeholder             ← Claude fills (Step 4)
  Tests/Integration/
    <ProjectName>.IntegrationTests.csproj  ← NUnit + NUnitLite + ExtentReports + AutoCAD.NET.Core
    Infrastructure/
      AppEntry.cs                       ← assembly-level attributes, ready to use
      DrawingTestBase.cs                ← transaction + ExtentReports base
      RunTestsCommand.cs                ← RunCADtests command, ready to use
      TestReport.cs                     ← ExtentReports wiring, ready to use
      TestData.cs                       ← statics stub           ← Claude fills (Step 4)
      TestSetupCommands.cs              ← [CommandMethod] stub   ← Claude fills (Step 4)
    IntegrationTests.cs                 ← placeholder test        ← Claude fills (Step 4)
    RunIntegrationTests.ps1             ← pre-wired for chosen AutoCAD version
  da/
    APS-Common.ps1                      ← generic APS REST helpers, ready to use
    Deploy-And-Test-DA.ps1              ← deploys bundle+activity, submits a test WorkItem
  AGENTS.md                             ← AI coding context for the generated project
```

`activity.json` and `params.example.json` are authored by Claude in Step 5 (migration-specific content — the actual DA command name and parameter fields), while `APS-Common.ps1`/`Deploy-And-Test-DA.ps1` are ready to use as scaffolded. See the Design Automation Guardrail for what belongs in every generated command.

After the user runs the scaffold command, read the generated stubs and proceed to Step 3.

### Step 3 — Generate C# code

The file structure is **derived from the Discovery Table**, not fixed. Only create what the LISP actually contains.

```
<ProjectName>/
  App.cs                          ← always: IExtensionApplication + assembly attributes
  Commands.cs                     ← always: one [CommandMethod] per discovered C: command
  Helpers/<GroupName>.cs          ← only if: helper defuns exist; group by logical concern
  Models/<EntityName>Data.cs      ← only if: 3+ related fields are extracted from one entity type
  Models/<CommandName>Input.cs    ← if: the command took any getpoint/getstring/getfiled/etc. input — always parameterized, even for a single value
  da/params.schema.json           ← always if Models/<CommandName>Input.cs exists — machine-readable mirror of it
```

**Derivation rules:**

- **Commands.cs** — one `public void CmdName()` per `(defun C:NAME ...)`. Use the Discovery Table to fill the body: entity filters, DXF→property reads, writes, file output.
- **Helpers/** — create if there are non-trivial helper `defun`s. Name the file after the logical group (e.g., `GeometryHelper.cs`, `StringHelper.cs`, `LayerHelper.cs`). Skip if helpers are simple one-liners inlined in the command.
- **Models/`<EntityName>Data.cs`** — create a `record` only when a command builds a structured data object from 3+ related fields. Name it after the entity concept (e.g., `HatchBoundary`, `TextItem`, `BlockRef`). Skip if data is just passed through inline.
- **Models/`<CommandName>Input.cs`** — create whenever the original LISP command took *any* interactive input (`getpoint`, `getstring`, `getfiled`, `getkword`, etc.), regardless of how many values. One field per input, in the order the original prompted for them. This is not optional and not conditioned on field count — see Design Automation Guardrail.
- **da/`params.schema.json`** — whenever a `<CommandName>Input.cs` record exists, also emit a plain JSON Schema mirror of it: one property per field, with `type` (`boolean`/`string`/`number`/`array`/etc. mapped from the C# type), `default` (from the record's `= ...` initializer, if any), and `description` (copied from the field's XML doc comment). This is the machine-readable contract for anything that needs to *produce* a valid `params.json` without reading C# — a hand-built form, a different skill generating a UI, a validation step. It is not DA-specific config and not a DCL/HTML feature; it's the same Input record, just in a format non-.NET tooling can consume. Keep it in sync with the record — regenerate whenever a field is added/renamed/retyped.
- **App.cs** — always include **both** `InternalsVisibleTo("<ProjectName>.IntegrationTests")` and `InternalsVisibleTo("<ProjectName>.Tests")` — `internal` helpers need visibility from the unit test project too, not just integration tests, or `dotnet test` fails with `CS0122`.

**Per-command body pattern — reads parameters, never prompts:**
```csharp
[CommandMethod("CMDNAME")]
public void CmdName()
{
    var db = HostApplicationServices.WorkingDatabase;

    string paramsPath = Path.Combine(Environment.CurrentDirectory, "params.json");
    var input = JsonSerializer.Deserialize<CmdNameInput>(File.ReadAllText(paramsPath))
        ?? throw new InvalidOperationException($"Failed to parse {paramsPath}");

    using var tr = db.TransactionManager.StartTransaction();
    try
    {
        // body derived from Discovery Table rows for this command, reading from `input`
        // instead of interactive getpoint/getstring/getfiled calls
        tr.Commit();
    }
    catch (System.Exception ex)
    {
        tr.Abort();
        ed.WriteMessage($"\nERROR: {ex.Message}\n");
        // do NOT rethrow — see "Never let an exception escape a [CommandMethod]" below
    }
}
```

**Never let an exception escape a `[CommandMethod]` uncaught — always catch, log via `Editor.WriteMessage`, and return.** A raw .NET exception crossing out of a command isn't a clean managed unwind inside AutoCAD's process — it's treated as a native-level fault and triggers AutoCAD's own crash/error-report flow (the same "Send error report" dialog a desktop crash shows). Headless `accoreconsole`/DA has no one to dismiss that dialog, so instead of a clean failure with a diagnostic message, the WorkItem hangs or times out opaquely. Confirmed empirically: a deliberate `throw new NotSupportedException(...)` for a genuine capability gap (see the `SupportPath` row below) triggered exactly this. Signal failure to DA via the `Editor.WriteMessage` log (visible in the WorkItem report) and/or a missing expected output file — never via an uncaught exception.

`WriteMessage`-style logging is still available (`AcCoreMgd.dll` includes the Editor) — but `Autodesk.AutoCAD.ApplicationServices.Application` (the bare desktop type) does **not** exist in a Core-only project and fails with `CS0234` (`AcMgd.dll`-only type, never referenced here — see the Design Automation Guardrail). Use `Autodesk.AutoCAD.ApplicationServices.Core.Application` instead — same `DocumentManager.MdiActiveDocument.Editor.WriteMessage(...)` surface, just the `.Core` namespace segment. Confirmed by an actual `dotnet build` failure/fix during the `gpmain.lsp` GardenPathDA migration; the scaffold's own `App.cs` template had this bug and has since been corrected.

**Use `Editor.WriteMessage`, not `Console.WriteLine`, for all command output/logging — never treat `Console.WriteLine` as an equivalent fallback.** `accoreconsole` happens to surface stdout locally, which makes `Console.WriteLine` look like it works during integration testing — but the real cloud Design Automation engine is not guaranteed to capture bare stdout the same way. `Editor.WriteMessage` writes through AutoCAD's own command-line/report pipeline, which is what actually ends up in the WorkItem's downloadable report log. Every `(princ ...)`/`(prompt ...)` call in the original LISP should map to `Editor.WriteMessage`, full stop — this replaces the earlier (incorrect) guidance that `Console.WriteLine` was a safe fallback needing no verification.

**Watch for `CS0104` ambiguous references — a whole category, not a one-off.** Several AutoCAD.NET namespaces shadow common BCL/WinForms type names. When both are `using`'d, the bare name is ambiguous and fails to compile. Always fully qualify the AutoCAD one, or alias it. Known collisions found in real migrations so far:

| Bare name | AutoCAD type | Collides with | Fix |
|-----------|-------------|----------------|-----|
| `Exception` | `Autodesk.AutoCAD.Runtime.Exception` | `System.Exception` | `catch (System.Exception ex)` |
| `Application` | `Autodesk.AutoCAD.ApplicationServices.Application` | `System.Windows.Forms.Application` | `using AcApp = Autodesk.AutoCAD.ApplicationServices.Application;` |
| `Color` | `Autodesk.AutoCAD.Colors.Color` | `System.Drawing.Color` | Fully qualify or alias `AcColor` |

**General rule:** any time a command uses `System.Windows.Forms` (file dialogs, message boxes) alongside AutoCAD namespaces, expect `Application` and possibly `Color`/`Point`/`Rectangle` collisions too. Check for ambiguity proactively when both namespace families are in the same file — don't wait for the compiler to find it one type at a time. Add newly discovered collisions to this table.

**A different, missing-`using` class of error — not ambiguity, absence.** `var ed = doc.Editor;` resolves member access without ever needing `Autodesk.AutoCAD.EditorInput` imported, since the compiler never needs the type name spelled out. The gap stays invisible until a **helper method's signature explicitly types an `Editor` parameter** (e.g. `private static int Foo(Database db, Transaction tr, Editor ed, ...)`) — that fails `CS0246` unless `using Autodesk.AutoCAD.EditorInput;` is present. Whenever a helper method takes `Editor` (or any AutoCAD type) as an explicit parameter type rather than through `var`, double-check its containing file's `using` list — don't assume the main command body's imports are automatically sufficient. Found during `BlockToXrefDA` (`Helpers`-heavy migration with a private static helper taking `Editor ed`); earlier migrations missed this because none had passed `Editor` as an explicit helper parameter yet.

### Step 4 — Tests

Tests are derived from the Discovery Table. Every command that touches the database or produces output gets tested.

**Tier 1 — xUnit (`dotnet test`, no AutoCAD host)**

For every helper or utility function whose logic is pure (math, string, boolean, parsing — no AutoCAD types):

```csharp
[Theory]
[InlineData(...)]
public void HelperMethod_Scenario_ExpectedResult() => Assert.Equal(expected, Helper.Method(input));
```

Rule: if the code compiles and runs without `accoreconsole`, it belongs in Tier 1. Do not use `Point3d`, `ObjectId`, or any AutoCAD type in xUnit tests — they require the host.

**Tier 2 — NUnit inside accoreconsole (`RunIntegrationTests.ps1`)**

Use the coreconsolerunner pattern. Generated from the Discovery Table as follows:

**TestData.cs** — add one property per measurable output of each C: command. Choose value types only:
- Entity created: capture key geometry (counts, coordinates as `Point2d`/`double`, flags as `bool`)
- File output: capture path as `string`, content summary as `string` or `int` line count
- Database modification: capture the modified property value (layer name, color index, etc.)

Never store `ObjectId`, `DBObject`, or any reference type that requires a live transaction.

**TestSetupCommands.cs** — one `[CommandMethod]` per command being tested. Each:
1. Calls the migrated command method with test inputs (hardcoded or from a fixed drawing state)
2. Captures results into `TestData` statics
3. Commits the transaction

Name the command `<ProjectName>SetupTest` (template pre-fills this).

**IntegrationTests.cs** — one `[Test]` per property in TestData:
```csharp
[OneTimeSetUp] public void CheckSetup() =>
    Assert.That(TestData.Initialized, Is.True, "<ProjectName>SetupTest did not run.");

[Test] public void <Property>_<ExpectedCondition>() =>
    Assert.That(TestData.<Property>, Is.<Constraint>);
```

**Package rule (test project, matching the main plugin project — see Design Automation Guardrail):**
- `AutoCAD.NET.Core` — `AcCoreMgd.dll` only (Database, Geometry, Runtime, Editor). Safe in accoreconsole and in the real DA engine.
- Never `AutoCAD.NET` anywhere in this skill's output — pulls `AcMgd.dll` (desktop UI), crashes accoreconsole and DA alike with `0xC0000005`.
- `ExcludeAssets="runtime"` — accoreconsole/DA provide the assemblies at runtime.
- Pin `System.Drawing.Common` to `8.0.0` explicitly — `ExtentReports` pulls `RazorEngine.NetCore.nixFix` → `System.Drawing.Common 5.0.0`, flagged `NU1904` (GHSA-rxg9-xrhp-64gj). Already included in the `dotnet new acad-lisp` template.

Run tests per the chosen Execution Mode: **Auto** runs `dotnet test` and `RunIntegrationTests.ps1` directly; **Pair-programming** prints both commands and waits for the user's results before continuing.

**If the user wants to manually compare LISP vs .NET behavior in real AutoCAD desktop:** warn them not to load both in the same session. Migrated commands intentionally reuse the exact LISP command names (that's the point — a drop-in replacement), so loading both means the second one either fails to register (duplicate command name) or silently shadows the first, making it impossible to tell which implementation actually ran.

**Closing and reopening the drawing does NOT achieve this isolation.** AutoLISP definitions and `NETLOAD`ed assemblies live in the running `acad.exe` process, not the document — `CLOSE` then `OPEN` within one continuous session leaves LISP's `defun c:*` commands (or a previously loaded .NET assembly) still active in memory. True isolation requires quitting AutoCAD entirely and relaunching it between the LISP test and the .NET test — two separate process launches, not two documents in one process. If scripting this via `.scr`, that means two separate script files run as two separate AutoCAD launches, never `CLOSE`/`OPEN` inside a single script expecting a clean command table.

### Step 5 — Bundle and Package

The `dotnet new acad-lisp` scaffold already generated `PackageContents.xml` with the correct serial from Step 0. Update it with the actual command names found in Step 1:

```xml
<!-- one <Command> per (defun C:NAME ...) discovered in Step 1 -->
<Commands GroupName="<ProjectName>_Commands">
  <Command Local="CMDNAME" Global="CMDNAME" />
</Commands>
```

The scaffold already includes `New-Bundle.ps1` — builds the project and assembles `<ProjectName>.bundle\Contents\Win64\` with the correct DLL/PDB. This is the same bundle folder structure `Deploy-And-Test-DA.ps1` zips and uploads as the APS AppBundle — there's no separate desktop-bundle step:

```powershell
./New-Bundle.ps1 -Config Release
```

(`New-Bundle.ps1`'s `-Deploy` flag, if present, copies to `%APPDATA%\Autodesk\ApplicationPlugins` for a local desktop sanity-check load — useful for confirming the assembly loads and runs cleanly before submitting a real DA WorkItem, but not the deployment path itself.)

Run per Execution Mode as with build/test above. Then fill in `da/activity.json` with the real command name(s) and `da_engine` from the version table, `da/params.example.json` with the actual `<CommandName>Input` fields, and `da/params.schema.json` as the JSON Schema mirror of the same `<CommandName>Input.cs` record (see Step 3's derivation rules) — see the Design Automation Guardrail for `Deploy-And-Test-DA.ps1` usage.

**Before handing off to `Deploy-And-Test-DA.ps1`, check whether `da/.env` exists.** If it's missing, prompt the user explicitly — e.g. "Copy `da/.env.example` to `da/.env` and fill in `APS_CLIENT_ID`/`APS_CLIENT_SECRET` (from an APS app at aps.autodesk.com/myapps) before running the deploy script." Never assume it's already there and let the script fail opaquely later. Claude still never asks for or handles the actual credential values in conversation (see the Design Automation Guardrail) — this is a presence check and reminder, not a request for the values themselves. Reusing an existing filled-in `.env` from another of the developer's own migrations (same APS account) is a standing exception — see `references/da-setup.md`.

**If the Discovery Table found a file-path input beyond the main seed drawing** — e.g. an xref/reference target the command attaches, a template file it reads — a DA sandbox can't reach it via an absolute host path (per the `getfiled` guardrail rule), so it needs to travel as its own uploaded parameter, not get baked into `params.json` as a local path string. Add one more `get` parameter to `activity.json` per extra file (own `localName`), and set the corresponding `<CommandName>Input` field to that `localName`, not an absolute path. `Deploy-And-Test-DA.ps1`'s `-ExtraFiles` hashtable (parameter name → local file to upload) handles this — don't hand-patch the script per migration; it's already generic. Found missing during `BlockToXrefDA`'s Tier 3 test (the first migration needing more than `inputFile`/`params`/`outputFile`) — apply this rule proactively at Step 5 for any future migration shaped the same way, don't wait to discover the gap again.

---

## Migration Examples

Five worked LISP → C# examples (ssget loop, entget+assoc extraction, GetLoopAt boundary extraction, file output → JSON, Region perimeter via Brep) plus the verbose/quiet-mode pattern live in [references/examples.md](references/examples.md) — load it when generating code for a pattern that matches one of these shapes.

---

## Known Edge Cases

**Not every pattern in the original LISP is intended behavior — some are genuine bugs.** When a check gates the *common* case behind a condition that usually fails (e.g. requiring a file to already exist before an operation whose whole purpose is to create it), that's almost always an authoring mistake, not a design choice worth preserving. Fix the underlying logic rather than faithfully reproducing dysfunction, and leave a comment explaining what the original did and why it was changed — see `(findfile ...)` gating an export operation below for the concrete case this rule came from. When genuinely unsure whether odd behavior is intentional (e.g. a business rule vs. a slip), preserve it and flag with a TODO instead of guessing.

**Before claiming a COM call has (or lacks) a typed .NET equivalent, verify it — don't guess from memory.** A plausible-sounding property name (`HostApplicationServices.SupportPath` was tried once — doesn't exist) can look right and still be wrong. Reflect on the actual installed `AcCoreMgd.dll`/`AcDbMgd.dll` to confirm a member exists before writing code that calls it, and confirm it's genuinely absent before writing a `NotSupportedException` gap comment. Caught once during real Tier 2 testing only because the developer independently checked the official API reference and pushed back — verify first next time instead of relying on that catch.

| Pattern | Risk | Resolution |
|---------|------|------------|
| `vl-catch-all-apply` | Error swallowing | Use `try/catch`, log to editor |
| `VARIANT` / `SAFEARRAY` unwrapping | COM type juggling | .NET API is typed — use `GetLoopAt` directly |
| DXF fallback (group code 10 before 91) | Elevation point confusion | Use typed API, skip DXF parsing entirely |
| `(setq x nil)` null checks | Implicit nil = false | Explicit null checks in C# |
| DCL dialogs | No direct .NET equivalent | v2: WPF / Palette / CUIX |
| `(command ...)` sequences | Runtime-dependent | Avoid; use direct API calls — see the Scope section's "Not out of scope, despite first appearances" note. Only sequences needing genuine live mid-command interaction (e.g. `pause`) stay out of scope entirely. |
| `(findfile ...)` | LISP searches ACAD support file paths (`ACAD` sysvar), not just the literal path | `File.Exists`/`File.Open` only check the literal path — document as a v2 TODO if the original relied on support-path search, don't silently narrow behavior |
| `(findfile ...)` gating a write/export operation | `findfile` only returns non-nil if the file **already exists** — if the original code requires `findfile` to succeed before it will export/create, it can never write a brand-new file, only overwrite an existing one. This is a real bug in several jtbworld.com samples (e.g. `viewsIO.lsp`'s `c:-ExportViews`), not intentional design. | Fix it: only gate the *overwrite confirmation* on `File.Exists`, and export unconditionally when the file doesn't exist yet. Comment the deviation from literal LISP behavior. |
| `DBVisualStyle` string-valued traits | No typed setter exists for many `VisualStyleProperty` values (readable via generic trait enumeration, not settable the same way) | Capture on export via the generic trait API; document as a known limitation on import rather than guessing a setter that doesn't exist |
| `getfiled` (LISP file picker) | GUI dialog — impossible headless, no message pump | Never a dialog. Becomes a file-path field on the command's `<CommandName>Input` record, read from `params.json` — see Design Automation Guardrail |
| `DBObjectCollection` / `Region.CreateFromCurves` result wrapped in `using` | Once appended via `AppendEntity` + `AddNewlyCreatedDBObject`, the transaction owns the object. Disposing the wrapping collection afterward (or a collection wrapping an already transaction-owned curve passed *into* `CreateFromCurves`) double-frees it — crashes `accoreconsole`/DA with an **uncatchable native SEH exception** (observed `0xE0000001` in `KERNELBASE.dll`, no managed stack trace, no `try/catch` helps). Confirmed during AcresDA integration testing; only found via `cer.log` + bisecting with `Editor.WriteMessage` checkpoints. | Never wrap a `DBObjectCollection` in `using` once its contents (or contents passed into it) become transaction-owned. |
| `Hatch.AppendLoop(HatchLoopTypes loopType, ObjectIdCollection dbObjIds)` without `HatchLoopTypes.External` | Compiles fine, then crashes natively inside `Hatch.EvaluateHatch(true)` — same uncatchable-SEH class as above, not a .NET exception. | Always OR in `HatchLoopTypes.External` when the loop boundary references an existing db curve by `ObjectId`. |
| ObjectDBX cross-file scanning (`vla-Open` on a *referenced* file to inspect its contents — e.g. an Xref manager counting nested xrefs/layers/blocks in each referenced drawing) | The referenced files are on the *local* filesystem the original LISP ran on. A DA sandbox only has what's explicitly uploaded — none of those files travel with the main input `.dwg` automatically. | Unsolved as of this writing — options are (a) scope down to what's derivable from the top-level `.dwg` alone (no nested-file open needed), or (b) require an upload manifest/zip preserving the referenced files' relative paths. Flag this explicitly to the user before committing to a design; don't silently drop the deep-scan feature or silently assume file access that won't exist in DA. |
| `vla-get-supportpath`/`vla-put-supportpath` (COM `Preferences.Files.SupportPath`) | No typed equivalent in `AcCoreMgd.dll`/`AcDbMgd.dll` — confirmed by reflecting on both DLLs (`HostApplicationServices` has no `SupportPath` member), then confirmed at the source: `pref.idl`'s `IAcadPreferencesFiles` declares `SupportPath` as a `propget`/`propput` pair on an `IDispatch`-derived interface — pure COM Automation, no ARX-managed wrapper exists to expose. Genuine, permanent DA capability gap, not a missed API lookup. Not to be confused with `PackageContents.xml`'s unrelated `SupportPath` attribute (a bundle-deployment path, not an app preference). | Catch it at the top of the command, log via `Editor.WriteMessage` with a clear gap explanation, and return — do **not** `throw`. See "Never let an exception escape a `[CommandMethod]`" above; a raw `NotSupportedException` here triggered AutoCAD's native crash/error-report flow in real `accoreconsole` testing. |

