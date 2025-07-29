#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
禁用指定文件夹中所有exe文件的网络访问权限

.DESCRIPTION
该函数通过创建Windows防火墙规则来阻止指定文件夹及其子文件夹中所有exe文件的入站和出站网络连接。
首先会删除已存在的相关防火墙规则，然后为每个exe文件创建新的阻止规则。

.PARAMETER folderName
需要禁用网络访问的文件夹路径

.EXAMPLE
Disable-Network -folderName "C:\Program Files\MyApp"
#>

function Disable-Network {
    param (
        # 确保参数必填
        [Parameter(Mandatory = $true)]
        # 验证文件夹路径合法
        [ValidateScript({
                if (-not (Test-Path $_ -PathType Container)) {
                    throw "Folder '$_' does not exist or is not a directory."
                }
                return $true
            })]
        [string] $folderName
    )

    try {
        Write-Host "Processing folder: $folderName" -ForegroundColor Yellow

        # 删除已存在的防火墙规则
        Write-Host "Removing existing firewall rules..." -ForegroundColor Cyan
        Remove-NetFirewallRule -DisplayName "Sogou Pinyin Service" -ErrorAction SilentlyContinue
        $displayName = "blocked $folderName via script"
        $removedRules = Remove-NetFirewallRule -DisplayName $displayName -ErrorAction SilentlyContinue

        # 遍历文件夹中所有exe文件，为每个文件创建入站和出站阻止规则
        Write-Host "Searching for .exe files..." -ForegroundColor Cyan
        $exeFiles = Get-ChildItem -Path $folderName -Recurse -Filter "*.exe" -ErrorAction SilentlyContinue

        if ($exeFiles.Count -eq 0) {
            Write-Warning "No .exe files found in $folderName"
            return
        }

        Write-Host "Found $($exeFiles.Count) .exe files. Adding firewall rules..." -ForegroundColor Cyan
        $count = 0
        $successCount = 0

        foreach ($file in $exeFiles) {
            try {
                # 创建入站规则
                New-NetFirewallRule `
                    -DisplayName $displayName `
                    -Direction Inbound `
                    -Program $file.FullName `
                    -Action Block `
                    -ErrorAction Stop `
                | Out-Null

                # 创建出站规则
                New-NetFirewallRule `
                    -DisplayName $displayName `
                    -Direction Outbound `
                    -Program $file.FullName `
                    -Action Block `
                    -ErrorAction Stop `
                | Out-Null

                $count += 2
                $successCount += 1
                Write-Host "  ✓ Added rules for $($file.Name)" -ForegroundColor Green
            }
            catch {
                Write-Warning "Failed to create firewall rules for $($file.FullName): $($_.Exception.Message)"
            }
        }

        Write-Host "Successfully added $count rules for $successCount files" -ForegroundColor Green
    }
    catch {
        throw "Failed to disable network for folder '$folderName': $($_.Exception.Message)"
    }
}

try {
    # 设置默认文件夹路径
    $folderName = "C:\Program Files (x86)\SogouInput"

    # 提示用户输入文件夹路径，如果直接回车则使用默认路径
    $result = Read-Host "Press enter to accept default folder: $folderName"
    if ($result -ne '') {
        $folderName = $result
    }

    # 调用函数禁用网络访问权限
    Write-Host "Starting network blocking process..." -ForegroundColor Yellow
    Disable-Network -folderName $folderName

    Write-Host "Processing second folder..." -ForegroundColor Yellow
    Disable-Network -folderName "C:\Windows\SysWOW64\IME\SogouPY"

    Write-Host "Network access blocking completed successfully." -ForegroundColor Green
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    exit 1
}
