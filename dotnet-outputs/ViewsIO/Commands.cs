using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.EditorInput;
using Autodesk.AutoCAD.Runtime;

namespace ViewsIO;

public class Commands
{
    // c:ExportViews — prompts for output path, exports all named views to JSON.
    [CommandMethod("EXPORTVIEWS")]
    public void ExportViews()
    {
        var (doc, db, ed) = Current();
        var path = PromptFilePath(ed, db, "Export views to", save: true);
        if (path is null) return;

        Run(db, ed, tr => ViewTableHelper.ExportViews(path, db, tr));
        ed.WriteMessage($"\nViews exported to: {path}\n");
    }

    // c:ImportViews — prompts for input path, imports named views from JSON.
    [CommandMethod("IMPORTVIEWS")]
    public void ImportViews()
    {
        var (doc, db, ed) = Current();
        var path = PromptFilePath(ed, db, "Import views from", save: false);
        if (path is null) return;
        if (!File.Exists(path)) { ed.WriteMessage($"\nFile not found: {path}\n"); return; }

        Run(db, ed, tr => ViewTableHelper.ImportViews(path, db, tr));
        ed.WriteMessage($"\nViews imported from: {path}\n");
    }

    // c:-ExportViews — silent command-line version (no dialog, for scripting/DA).
    [CommandMethod("-EXPORTVIEWS")]
    public void ExportViewsSilent()
    {
        var (doc, db, ed) = Current();
        var path = PromptString(ed, db, "Enter export filename");
        if (path is null) return;

        Run(db, ed, tr => ViewTableHelper.ExportViews(path, db, tr));
    }

    // c:-ImportViews — silent command-line version.
    [CommandMethod("-IMPORTVIEWS")]
    public void ImportViewsSilent()
    {
        var (doc, db, ed) = Current();
        var path = PromptString(ed, db, "Enter import filename");
        if (path is null) return;
        if (!File.Exists(path)) { ed.WriteMessage($"\nFile not found: {path}\n"); return; }

        Run(db, ed, tr => ViewTableHelper.ImportViews(path, db, tr));
    }

    // --- helpers ---

    private static (Document doc, Database db, Editor ed) Current()
    {
        var doc = Application.DocumentManager.MdiActiveDocument;
        return (doc, doc.Database, doc.Editor);
    }

    private static string? PromptFilePath(Editor ed, Database db, string prompt, bool save)
    {
        var defaultPath = Path.ChangeExtension(db.Filename, ".json");
        var opts = new PromptStringOptions($"\n{prompt} [{defaultPath}]: ") { AllowSpaces = true };
        var res  = ed.GetString(opts);
        if (res.Status != PromptStatus.OK) return null;
        return string.IsNullOrWhiteSpace(res.StringResult) ? defaultPath : res.StringResult;
    }

    private static string? PromptString(Editor ed, Database db, string prompt)
    {
        var defaultPath = Path.ChangeExtension(db.Filename, ".json");
        var opts = new PromptStringOptions($"\n{prompt} [{defaultPath}]: ") { AllowSpaces = true };
        var res  = ed.GetString(opts);
        if (res.Status != PromptStatus.OK) return null;
        return string.IsNullOrWhiteSpace(res.StringResult) ? defaultPath : res.StringResult;
    }

    private static void Run(Database db, Editor ed, Action<Transaction> body)
    {
        using var tr = db.TransactionManager.StartTransaction();
        try   { body(tr); tr.Commit(); }
        catch (System.Exception ex) { ed.WriteMessage($"\nError: {ex.Message}\n"); tr.Abort(); }
    }
}
