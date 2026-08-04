using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Geometry;
using HatchBDA.Models;

namespace HatchBDA.Helpers;

/// <summary>
/// Recreates the boundary geometry of a HATCH entity as ordinary drawing entities
/// (Line / Arc / Circle / Ellipse / Polyline) on the hatch's own layout.
///
/// Ported from (defun hatchb (hl ...) ...) in HATCHB.lsp. The original walked raw DXF
/// group codes (91/92/93/72/73/75/10/11/40/42/50/51/94/95/96) via entget + assoc/member
/// to reconstruct each boundary loop by hand. Per the skill's "never use DXF group codes
/// when a typed API exists" rule, that whole manual walk is replaced here by the typed
/// Hatch.NumberOfLoops / Hatch.GetLoopAt(int) API, which returns a HatchLoop already
/// broken into Curve2d edges (or a BulgeVertexCollection for polyline-type loops) —
/// eliminating ~15 individual DXF group-code reads.
/// </summary>
public static class HatchBoundaryHelper
{
    /// <summary>
    /// Outcome of recreating a single hatch's boundary.
    /// </summary>
    /// <param name="LastCreated">
    /// The last entity created — mirrors the original's use of (entlast) immediately
    /// after the loops-processing repeat, which is what areaOfObject was called on.
    /// </param>
    /// <param name="HasMultipleLoopsOrUnsupportedEdge">
    /// True when the hatch had more than one loop (islands — see HatchBoundaryResult) or
    /// contained an edge type this migration can't faithfully recreate (spline). Mirrors
    /// (setq bMoreLoops T) / (setq noarea T) in the original.
    /// </param>
    public readonly record struct LoopBoundaryOutcome(Entity? LastCreated, bool HasMultipleLoopsOrUnsupportedEdge);

