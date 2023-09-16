function Disable-Network {
    param (
        [string] $folderName
    )

    Remove-NetFirewallRule -DisplayName "blocked $folderName via script"

    Get-ChildItem -Path $folderName -Recurse *.exe | Select-Object FullName | ForEach-Object -Process {
        New-NetFirewallRule `
            -DisplayName "blocked $folderName via script" `
            -Direction Inbound `
            -Program $_.FullName `
            -Action Block

        New-NetFirewallRule `
            -DisplayName "blocked $folderName via script" `
            -Direction Outbound `
            -Program $_.FullName `
            -Action Block
    }
}

Disable-Network -folderName "C:\Program Files (x86)\SogouInput"