using Microsoft.JSInterop;

namespace UkrGuru.WebJobs.Admin;

public static class FileExporter
{
    public static async Task SaveAsync(IJSRuntime jsRuntime, byte[] byteData, string fileName)
    {
        if (byteData == null)
        {
            await jsRuntime.InvokeVoidAsync("alert", "The byte array provided for Exporting was Null.");
        }
        else
        {
            await jsRuntime.InvokeVoidAsync("saveFile", Convert.ToBase64String(byteData), GetMimeType(fileName), fileName);
        }

        static string GetMimeType(string fileName)
        {
            return Path.GetExtension(fileName).ToLower() switch
            {
                ".txt" => "text/plain",
                ".html" => "text/html",
                ".rtf" => "application/rtf",
                ".pdf" => "application/pdf",
                ".zip" => "application/zip",
                ".json" => "application/json",
                ".xml" => "application/xml",
                ".gif" => "image/gif",
                ".tiff" => "image/tiff",
                ".jpg" => "image/jpeg",
                _ => "application/octet-stream",
            };
        }
    }
}
