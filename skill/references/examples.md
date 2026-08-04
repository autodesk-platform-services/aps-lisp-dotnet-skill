# Migration Examples

Worked LISP → C# examples referenced from `SKILL.md` Step 3. Load this file when generating code for a pattern that matches one of these shapes.

### Example 1: ssget + sslength + ssname loop

**LISP:**
```lisp
(setq ss (ssget "_X" '((0 . "HATCH"))))
(repeat (sslength ss)
  (setq ent (ssname ss i))
  ...
  (setq i (1+ i))
)
```

**C#:**
```csharp
using (var tr = db.TransactionManager.StartTransaction())
{
    var bt = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);
    var btr = (BlockTableRecord)tr.GetObject(bt[BlockTableRecord.ModelSpace], OpenMode.ForRead);
    foreach (ObjectId id in btr)
    {
        var entity = tr.GetObject(id, OpenMode.ForRead) as Hatch;
        if (entity == null) continue;
        // ... process hatch
    }
    tr.Commit();
}
```

### Example 2: entget + assoc DXF extraction

**LISP:**
```lisp
(setq entdata (entget ent))
(setq handle (cdr (assoc 5 entdata)))
(setq numLoops (cdr (assoc 91 entdata)))
```

**C#:**
```csharp
var hatch = (Hatch)tr.GetObject(id, OpenMode.ForRead);
string handle = hatch.Handle.ToString();
int numLoops = hatch.NumberOfLoops;
```

### Example 3: GetLoopAt boundary extraction

**LISP:**
```lisp
(vlax-invoke-method hatch-obj 'GetLoopAt 0 'loopObjs)
```

**C#:**
```csharp
// GetLoopAt returns a HatchLoop struct, not an out-param overload — confirmed via
// reflection against AcDbMgd.dll 26.0.0 (the out-param shape doesn't compile: CS1501).
HatchLoop loop = hatch.GetLoopAt(0);
foreach (Curve2d curve in loop.Curves)
{
    var interval = curve.GetInterval();
    double length = curve.GetLength(interval.LowerBound, interval.UpperBound);
    // process curve
}
```
This also replaces the older "hatchgenerateboundary + erase temp entity" LISP pattern some
migrations use to get boundary geometry — `GetLoopAt` reads the same loop directly, no
temporary boundary entity ever needs to be created.

### Example 4: File output → JSON

**LISP:**
```lisp
(setq json-file (open filename "w"))
(write-line "[" json-file)
(write-line (strcat "  {\"handle\": \"" handle "\"}") json-file)
(write-line "]" json-file)
(close json-file)
```

**C#:**
```csharp
var records = hatches.Select(h => new { handle = h.Handle.ToString(), vertices = ExtractVertices(h) });
File.WriteAllText(outputPath, JsonSerializer.Serialize(records, new JsonSerializerOptions { WriteIndented = true }));
```

### Example 5: Region perimeter via Brep (no typed Region.Perimeter exists)

**LISP:**
```lisp
(vla-get-Perimeter region-obj)
```

**C#:**
```csharp
// Region has no typed Perimeter property. Sum the arc length of every Brep edge instead.
private static double GetRegionPerimeter(Region region)
{
    double total = 0;
    using var brep = new Brep(region);
    foreach (Edge edge in brep.Edges)   // Autodesk.AutoCAD.BoundaryRepresentation.Edge, not "BrepEdge"
    {
        Curve3d curve = edge.Curve;
        var interval = curve.GetInterval();
        total += curve.GetLength(interval.LowerBound, interval.UpperBound, Tolerance.Global.EqualPoint);
    }
    return total;
}
```
Needs `using Autodesk.AutoCAD.BoundaryRepresentation;` and `using Autodesk.AutoCAD.Geometry;`.
Confirmed via reflection against `acdbmgdbrep.dll` 26.0.0 during the AcresDA migration — the
enumerated type is `Edge`, and its curve is exposed via the `.Curve` property (`Curve3d`), not
a `GetCurve()` method.

## Verbose / Quiet Mode Pattern

**LISP:**
```lisp
(setq *HATCH_EXPORT_VERBOSE* nil)
(defun dbg-print (msg)
  (if *HATCH_EXPORT_VERBOSE* (princ msg))
)
```

**C#:**
```csharp
private bool _verbose = false;
private void DbgPrint(string msg)
{
    if (_verbose) _ed.WriteMessage(msg);
}
```
