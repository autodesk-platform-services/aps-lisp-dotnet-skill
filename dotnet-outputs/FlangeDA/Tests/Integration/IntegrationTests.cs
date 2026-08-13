using FlangeDA.IntegrationTests.Infrastructure;
using NUnit.Framework;

namespace FlangeDA.IntegrationTests;

[TestFixture]
public class HolePatternIntegrationTests : DrawingTestBase
{
    [OneTimeSetUp]
    public void CheckSetup() =>
        Assert.That(TestData.Initialized, Is.True,
            "FlangeDASetupTest command did not run — check the generated .scr file.");

    [Test]
    public void FlatPattern_CreatesOneCirclePerHolePlusPcdCircle() =>
        Assert.That(TestData.FlatCircleCount, Is.EqualTo(6 + 1));

    [Test]
    public void FlatPattern_CreatesOneCentrelinePerHole() =>
        Assert.That(TestData.FlatLineCount, Is.EqualTo(6));

    [Test]
    public void AngledPattern_CreatesOneEllipsePerHolePlusPcdEllipse() =>
        Assert.That(TestData.AngledEllipseCount, Is.EqualTo(6 + 1));

    [Test]
    public void AngledPattern_CreatesOneCentrelinePerHole() =>
        Assert.That(TestData.AngledLineCount, Is.EqualTo(6));
}
