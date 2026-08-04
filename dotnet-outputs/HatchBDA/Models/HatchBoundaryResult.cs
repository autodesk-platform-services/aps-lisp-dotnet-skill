namespace HatchBDA.Models;

/// <summary>
/// Summary of one HB/HBL/HATCHB run, logged to the Editor/console and available for
/// integration-test assertions in place of the original's plain-text
/// (princ "\nTotal Area = ") (princ area) output.
/// </summary>
/// <param name="HatchesProcessed">Number of HATCH entities the command recreated boundaries for.</param>
/// <param name="TotalArea">
/// Running total of boundary area, only when <see cref="AreaIsReliable"/> is true — mirrors
/// the original's (if (and area (not bMoreLoops)) ...) gate: a single hatch with islands
/// (more than one loop) makes the running total ambiguous (no way to know which loops to
/// add vs. subtract — see the original's own comment: "Tries to get the area on islands but
/// it's not clear how to know if an island is filled or not"), so the original suppresses the
/// total for the whole run rather than print a possibly-wrong number. Preserved here.
/// </param>
/// <param name="AreaIsReliable">False once any processed hatch had multiple loops or an
/// unsupported edge (e.g. a spline boundary edge) — see <see cref="TotalArea"/>.</param>
public record HatchBoundaryResult(int HatchesProcessed, double? TotalArea, bool AreaIsReliable);
