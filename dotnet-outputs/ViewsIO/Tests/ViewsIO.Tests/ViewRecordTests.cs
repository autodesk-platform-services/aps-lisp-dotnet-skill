using System.Text.Json;
using Xunit;

namespace ViewsIO.Tests;

// Pure logic — no AutoCAD runtime needed.
public class ViewRecordTests
{
    [Fact]
    public void ViewRecord_RoundTrips_JsonSerialization()
    {
        var record = new ViewRecord
        {
            Name = "TestView", TargetX = 1.0, TargetY = 2.0, TargetZ = 0.0,
            ViewDirX = 0.0, ViewDirY = 0.0, ViewDirZ = 1.0,
            Height = 10.0, Width = 8.0, TwistAngle = 0.0, VisualStyleName = "Conceptual"
        };
        var json   = JsonSerializer.Serialize(record);
        var result = JsonSerializer.Deserialize<ViewRecord>(json);
        Assert.Equal(record, result);
    }

    [Fact]
    public void ViewRecord_NullVisualStyleName_Serializes()
    {
        var record = new ViewRecord { Name = "NoStyle", VisualStyleName = null };
        var json   = JsonSerializer.Serialize(record);
        var result = JsonSerializer.Deserialize<ViewRecord>(json);
        Assert.Null(result?.VisualStyleName);
    }

    [Theory]
    [InlineData("ViewA")]
    [InlineData("My Custom View 1")]
    [InlineData("*Active")]
    public void ViewRecord_PreservesName(string name)
    {
        var record = new ViewRecord { Name = name };
        var json   = JsonSerializer.Serialize(record);
        var result = JsonSerializer.Deserialize<ViewRecord>(json);
        Assert.Equal(name, result?.Name);
    }
}
