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
- `AutoCAD.NET` — main plugin (desktop interactive, includes AcMgd.dll).
- `AutoCAD.NET.Core` — integration tests only (AcCoreMgd.dll, headless-safe).
- Never reference `AcMgd.dll` in test projects — crashes accoreconsole with 0xC0000005.

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
