using FlangeDA.Models;

namespace FlangeDA.Helpers;

/// <summary>
/// Mirrors Flange.lsp's (info) function: validates the hole-pattern dialog inputs
/// before drawing. The original had a real bug — several branches wrapped
/// (alert ...) and (exit) in a stray extra set of parens (e.g. "((alert \"x\") (exit))"),
/// which calls the alert's return value as a function instead of sequencing the two
/// calls. That's an authoring mistake, not intended behavior (see SKILL.md's Known
/// Edge Cases), so it is not reproduced here — missing/invalid required fields throw
/// a clear exception instead.
/// </summary>
internal static class PatternValidator
{
    internal static IReadOnlyList<string> Validate(HolePatternInput input)
    {
        if (input.PatternDiameter <= 0)
        {
            throw new ArgumentException("No pcd given (PatternDiameter must be > 0).");
        }
        if (input.NumberOfHoles <= 0)
        {
            throw new ArgumentException("No. of holes not given (NumberOfHoles must be > 0).");
        }
        if (input.HoleDiameter <= 0)
        {
            throw new ArgumentException("No hole dia given (HoleDiameter must be > 0).");
        }

        var warnings = new List<string>();
        if (input.NumberOfHoles * input.HoleDiameter >= input.PatternDiameter * Math.PI)
        {
            warnings.Add("Too many holes??");
        }
        return warnings;
    }
}
