# AGENTS.md

## Build
```
dotnet build
dotnet test Tests/MyPlugin.Tests/
```

## Integration Tests (requires AutoCAD accoreconsole)
```
pwsh Tests/Integration/RunIntegrationTests.ps1 -OpenReport
```

## AutoCAD .NET package rule
- `AutoCAD.NET.Core` everywhere — main plugin and test projects alike (`AcCoreMgd.dll`, headless-safe).
- Never reference `AutoCAD.NET`/`AcMgd.dll` anywhere in this project — crashes accoreconsole and the real DA engine alike with `0xC0000005`. Design Automation is this project's only target; there is no desktop build to justify it.

## Design Automation input pattern
Every command's inputs come from `params.json`, never from an interactive prompt or dialog (`getpoint`/`getstring`/`getfiled` in the original LISP all become fields on a `Models/<CommandName>Input.cs` record). A DA Activity has no display and no live console — code that relies on interactive input hangs or fails in the cloud instead of erroring at build time.

## Test pattern (coreconsolerunner)
Commands WRITE (document lock held automatically via `[CommandMethod]`).
NUnit tests only READ from `TestData` statics — no `LockDocument`, no `OpenCloseTransaction`.
Setup command `MyPluginSetupTest` runs before `RunCADtests` in the generated .scr file.

## Transaction pattern
Use `db.TransactionManager.StartTransaction()` only.
Never use `StartOpenCloseTransaction()` in accoreconsole context.

## Adding integration tests
1. Add value-type properties to `TestData.cs` (Point2d, double, int, bool — no ObjectId refs).
2. Capture them in `TestSetupCommands.SetupTestData()` (command context).
3. Read them in test classes inheriting `DrawingTestBase`.
