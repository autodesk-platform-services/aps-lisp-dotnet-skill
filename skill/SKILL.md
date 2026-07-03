---
name: lisp-to-dotnet
description: "AutoLISP to AutoCAD .NET migration skill. Analyzes .lsp files, maps Lisp patterns to .NET equivalents, generates C# plugin code with unit tests, AppStore bundle packaging, and Design Automation (DA) deployment. AutoLISP does not run in Design Automation — this skill is the migration path."
argument-hint: "Path to .lsp file and target (e.g., 'convert gpmain.lsp to .NET for AppStore' or 'convert ExportHatch.lsp to Design Automation')"
---

# AutoLISP → AutoCAD .NET Migration Skill

Converts AutoLISP routines into production-ready AutoCAD .NET C# plugins.

**Core motivation:** Visual LISP (the COM/ActiveX API — `vlax-*`, `vla-*`, `vlax-invoke-method`) does not work in Design Automation. The COM runtime is absent in headless accoreconsole. Basic AutoLISP (`entget`, `ssget`, `entmod`) does run in DA, but most real-world LISP plugins use Visual LISP COM calls and are therefore blocked. Migration to .NET typed API is the only path to cloud automation for those plugins. This skill removes the C# syntax barrier for LISP developers.

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
- **nuget_version** → `AutoCAD.NET` version in `.csproj`
- **tfm** → `TargetFramework` in `.csproj`

If the user has already provided any path in the argument, accept it and only ask for the missing ones.

## Conversion Targets

Always ask or infer which target the user needs:

| Target | Flag | Output | Notes |
|--------|------|--------|-------|
| Desktop + AppStore | `--target desktop` | `.bundle` for `%APPDATA%\Autodesk\ApplicationPlugins` | Full editor access, UI allowed |
| Design Automation | `--target da` | `.bundle` for DA activity via APS | No editor, no UI, headless only |
| Both | `--target both` | Two bundles, shared core logic | Recommended for most migrations |

Default to `--target both` unless user specifies otherwise.

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
- AppStore bundle packaging (desktop)
- Design Automation bundle + activity (DA)

### Out of Scope (v2)
- DCL dialog box UI migration (CUIX/WPF replacement — needs design session)
- `(command ...)` macro sequences
- Complex reactor chains
- AutoLISP reactor / event-driven code

---

## Pattern Mapping Reference

### Selection Sets

| AutoLISP | C# (.NET) |
|----------|-----------|
| `(ssget "_X" '((0 . "HATCH")))` | `db.GetModelSpace().Cast<Entity>().OfType<Hatch>()` |
| `(ssget "_X" '((0 . "LINE")))` | `.OfType<Line>()` |
| `(sslength ss)` | `selSet.Count` |
| `(ssname ss i)` | `selSet[i]` |
| `(ssadd ent ss)` | `selSet.Add(entity)` |

### Entity Data (DXF Group Codes)

| AutoLISP | C# (.NET) |
|----------|-----------|
| `(entget ent)` | `tr.GetObject(id, OpenMode.ForRead)` |
| `(assoc 0 entdata)` | `entity.GetType().Name` (or `entity.GetRXClass().DxfName`) |
| `(assoc 5 entdata)` | `entity.Handle.ToString()` |
| `(assoc 8 entdata)` | `entity.Layer` |
| `(assoc 10 entdata)` | depends on entity type (e.g., `line.StartPoint`) |
| `(cdr (assoc 91 entdata))` | `hatch.NumberOfLoops` |
| `(entmod newdata)` | `entity.UpgradeOpen(); entity.Property = value;` |
| `(entdel ent)` | `entity.Erase()` |

### VLA-Object / COM Interop

| AutoLISP | C# (.NET) |
|----------|-----------|
| `(vlax-ename->vla-object ent)` | `tr.GetObject(ent, OpenMode.ForRead)` |
| `(vla-get-Handle obj)` | `entity.Handle` |
| `(vla-get-NumberOfLoops hatch)` | `hatch.NumberOfLoops` |
| `(vlax-invoke-method hatch 'GetLoopAt 0 'loopObjs)` | `hatch.GetLoopAt(0, out loopType, out curves)` |
| `(vlax-safearray->list coords)` | `curves.Cast<Entity>().ToList()` |
| `(vla-get-Coordinates polyline)` | `lwpoly.GetPoint2dAt(i)` |

