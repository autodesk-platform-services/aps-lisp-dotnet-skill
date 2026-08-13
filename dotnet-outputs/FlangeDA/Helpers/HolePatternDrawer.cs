using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Geometry;
using FlangeDA.Models;

namespace FlangeDA.Helpers;

/// <summary>
/// Migrated from Flange.lsp's draw_pattern (flat/circular, FlangeTangentAngleDegrees == 0)
/// and draw_angpattern (angled/elliptical, non-zero) — the two hole-pattern branches
/// reachable from the DCL "pat" selection. Original ARRAY/ROTATE command macros are
/// replaced with direct polar/elliptical math and Entity.TransformBy — see SKILL.md's
/// "Not out of scope, despite first appearances" note; no (command ...) call survives here.
/// </summary>
internal static class HolePatternDrawer
{
    internal static void DrawFlatPattern(Database db, Transaction tr, HolePatternInput input)
    {
        var center = new Point3d(input.CenterX, input.CenterY, 0);
        int num = input.NumberOfHoles;
        double startAngle = input.Offset ? GeometryHelper.DegreesToRadians(180.0 / num) : 0.0;
        double step = 2.0 * Math.PI / num;
        double pcdRadius = input.PatternDiameter / 2.0;
        double holeRadius = input.HoleDiameter / 2.0;

        var space = (BlockTableRecord)tr.GetObject(db.CurrentSpaceId, OpenMode.ForWrite);
        ObjectId centreLayerId = LayerHelper.EnsureCentreLayer(db, tr);

        for (int i = 0; i < num; i++)
        {
            double angle = startAngle + i * step;
            Point3d holeCenter = GeometryHelper.Polar(center, angle, pcdRadius);
            AppendCircle(tr, space, holeCenter, holeRadius, ObjectId.Null);
        }

        AppendCircle(tr, space, center, pcdRadius, centreLayerId);

        for (int i = 0; i < num; i++)
        {
            double angle = startAngle + i * step;
            Point3d holeCenter = GeometryHelper.Polar(center, angle, pcdRadius);
            Point3d p2 = GeometryHelper.Polar(holeCenter, angle + Math.PI, input.HoleDiameter);
            Point3d p3 = GeometryHelper.Polar(p2, angle, input.HoleDiameter * 2.0);
            AppendLine(tr, space, p2, p3, centreLayerId);
        }
    }

    internal static void DrawAngledPattern(Database db, Transaction tr, HolePatternInput input)
    {
        var center = new Point3d(input.CenterX, input.CenterY, 0);
        int num = input.NumberOfHoles;
        double ftangRad = GeometryHelper.DegreesToRadians(input.FlangeTangentAngleDegrees);
        double halfPcd = input.PatternDiameter / 2.0;
        double minusPcd = halfPcd - input.HoleDiameter;
        double plusPcd = halfPcd + input.HoleDiameter;
        double minorHalfPcd = halfPcd * Math.Cos(ftangRad);
        double minorMinusPcd = minusPcd * Math.Cos(ftangRad);
        double minorPlusPcd = plusPcd * Math.Cos(ftangRad);
        double startAngle = input.Offset ? GeometryHelper.DegreesToRadians(180.0 / num) : 0.0;
        double step = 2.0 * Math.PI / num;
        double holeRadius = input.HoleDiameter / 2.0;

        var space = (BlockTableRecord)tr.GetObject(db.CurrentSpaceId, OpenMode.ForWrite);
        ObjectId centreLayerId = LayerHelper.EnsureCentreLayer(db, tr);

        var created = new List<ObjectId>();

        created.Add(AppendTiltedCircle(tr, space, center, halfPcd, input.FlangeTangentAngleDegrees, centreLayerId));

        for (int i = 0; i < num; i++)
        {
            double angle = startAngle + i * step;
            Point3d la = PointOnEllipse(center, minusPcd, minorMinusPcd, angle);
            Point3d lb = PointOnEllipse(center, plusPcd, minorPlusPcd, angle);
            created.Add(AppendLine(tr, space, la, lb, centreLayerId));

            Point3d holeCenter = PointOnEllipse(center, halfPcd, minorHalfPcd, angle);
            created.Add(AppendTiltedCircle(tr, space, holeCenter, holeRadius, input.FlangeTangentAngleDegrees, ObjectId.Null));
        }

        if (input.RotationAngleDegrees != 0.0)
        {
            var rotation = Matrix3d.Rotation(GeometryHelper.DegreesToRadians(input.RotationAngleDegrees), Vector3d.ZAxis, center);
            foreach (ObjectId id in created)
            {
                var entity = (Entity)tr.GetObject(id, OpenMode.ForWrite);
                entity.TransformBy(rotation);
            }
        }
    }

    /// <summary>Parametric point on an axis-aligned ellipse centred at <paramref name="center"/> — mirrors the repeated (+ yvalue (* (sin ra) trig...)) construct in draw_anglefront/draw_angpattern.</summary>
    private static Point3d PointOnEllipse(Point3d center, double majorRadius, double minorRadius, double angleRadians) =>
        new(center.X + majorRadius * Math.Cos(angleRadians), center.Y + minorRadius * Math.Sin(angleRadians), center.Z);

    private static ObjectId AppendCircle(Transaction tr, BlockTableRecord space, Point3d center, double radius, ObjectId layerId)
    {
        var circle = new Circle(center, Vector3d.ZAxis, radius);
        if (!layerId.IsNull) circle.LayerId = layerId;
        ObjectId id = space.AppendEntity(circle);
        tr.AddNewlyCreatedDBObject(circle, true);
        return id;
    }

    /// <summary>A circle of the given radius foreshortened by tiltDegrees — mirrors the repeated 3-point "ellipse" command calls whose third point is always offset by radius * sin(90 - ftang).</summary>
    private static ObjectId AppendTiltedCircle(Transaction tr, BlockTableRecord space, Point3d center, double radius, double tiltDegrees, ObjectId layerId)
    {
        double ratio = Math.Sin(GeometryHelper.DegreesToRadians(90.0 - tiltDegrees));
        var ellipse = new Ellipse(center, Vector3d.ZAxis, new Vector3d(radius, 0, 0), ratio, 0.0, 2.0 * Math.PI);
        if (!layerId.IsNull) ellipse.LayerId = layerId;
        ObjectId id = space.AppendEntity(ellipse);
        tr.AddNewlyCreatedDBObject(ellipse, true);
        return id;
    }

    private static ObjectId AppendLine(Transaction tr, BlockTableRecord space, Point3d p1, Point3d p2, ObjectId layerId)
    {
        var line = new Line(p1, p2);
        if (!layerId.IsNull) line.LayerId = layerId;
        ObjectId id = space.AppendEntity(line);
        tr.AddNewlyCreatedDBObject(line, true);
        return id;
    }
}
