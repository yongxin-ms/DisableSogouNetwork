#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    移除由 run.ps1 创建的所有搜狗输入法防火墙阻断规则

.DESCRIPTION
    删除所有属于 "DisableSogouNetwork" 分组的防火墙规则（由新版 run.ps1 创建）。
    本脚本不会创建任何新的 Allow 规则，仅执行清除操作。

.EXAMPLE
    .\uninstall.ps1
#>

param (
    [string]   $MainFolder = '',
    [string[]] $ExtraFolders = @('C:\Windows\SysWOW64\IME\SogouPY')
)

function Enable-ExeAccessRule {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $FolderPath
    )

    if (-not (Test-Path -Path $FolderPath -PathType Container)) {
        Write-Warning "目录不存在，已跳过：$FolderPath"
        return
    }

    Write-Host "正在处理目录：$FolderPath" -ForegroundColor Yellow
    # 枚举目录下所有 exe 文件
    $exeFiles = Get-ChildItem -Path $FolderPath -Recurse -Filter '*.exe' -ErrorAction SilentlyContinue
    if (-not $exeFiles -or $exeFiles.Count -eq 0) {
        Write-Warning "未找到 .exe 文件：$FolderPath"
        return
    }

    Write-Host "  找到 $($exeFiles.Count) 个 .exe 文件，正在恢复权限..." -ForegroundColor Cyan

    # 需要恢复权限的更新程序列表
    $exeList = @("SOGOUSmartAssistant.exe", "SogouPlayLauncher.exe", "SGWangzai.exe", "SGSmartAssistant.exe", "SGDownload.exe", "PinyinUp.exe")

    foreach ($file in $exeFiles) {
        try {
            if ($exeList -contains $file.Name) {
                $acl = Get-Acl $file.FullName
                $denyRules = $acl.Access | Where-Object {
                    (
                        $_.IdentityReference -like '*S-1-5-32-545*' -or
                        $_.IdentityReference -like '*Everyone*' -or
                        $_.IdentityReference -like '*BUILTIN\\Users*' -or
                        $_.IdentityReference -like '*Users*'
                    ) -and $_.AccessControlType -eq 'Deny' -and
                    ($_.FileSystemRights -band ([System.Security.AccessControl.FileSystemRights]::Read -bor [System.Security.AccessControl.FileSystemRights]::ExecuteFile))
                }
                foreach ($r in $denyRules) { $acl.RemoveAccessRuleSpecific($r) }
                try {
                    Set-Acl -Path $file.FullName -AclObject $acl
                    Start-Sleep -Milliseconds 200
                    $remaining = (Get-Acl $file.FullName).Access | Where-Object {
                        $_.IdentityReference -like '*S-1-5-32-545*' -and $_.AccessControlType -eq 'Deny' -and
                        ($_.FileSystemRights -band ([System.Security.AccessControl.FileSystemRights]::Read -bor [System.Security.AccessControl.FileSystemRights]::ExecuteFile))
                    }
                    if ($remaining -and $remaining.Count -gt 0) {
                        Write-Warning "    PowerShell 移除 Deny 规则未生效，尝试使用 icacls 回退修复：$($file.Name)"
                        & icacls $file.FullName /remove:d "Everyone" /C | Out-Null
                        & icacls $file.FullName /remove:d "Users" /C | Out-Null
                        & icacls $file.FullName /grant:r "Users:(RX)" /C | Out-Null
                        Write-Host "    [权限] 已用 icacls 恢复 Users/Everyone 对 '$($file.Name)' 的权限。" -ForegroundColor Green
                    }
                    else {
                        Write-Host "    [权限] 已恢复 Users 组对 '$($file.Name)' 的读取和执行权限。" -ForegroundColor Green
                    }
                }
                catch {
                    Write-Warning "    Set-Acl 或 icacls 操作失败：$($_.Exception.Message)"
                }
            }
        }
        catch {
            Write-Warning "    无法修改权限：$($file.FullName). 错误: $_"
        }
    }
}

$script:GroupName = 'DisableSogouNetwork'

Write-Host '=== 卸载 DisableSogouNetwork 防火墙规则 ===' -ForegroundColor Yellow
Write-Host ''

# 删除规则（按分组）
Write-Host "正在删除分组 '$script:GroupName' 中的所有规则..." -ForegroundColor Cyan
$newRules = Get-NetFirewallRule -Group $script:GroupName -ErrorAction SilentlyContinue
if ($newRules) {
    $newCount = ($newRules | Measure-Object).Count
    $newRules | Remove-NetFirewallRule -ErrorAction SilentlyContinue
    Write-Host "  已删除 $newCount 条规则（分组：$script:GroupName）。" -ForegroundColor Green
}
else {
    Write-Host "  未找到规则（分组：$script:GroupName）。" -ForegroundColor Gray
}


# 若未通过参数传入主目录，则交互提示
$defaultMain = 'C:\Program Files (x86)\SogouInput'
if ($MainFolder -eq '') {
    $userInput = Read-Host "请输入搜狗输入法目录（直接回车使用默认：$defaultMain）"
    $MainFolder = if ($userInput -ne '') { $userInput } else { $defaultMain }
}

Write-Host ''
Write-Host '=== 开始恢复搜狗输入法特定程序的执行权限 ===' -ForegroundColor Yellow
Write-Host "主目录    ：$MainFolder" -ForegroundColor Cyan

Enable-ExeAccessRule -FolderPath $MainFolder
# 处理额外目录（不存在时仅警告，不中断）
foreach ($folder in $ExtraFolders) {
    Write-Host ''
    Enable-ExeAccessRule -FolderPath $folder
}

Write-Host ''
Write-Host '=== 卸载完成！防火墙阻断规则已清除，搜狗输入法可恢复联网。===' -ForegroundColor Green
