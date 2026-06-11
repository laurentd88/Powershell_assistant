$DIR = "PATH"

$extensions = @(".jpg", ".jpeg", ".png", ".mp4")

Get-ChildItem -Path $DIR -Recurse -File |
Where-Object {
    $extensions -contains $_.Extension.ToLower()
} |
ForEach-Object {

    if ($_.BaseName -match '^IMG_(\d{4})(\d{2})(\d{2})-') {

        $year  = [int]$matches[1]
        $month = [int]$matches[2]
        $day   = [int]$matches[3]

        try {

            $date = Get-Date -Year $year -Month $month -Day $day

            $_.CreationTime = $date

            Write-Host "OK : $($_.FullName) -> CreationTime = $($date.ToString('yyyy-MM-dd'))"

        }
        catch {
            Write-Warning "Date invalide : $($_.FullName)"
        }
    }
}
