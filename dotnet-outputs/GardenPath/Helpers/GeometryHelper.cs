using Autodesk.AutoCAD.Geometry;

namespace GardenPath;

public static class GeometryHelper
{
    // (defun Degrees->Radians (numberOfDegrees) (* pi (/ numberOfDegrees 180.0)))
    public static double DegreesToRadians(double degrees) => Math.PI * degrees / 180.0;

    // (defun 3dPoint->2dPoint (3dpt) (list (float (car 3dpt)) (float (cadr 3dpt))))
    public static Point2d Point3dTo2d(Point3d pt) => new(pt.X, pt.Y);

    // (polar basePt angle distance)
    public static Point3d Polar(Point3d basePt, double angle, double distance) =>
        new(basePt.X + distance * Math.Cos(angle),
            basePt.Y + distance * Math.Sin(angle),
            basePt.Z);
}
