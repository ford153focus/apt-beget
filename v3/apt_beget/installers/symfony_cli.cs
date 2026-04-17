using System.IO;
using apt_beget;

namespace apt_beget.installers;

class symfony_cli
{
    public static async Task install(string? path = null)
    {
        string path2setup = Path.Combine(Path.GetTempPath(), "symfony-cli-setup.sh");

        await Helpers.DownloadFileAsync(
            "https://get.symfony.com/cli/installer",
            path2setup
        );

        Helpers.Exec($"bash {path2setup}");

        File.Move(
            Path.Join(Helpers.homePath, ".symfony5", "bin", "symfony"),
            Path.Join(Helpers.localBinPath, "symfony")
        );

        Helpers.Chmod(Path.Join(Helpers.localBinPath, "symfony"), "700");

        File.Delete(path2setup);
        Directory.Delete(Path.Join(Helpers.homePath, ".symfony5", "bin"), true);
    }

    public static async Task uninstall(string? path = null)
    {
        throw new NotImplementedException();
    }
}