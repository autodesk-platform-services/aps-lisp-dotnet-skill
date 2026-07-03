namespace ViewsIO;

// Serialization DTO for a named view — doubles instead of Point3d/Vector3d
// so System.Text.Json can round-trip without custom converters.
public record ViewRecord
{
    public string  Name            { get; init; } = "";
    public double  TargetX         { get; init; }
    public double  TargetY         { get; init; }
    public double  TargetZ         { get; init; }
    public double  ViewDirX        { get; init; }
    public double  ViewDirY        { get; init; }
    public double  ViewDirZ        { get; init; }
    public double  Height          { get; init; }
    public double  Width           { get; init; }
    public double  TwistAngle      { get; init; }
    public string? VisualStyleName { get; init; }
}
