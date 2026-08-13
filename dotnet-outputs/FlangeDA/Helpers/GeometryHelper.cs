using Autodesk.AutoCAD.Geometry;

namespace FlangeDA.Helpers;

/// <summary>Mirrors Flange.lsp's (Degrees->Radians numberOfDegrees) and (polar pt angle dist) helpers.</summary>
internal static class GeometryHelper
{
    internal static double DegreesToRadians(double numberOfDegrees) => numberOfDegrees * Math.PI / 180.0;

    internal static Point3d Polar(Point3d point, double angleRadians, double distance) =>
        new(point.X + distance * Math.Cos(angleRadians), point.Y + distance * Math.Sin(angleRadians), point.Z);
}