### File I/O

| AutoLISP | C# (.NET) |
|----------|-----------|
| `(open filename "w")` | `File.CreateText(path)` / `StreamWriter` |
| `(write-line str file)` | `writer.WriteLine(str)` |
| `(close file)` | `writer.Dispose()` / `using` block |
| `(getvar "CDATE")` | `DateTime.Now.ToString("yyyyMMdd_HHmmss")` |

### String / Math

| AutoLISP | C# (.NET) |
|----------|-----------|
| `(strcat a b c)` | `string.Concat(a, b, c)` / `$"{a}{b}{c}"` |
| `(itoa n)` | `n.ToString()` |
| `(rtos x 2 8)` | `x.ToString("F8")` |
| `(atof s)` | `double.Parse(s)` |
| `(strlen s)` | `s.Length` |
| `(substr s 1 n)` | `s.Substring(0, n)` |
| `(fix x)` | `(int)x` |
| `(logand a b)` | `a & b` |
| `(1+ n)` | `n + 1` |
| `(vl-remove-if pred list)` | `.Where(x => !pred(x))` |
| `(foreach item list ...)` | `foreach (var item in list)` |
| `(repeat n ...)` | `for (int i = 0; i < n; i++)` |

### Command Registration

| AutoLISP | C# (.NET) |
|----------|-----------|
| `(defun C:MYCOMMAND () ...)` | `[CommandMethod("MYCOMMAND")] public void MyCommand()` |
| `(setq *VERBOSE* nil)` | `private bool _verbose = false;` |
| `(princ msg)` | `ed.WriteMessage(msg)` |

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
| **User input** | `(getpoint)`, `(getreal)`, `(getstring)`, `(getdist)` | `ed.GetPoint()`, `ed.GetDouble()`, `ed.GetString()`, `ed.GetDistance()` |
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

The template produces a complete scaffold with TFM, NuGet versions, `PackageContents.xml` serial, and `RunIntegrationTests.ps1` defaults all pre-resolved for the chosen AutoCAD version:

```
<ProjectName>/
  <ProjectName>.csproj                  ← correct TFM + AutoCAD.NET version
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
  AGENTS.md                             ← AI coding context for the generated project
```

After the user runs the scaffold command, read the generated stubs and proceed to Step 3.

### Step 3 — Generate C# code

The file structure is **derived from the Discovery Table**, not fixed. Only create what the LISP actually contains.

```
<ProjectName>/
  App.cs                          ← always: IExtensionApplication + assembly attributes
  Commands.cs                     ← always: one [CommandMethod] per discovered C: command
  Helpers/<GroupName>.cs          ← only if: helper defuns exist; group by logical concern
  Models/<EntityName>Data.cs      ← only if: 3+ related fields are extracted from one entity type
```

**Derivation rules:**

