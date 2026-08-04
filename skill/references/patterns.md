# Pattern Mapping Reference

Detailed AutoLISP → C# (.NET) mapping tables, referenced from `SKILL.md` Step 1's Discovery Table. Load this file when the Discovery Table needs a specific mapping not already obvious from context.

### Selection Sets

| AutoLISP | C# (.NET) |
|----------|-----------|
| `(ssget "_X" '((0 . "HATCH")))` | `db.GetModelSpace().Cast<Entity>().OfType<Hatch>()` |
| `(ssget "_X" '((0 . "LINE")))` | `.OfType<Line>()` |
| `(sslength ss)` | `selSet.Count` |
| `(ssname ss i)` | `selSet[i]` |
| `(ssadd ent ss)` | `selSet.Add(entity)` |

### Entity Data (DXF Group Codes)

| AutoLISP | C# (.NET) |
|----------|-----------|
| `(entget ent)` | `tr.GetObject(id, OpenMode.ForRead)` |
| `(assoc 0 entdata)` | `entity.GetType().Name` (or `entity.GetRXClass().DxfName`) |
| `(assoc 5 entdata)` | `entity.Handle.ToString()` |
| `(assoc 8 entdata)` | `entity.Layer` |
| `(assoc 10 entdata)` | depends on entity type (e.g., `line.StartPoint`) |
| `(cdr (assoc 91 entdata))` | `hatch.NumberOfLoops` |
| `(entmod newdata)` | `entity.UpgradeOpen(); entity.Property = value;` |
| `(entdel ent)` | `entity.Erase()` |

### VLA-Object / COM Interop

| AutoLISP | C# (.NET) |
|----------|-----------|
| `(vlax-ename->vla-object ent)` | `tr.GetObject(ent, OpenMode.ForRead)` |
| `(vla-get-Handle obj)` | `entity.Handle` |
| `(vla-get-NumberOfLoops hatch)` | `hatch.NumberOfLoops` |
| `(vlax-invoke-method hatch 'GetLoopAt 0 'loopObjs)` | `hatch.GetLoopAt(0).Curves` — returns a `HatchLoop` struct, **not** an out-param overload; confirmed via reflection against `AcDbMgd.dll` 26.0.0 during the AcresDA migration (`CS1501: No overload for method 'GetLoopAt' takes 3 arguments` when the wrong shape was tried first) |
| `(vlax-safearray->list coords)` | `curves.Cast<Entity>().ToList()` |
| `(vla-get-Coordinates polyline)` | `lwpoly.GetPoint2dAt(i)` |
| `(vla-get-Perimeter region)` | No typed `Region.Perimeter` exists. Sum `Curve3d.GetLength(...)` over every `Autodesk.AutoCAD.BoundaryRepresentation.Brep(region).Edges` instead — see `references/examples.md` Example 5 |

### File I/O

| AutoLISP | C# (.NET) |
|----------|-----------|
| `(open filename "w")` | `File.CreateText(path)` / `StreamWriter` |
| `(write-line str file)` | `writer.WriteLine(str)` |
| `(close file)` | `writer.Dispose()` / `using` block |
| `(getvar "CDATE")` | `DateTime.Now.ToString("yyyyMMdd_HHmmss")` |

### String / Math

| AutoLISP | C# (.NET) |
|----------|-----------|
| `(strcat a b c)` | `string.Concat(a, b, c)` / `$"{a}{b}{c}"` |
| `(itoa n)` | `n.ToString()` |
| `(rtos x 2 8)` | `x.ToString("F8")` |
| `(atof s)` | `double.Parse(s)` |
| `(strlen s)` | `s.Length` |
| `(substr s 1 n)` | `s.Substring(0, n)` |
| `(fix x)` | `(int)x` |
| `(logand a b)` | `a & b` |
| `(1+ n)` | `n + 1` |
| `(vl-remove-if pred list)` | `.Where(x => !pred(x))` |
| `(foreach item list ...)` | `foreach (var item in list)` |
| `(repeat n ...)` | `for (int i = 0; i < n; i++)` |

### Command Registration

| AutoLISP | C# (.NET) |
|----------|-----------|
| `(defun C:MYCOMMAND () ...)` | `[CommandMethod("MYCOMMAND")] public void MyCommand()` |
| `(setq *VERBOSE* nil)` | `private bool _verbose = false;` |
| `(princ msg)` | `ed.WriteMessage(msg)` |
