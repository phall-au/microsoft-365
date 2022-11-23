<#
.SYNOPSIS
Generate report of all SharePoint site owners.

.DESCRIPTION
Generate a CSV report of all SharePoint site owners, including their attached Microsoft 365 Group (if applicable).

.NOTES
Date Created:   23/11/2022
Date Modified:  23/11/2022
Author:              @phall-au  
#>

#Requires -Modules ExchangeOnlineManagement
#Requires -Modules Microsoft.Online.SharePoint.PowerShell

Import-Module -Name ExchangeOnlineManagement
Import-Module -Name Microsoft.Online.SharePoint.PowerShell

$Report = @() 
$ReportPath = "$($env:TMP)\SPOSiteOwners_" + (Get-Date -Format yyyy-MM-ddTHHMM) + ".csv"
$SPOSites = Get-SPOSite -Limit All | Select-Object Title,Url,Owner,RelatedGroupId,GroupId,IsTeamsConnected,IsTeamsChannelConnected

foreach ($SPOSite in $SPOSites) {
    Write-Host "Getting details for $($SPOSite.Url)..." -ForegroundColor Cyan

    # Check if Microsoft 365 Group is connected and get Group owners. Else, retrieve the owner listed against the SPO site.
    if ($SPOSite.RelatedGroupId -notlike "00000000-0000-0000-0000-000000000000") {
        $Owners = (Get-UnifiedGroup -Identity $SPOSite.RelatedGroupId).ManagedBy
    } else {
        $Owners = $SPOSite.Owner
    }

    foreach ($Owner in $Owners) {
        if ($Owner) {
            $OwnerName = (Get-Mailbox -Identity $Owner).DisplayName
        } else {
            $OwerName = $null
        }

        $Obj = New-Object PSObject
        $Obj | Add-Member -MemberType NoteProperty -Name Title -Value $SPOSite.Title
        $Obj | Add-Member -MemberType NoteProperty -Name Url -Value $SPOSite.Url
        $Obj | Add-Member -MemberType NoteProperty -Name OwnerUserId -Value $Owner.split("@")[0]
        $Obj | Add-Member -MemberType NoteProperty -Name OwnerName -Value $OwnerName
        $Obj | Add-Member -MemberType NoteProperty -Name RelatedGroupId -Value $SPOSite.RelatedGroupId
        $Obj | Add-Member -MemberType NoteProperty -Name IsTeamsConnected -Value $SPOSite.IsTeamsConnected
        $Obj | Add-Member -MemberType NoteProperty -Name IsTeamsChannelConnected -Value $SPOSite.IsTeamsChannelConnected
        $Report += $Obj
    }
}

$Report | Export-Csv -Path $ReportPath -NoTypeInformation -Force

if ($IsWindows) {
    [console]::beep(500,1000)
}

Write-Host "Script complete." -ForegroundColor Green