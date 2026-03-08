#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    禁用搜狗输入法相关 exe 文件的网络访问权限

.DESCRIPTION
    通过创建 Windows 防火墙阻止规则，阻断指定目录及其子目录中所有 .exe 文件的网络连接。
    所有规则统一归入分组 "DisableSogouNetwork"，便于批量管理与精准删除。
    重复运行前会自动清除同组旧规则，确保幂等性，不会造成规则膨胀。

.PARAMETER MainFolder
    主目录路径。若不传入，脚本将交互提示，直接回车使用默认值
    C:\Program Files (x86)\SogouInput

.PARAMETER ExtraFolders
    额外需要处理的目录列表（默认含 C:\Windows\SysWOW64\IME\SogouPY）。
    若某目录不存在，会输出警告并跳过，不影响其他目录的处理。

.PARAMETER DirectionMode
    防火墙规则方向：
      Both        - 同时阻断入站和出站（默认）
      OutboundOnly - 仅阻断出站

.EXAMPLE
    .\run.ps1
    # 交互式输入，回车使用默认路径，同时阻断入站+出站

.EXAMPLE
    .\run.ps1 -MainFolder "D:\SogouInput" -DirectionMode OutboundOnly
    # 指定目录，仅阻断出站流量
#>

param (
    [string]   $MainFolder    = '',
    [string[]] $ExtraFolders  = @('C:\Windows\SysWOW64\IME\SogouPY'),
    [ValidateSet('Both', 'OutboundOnly')]
    [string]   $DirectionMode = 'Both'
)

$script:GroupName = 'DisableSogouNetwork'

function Add-BlockRule {
    <#
    .SYNOPSIS 为指定目录下的所有 .exe 添加防火墙阻断规则。
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $FolderPath,

        [ValidateSet('Both', 'OutboundOnly')]
        [string] $Mode = 'Both'
    )

    if (-not (Test-Path -Path $FolderPath -PathType Container)) {
        Write-Warning "目录不存在，已跳过：$FolderPath"
        return
    }

    Write-Host "正在处理目录：$FolderPath" -ForegroundColor Yellow

    # 清除该目录下已有的同组规则，确保幂等
    Write-Host "  清除同目录旧规则（分组：$script:GroupName）..." -ForegroundColor Cyan
    $existingRules = Get-NetFirewallRule -Group $script:GroupName -ErrorAction SilentlyContinue
    if ($existingRules) {
        foreach ($rule in $existingRules) {
            $appFilter = $rule | Get-NetFirewallApplicationFilter -ErrorAction SilentlyContinue
            if ($appFilter -and $appFilter.Program -like "$FolderPath\*") {
                $rule | Remove-NetFirewallRule -ErrorAction SilentlyContinue
            }
        }
    }

    # 枚举目录下所有 exe 文件
    $exeFiles = Get-ChildItem -Path $FolderPath -Recurse -Filter '*.exe' -ErrorAction SilentlyContinue
    if (-not $exeFiles -or $exeFiles.Count -eq 0) {
        Write-Warning "未找到 .exe 文件：$FolderPath"
        return
    }

    Write-Host "  找到 $($exeFiles.Count) 个 .exe 文件，正在创建阻断规则..." -ForegroundColor Cyan
    $addedRules = 0
    $addedFiles = 0

    foreach ($file in $exeFiles) {
        try {
            # 出站阻断规则（始终创建）
            New-NetFirewallRule `
                -DisplayName "$script:GroupName - $($file.FullName) [Outbound]" `
                -Group $script:GroupName `
                -Direction Outbound `
                -Program $file.FullName `
                -Action Block `
                -ErrorAction Stop | Out-Null
            $addedRules++

            if ($Mode -eq 'Both') {
                # 入站阻断规则
                New-NetFirewallRule `
                    -DisplayName "$script:GroupName - $($file.FullName) [Inbound]" `
                    -Group $script:GroupName `
                    -Direction Inbound `
                    -Program $file.FullName `
                    -Action Block `
                    -ErrorAction Stop | Out-Null
                $addedRules++
            }

            $addedFiles++
            Write-Host "    [+] $($file.Name)" -ForegroundColor Green
        }
        catch {
            Write-Warning "为 '$($file.FullName)' 创建规则失败：$($_.Exception.Message)"
        }
    }

    Write-Host "  已为 $addedFiles 个文件成功创建 $addedRules 条规则。" -ForegroundColor Green
}

# ── 主流程 ────────────────────────────────────────────────────────────────────

# 若未通过参数传入主目录，则交互提示
$defaultMain = 'C:\Program Files (x86)\SogouInput'
if ($MainFolder -eq '') {
    $userInput = Read-Host "请输入搜狗输入法目录（直接回车使用默认：$defaultMain）"
    $MainFolder = if ($userInput -ne '') { $userInput } else { $defaultMain }
}

Write-Host ''
Write-Host '=== 开始禁用搜狗输入法网络访问 ===' -ForegroundColor Yellow
Write-Host "主目录    ：$MainFolder" -ForegroundColor Cyan
Write-Host "方向模式  ：$DirectionMode" -ForegroundColor Cyan
Write-Host "规则分组  ：$script:GroupName" -ForegroundColor Cyan
Write-Host ''

# 处理主目录
Add-BlockRule -FolderPath $MainFolder -Mode $DirectionMode

# 处理额外目录（不存在时仅警告，不中断）
foreach ($folder in $ExtraFolders) {
    Write-Host ''
    Add-BlockRule -FolderPath $folder -Mode $DirectionMode
}

Write-Host ''
Write-Host '=== 完成 ===' -ForegroundColor Green
Write-Host "所有规则已归入分组：'$script:GroupName'" -ForegroundColor Cyan
Write-Host "提示：可在「Windows Defender 防火墙 -> 高级安全设置」中按分组筛选查看规则。" -ForegroundColor Cyan
Write-Host '如需卸载，请以管理员身份运行 uninstall.ps1' -ForegroundColor Cyan
