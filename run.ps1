#Requires -Version 5.1
#Requires -RunAsAdministrator

function Disable-Network {
    param (
        [string] $folderName
    )

    if (($result = Read-Host "Press enter to accept default folder: $folderName") -ne '') {
        $folderName = $result
    }

    Remove-NetFirewallRule -DisplayName "Sogou Pinyin Service" -ErrorAction Ignore

    $displayName = "blocked $folderName via script"
    Remove-NetFirewallRule -DisplayName $displayName -ErrorAction Ignore

    Write-Host "Adding rules..."
    $count = 0
    Get-ChildItem -Path $folderName -Recurse *.exe | ForEach-Object -Process {
        New-NetFirewallRule `
            -DisplayName $displayName `
            -Direction Inbound `
            -Program $_.FullName `
            -Action Block `
        | out-null

        New-NetFirewallRule `
            -DisplayName $displayName `
            -Direction Outbound `
            -Program $_.FullName `
            -Action Block `
        | out-null

        $count += 2
    }

    Write-Host "Successfully added $count rules"
}

Disable-Network -folderName "C:\Program Files (x86)\SogouInput"