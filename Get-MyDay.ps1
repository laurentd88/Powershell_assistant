<#
.SYNOPSIS
Script to identify the day of the week based on a date.

.DESCRIPTION
This script takes a day, month, and optionally a year (default is the current year)
and returns the corresponding day of the week in French.

.PARAMETER day
Day of the month (positive integer)

.PARAMETER month
Month of the year (positive integer)

.PARAMETER year
Year (positive integer, optional - defaults to current year)

.EXAMPLE
Get-MyDay -day 13 -month 5 -year 2025
Get-MyDay -day 13 -month 2
#>

function Get-MyDay {
    param(
        [Parameter(Mandatory=$false)]
        [int]$day,

        [Parameter(Mandatory=$false)]
        [int]$month,

        [Parameter(Mandatory=$false)]
        [int]$year = (Get-Date).Year
    )

    # Check parameters 
    if (-not $day) {
        $dayInput = Read-Host "Give me the day"
        if ($dayInput -match '^\d+$') { $day = [int]$dayInput } else { Write-Error "Day must be a positive integer."; return }
    }

    if (-not $month) {
        $monthInput = Read-Host "Give me the month"
        if ($monthInput -match '^\d+$') { $month = [int]$monthInput } else { Write-Error "Month must be a positive integer."; return }
    }

    if (-not $PSBoundParameters.ContainsKey('year')) {
        $yearInput = Read-Host "Give me the year or press enter for current year"
        if ($yearInput -match '^\d+$') { $year = [int]$yearInput }
    }

    try {
        $date = Get-Date -Year $year -Month $month -Day $day
        $jour = $date.ToString("dddd", [System.Globalization.CultureInfo]::GetCultureInfo("fr-FR"))
        Write-Output ("Date : {0} is a {1}." -f $date.ToShortDateString(), $jour)
    } catch {
        Write-Error "Invalid date : $_"
    }
}
