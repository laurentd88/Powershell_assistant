# ============================================
# CREATE FUNCTION Get-FileCount
# ============================================

function Get-FileCount {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    
    # CHECK IF PATH EXIST
    if (-not (Test-Path $Path)) {
        Write-Host "ERREUR : Path is dead" -ForegroundColor Red
        return 0, $null
    }
    
    # Count only files
    $files = Get-ChildItem -Path $Path -File -ErrorAction SilentlyContinue
    $count = $files.Count
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "ANALYSE DU DOSSIER SOURCE" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "Chemin : $Path" -ForegroundColor White
    Write-Host "Nombre total de fichiers trouvés : $count" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Cyan
    
    return $count, $files
}

# ============================================
# CREATE FUNCTION Convert-NumberToAlpha
# ============================================

function Convert-NumberToAlpha {
    param([int]$Number)
    
    $letters = @("A","B","C","D","E","F","G","H","I","J","K","L","M",
                 "N","O","P","Q","R","S","T","U","V","W","X","Y","Z")
    
    $result = ""
    $n = $Number
    
    while ($n -gt 0) {
        $n--
        $remainder = $n % 26
        $result = $letters[$remainder] + $result
        $n = [math]::Floor($n / 26)
    }
    
    return $result
}

# ============================================
# SCRIPT
# ============================================

$Dir_Path = Read-Host "Add the path with format C:\\Users\Dir"
$MaxFilesInDir = Read-Host "Define the maximum of files that can be add in a directory"

# Obtain list of directories with fullname
$ListDir = @(Get-ChildItem -Path $Dir_Path -Directory -Recurse).FullName

# Add the source directory
$ListDir = @($Dir_Path) + $ListDir

#$maxFilesInDir = 1000

foreach ($Dir in $ListDir) {
    # Count files in Source Dir
    $NbFilesDir, $Files = Get-FileCount -Path $Dir
    
    if ($NbFilesDir -eq 0) {
        Write-Host "Empty Dir : $Dir" -ForegroundColor Yellow
        continue
    }
        
    $nbDir = [Math]::Ceiling($NbFilesDir / $MaxFilesInDir)
    Write-Host "For $Dir with $NbFilesDir files, $nbDir Dir will be created" -ForegroundColor Green
    
    $fileIndex = 0

    for ($i = 0; $i -lt $nbDir; $i++) {
        $DirName = Convert-NumberToAlpha -Number ($i + 1)
        
        $NewDirPath = Join-Path -Path $Dir -ChildPath $DirName
        
        if (-not (Test-Path $NewDirPath)) {
            New-Item -ItemType Directory -Path $NewDirPath -Force | Out-Null
            Write-Host "Directory created : $DirName" -ForegroundColor Cyan
        } else {
            Write-Host "Directory existed already : $DirName" -ForegroundColor Yellow
        }
        $CntfilesFollow = $NbFilesDir - $fileIndex
        $VolFilesToMove = [math]::Min($MaxFilesInDir, $CntfilesFollow)

        $MoveFiles = $Files[$fileIndex..($fileIndex + $Volfilestomove -1)]

        $countMove = 0
        foreach ($File in $MoveFiles) {
            $DestDir = Join-Path -Path $NewDirPath -ChildPath $file.Name
            Move-Item -Path $File.FullName -Destination $DestDir 
            $countMove++
         }
         Write-Host " $countMove files moved in $DirName.Fullname "
            
         $fileIndex = $fileIndex + $VolFilesToMove
    }
    
    Write-Host ""
}

Write-Host "============================================================" -ForegroundColor Green
Write-Host "Operation status : achieved " -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
