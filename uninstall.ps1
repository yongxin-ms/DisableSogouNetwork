#Requires -Version 5.1
#Requires -RunAsAdministrator

function Uninstall {
    param (
        [string] $folderName
    )

    if (($result = Read-Host "Press enter to accept default folder: $folderName") -ne '') {
        $folderName = $result
    }

    $displayName = "blocked $folderName via script"
    Remove-NetFirewallRule -DisplayName $displayName -ErrorAction Ignore

    $count = 0
    Get-ChildItem -Path $folderName -Recurse *.exe | ForEach-Object -Process {
        New-NetFirewallRule `
            -DisplayName "Sogou Pinyin Service" `
            -Direction Inbound `
            -Program $_.FullName `
            -Action Allow

        $count += 1
    }

    Write-Host "Successfully added $count rules"
}

Uninstall -folderName "C:\Program Files (x86)\SogouInput"