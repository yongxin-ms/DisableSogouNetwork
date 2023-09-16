function Disable-Network {
    param (
        [string] $folderName
    )

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
        #Write-Host $_.FullName
    }
}

Disable-Network -folderName "C:\Program Files (x86)\SogouInput"