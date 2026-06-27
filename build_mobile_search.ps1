param(
    [string]$InputCsv = (Join-Path $PSScriptRoot 'namecard_contacts_enriched_v1.csv'),
    [string]$OutputDir = (Join-Path $PSScriptRoot 'mobile_data'),
    [string]$WebOutputDir = (Join-Path $PSScriptRoot 'mobile_search'),
    [string]$PackagePath = (Join-Path $PSScriptRoot 'mobile_search_update.zip')
)

$ErrorActionPreference = 'Stop'

if (!(Test-Path -LiteralPath $InputCsv -PathType Leaf)) {
    throw "Input CSV not found: $InputCsv"
}

if (!(Test-Path -LiteralPath $OutputDir -PathType Container)) {
    New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
}

if (!(Test-Path -LiteralPath $WebOutputDir -PathType Container)) {
    New-Item -ItemType Directory -Force -Path $WebOutputDir | Out-Null
}

$fields = @(
    'record_id',
    'review_status',
    'confidence',
    'source_pdf',
    'source_page',
    'card_position',
    'source_image',
    'person_name',
    'chinese_name',
    'company',
    'company_normalized',
    'title',
    'industry_tags',
    'relationship_stage',
    'country',
    'city',
    'email_primary',
    'email_secondary',
    'mobile',
    'phone',
    'website',
    'address',
    'notes',
    'primary_category_code',
    'primary_category',
    'subcategory',
    'business_role',
    'classification_confidence',
    'online_check_status',
    'verified_on',
    'classification_basis'
)

$rows = Import-Csv -LiteralPath $InputCsv -Encoding UTF8
$contacts = foreach ($row in $rows) {
    $item = [ordered]@{}
    foreach ($field in $fields) {
        $value = $row.$field
        if ($null -eq $value) {
            $value = ''
        }
        $item[$field] = [string]$value
    }
    [pscustomobject]$item
}

$companyNames = New-Object System.Collections.Generic.HashSet[string]
foreach ($contact in $contacts) {
    $company = $contact.company_normalized
    if ([string]::IsNullOrWhiteSpace($company)) {
        $company = $contact.company
    }
    $company = $company.Trim()
    if ($company.Length -gt 0) {
        [void]$companyNames.Add($company)
    }
}

$source = Get-Item -LiteralPath $InputCsv
$hash = (Get-FileHash -LiteralPath $InputCsv -Algorithm SHA256).Hash.ToLowerInvariant().Substring(0, 12)

$payload = [ordered]@{
    meta = [ordered]@{
        generatedAt = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss zzz')
        sourceCsv = $source.Name
        sourceLastWriteTime = $source.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')
        dataVersion = $hash
        contactCount = $contacts.Count
        companyCount = $companyNames.Count
    }
    contacts = $contacts
}

$json = $payload | ConvertTo-Json -Depth 6 -Compress
$target = Join-Path $OutputDir 'namecard_contacts_data.json'
[System.IO.File]::WriteAllText($target, $json, [System.Text.UTF8Encoding]::new($false))
$webTarget = Join-Path $WebOutputDir 'contacts-data.json'
[System.IO.File]::WriteAllText($webTarget, $json, [System.Text.UTF8Encoding]::new($false))

$packageFiles = @(
    'index.html',
    'styles.css',
    'app-online-sync-v2.js',
    'sw.js',
    'manifest.webmanifest',
    'icon.svg',
    'contacts-data.json'
)

$missingFiles = @()
foreach ($fileName in $packageFiles) {
    $filePath = Join-Path $WebOutputDir $fileName
    if (!(Test-Path -LiteralPath $filePath -PathType Leaf)) {
        $missingFiles += $filePath
    }
}

if ($missingFiles.Count -gt 0) {
    throw "Missing mobile_search files: $($missingFiles -join ', ')"
}

if (Test-Path -LiteralPath $PackagePath -PathType Leaf) {
    Remove-Item -LiteralPath $PackagePath -Force
}

$packageFilePaths = foreach ($fileName in $packageFiles) {
    Join-Path $WebOutputDir $fileName
}

Compress-Archive -LiteralPath $packageFilePaths -DestinationPath $PackagePath -Force

Write-Host "Generated $target"
Write-Host "Generated $webTarget"
Write-Host "Generated $PackagePath"
Write-Host "Contacts: $($contacts.Count)"
Write-Host "Companies: $($companyNames.Count)"
Write-Host "Version: $hash"
