# ============================================
# FUNCTION TO DETERMINE FILE TYPE
# ============================================

function Get-FileType {
    param([string]$Extension)
    
    $Extension = $Extension.ToLower()
    
    # Images
    $imageExtensions = @(".jpg", ".jpeg", ".png", ".gif", ".bmp", ".tiff", ".tif", ".ico", ".svg", ".webp")
    if ($Extension -in $imageExtensions) { return "Image" }
    
    # Texts
    $textExtensions = @(".txt", ".doc", ".docx", ".rtf", ".odt", ".md")
    if ($Extension -in $textExtensions) { return "Text" }
    
    # Presentations
    $presentationExtensions = @(".ppt", ".pptx", ".odp", ".key")
    if ($Extension -in $presentationExtensions) { return "Presentation" }
    
    # PDF documents
    $pdfExtensions = @(".pdf")
    if ($Extension -in $pdfExtensions) { return "PDF" }
    
    # Spreadsheets
    $spreadsheetExtensions = @(".xls", ".xlsx", ".ods", ".csv")
    if ($Extension -in $spreadsheetExtensions) { return "Spreadsheet" }
    
    # Archives
    $archiveExtensions = @(".zip", ".rar", ".7z", ".tar", ".gz")
    if ($Extension -in $archiveExtensions) { return "Archive" }
    
    # Audio
    $audioExtensions = @(".mp3", ".wav", ".flac", ".aac", ".ogg", ".m4a")
    if ($Extension -in $audioExtensions) { return "Audio" }
    
    # Video
    $videoExtensions = @(".mp4", ".avi", ".mkv", ".mov", ".wmv", ".flv", ".webm")
    if ($Extension -in $videoExtensions) { return "Video" }
    
    # Source code
    $codeExtensions = @(".ps1", ".py", ".js", ".html", ".css", ".json", ".xml", ".bat", ".cmd", ".vbs")
    if ($Extension -in $codeExtensions) { return "Code" }
    
    # Default
    return "Other"
}

# ============================================
# FUNCTION TO SCAN FILES (MODIFIED - STREAMING)
# ============================================

