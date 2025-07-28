function Get-Triangle {
<#
    .SYNOPSIS
    Determine if a triangle is equilateral, isosceles, or scalene.
 
    .DESCRIPTION
    Given 3 sides of a triangle, return the type of that triangle if it is a valid triangle.
    
    .PARAMETER Sides
    The lengths of a triangle's sides.

    .EXAMPLE
    Get-Triangle -Sides @(1,2,3)
    Return: [Triangle]::SCALENE
#>
    
    [CmdletBinding()]
    param (
        [double[]]$Sides
    )

    # Déclaration dynamique de l'enum
    if (-not ([System.Management.Automation.PSTypeName]'Triangle').Type) {
        Add-Type -TypeDefinition @"
            public enum Triangle {
                Equilateral,
                Isosceles,
                Scalene
            }
"@
    }

    # check sides - limit 3
    if ($Sides.Count -ne 3) {
        throw "You must provide exactly 3 sides."
    }

    $a, $b, $c = $Sides

    # all sides > 0
    if ($a -le 0 -or $b -le 0 -or $c -le 0) {
        throw "All side lengths must be positive."
    }

    # sides class by order ascending
    $sorted = @($a, $b, $c) | Sort-Object
    $s1, $s2, $s3 = $sorted[0], $sorted[1], $sorted[2]

    # validate the triangle
    if ($s1 + $s2 -lt $s3) {
        throw "Side lengths violate triangle inequality."
    }
    
    # Select the type
    if ($a -eq $b -and $b -eq $c) {
        return [Triangle]::Equilateral
    } 
    elseif ($a -eq $b -or $a -eq $c -or $b -eq $c) {
        return [Triangle]::Isosceles
    } 
    else {
        return [Triangle]::Scalene
    }
}
