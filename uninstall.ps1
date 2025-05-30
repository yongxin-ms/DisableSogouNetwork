#Requires -Version 5.1
#Requires -RunAsAdministrator

function Reset {
    param (
        [string] $folderName
    )

    $stdDisplayName = "Sogou Pinyin Service"
    Remove-NetFirewallRule -DisplayName $stdDisplayName -ErrorAction Ignore

    $displayName = "blocked $folderName via script"
    Remove-NetFirewallRule -DisplayName $displayName -ErrorAction Ignore

    Write-Host "Adding rules..."
    $count = 0
    Get-ChildItem -Path $folderName -Recurse *.exe | ForEach-Object -Process {
        New-NetFirewallRule `
            -DisplayName $stdDisplayName `
            -Direction Inbound `
            -Program $_.FullName `
            -Action Allow `
        | out-null

        $count += 1
    }

    Write-Host "Successfully added $count rules"
}

$folderName = "C:\Program Files (x86)\SogouInput"

if (($result = Read-Host "Press enter to accept default folder: $folderName") -ne '') {
	$folderName = $result
}

Reset -folderName $folderName
Reset -folderName "C:\Windows\SysWOW64\IME\SogouPY"
