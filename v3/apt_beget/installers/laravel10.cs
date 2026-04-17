using System.IO;
using apt_beget;

namespace apt_beget.installers;

class laravel10
{
    public static async Task install(string? path = null)
    {
        Helpers.set_php_cli_version("8.4");

        await composer.install();
        await symfony_cli.install();

        Helpers.Exec($"composer create-project laravel/laravel {path ?? "."}");

        File.CreateSymbolicLink("public_html", "public");
    }

    public static async Task uninstall(string? path = null)
    {
        throw new NotImplementedException();
    }
}