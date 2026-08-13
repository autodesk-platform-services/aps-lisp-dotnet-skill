# lisp-to-dotnet

Claude Code skill that migrates AutoLISP (`.lsp`) plugins into AutoCAD .NET C# for **Design Automation**. AutoLISP's COM/ActiveX runtime (`vla-`/`vlax-`) doesn't exist in the headless DA engine — this skill reads a `.lsp` file, maps every command/entity op/DXF access/COM call to its .NET equivalent, and generates a full DA-ready plugin: source, unit tests, `accoreconsole` integration tests, and a deployable bundle.

Details: [`skill/SKILL.md`](skill/SKILL.md) · Architecture/status: [`SPEC.md`](SPEC.md)

## Validated

- **3 independent real APS Design Automation deploys** — HatchBDA, AcresDA, FlangeDA — each submitted a real WorkItem against the live cloud service and got a result back, not simulated.
- **Corpus-wide dry run**: 62/62 real-world `.lsp` files (jtbworld.com corpus) produced a correct Discovery Table, no silent skips.
- **7/7 full migrations** (scaffold → codegen → build → unit tests, representative sample spanning VLA/COM, file I/O, heaviest interactive-input file in the corpus) — all passing, several real bugs found and fixed in the skill itself along the way (never-let-an-exception-escape-a-command, missing `using` directives, `InternalsVisibleTo` gaps).

## Get started

```sh
git clone https://github.com/autodesk-platform-services/aps-lisp-dotnet-skill.git
cd aps-lisp-dotnet-skill
cp -r skill ~/.claude/skills/lisp-to-dotnet
dotnet new install skill/templates/acad-lisp-migration
claude "/lisp-to-dotnet <your-file>.lsp"
```

## Before / after

![Discovery Table overview](LISP-NET-SKILL.png)

- `before.mp4` — desktop AutoLISP, interactive
- `after.mp4` — Design Automation, headless, cloud

Design-Automation-only by construction — every migrated command is parameterized and non-interactive, no desktop/interactive output.

## Credits

The 64-file test corpus (`lisps/`) that this skill was validated against is real-world AutoLISP by Jimmy Bergmark, [JTB World](https://jtbworld.com/autolisp-visual-lisp) — decades of genuinely useful, freely-shared LISP routines, and reuse is explicitly welcomed on the site itself: *"Please feel free to be inspired, cut&paste or if you have any feedback, questions or looking for an AutoLISP programmer for small or large projects go here."* Several of the corpus's real bugs and edge cases (found and fixed as part of validating this skill) trace back to these files — thank you for keeping them public.
