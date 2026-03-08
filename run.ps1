param (
    [bool]$BlockLocalProxyBypass = $true,
    [string[]]$LocalProxyPorts = @(10808, 10809, 7890, 7891, 8080, 1080),
    [string[]]$LocalProxyAddresses = @("127.0.0.1", "::1")
)

# Existing behavior and grouping 'DisableSogouNetwork'

# Define the Sogou IME executables
$sogouExecutables = @("SogouIME.exe", "SogouInput.exe")

# Remove existing rules for the folder
foreach ($exe in $sogouExecutables) {
    Get-NetFirewallRule | Where-Object { $_.DisplayName -like "*$exe*" } | Remove-NetFirewallRule
}

if ($BlockLocalProxyBypass) {
    foreach ($exe in $sogouExecutables) {
        foreach ($port in $LocalProxyPorts) {
            foreach ($address in $LocalProxyAddresses) {
                New-NetFirewallRule -DisplayName "Block $exe to $address:$port" `
                                    -Direction Outbound `
                                    -Protocol TCP `
                                    -RemoteAddress $address `
                                    -RemotePort $port `
                                    -Action Block
            }
        }
    }
}

# Updating help comments and output
Write-Host "Firewall rules added to block Sogou IME executables from accessing the specified local proxy addresses and ports."