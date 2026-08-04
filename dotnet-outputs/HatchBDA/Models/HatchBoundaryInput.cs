namespace HatchBDA.Models;

/// <summary>
/// Design Automation parameter record for the HB / HBL / HATCHB commands.
///
/// Replaces the original LISP's interactive hatch selection:
///   (if (/= (setq ss2 (ssget '((0 . "HATCH")))) nil) ...)
/// which prompted the desktop user to pick hatches on screen. A DA Activity
/// has no display and no live console, so there is nothing to pick — the
/// caller must say up front which hatches to process, via params.json.
/// </summary>
public record HatchBoundaryInput
{
    /// <summary>
    /// When true (the default), every HATCH entity found in the drawing's
    /// layouts is processed — the DA equivalent of "just pick them all"
    /// rather than a filtered pick. This is the recommended default for a
    /// batch/headless WorkItem.
    /// </summary>
    public bool ProcessAllHatches { get; init; } = true;

    /// <summary>
    /// Optional explicit selection. Only consulted when <see cref="ProcessAllHatches"/>
    /// is false. Each entry is an AutoCAD entity Handle, e.g. the hex string produced by
    /// <c>Entity.Handle.ToString()</c> (matches what a params.json authored by an upstream
    /// step — e.g. a prior "find the hatches I care about" activity — would supply).
    /// </summary>
    public IReadOnlyList<string>? HatchHandles { get; init; }
}
