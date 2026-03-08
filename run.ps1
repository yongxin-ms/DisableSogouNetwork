#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    禁用搜狗输入法相关 exe 文件的网络访问权限

.DESCRIPTION
    通过创建 Windows 防火墙阻止规则，阻断指定目录及其子目录中所有 .exe 文件的网络连接。
    所有规则统一归入分组 "DisableSogouNetwork"，便于批量管理与精准删除。
    重复运行前会自动清除同组旧规则，确保幂等性，不会造成规则膨胀。

    可选功能：阻断 v2rayN 本地代理绕过。
    当用户启用 v2rayN 等代理软件后，搜狗输入法可能通过连接本机回环代理端口（如 Mixed Port）
    将网络请求转交给代理进程，从而绕过按程序阻断的策略。
    启用此功能（BlockV2rayNProxyBypass）后，脚本会额外为每个 exe 分别创建 IPv4 与 IPv6 两条出站阻断规则，
    禁止其连接 127.0.0.1 / ::1 上指定的代理端口（默认覆盖 10808、10811、10812、10813）。
    注意：部分系统不允许为 IPv6 回环地址（::1）创建防火墙规则；此时 IPv6 规则创建失败会被单独捕获并以
    警告形式输出，脚本会继续处理其余规则，IPv4 回环规则不受影响。

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

.PARAMETER BlockV2rayNProxyBypass
    是否启用 v2rayN 本地代理绕过阻断（默认 $true）。
    启用后，会额外为每个 exe 分别创建 IPv4（127.0.0.1）与 IPv6（::1）两条出站阻断规则，
    禁止其连接本机回环地址上的 v2rayN 代理端口，防止通过代理绕过联网限制。
    若系统不支持 IPv6 回环地址规则，IPv6 规则创建失败时会输出警告并跳过，不影响整体流程。

.PARAMETER V2rayNMixedPort
    v2rayN 的 Mixed Port 端口号（默认 10808）。
    与 V2rayNExtraPortOffsets 共同决定需要阻断的端口集合。

.PARAMETER V2rayNExtraPortOffsets
    相对于 V2rayNMixedPort 的偏移量列表（默认 @(3, 4, 5)）。
    默认偏移对应：PAC Port（+3=10811）、Xray API（+4=10812）、mihomo API（+5=10813）。

.EXAMPLE
    .\run.ps1
    # 交互式输入，回车使用默认路径，同时阻断入站+出站，并启用 v2rayN 绕过阻断

.EXAMPLE
    .\run.ps1 -MainFolder "D:\SogouInput" -DirectionMode OutboundOnly
    # 指定目录，仅阻断出站流量，并启用 v2rayN 绕过阻断

.EXAMPLE
    .\run.ps1 -BlockV2rayNProxyBypass $false
    # 禁用 v2rayN 绕过阻断，仅保留原有防火墙规则

.EXAMPLE
    .\run.ps1 -V2rayNMixedPort 7890 -V2rayNExtraPortOffsets @(1, 2)
    # 使用自定义 Mixed Port 7890，额外阻断 7891、7892 端口
#>

param (
    [string]   $MainFolder               = '',
    [string[]] $ExtraFolders             = @('C:\Windows\SysWOW64\IME\SogouPY'),
    [ValidateSet('Both', 'OutboundOnly')]
    [string]   $DirectionMode            = 'Both',
    [bool]     $BlockV2rayNProxyBypass   = $true,
    [int]      $V2rayNMixedPort          = 10808,
    [int[]]    $V2rayNExtraPortOffsets   = @(3, 4, 5)
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
        [string] $Mode = 'Both',

        [bool]   $BlockV2rayNProxyBypass  = $true,
        [int]    $V2rayNMixedPort         = 10808,
        [int[]]  $V2rayNExtraPortOffsets  = @(3, 4, 5)
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

    # 预计算 v2rayN 本地代理绕过阻断端口（本次循环所有 exe 共用）
    $loopbackPorts = $null
    if ($BlockV2rayNProxyBypass) {
        $loopbackPorts = @([string]$V2rayNMixedPort) + ($V2rayNExtraPortOffsets | ForEach-Object { [string]($V2rayNMixedPort + $_) })
    }

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

            # v2rayN 本地代理绕过阻断规则（IPv4）：禁止该 exe 连接本机 IPv4 回环代理端口
            if ($BlockV2rayNProxyBypass) {
                New-NetFirewallRule `
                    -DisplayName "$script:GroupName - $($file.FullName) [BlockV2rayNLoopback IPv4]" `
                    -Group $script:GroupName `
                    -Direction Outbound `
                    -Program $file.FullName `
                    -Protocol TCP `
                    -RemoteAddress '127.0.0.1' `
                    -RemotePort $loopbackPorts `
                    -Action Block `
                    -ErrorAction Stop | Out-Null
                $addedRules++

                # v2rayN 本地代理绕过阻断规则（IPv6）：部分系统不支持 IPv6 回环地址规则，失败时仅警告并继续
                try {
                    New-NetFirewallRule `
                        -DisplayName "$script:GroupName - $($file.FullName) [BlockV2rayNLoopback IPv6]" `
                        -Group $script:GroupName `
                        -Direction Outbound `
                        -Program $file.FullName `
                        -Protocol TCP `
                        -RemoteAddress '::1' `
                        -RemotePort $loopbackPorts `
                        -Action Block `
                        -ErrorAction Stop | Out-Null
                    $addedRules++
                }
                catch {
                    Write-Warning "为 '$($file.FullName)' 创建 IPv6 loopback 规则失败（已忽略）：$($_.Exception.Message)"
                }
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
if ($BlockV2rayNProxyBypass) {
    $loopbackPortsInfo = @($V2rayNMixedPort) + ($V2rayNExtraPortOffsets | ForEach-Object { $V2rayNMixedPort + $_ })
    Write-Host "v2rayN绕过阻断：已启用（MixedPort：$V2rayNMixedPort，阻断端口：$($loopbackPortsInfo -join ', ')）" -ForegroundColor Cyan
}
else {
    Write-Host "v2rayN绕过阻断：已禁用" -ForegroundColor Cyan
}
Write-Host ''

# 处理主目录
Add-BlockRule -FolderPath $MainFolder -Mode $DirectionMode `
    -BlockV2rayNProxyBypass $BlockV2rayNProxyBypass `
    -V2rayNMixedPort $V2rayNMixedPort `
    -V2rayNExtraPortOffsets $V2rayNExtraPortOffsets

# 处理额外目录（不存在时仅警告，不中断）
foreach ($folder in $ExtraFolders) {
    Write-Host ''
    Add-BlockRule -FolderPath $folder -Mode $DirectionMode `
        -BlockV2rayNProxyBypass $BlockV2rayNProxyBypass `
        -V2rayNMixedPort $V2rayNMixedPort `
        -V2rayNExtraPortOffsets $V2rayNExtraPortOffsets
}

Write-Host ''
Write-Host '=== 完成 ===' -ForegroundColor Green
Write-Host "所有规则已归入分组：'$script:GroupName'" -ForegroundColor Cyan
Write-Host "提示：可在「Windows Defender 防火墙 -> 高级安全设置」中按分组筛选查看规则。" -ForegroundColor Cyan
Write-Host '如需卸载，请以管理员身份运行 uninstall.ps1' -ForegroundColor Cyan
