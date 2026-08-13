# AutoLISP → AutoCAD .NET Migration Skill

## Problem

Visual LISP (`vlax-*`, `vla-*`, COM/ActiveX calls) does not run in Design Automation — the COM runtime is absent from headless `accoreconsole`. Basic AutoLISP (`entget`, `ssget`, `entmod`) does run in DA, but most real-world LISP plugins use Visual LISP COM calls and are blocked from the cloud. Migrating to the typed .NET API is the only path to Design Automation for those plugins.

## Objective

A Claude Code skill (`/lisp-to-dotnet`) that reads an AutoLISP file and generates a complete, production-ready AutoCAD .NET C# plugin for Design Automation — source, unit tests, `accoreconsole` integration tests, and a deployable bundle. Not a fixed template for one entity shape: the analysis step (a **Discovery Table**) is generic, so it adapts to whatever the LISP file actually contains.

**Expected outcome:** a developer with a legacy LISP plugin and no prior AutoCAD .NET experience can run the skill and get a working, DA-deployable C# project — not a partial scaffold that still needs hand-finishing, and not code that merely compiles without ever being proven against real APS Design Automation.

## Anti-goals

- **Not a desktop/interactive tool.** Design Automation only, by construction — every migrated command is parameterized and non-interactive. No desktop output, no `--target` split. (Prior multi-target version preserved on the `desktop` git branch if that scope is ever needed again.)
- **Not a dialog *renderer* — but DCL values are still real input, not dead code.** DCL mechanics (`load_dialog`/`new_dialog`/`action_tile`/etc.) are stubbed, never turned into broken UI. But every value a DCL tile gathered is treated as interactive input, same as `getpoint`/`getkword` — extracted into the same `<CommandName>Input` record and `params.schema.json` contract. The dialog's actual replacement — a static HTML form + Node/Python server — is a follow-on build phase on top of this skill's own output, not a disconnected handoff. Demonstrated end-to-end with `FlangeDA`.
- **Not a shared, compiled CLI.** Per-migration PowerShell scripts (`da/*.ps1`), not one central tool — a real APS bug's fix should be a visible edit to a script the developer already has open, not a separate CLI build/release cycle.
- **Not a guesser.** Never invents a plausible-sounding .NET API for a COM call — capability gaps get verified (DLL reflection, or the original IDL source) and logged clearly, not papered over.

## Structure

```
skill/
  SKILL.md              ← the skill itself: procedure, guardrails, pattern mapping
  references/            ← detail loaded on demand, kept out of SKILL.md's line budget
    patterns.md            LISP → C# mapping tables (selection sets, DXF codes, VLA/COM, file I/O)
    examples.md             worked before/after code examples
    da-setup.md             what Claude asks for vs. what the developer fills in (env paths, credentials)
  templates/
    acad-lisp-migration/  ← the `dotnet new` template — scaffolds the full generated project
```

Everything under `skill/` is the deployable unit (installed via `/plugin install` or copied to `~/.claude/skills/`). Everything else in this repo — `dotnet-outputs/` (worked examples), `lisps/` (test corpus), `evals/` (quality gate) — supports developing and validating the skill, but isn't part of what a user installs.

## Architecture

1. **DCL Guardrail** — scans for dialog code first; refuses rather than generating broken UI.
2. **Design Automation Guardrail** — every interactive input (`getpoint`/`getstring`/`getfiled`/`getkword`) becomes a `params.json`-backed field, never a live prompt.
3. **Discovery Table** — every command, entity access, DXF read/write, and COM call catalogued with its .NET equivalent before any code is written.
4. **Scaffold** — `dotnet new acad-lisp-migration` generates the full project structure (csproj, tests, bundle manifest, DA scripts) with the correct AutoCAD version/TFM/NuGet already resolved.
5. **Code generation** — pure/testable model code separated from AutoCAD-dependent service code; `Editor.WriteMessage` for all output/logging, never `Console.WriteLine`.
6. **Tests** — xUnit for pure logic, NUnit self-hosted inside `accoreconsole` for anything touching the database.
7. **Bundle + real DA deployment** — `PackageContents.xml` + `da/Deploy-And-Test-DA.ps1` deploy to real APS Design Automation and submit an actual WorkItem. Credentials never pass through Claude — `da/.env` is filled in by the developer, gitignored.
8. **Machine-readable params contract** — `da/params.schema.json` mirrors the input record as JSON Schema, for any non-.NET consumer.

## Status

Validated via the eval suite (`evals/evals.json`), a 62-file corpus sweep, 7 full migrations, and 5 independent real APS Design Automation WorkItem successes. Specific findings, fixes, and edge cases live in `SKILL.md`'s Known Edge Cases — not duplicated here.
