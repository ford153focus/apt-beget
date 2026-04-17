using System.Diagnostics;

namespace apt_beget;

public static class Helpers
{
    public static string homePath = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
    public static string localBinPath = Path.Join(homePath, ".local", "bin");

    public static void Chmod(string path, string octalMode)
    {
        UnixFileMode mode = (UnixFileMode)Convert.ToInt32(octalMode, 8);
        File.SetUnixFileMode(path, mode);
    }

    public static async Task DownloadFileAsync(string url, string outputPath)
    {
        using HttpClient client = new();
        
        // Get the stream from the URL without buffering the whole file into RAM
        using Stream remoteStream = await client.GetStreamAsync(url);
        
        // Create the local file stream
        using FileStream localStream = new(outputPath, FileMode.Create, FileAccess.Write);
        
        // Stream the data from the internet directly to the disk
        await remoteStream.CopyToAsync(localStream);
    }

    public static void EmptyFolder(string folderPath)
    {
        DirectoryInfo di = new(folderPath);

        // Delete all files
        foreach (FileInfo file in di.GetFiles())
        {
            file.Delete(); 
        }

        // Delete all subdirectories (true = recursive)
        foreach (DirectoryInfo dir in di.GetDirectories())
        {
            dir.Delete(true); 
        }
    }

    public static void Exec(string cmd)
    {
        var arr = cmd.Split(' ');
        using var process = new Process();
        process.StartInfo = new ProcessStartInfo
        {
            FileName = arr[0],
            Arguments = string.Join(" ", arr[1..]),
            RedirectStandardOutput = false,
            RedirectStandardError = false,
            UseShellExecute = true, // Required for redirecting output
            CreateNoWindow = true
        };

        process.Start();
        process.WaitForExit();

        if (process.ExitCode != 0)
        {
            string error = process.StandardError.ReadToEnd();
            throw new Exception($"Process failed with exit code {process.ExitCode}: {error}");
        }
    }

    public static bool IsDocker()
    {
        return File.ReadAllLines("/proc/self/cgroup").Any(x => x.Contains("cpuset") && x.Contains("docker"));
    }

    public static bool IsSiteUser()
    {
        return Environment.UserName.Contains('_');
    }

    public static void set_php_cli_version(string version)
    {
        Directory.CreateDirectory(localBinPath);
        string php_exe_path = Path.Join(localBinPath, "php");
        File.WriteAllText(php_exe_path, $"/usr/local/bin/php{version} $@");
        Chmod(php_exe_path, "700");
    }
}

class Program
{
    static void Main(string[] args)
    {
        Console.WriteLine("Hello, World!");
    }
}
