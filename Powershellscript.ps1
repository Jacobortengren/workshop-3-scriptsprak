### Del A ###
### Task 1: Läs in JSON-filen med Get-Content och ConvertFrom-Json ###

$jsonText = Get-Content -Path ".\ad_export.json" -Raw -Encoding UTF8
$adData = $jsonText | ConvertFrom-Json

### Task 2: Visa domännamn och exportdatum ###

$adData.domain
$adData.export_date

### Task 3: Lista användare som inte loggat in på 30+ dagar ###
$gransdatum = (Get-Date).AddDays(-30)
$inaktivaAnvandare = $adData.users | Where-Object { [datetime]$_.lastLogon -lt $gransdatum }

# Visa inaktiva användare
$inaktivaAnvandare | Format-Table displayName, lastLogon

### Task 4: Räkna antal användare per avdelning med enkel loop ###
$avdelningCount = @{}

foreach ($user in $adData.users) {
    $dept = $user.department
    if ($avdelningCount.ContainsKey($dept)) {
        $avdelningCount[$dept] += 1
    }
    else {
        $avdelningCount[$dept] = 1
    }
}

# Visa resultatet
foreach ($key in $avdelningCount.Keys) {
    Write-Host "$key : $($avdelningCount[$key])"
}
