param(
    [int]$Port = 8787
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootFull = [System.IO.Path]::GetFullPath($Root)
$Listener = [System.Net.HttpListener]::new()
$Prefix = "http://127.0.0.1:$Port/"
$Listener.Prefixes.Add($Prefix)
$Listener.Start()

Write-Host "Serving $RootFull at $Prefix"

try {
    while ($Listener.IsListening) {
        $Context = $Listener.GetContext()
        try {
            $RequestPath = [System.Uri]::UnescapeDataString($Context.Request.Url.AbsolutePath.TrimStart('/'))
            if ([string]::IsNullOrWhiteSpace($RequestPath)) {
                $RequestPath = 'index.html'
            }

            $FullPath = [System.IO.Path]::GetFullPath((Join-Path $RootFull $RequestPath))
            if (!$FullPath.StartsWith($RootFull, [System.StringComparison]::OrdinalIgnoreCase) -or !(Test-Path -LiteralPath $FullPath -PathType Leaf)) {
                $Context.Response.StatusCode = 404
                $Bytes = [System.Text.Encoding]::UTF8.GetBytes('Not found')
                $Context.Response.OutputStream.Write($Bytes, 0, $Bytes.Length)
                continue
            }

            $Extension = [System.IO.Path]::GetExtension($FullPath).ToLowerInvariant()
            $ContentType = switch ($Extension) {
                '.html' { 'text/html; charset=utf-8' }
                '.css' { 'text/css; charset=utf-8' }
                '.js' { 'application/javascript; charset=utf-8' }
                '.json' { 'application/json; charset=utf-8' }
                '.webmanifest' { 'application/manifest+json; charset=utf-8' }
                '.svg' { 'image/svg+xml' }
                default { 'application/octet-stream' }
            }

            $Bytes = [System.IO.File]::ReadAllBytes($FullPath)
            $Context.Response.ContentType = $ContentType
            $Context.Response.Headers['Cache-Control'] = 'no-cache'
            $Context.Response.ContentLength64 = $Bytes.Length
            $Context.Response.OutputStream.Write($Bytes, 0, $Bytes.Length)
        } finally {
            $Context.Response.OutputStream.Close()
        }
    }
} finally {
    $Listener.Stop()
}
