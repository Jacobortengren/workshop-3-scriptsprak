### Del A #####################################################################################
###############################################################################################
### Task 1: Läs in JSON-filen med Get-Content och ConvertFrom-Json ############################
###############################################################################################

$jsonText = Get-Content -Path ".\ad_export.json" -Raw -Encoding UTF8
$adData = $jsonText | ConvertFrom-Json

###############################################################################################
### Task 2: Visa domännamn och exportdatum ####################################################
###############################################################################################
$DomainAndDate = @"
---DOMAIN-&-DATE-OF-EXPORT-------------------

Domain      : $($adData.domain)
Export Date : $($adData.export_date -replace 'T', ' ')

"@
Write-Host $DomainAndDate

###############################################################################################
### Task 3: Lista användare som inte loggat in på 30+ dagar ###################################
###############################################################################################

$gransdatum = (Get-Date).AddDays(-30)
$inaktivaAnvandare = $adData.users | Where-Object { [datetime]$_.lastLogon -lt $gransdatum }

$userReport = @"
---USERS-THAT-HAVENT-LOGGED-IN-FOR-30-DAYS---
"@

$userTable = $inaktivaAnvandare | Select-Object @{Name = 'Display Name'; Expression = { $_.displayName } }, 
@{Name = 'Last logon'; Expression = { ([datetime]$_.lastLogon).ToString("yyyy-MM-dd HH:mm:ss") } } |
Format-Table -AutoSize | Out-String

Write-Host $userReport
Write-Host $userTable

###############################################################################################
### Task 4: Räkna antal användare per avdelning med enkel loop ################################
###############################################################################################

$deptReport = @"
---NUMBER-OF-USERS-PER-DEPARTMENT-----------
"@

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

$deptStrings = ""
foreach ($key in $avdelningCount.Keys) {
    $deptStrings += "$key : $($avdelningCount[$key]) Users`n"
}

Write-Host $deptReport
Write-Host $deptStrings

### Del B #####################################################################################
###############################################################################################
### Task 5: Använd Group-Object för att gruppera datorer per site #############################
###############################################################################################

$siteReport = @"
---COMPUTERS-GROUPED-BY-SITE----------------
"@

$groupedComputers = $adData.computers | Group-Object -Property site
$siteStrings = ""
foreach ($group in $groupedComputers) {
    $siteStrings += "Site: $($group.Name) - $($group.Count) Computers`n"
    foreach ($comp in $group.Group) {
        if ($comp.computerName) {
            $siteStrings += "    $($comp.computerName)`n"
        }
    }
    $siteStrings += "`n"
}

Write-Host $siteReport
Write-Host $siteStrings

###############################################################################################
### Task 6 : Skapa CSV-fil inactive_users.csv med användare som inte loggat in på 30+ dagar ###
###############################################################################################

$csvPath = ".\inactive_users.csv"
$inaktivaAnvandare |
Select-Object displayName, lastLogon, department |
Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

###############################################################################################
### Task 7 : Beräkna hur många dagars lösenordsålder varje användare har ######################
###############################################################################################

$passwordReport = @"
---PASSWORD-AGE-IN-DAYS---------------------
"@

$passwordStrings = ""
$today = Get-Date
$adData.users | ForEach-Object {
    $passwordSetDate = [datetime]$_.passwordLastSet
    $daysOld = ($today - $passwordSetDate).Days
    $passwordStrings += "$($_.displayName) : $daysOld days`n"
}

Write-Host $passwordReport
Write-Host $passwordStrings

###############################################################################################
### Task 8 : Lista de 10 datorer som inte checkat in på längst tid (använd Sort-Object) #######
###############################################################################################

$topCompReport = @"
---TOP 10 COMPUTERS THAT HAVEN'T CHECKED IN------
"@

$computersWithLogon = $adData.computers | Where-Object { $_.lastLogon }
$top10Computers = $computersWithLogon |
Sort-Object { [datetime]$_.lastLogon } |
Select-Object -First 10

$topCompStrings = ""
$top10Computers | ForEach-Object {
    $lastCheck = ([datetime]$_.lastLogon).ToString("yyyy-MM-dd HH:mm:ss")
    $topCompStrings += "Computer: $($_.name) - Last Check-In: $lastCheck`n"
}

Write-Host $topCompReport
Write-Host $topCompStrings
# Slut på raporten.
$endReport = @"
-------------------END OF REPORT-------------------
"@
Write-Host $endReport