    /// <summary>
    /// (if (/= (setq ss2 (ssget '((0 . "HATCH")))) nil) ...)
    /// Resolves which HATCH entities to process from the DA parameter record instead of
    /// an interactive pick. "Process all" walks every layout's BlockTableRecord (Model
    /// space plus every paper space layout) rather than just "the current space" the
    /// original ssget implicitly scoped to — a deliberate broadening, since a headless
    /// batch WorkItem has no single "current layout" in the interactive sense, and
    /// skipping non-active layouts would silently under-process the drawing.
    /// Block *definitions* (non-layout BlockTableRecords) are intentionally excluded so
    /// a hatch used inside a block isn't recreated once per insertion.
    /// </summary>
    public static IEnumerable<ObjectId> ResolveHatchIds(Transaction tr, Database db, HatchBoundaryInput input)
    {
        var hatchClass = Autodesk.AutoCAD.Runtime.RXObject.GetClass(typeof(Hatch));

        if (input.ProcessAllHatches || input.HatchHandles is null || input.HatchHandles.Count == 0)
        {
            var bt = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);
            foreach (ObjectId btrId in bt)
            {
                var btr = (BlockTableRecord)tr.GetObject(btrId, OpenMode.ForRead);
                if (!btr.IsLayout) continue;

                foreach (ObjectId id in btr)
                {
                    if (id.ObjectClass == hatchClass)
                        yield return id;
                }
            }
        }
        else
        {
            foreach (var handleText in input.HatchHandles)
            {
                var handle = new Handle(Convert.ToInt64(handleText, 16));
                var id = db.GetObjectId(false, handle, 0);
                if (!id.IsNull && id.ObjectClass == hatchClass)
                    yield return id;
            }
        }
    }

    /// <summary>
    /// (defun areaOfObject (en / curve area) ... (vl-catch-all-apply 'vlax-curve-getArea (list curve)))
    /// vl-catch-all-apply swallowed any COM error from vlax-curve-getArea (e.g. an open,
    /// non-planar, or degenerate curve) and returned nil. Curve.Area is the direct typed
    /// equivalent of vlax-curve-getArea — it throws Autodesk.AutoCAD.Runtime.Exception in
    /// the same situations, so try/catch is the direct, typed replacement per the skill's
    /// vl-catch-all-apply → try/catch rule.
    /// </summary>
    public static double SafeGetArea(Curve curve)
    {
        try
        {
            return curve.Area;
        }
        catch (Autodesk.AutoCAD.Runtime.Exception)
        {
            return 0.0;
        }
    }

    /// <summary>
    /// (repeat loops1 ... ) — recreates every boundary loop of one hatch.
    /// </summary>
    public static LoopBoundaryOutcome RecreateBoundary(
        Transaction tr,
        BlockTableRecord space,
        Hatch hatch,
        bool copyHatchLayer)
    {
        // (trans pt ent 0): the points/curves returned by HatchLoop are expressed in the
        // hatch's own OCS/plane (Hatch.Normal + Hatch.Elevation), same as the raw group-10/11
        // points the original read via entget. Transform back to WCS the same way the
        // original's per-point (trans ... ent 0) calls did (added 2008-02-29 to support
        // "hatches in non WCS" — see HATCHB.lsp's version history at the top of the file).
        var planeToWorld = Matrix3d.PlaneToWorld(hatch.Normal);
        var elevation = hatch.Elevation;

        Point3d To3d(Point2d p) => new Point3d(p.X, p.Y, elevation).TransformBy(planeToWorld);
        Vector3d ToVector3d(Vector2d v) => new Vector3d(v.X, v.Y, 0.0).TransformBy(planeToWorld);

        Entity? lastCreated = null;
        bool unsupportedEdge = false;
        int loopCount = hatch.NumberOfLoops;

        for (int i = 0; i < loopCount; i++)
        {
            var loop = hatch.GetLoopAt(i);
            lastCreated = null;

            if (loop.IsPolyline)
            {
                lastCreated = CreatePolylineLoop(tr, space, loop, To3d, hatch, copyHatchLayer);
            }
            else
            {
                // (repeat noe ... (cond ((= et 1) line) ((= et 2) arc) ((= et 3) ellipse) ((= et 4) spline)))
                // The individual Line/Arc/Circle/Ellipse edges below are each appended to
                // `space` as their own entity — exactly what vla-AddLine/AddCircle/AddArc/
                // AddEllipse did. The original then re-joined that chain of separate edges
                // back into one polyline via:
                //   (if (= (getvar "peditaccept") 1)
                //     (command "_.pedit" (entlast) "_J" ss "" "")
                //     (command "_.pedit" (entlast) "_Y" "_J" ss "" ""))
                // TODO v2: PEDIT-join is a (command ...) macro sequence — out of scope for
                // v1 per SKILL.md ("(command ...) macro sequences" is explicitly out of
                // scope). Recreating it would mean building a Polyline from the resulting
                // Curve3d segments (JoinEntities/Polyline.JoinEntity is the typed analogue)
                // instead of shelling out to the PEDIT command. Left unmigrated: the boundary
                // is recreated as separate Line/Arc/Ellipse entities rather than one joined
                // LWPOLYLINE.
                foreach (Curve2d curve2d in loop.Curves)
                {
                    var created = CreateEdge(tr, space, curve2d, To3d, ToVector3d, hatch, copyHatchLayer);
                    if (created is null)
                    {
                        unsupportedEdge = true;
                        continue;
                    }
                    lastCreated = created;
                }
            }
        }

        return new LoopBoundaryOutcome(lastCreated, IsAreaUnreliable(loopCount, unsupportedEdge));
    }

    /// <summary>
    /// (if (and (= noarea nil) (= loops1 1)) (setq area (+ area (areaOfObject (entlast))))
    ///     (setq bMoreLoops T))
    /// True when this hatch's area can't be trusted in the running total: more than one loop
    /// (islands — no way to know which loops to add vs. subtract, per the original's own
    /// comment) or an edge this migration couldn't recreate (e.g. a spline). Pulled out as a
    /// pure int/bool function so it's unit-testable at Tier 1 without an AutoCAD host.
    /// </summary>
    public static bool IsAreaUnreliable(int loopCount, bool hasUnsupportedEdge) =>
        loopCount != 1 || hasUnsupportedEdge;

    /// <summary>
    /// Polyline-type loop (bptf boole-1-2 flag set in the original):
    ///   (setq obj (vla-addLightweightPolyline space VLADataPts))
    ///   (vla-setBulge obj nr (nth nr blist))
    ///   (if (= ic 1) (vla-put-closed obj T))
    /// → typed Polyline built directly from the loop's BulgeVertexCollection, which already
    /// carries per-vertex bulge (replacing the manual vlax-make-safearray / vla-setBulge dance).
    ///
    /// Matches the original's 3dPoint->2dPoint(trans pt ent 0) behavior of flattening each
    /// vertex to WCS X/Y only (Z dropped) — a Lightweight Polyline is inherently planar, so
    /// the recreated boundary is placed in the default (world) plane exactly as the original's
    /// vla-addLightweightPolyline call did, not tilted to the hatch's own OCS.
    /// </summary>
    private static Polyline CreatePolylineLoop(
        Transaction tr,
        BlockTableRecord space,
        HatchLoop loop,
        Func<Point2d, Point3d> to3d,
        Hatch hatch,
        bool copyHatchLayer)
    {
        var pline = new Polyline();
        int index = 0;
        foreach (BulgeVertex bv in loop.Polyline)
        {
            var wcs = to3d(bv.Vertex);
            pline.AddVertexAt(index++, new Point2d(wcs.X, wcs.Y), bv.Bulge, 0.0, 0.0);
        }

        // A hatch boundary loop is by definition a closed region, so the recreated
        // polyline is always closed — the typed HatchLoop API doesn't expose the original's
        // literal group-73 "ic" flag separately from IsPolyline, but every polyline-type
        // hatch loop this skill has seen is a closed ring.
        pline.Closed = true;

        AppendAndTagLayer(tr, space, pline, hatch, copyHatchLayer);
        return pline;
    }

    /// <summary>
    /// Non-polyline edge dispatch — one Curve2d per boundary edge, mirroring the original's
    /// (cond ((= et 1) ...) ((= et 2) ...) ((= et 3) ...) ((= et 4) ...)) on DXF group 72.
    /// Returns null for an edge type this migration can't faithfully recreate (spline),
    /// matching the original's own "\nElliptic arc not supported!" style graceful skip.
    /// </summary>
    private static Entity? CreateEdge(
        Transaction tr,
        BlockTableRecord space,
        Curve2d curve2d,
        Func<Point2d, Point3d> to3d,
        Func<Vector2d, Vector3d> toVector3d,
        Hatch hatch,
        bool copyHatchLayer)
    {
        Entity entity;
        switch (curve2d)
        {
            case LineSegment2d line:
                // (setq obj (vla-AddLine space (vlax-3d-point (trans (cdr (assoc 10 ed1)) ent 0))
                //                              (vlax-3d-point (trans (cdr (assoc 11 ed1)) ent 0))))
                entity = new Line(to3d(line.StartPoint), to3d(line.EndPoint));
                break;

            case CircularArc2d arc when IsFullCircle(arc):
                // (if (and (equal ang1 0 0.00001) (equal ang2 6.28319 0.00001))
                //   (setq obj (vla-AddCircle space (vlax-3d-point (trans (cdr (assoc 10 ed1)) ent 0))
                //                                   (cdr (assoc 40 ed1)))) ...)
                entity = new Circle(to3d(arc.Center), hatch.Normal, arc.Radius);
                break;

            case CircularArc2d arc:
                // (setq obj (vla-AddArc space (vlax-3d-point (trans (cdr (assoc 10 ed1)) ent 0))
                //                             (cdr (assoc 40 ed1)) ang1/ang2 (cw-adjusted)))
                entity = new Arc(to3d(arc.Center), hatch.Normal, arc.Radius, arc.StartAngle, arc.EndAngle);
                break;

            case EllipticalArc2d ellipse:
                // (setq obj (vla-AddEllipse space (vlax-3d-point (trans (cdr (assoc 10 ed1)) ent 0))
                //                                  (vlax-3d-point (trans (cdr (assoc 11 ed1)) ent 0))
                //                                  (cdr (assoc 40 ed1))))
                // (vla-put-startangle obj ...) (vla-put-endangle obj ...)
                entity = new Ellipse(
                    to3d(ellipse.Center),
                    hatch.Normal,
                    toVector3d(ellipse.MajorAxis),
                    ellipse.MinorRadius / ellipse.MajorRadius,
                    ellipse.StartAngle,
                    ellipse.EndAngle);
                break;

            case NurbCurve2d:
                // ((= et 4) ; spline) in the original builds a raw SPLINE DXF entity from
                // manually-walked knot/control-point group codes (94/95/96/40/10) and is only
                // reliable for *closed* splines — the file's own header calls this a "Known
                // problem with some elipses and splines". The .NET Spline type doesn't expose
                // a public constructor that takes an explicit degree/knot-vector/control-point
                // NURBS definition (only fit-point or fit-tolerance overloads, which would
                // approximate rather than exactly reproduce the boundary).
                // TODO: verify — spline boundary edge left unrecreated rather than guessing an
                // approximate reconstruction. Flag for a design follow-up if HATCHB is migrated
                // for drawings with spline-bounded hatches.
                return null;

            default:
                // TODO: verify — unrecognized Curve2d subtype in hatch boundary loop.
                return null;
        }

        AppendAndTagLayer(tr, space, entity, hatch, copyHatchLayer);
        return entity;
    }

    private static void AppendAndTagLayer(Transaction tr, BlockTableRecord space, Entity entity, Hatch hatch, bool copyHatchLayer)
    {
        space.AppendEntity(entity);
        tr.AddNewlyCreatedDBObject(entity, true);

        // hl parameter (HB = nil, HBL = T): (if hl (vla-put-layer obj layer)) — HBL copies the
        // hatch's own layer onto the recreated boundary; HB leaves it on the current layer.
        if (copyHatchLayer)
            entity.Layer = hatch.Layer;
    }

    private static bool IsFullCircle(CircularArc2d arc) => IsFullSweep(arc.StartAngle, arc.EndAngle);

    /// <summary>
    /// (equal ang1 0 0.00001) (equal ang2 6.28319 0.00001) — same tolerance-based full-sweep
    /// check as the original, just against the typed CircularArc2d angles instead of raw
    /// DXF group 50/51 values. Pulled out as a pure double-only function (no AutoCAD types)
    /// so it can be unit-tested at Tier 1 without an AutoCAD host — see
    /// Tests/HatchBDA.Tests/HatchBoundaryHelperTests.cs.
    /// </summary>
    public static bool IsFullSweep(double startAngle, double endAngle) =>
        Math.Abs(startAngle) < 1e-4 && Math.Abs(endAngle - (2 * Math.PI)) < 1e-4;
}
