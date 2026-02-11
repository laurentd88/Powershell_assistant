<#  
.SYNOPSIS
    Lists the largest directories and files on the system.

.DESCRIPTION
    This script enumerates all filesystem drives, checks access permissions,
    and scans only authorized locations to find the largest directories and files.
    Includes an interactive menu to:
        - Select a specific partition
        - Exclude partition(s)
        - Scan all partitions
        - Exit

.AUTHOR
    Laurent

.VERSION
    2.0
#>

#region Convert-ToHumanSize

function Convert-ToHumanSize {
    param (
        [long]$Bytes
    )

    switch ($Bytes) {
        { $_ -ge 1TB } { return "{0:N2} TB" -f ($Bytes / 1TB) }
        { $_ -ge 1GB } { return "{0:N2} GB" -f ($Bytes / 1GB) }
        { $_ -ge 1MB } { return "{0:N2} MB" -f ($Bytes / 1MB) }
        { $_ -ge 1KB } { return "{0:N2} KB" -f ($Bytes / 1KB) }
        default        { return "$Bytes Bytes" }
    }
}

#endregion

#region Search-Part Search-BigDir Search-BigFiles Functions

function Search-Part {

    $drives = Get-PSDrive -PSProvider FileSystem
    $results = @()

    foreach ($drive in $drives) {

        $status = "access pending"

        try {
            Get-ChildItem -Path $drive.Root -ErrorAction Stop | Out-Null
            $status = "access granted"
        }
        catch {
            $status = "access denied"
        }

        $results += [PSCustomObject]@{
            Drive  = $drive.Root
            Status = $status
        }
    }

    return $results
}

function Search-BigDir {

    param (
        [string[]]$AuthorizedDrives
    )

    $dirSizes = @{}
    $fileCount = 0

    foreach ($drive in $AuthorizedDrives) {

        Write-Host "Scanning drive $drive ..."

        Get-ChildItem -Path $drive -File -Recurse -ErrorAction SilentlyContinue |
        ForEach-Object {

            if (-not $_.Directory -or -not $_.Directory.FullName) {
                return
            }

            $fileCount++

            if ($fileCount % 5000 -eq 0) {
                Write-Progress `
                    -Activity "Scanning files" `
                    -Status "$fileCount files processed"
            }

            $parentDir = $_.Directory.FullName

            if (-not $dirSizes.ContainsKey($parentDir)) {
                $dirSizes[$parentDir] = 0
            }

            $dirSizes[$parentDir] += $_.Length
        }
    }

    Write-Progress -Activity "Scanning files" -Completed

    $dirSizes.GetEnumerator() |
        Sort-Object Value -Descending |
        Select-Object -First 10 |
        ForEach-Object {
            [PSCustomObject]@{
                FullName = $_.Key
                Size     = Convert-ToHumanSize $_.Value
            }
        }
}

function Search-BigFiles {

    param (
        [string[]]$AuthorizedDrives
    )

    $files = @()

    foreach ($drive in $AuthorizedDrives) {
        try {
            Get-ChildItem -Path $drive -File -Recurse -ErrorAction SilentlyContinue |
            ForEach-Object {
                $files += [PSCustomObject]@{
                    FullName = $_.FullName
                    Size     = $_.Length
                }
            }
        }
        catch {}
    }

    return $files |
        Sort-Object Size -Descending |
        Select-Object -First 10 |
        ForEach-Object {
            [PSCustomObject]@{
                FullName = $_.FullName
                Size     = Convert-ToHumanSize $_.Size
            }
        }
}

#endregion

#region Interactive Menu

$partitions = Search-Part

Write-Host "`n=== Drive Access Status ==="
$partitions | Format-Table -AutoSize

$authorizedDrives = $partitions |
    Where-Object Status -eq "access granted" |
    Select-Object -ExpandProperty Drive

if (-not $authorizedDrives) {
    Write-Host "No accessible drives found. Exiting."
    return
}

do {
    Write-Host "`n==============================="
    Write-Host "1 - Select a specific partition"
    Write-Host "2 - Exclude partition(s)"
    Write-Host "3 - Scan ALL authorized partitions"
    Write-Host "4 - Exit"
    Write-Host "==============================="

    $choice = Read-Host "Enter your choice"

    switch ($choice) {

        "1" {
            Write-Host "`nAvailable partitions:"
            for ($i = 0; $i -lt $authorizedDrives.Count; $i++) {
                Write-Host "$($i+1) - $($authorizedDrives[$i])"
            }

            $selection = Read-Host "Select partition number"
            $index = [int]$selection - 1

            if ($index -ge 0 -and $index -lt $authorizedDrives.Count) {
                $selected = $authorizedDrives[$index]

                Write-Host "`n=== Top 10 Largest Directories ==="
                Search-BigDir -AuthorizedDrives @($selected) | Format-Table -AutoSize

                Write-Host "`n=== Top 10 Largest Files ==="
                Search-BigFiles -AuthorizedDrives @($selected) | Format-Table -AutoSize
            }
            else {
                Write-Host "Invalid selection."
            }
        }

        "2" {
            Write-Host "`nAvailable partitions:"
            for ($i = 0; $i -lt $authorizedDrives.Count; $i++) {
                Write-Host "$($i+1) - $($authorizedDrives[$i])"
            }

            $excludeInput = Read-Host "Enter partition numbers to exclude (comma separated)"
            $excludeIndexes = $excludeInput -split "," | ForEach-Object { ([int]$_) - 1 }

            $selectedDrives = @()

            for ($i = 0; $i -lt $authorizedDrives.Count; $i++) {
                if ($excludeIndexes -notcontains $i) {
                    $selectedDrives += $authorizedDrives[$i]
                }
            }

            if ($selectedDrives.Count -eq 0) {
                Write-Host "No drives left to scan."
            }
            else {
                Write-Host "`n=== Top 10 Largest Directories ==="
                Search-BigDir -AuthorizedDrives $selectedDrives | Format-Table -AutoSize

                Write-Host "`n=== Top 10 Largest Files ==="
                Search-BigFiles -AuthorizedDrives $selectedDrives | Format-Table -AutoSize
            }
        }

        "3" {
            Write-Host "`n=== Top 10 Largest Directories ==="
            Search-BigDir -AuthorizedDrives $authorizedDrives | Format-Table -AutoSize

            Write-Host "`n=== Top 10 Largest Files ==="
            Search-BigFiles -AuthorizedDrives $authorizedDrives | Format-Table -AutoSize
        }

        "4" {
            Write-Host "Exiting..."
        }

        default {
            Write-Host "Invalid choice."
        }
    }

} while ($choice -ne "4")

#endregion
