using MyPlugin.IntegrationTests.Infrastructure;
using NUnit.Framework;

namespace MyPlugin.IntegrationTests;

// TODO: Replace with migration-specific integration tests.
// Tests only READ from TestData — no database writes from test threads.
[TestFixture]
public class PlaceholderIntegrationTests : DrawingTestBase
{
    [OneTimeSetUp]
    public void CheckSetup() =>
        Assert.That(TestData.Initialized, Is.True,
            "MyPluginSetupTest command did not run — check the generated .scr file.");

    [Test]
    public void TestData_IsInitialized() =>
        Assert.That(TestData.Initialized, Is.True);
}
