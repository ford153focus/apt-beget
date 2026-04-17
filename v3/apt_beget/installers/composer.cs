using System.IO;
using apt_beget;

namespace apt_beget.installers;

class composer
{
    public static async Task install(string? path = null)
    {
        string path2setup = Path.Combine(Path.GetTempPath(), "composer-setup.php");

        await Helpers.DownloadFileAsync(
            "https://getcomposer.org/installer",
            path2setup
        );

        Helpers.Exec($"php {path2setup} --install-dir={Helpers.localBinPath} --filename=composer");
        Helpers.Chmod(Path.Join(Helpers.localBinPath, "composer"), "700");

        File.Delete(path2setup);
    }

    public static async Task uninstall(string? path = null)
    {
        throw new NotImplementedException();
    }
}