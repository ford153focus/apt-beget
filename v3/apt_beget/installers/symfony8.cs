using System.IO;
using apt_beget;

namespace apt_beget.installers;

class symfony8
{
    public static async Task install(string? path = null)
    {
        Helpers.set_php_cli_version("8.4");

        await composer.install();
        await symfony_cli.install();

        Helpers.Exec($"composer create-project symfony/skeleton:'8.0.*' {path ?? "."}");
        Helpers.Exec("composer require webapp");
        Helpers.Exec("composer require symfony/apache-pack");

        File.CreateSymbolicLink("public_html", "public");
    }

    public static async Task uninstall(string? path = null)
    {
        throw new NotImplementedException();
    }
}