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

Write-Host ''
Write-Host '=== 卸载完成！防火墙阻断规则已清除，搜狗输入法可恢复联网。===' -ForegroundColor Green
