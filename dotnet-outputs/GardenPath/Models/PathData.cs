using Autodesk.AutoCAD.Geometry;

namespace GardenPath;

// Maps gp_PathData association list: assoc 10=Start, 11=End, 40=Width, 41=Length, 50=PathAngle
public record PathData(
    Point3d StartPoint,
    Point3d EndPoint,
    double  Width,
    double  Length,
    double  PathAngle
);
