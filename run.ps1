function Disable-Network {
    param (
        [string] $folderName
    )

    if (($result = Read-Host "Press enter to accept default folder: $folderName") -ne '') {
        $folderName = $result
    }

    $displayName = "blocked $folderName via script"
    Remove-NetFirewallRule -DisplayName $displayName

    Get-ChildItem -Path $folderName -Recurse *.exe | Select-Object FullName | ForEach-Object -Process {
        New-NetFirewallRule `
            -DisplayName $displayName `
            -Direction Inbound `
            -Program $_.FullName `
            -Action Block

        New-NetFirewallRule `
            -DisplayName $displayName `
            -Direction Outbound `
            -Program $_.FullName `
            -Action Block
    }
}

Disable-Network -folderName "C:\Program Files (x86)\SogouInput"