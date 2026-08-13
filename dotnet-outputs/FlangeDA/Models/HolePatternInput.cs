namespace FlangeDA.Models;

/// <summary>
/// Parameters for the user-defined hole-pattern branch of the original Flange.lsp
/// (select = "pat" in the LISP dialog). Every value below was originally gathered
/// interactively (DCL dialog tiles or getpoint) — see SKILL.md's Design Automation
/// Guardrail. There is no live dialog or command-line prompt in Design Automation,
/// so all of it now arrives as one params.json.
/// </summary>
public sealed record HolePatternInput
{
    /// <summary>Draw the first hole offset by half the angular spacing instead of at angle 0. Mirrors the "offset" dialog tile ("1" = offset, "0" = on-centre).</summary>
    public bool Offset { get; init; } = true;

    /// <summary>Flange tilt angle in degrees. 0 draws the flat pattern (circles); non-zero draws the angled/tilted pattern (ellipses). Mirrors the "ftang" dialog tile.</summary>
    public double FlangeTangentAngleDegrees { get; init; } = 0.0;

    /// <summary>Pitch circle diameter the holes sit on. Mirrors the "ddpcd" input_pattern dialog tile.</summary>
    public double PatternDiameter { get; init; }

    /// <summary>Number of holes in the pattern. Mirrors the "num" input_pattern dialog tile.</summary>
    public int NumberOfHoles { get; init; }

    /// <summary>Diameter of each hole. Mirrors the "holedia" input_pattern dialog tile.</summary>
    public double HoleDiameter { get; init; }

    /// <summary>X of the pattern centre point. Mirrors the original interactive "Pick centre of pcd." getpoint.</summary>
    public double CenterX { get; init; }

    /// <summary>Y of the pattern centre point. Mirrors the original interactive "Pick centre of pcd." getpoint.</summary>
    public double CenterY { get; init; }

    /// <summary>Rotation applied to the finished pattern about the centre point, in degrees. Replaces the original angled-branch "ROTATE (catch) pick_pcd pause" — pause is live drag input with no DA equivalent, so a fixed angle takes its place. 0 = no rotation.</summary>
    public double RotationAngleDegrees { get; init; } = 0.0;
}