function Export-FilesInventoryToCSV {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [Parameter(Mandatory=$false)]
        [string]$OutputCSV = "D:\file_inventory.csv",
        
        [Parameter(Mandatory=$false)]
        [string[]]$IncludedExtensions = @("*"),
        
        [Parameter(Mandatory=$false)]
        [switch]$Recurse = $true
    )
    
    # Check if path exists
    if (-not (Test-Path $Path)) {
        Write-Host "ERROR: Path '$Path' does not exist" -ForegroundColor Red
        return $null
    }
    
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "FILE INVENTORY" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "Path: $Path" -ForegroundColor White
    Write-Host "Mode: $(if($Recurse){'Recursive'}else{'Non recursive'})" -ForegroundColor White
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Get all files
    Write-Host "Searching for files..." -ForegroundColor Yellow
    
    if ($Recurse) {
        $allFiles = Get-ChildItem -Path $Path -File -Recurse -ErrorAction SilentlyContinue
    } else {
        $allFiles = Get-ChildItem -Path $Path -File -ErrorAction SilentlyContinue
    }
    
    # Filter by extension if needed
    if ($IncludedExtensions[0] -ne "*") {
        $allFiles = $allFiles | Where-Object { $_.Extension -in $IncludedExtensions }
    }
    
    $totalFiles = $allFiles.Count
    Write-Host "$totalFiles files to analyze" -ForegroundColor Cyan
    Write-Host ""
    
    # === SEUL CHANGEMENT ICI ===
    # Au lieu de stocker dans $results, on écrit DIRECTEMENT dans le CSV
    # Création du CSV avec en-têtes
    $headers = "Index;Type;Name;FullName;CreationDate;ModificationDate;SizeBytes;SizeKB;SizeMB;Extension;Hash"
    $headers | Out-File -FilePath $OutputCSV -Encoding UTF8
    
    $processed = 0
    $index = 1
    
    foreach ($file in $allFiles) {
        # Progress
        $processed++
        $percent = [math]::Round(($processed / $totalFiles) * 100, 1)
        Write-Progress -Activity "Analyzing files" -Status "$processed/$totalFiles - $($file.Name)" -PercentComplete $percent
        
        # Calculate file hash
        try {
            $hash = (Get-FileHash -Path $file.FullName -Algorithm SHA256).Hash
        } catch {
            $hash = "READ_ERROR"
        }
        
        # Determine file type
        $fileType = Get-FileType -Extension $file.Extension
        
        # Créer la ligne CSV (sans créer d'objet PSCustomObject)
        $sizeKB = [math]::Round($file.Length / 1KB, 2)
        $sizeMB = [math]::Round($file.Length / 1MB, 2)
        
        # Écrire directement dans le fichier
        "$index;$fileType;$($file.Name);$($file.FullName);$($file.CreationTime);$($file.LastWriteTime);$($file.Length);$sizeKB;$sizeMB;$($file.Extension);$hash" | Out-File -FilePath $OutputCSV -Encoding UTF8 -Append
        
        $index++
    }
    
    Write-Progress -Activity "Analyzing files" -Completed
    
    # Export to CSV - PLUS BESOIN, DÉJÀ FAIT !
    # $results | Export-Csv -Path $OutputCSV -NoTypeInformation -Encoding UTF8 -Delimiter ";"
    
    # Display summary - MODIFIÉ car on n'a plus $results
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host "INVENTORY RESULTS" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host "Files analyzed: $totalFiles" -ForegroundColor White
    
    # Pour les statistiques par type, il faut re-lire le CSV ou re-scanner
    Write-Host "Files by type:" -ForegroundColor Yellow
    
    # Option rapide : on refait un group simple sans re-scanner tous les fichiers
    $typeStats = @{}
    foreach ($file in $allFiles) {
        $fileType = Get-FileType -Extension $file.Extension
        if ($typeStats.ContainsKey($fileType)) {
            $typeStats[$fileType]++
        } else {
            $typeStats[$fileType] = 1
        }
    }
    
    $typeStats.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object {
        Write-Host "  - $($_.Key) : $($_.Value) file(s)" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "CSV created: $OutputCSV" -ForegroundColor Green
    Write-Host "Columns: Index, Type, Name, FullName, CreationDate, SizeBytes, SizeKB, SizeMB, Extension, Hash" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Green
    
    # Preview in console (on lit les 5 premières lignes du CSV)
    Write-Host ""
    Write-Host "PREVIEW (first 5 files):" -ForegroundColor Cyan
    Get-Content $OutputCSV -TotalCount 6 | Select-Object -Skip 1 | ForEach-Object {
        $parts = $_ -split ';'
        Write-Host "$($parts[0]) $($parts[1]) $($parts[2]) $($parts[8]) $($parts[9])" -ForegroundColor Gray
    }
    
    return $true
}

# ============================================
# USAGE EXAMPLES
# ============================================

$Dir = Read-Host "Enter the directory path (example: D:\TEST or C:\Users\Documents)"

# Create CSV name and path
$Date = Get-Date -Format "yyyy-MM-dd"
$CSVName = "FileInventory_$Date.csv"
$DefaultCSVPath = Join-Path $env:USERPROFILE -ChildPath "Desktop\$CSVName"

Write-Host ""
$UserInput = Read-Host "Enter CSV path (press Enter for default: $DefaultCSVPath)"
if ([string]::IsNullOrWhiteSpace($UserInput)) {
    $CSVPath = $DefaultCSVPath
    Write-Host "Using default path: $CSVPath" -ForegroundColor Cyan
} else {
    $CSVPath = $UserInput
    Write-Host "Using custom path: $CSVPath" -ForegroundColor Green
}

Export-FilesInventoryToCSV -Path $Dir -OutputCSV $CSVPath -Recurse 

Write-Host ""

# FILE ANALYSIS (légèrement modifié car on utilise Import-Csv)
$csv = Import-Csv -Path $CSVPath -Delimiter ";" -ErrorAction SilentlyContinue

if ($csv) {
    $uniqueHashes = $csv | Select-Object -ExpandProperty Hash -Unique
    $realFileCount = $uniqueHashes.Count
    $totalFiles = $csv.Count
    $duplicateCount = $totalFiles - $realFileCount

    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "FILE ANALYSIS" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "Total files in CSV (with duplicates): $totalFiles" -ForegroundColor Yellow
    Write-Host "Real unique files (by content): $realFileCount" -ForegroundColor Green
    Write-Host "Duplicate files: $duplicateCount" -ForegroundColor Red
    Write-Host "============================================================" -ForegroundColor Cyan
} else {
    Write-Host "Could not analyze CSV file" -ForegroundColor Red
}
