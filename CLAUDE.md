# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repo Layout

```
skill/          ← DEPLOYABLE UNIT — deploy this folder via skills CLI
  SKILL.md        ← skill definition (Discovery Table procedure, pattern
                     mapping reference, environment setup, DCL guardrail)
  templates/
    acad-lisp-migration/   ← `dotnet new` template — scaffolds the full
                              project structure (csproj, App.cs, test
                              infra, PackageContents.xml, bundle script).
                              Install once: `dotnet new install
                              skill/templates/acad-lisp-migration`

dotnet-outputs/ ← reference migrations produced BY the skill — not
                   deployed, not part of the skill package. Kept at repo
                   root (sibling to skill/) so the deployable unit stays
                   small. bin/obj/*.dll/*.pdb are gitignored.
  GardenPath/     ← full worked example (desktop + accoreconsole
                     integration tests, verified passing)
  ViewsIO/        ← dry-run migration of viewsIO.lsp — exercises
                     entget/entmod/entmake/entmakex + VLA dictionary
                     access (not yet built/run)

lisps/          ← research corpus only — 64 real-world .lsp samples
                   from jtbworld.com. NOT deployed. Used for pattern
                   discovery and skill testing.

evals/          ← eval suite for the SKILL ITSELF (evals.json + fixture
                   .lsp files + Run-Eval.ps1 manual-verification harness).
                   Validates skill quality/regressions — not something a
                   customer running a migration ever touches. Kept at
                   repo root, not inside skill/, for the same reason as
                   dotnet-outputs/ and lisps/: the deployable unit stays
                   small and customer-facing only.

CLAUDE.md       ← this file — project context, NOT deployed
```

All learning from worked examples is captured directly in `SKILL.md` (the Discovery Table procedure and pattern mapping reference) — `dotnet-outputs/` exists for human verification, not as something the skill reads from at migration time.

**Branches:** `master`/`au-2026-da-only` — Design Automation is the skill's only target (see Scope Boundaries below); no desktop/interactive output is generated. `desktop` — a preserved snapshot of the prior multi-target (desktop + DA + both) skill, kept in case that scope is needed again later. `dotnet-outputs/GardenPath` predates the DA-only pivot and still reflects the old desktop-oriented shape — treat it as historical, not as current expected output.

## What This Is

A Claude Code skill (`skill/SKILL.md`) that converts AutoLISP (`.lsp`) routines into a production-ready AutoCAD .NET C# plugin for **Design Automation**. The skill itself is pure documentation — no build system exists here. The **outputs** it generates are C# projects, one per migration, DA-only.

## Invoking the Skill

```
/lisp-to-dotnet <path-to-file.lsp> [migration goal]
```

Example: `/lisp-to-dotnet lisps/viewsIO.lsp convert to .NET with unit tests`

## Migration Flow

1. Resolve environment paths + AutoCAD version (Step 0 in SKILL.md)
2. Read the `.lsp` file, build the Discovery Table (Step 1) — this is fully generic, not tied to any fixed entity type or command shape
3. User runs `dotnet new acad-lisp -n <ProjectName> --AutoCADVersion <year>` to scaffold (Step 2)
4. Claude fills in the generated stubs — `Commands.cs`, `Helpers/`, `Models/`, `TestData.cs`, `TestSetupCommands.cs` — derived from the Discovery Table (Steps 3–4). Every interactive LISP input (`getpoint`/`getstring`/`getfiled`/etc.) becomes a field on a parameterized `<CommandName>Input` record read from `params.json` — never an interactive prompt.
5. User runs `RunIntegrationTests.ps1` (accoreconsole) and `dotnet test` (xUnit) to verify
6. `New-Bundle.ps1` packages the DA bundle (Step 5); `da/Deploy-And-Test-DA.ps1` deploys it to a real APS Design Automation activity and submits a test WorkItem

File structure and test count are **derived per-migration** from what the LISP actually contains — not a fixed template. See SKILL.md Step 3 for the derivation rules.

## Generated .csproj Requirements

- TFM/NuGet version derived from AutoCAD year (2025→net8.0-windows/25.0.0, 2026→net8.0-windows/25.1.0, 2027→net10.0-windows/26.0.0)
- `PlatformTarget x64`, `GenerateTargetFrameworkAttribute false`
- **`AutoCAD.NET.Core` everywhere — main plugin and test projects alike.** Never `AutoCAD.NET` (`AcMgd.dll` crashes both `accoreconsole` and the real DA engine with `0xC0000005`). Design Automation is this skill's only target; there is no desktop project to justify the full package.
- Unit tests: `xUnit` + `AutoCAD.NET.Model`

## Scope Boundaries

**In scope (v1):** `defun C:*` commands, `ssget`/`ssname`/`sslength`, `entget`/`entmod`/`entdel`/`entmake`, DXF group code `assoc`, VLA-Object/COM interop, file I/O, string/math utilities, unit tests, Design Automation bundle + activity deployment.

**Out of scope (v2):** DCL dialogs (flag as TODO, WPF/Palette replacement needs design session), `(command ...)` macro sequences, reactor/event-driven code.

## Key Migration Rules

- `defun C:CMD` → `[CommandMethod("CMD")] public void Cmd()`
- `ssget "_X" '((0 . "HATCH"))` → `btr.Cast<Entity>().OfType<Hatch>()`
- `entget` + `assoc` → typed .NET properties (never use DXF group codes when a typed API exists)
- `vlax-invoke-method hatch 'GetLoopAt ...` → `hatch.GetLoopAt(0, out loopType, out curves)`
- `open`/`write-line`/`close` → `using var writer = File.CreateText(path)`; prefer `JsonSerializer` for structured output
- Global `setq` vars → class-level fields
- `vl-catch-all-apply` → `try/catch` with editor log

## Unit Test Strategy

- Pure logic (math, string, JSON serialization): xUnit, no AutoCAD runtime needed
- Database/entity operations: NUnit + NUnitLite self-hosted in accoreconsole (coreconsolerunner pattern) — commands WRITE (doc lock automatic), NUnit threads only READ from `TestData` statics. No `LockDocument`, no `OpenCloseTransaction`.
- ExtentReports HTML output for the integration test run, viewable in VS Code Simple Browser

## Worked Examples

`dotnet-outputs/GardenPath` and `dotnet-outputs/ViewsIO` predate the Design-Automation-only pivot and still reflect the old desktop-oriented shape — treat as historical validation, not current expected output. `skill/evals/files/` holds the current fixtures used for skill evaluation (`gpmain.lsp`, `HATCHB.lsp`, `mstxt.lsp`) — see `skill/evals/evals.json`.