- **Commands.cs** — one `public void CmdName()` per `(defun C:NAME ...)`. Use the Discovery Table to fill the body: entity filters, DXF→property reads, writes, file output.
- **Helpers/** — create if there are non-trivial helper `defun`s. Name the file after the logical group (e.g., `GeometryHelper.cs`, `StringHelper.cs`, `LayerHelper.cs`). Skip if helpers are simple one-liners inlined in the command.
- **Models/** — create a `record` only when a command builds a structured data object from 3+ related fields. Name it after the entity concept (e.g., `HatchBoundary`, `TextItem`, `BlockRef`). Skip if data is just passed through inline.
- **App.cs** — always include `InternalsVisibleTo("<ProjectName>.IntegrationTests")` for test access to `internal` helpers.

**Per-command body pattern:**
```csharp
[CommandMethod("CMDNAME")]
public void CmdName()
{
    var doc = Application.DocumentManager.MdiActiveDocument;
    var db  = doc.Database;
    var ed  = doc.Editor;
    using var tr = db.TransactionManager.StartTransaction();
    try
    {
        // body derived from Discovery Table rows for this command
        tr.Commit();
    }
    catch (System.Exception ex)
    {
        ed.WriteMessage($"\nError: {ex.Message}\n");
        tr.Abort();
    }
}
```

**Watch for `CS0104` ambiguous references — a whole category, not a one-off.** Several AutoCAD.NET namespaces shadow common BCL/WinForms type names. When both are `using`'d, the bare name is ambiguous and fails to compile. Always fully qualify the AutoCAD one, or alias it. Known collisions found in real migrations so far:

| Bare name | AutoCAD type | Collides with | Fix |
|-----------|-------------|----------------|-----|
| `Exception` | `Autodesk.AutoCAD.Runtime.Exception` | `System.Exception` | `catch (System.Exception ex)` |
| `Application` | `Autodesk.AutoCAD.ApplicationServices.Application` | `System.Windows.Forms.Application` | `using AcApp = Autodesk.AutoCAD.ApplicationServices.Application;` |
| `Color` | `Autodesk.AutoCAD.Colors.Color` | `System.Drawing.Color` | Fully qualify or alias `AcColor` |

**General rule:** any time a command uses `System.Windows.Forms` (file dialogs, message boxes) alongside AutoCAD namespaces, expect `Application` and possibly `Color`/`Point`/`Rectangle` collisions too. Check for ambiguity proactively when both namespace families are in the same file — don't wait for the compiler to find it one type at a time. Add newly discovered collisions to this table.

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

**Package rule (integration test project only):**
- `AutoCAD.NET.Core` — `AcCoreMgd.dll` only (Database, Geometry, Runtime, Editor). Safe in accoreconsole.
- Never `AutoCAD.NET` in test project — pulls `AcMgd.dll` (desktop UI), crashes accoreconsole with `0xC0000005`.
- Main plugin project keeps `AutoCAD.NET` (targets interactive AutoCAD).
- `ExcludeAssets="runtime"` on both — accoreconsole provides assemblies at runtime.
- Pin `System.Drawing.Common` to `8.0.0` explicitly — `ExtentReports` pulls `RazorEngine.NetCore.nixFix` → `System.Drawing.Common 5.0.0`, flagged `NU1904` (GHSA-rxg9-xrhp-64gj). Already included in the `dotnet new acad-lisp` template.

Run tests per the chosen Execution Mode: **Auto** runs `dotnet test` and `RunIntegrationTests.ps1` directly; **Pair-programming** prints both commands and waits for the user's results before continuing.

### Step 5 — Bundle and Package

The `dotnet new acad-lisp` scaffold already generated `PackageContents.xml` with the correct serial from Step 0. Update it with the actual command names found in Step 1:

```xml
<!-- one <Command> per (defun C:NAME ...) discovered in Step 1 -->
<Commands GroupName="<ProjectName>_Commands">
  <Command Local="CMDNAME" Global="CMDNAME" />
</Commands>
```

For **desktop + AppStore** deployment, the scaffold already includes `New-Bundle.ps1` — builds the project and assembles `<ProjectName>.bundle\Contents\Win64\` with the correct DLL/PDB:

```powershell
./New-Bundle.ps1 -Config Release
# or, to deploy straight to %APPDATA%\Autodesk\ApplicationPlugins for local testing:
./New-Bundle.ps1 -Config Release -Deploy
```

Run per Execution Mode as with build/test above.

For **Design Automation**, the bundle is the same structure but the activity JSON uses `da_engine` from the version table:
```json
{ "engine": "<da_engine>", "appbundles": ["<owner>.<ProjectName>+dev"] }
```

No editor (`ed`) calls in the DA variant — replace with file output or return codes.

---

## Migration Examples

### Example 1: ssget + sslength + ssname loop

**LISP:**
```lisp
(setq ss (ssget "_X" '((0 . "HATCH"))))
(repeat (sslength ss)
  (setq ent (ssname ss i))
  ...
  (setq i (1+ i))
)
```

**C#:**
```csharp
using (var tr = db.TransactionManager.StartTransaction())
{
    var bt = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);
    var btr = (BlockTableRecord)tr.GetObject(bt[BlockTableRecord.ModelSpace], OpenMode.ForRead);
    foreach (ObjectId id in btr)
    {
        var entity = tr.GetObject(id, OpenMode.ForRead) as Hatch;
        if (entity == null) continue;
        // ... process hatch
    }
    tr.Commit();
}
```

### Example 2: entget + assoc DXF extraction

**LISP:**
```lisp
(setq entdata (entget ent))
(setq handle (cdr (assoc 5 entdata)))
(setq numLoops (cdr (assoc 91 entdata)))
```

**C#:**
```csharp
var hatch = (Hatch)tr.GetObject(id, OpenMode.ForRead);
string handle = hatch.Handle.ToString();
int numLoops = hatch.NumberOfLoops;
```

### Example 3: GetLoopAt boundary extraction

**LISP:**
```lisp
(vlax-invoke-method hatch-obj 'GetLoopAt 0 'loopObjs)
```

**C#:**
```csharp
hatch.GetLoopAt(0, out HatchLoopTypes loopType, out Curve2dCollection curves);
foreach (var curve in curves.Cast<CircularArc2d>())
{
    // process curve
}
```

### Example 4: File output → JSON

**LISP:**
```lisp
(setq json-file (open filename "w"))
(write-line "[" json-file)
(write-line (strcat "  {\"handle\": \"" handle "\"}") json-file)
(write-line "]" json-file)
(close json-file)
```

**C#:**
```csharp
var records = hatches.Select(h => new { handle = h.Handle.ToString(), vertices = ExtractVertices(h) });
File.WriteAllText(outputPath, JsonSerializer.Serialize(records, new JsonSerializerOptions { WriteIndented = true }));
```

---

## Verbose / Quiet Mode Pattern

**LISP:**
```lisp
(setq *HATCH_EXPORT_VERBOSE* nil)
(defun dbg-print (msg)
  (if *HATCH_EXPORT_VERBOSE* (princ msg))
)
```

**C#:**
```csharp
private bool _verbose = false;
private void DbgPrint(string msg)
{
    if (_verbose) _ed.WriteMessage(msg);
}
```

---

## Known Edge Cases

| Pattern | Risk | Resolution |
|---------|------|------------|
| `vl-catch-all-apply` | Error swallowing | Use `try/catch`, log to editor |
| `VARIANT` / `SAFEARRAY` unwrapping | COM type juggling | .NET API is typed — use `GetLoopAt` directly |
| DXF fallback (group code 10 before 91) | Elevation point confusion | Use typed API, skip DXF parsing entirely |
| `(setq x nil)` null checks | Implicit nil = false | Explicit null checks in C# |
| DCL dialogs | No direct .NET equivalent | v2: WPF / Palette / CUIX |
| `(command ...)` sequences | Runtime-dependent | Avoid; use direct API calls |
| `(findfile ...)` | LISP searches ACAD support file paths (`ACAD` sysvar), not just the literal path | `File.Exists`/`File.Open` only check the literal path — document as a v2 TODO if the original relied on support-path search, don't silently narrow behavior |
| `DBVisualStyle` string-valued traits | No typed setter exists for many `VisualStyleProperty` values (readable via generic trait enumeration, not settable the same way) | Capture on export via the generic trait API; document as a known limitation on import rather than guessing a setter that doesn't exist |
| `getfiled` (LISP file picker) | GUI dialog, needs a .NET equivalent | `System.Windows.Forms.OpenFileDialog`/`SaveFileDialog` + `<UseWindowsForms>true</UseWindowsForms>` in the csproj — check for an `Autodesk.AutoCAD.Windows` wrapper first, but don't assume one exists for every entity/version; WinForms is the safe fallback |

---

## AU 2026 Demo Targets

Target files for live migration demo:

1. `ExportHatchToJSON.lsp` → `HatchExporter.cs`
   - Shows: ssget, entget, GetLoopAt, file output
   - Tests: boundary extraction, JSON format

2. `TextExtract.lsp` → `TextExtractor.cs`  
   - Shows: text entity ops, string handling

3. `APS_ExportHatchToJSON.lsp` → `ApsHatchExporter.cs`
   - Shows: DA/headless variant, no editor dependency
