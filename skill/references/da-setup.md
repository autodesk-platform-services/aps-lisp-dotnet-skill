# Design Automation Setup — What Claude Asks vs. What the Developer Fills In

Two different categories of prerequisite, handled two different ways. Referenced from `SKILL.md`'s Design Automation Guardrail — read this when a migration reaches the point of actually deploying/testing against real APS.

## What Claude asks for directly (Step 0)

Non-secret, needed immediately to scaffold and build:

- AutoCAD install folder (derives `accoreconsole.exe` path, NuGet version)
- LISP project folder
- ARX SDK folder

These are safe to ask in conversation — they're local filesystem paths, not credentials.

## What Claude never asks for: APS credentials

**Claude does not request, handle, or type `APS_CLIENT_ID`/`APS_CLIENT_SECRET` in the conversation, ever.** These are real API secrets tied to the developer's own Autodesk Platform Services account and billing — pasting them into an LLM chat is a bad security practice regardless of how much you trust the tool. Instead:

1. The scaffold includes `da/.env.example` — copy it to `da/.env` (gitignored, never committed) and fill in your own values from an APS app at [aps.autodesk.com/myapps](https://aps.autodesk.com/myapps) (needs Design Automation + Data Management API access enabled).
2. `da/APS-Common.ps1` loads `da/.env` automatically (via `Import-DotEnv`, dot-sourced at the top of every DA script) — nothing else to configure.
3. Run `da/Deploy-And-Test-DA.ps1 -InputDwg <seed.dwg>` yourself, in your own shell.

You can ask Claude for help interpreting the *output* of that run (build errors, WorkItem failure reports, REST error messages) without ever pasting the actual credential values into the conversation — the script reads them from `.env` on your machine, Claude never sees them.

## Complete prerequisites checklist

Everything actually required to go from a `.lsp` file to a real DA WorkItem result, end to end:

| Prerequisite | Who provides it | When |
|---|---|---|
| AutoCAD install folder | User, asked by Claude | Step 0 |
| LISP project folder | User, asked by Claude | Step 0 |
| ARX SDK folder | User, asked by Claude | Step 0 |
| `da/.env` (APS Client ID/Secret, nickname) | User, filled in themselves from `da/.env.example` | Before running `Deploy-And-Test-DA.ps1` |
| A seed `.dwg` matching the migrated command's expected input | User, or Claude-generated — see below | Before running `Deploy-And-Test-DA.ps1` |

If any of these is missing when a step needs it, stop and ask for it explicitly rather than guessing or substituting a placeholder — a migration that silently assumes an AutoCAD path or a seed drawing that doesn't exist fails confusingly later instead of clearly now.

## No seed `.dwg` and no AutoCAD desktop? Generate one headlessly

The developer doesn't need AutoCAD desktop to produce a seed drawing. Add a small dev-only `[CommandMethod]` to the main plugin (e.g. `HBSEED`) that builds the minimal entity the migrated command needs directly via the Database API — clearly commented as dev/test-only, never added to `PackageContents.xml`'s `<Commands>` list. Then run `accoreconsole` with no `/i` (it opens its own blank drawing) and `FILEDIA 0` before `QSAVE` so the save-as prompt is answered on the command line. Full script pattern and rationale in SKILL.md's Design Automation Guardrail section — this is the same technique used to produce `HatchBDA`'s `seed.dwg` (`da/Make-SeedDwg.ps1`).

If the migrated command only *creates* geometry from scratch (form-driven generators — every input comes from `params.json`, nothing depends on what's already in the drawing) and never reads pre-existing entities, skip the dev-seed-command step entirely: any blank drawing works, so just run `accoreconsole` with no `/i` directly against the real command.

## Nickname/resource issues mid-deployment

If a `Deploy-And-Test-DA.ps1` run fails with a nickname- or "could not be found"-shaped error, see SKILL.md's Design Automation Guardrail for the confirmed root causes (unqualified `activityId` references, the `GET /forgeapps/me` default-identity-equals-`APS_CLIENT_ID` gotcha, and `Resolve-DANickname` trusting a requested nickname that never actually PATCHed — fixed at the source, see SKILL.md) before assuming it's a new bug. `-Owner <known real nickname>` explicitly still works as a fast manual override if needed. `da/Reset-APSApp.ps1 -Confirm` is the last-resort clean-slate reset if resource state is genuinely confused across runs.

## Reusing an existing `.env` across migrations

Copying an already-filled-in `da/.env` from one of the developer's own migration folders into another (same APS account, same registered nickname, reused on purpose) is a **standing allowed exception** to "the developer fills it in themselves" — as long as it's a plain file copy, explicitly directed by the developer, and the actual secret values are never read or echoed into the conversation (key *names* only, if verifying shape). Every migration still gets its own `da/.env.example` for the case where the developer wants a fresh app/account instead.
