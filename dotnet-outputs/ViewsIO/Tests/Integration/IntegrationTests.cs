using ViewsIO.IntegrationTests.Infrastructure;
using NUnit.Framework;

namespace ViewsIO.IntegrationTests;

[TestFixture]
public class ViewsIOIntegrationTests : DrawingTestBase
{
    [OneTimeSetUp]
    public void CheckSetup() =>
        Assert.That(TestData.Initialized, Is.True,
            "ViewsIOSetupTest command did not run — check the generated .scr file.");

    [Test]
    public void ExportFile_IsCreated() =>
        Assert.That(TestData.ExportFileExists, Is.True);

    [Test]
    public void ExportedViewCount_MatchesInitialViewCount() =>
        Assert.That(TestData.ExportedViewCount, Is.EqualTo(TestData.InitialViewCount));

    [Test]
    public void ImportWithExistingViews_DoesNotDuplicateThem() =>
        Assert.That(TestData.ViewCountAfterImport, Is.EqualTo(TestData.InitialViewCount));
}
