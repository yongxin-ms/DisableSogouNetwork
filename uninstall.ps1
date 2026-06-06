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
    # 定义要拒绝的权限：读取 & 执行
    $denyRight = [System.Security.AccessControl.FileSystemRights]::Read -bor [System.Security.AccessControl.FileSystemRights]::ExecuteFile
    $denyRule = [System.Security.AccessControl.AccessControlType]::Deny
    # 普通用户组 Users (SID:S-1-5-32-545)
    $userGroup = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-545")

    foreach ($file in $exeFiles) {
        try {
            if ($exeList -contains $file.Name) {
                # 获取当前访问控制列表
                $acl = Get-Acl -Path $file.FullName
                # 创建新的拒绝访问规则
                $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($userGroup, $denyRight, $denyRule)
                # 将拒绝规则从 ACL 中移除
                $acl.RemoveAccessRule($accessRule)
                # 将修改后的 ACL 应用回文件
                Set-Acl -Path $file.FullName -AclObject $acl
                Write-Host "    [权限] 已恢复 Users 组对 '$($file.Name)' 的读取和执行权限。" -ForegroundColor Green
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
