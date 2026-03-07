#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    移除由 run.ps1 创建的所有搜狗输入法防火墙阻断规则

.DESCRIPTION
    删除所有属于 "DisableSogouNetwork" 分组的防火墙规则（由新版 run.ps1 创建）。
    同时兼容删除旧版本脚本（未使用分组标记）所创建的规则（通过 DisplayName 匹配）。
    本脚本不会创建任何新的 Allow 规则，仅执行清除操作。

.EXAMPLE
    .\uninstall.ps1
#>

$script:GroupName = 'DisableSogouNetwork'

Write-Host '=== 卸载 DisableSogouNetwork 防火墙规则 ===' -ForegroundColor Yellow
Write-Host ''

# 删除新版本规则（按分组）
Write-Host "正在删除分组 '$script:GroupName' 中的所有规则..." -ForegroundColor Cyan
$newRules = Get-NetFirewallRule -Group $script:GroupName -ErrorAction SilentlyContinue
if ($newRules) {
    $newCount = ($newRules | Measure-Object).Count
    $newRules | Remove-NetFirewallRule -ErrorAction SilentlyContinue
    Write-Host "  已删除 $newCount 条规则（新版，分组：$script:GroupName）。" -ForegroundColor Green
}
else {
    Write-Host "  未找到新版规则（分组：$script:GroupName）。" -ForegroundColor Gray
}

# 兼容删除旧版本规则（按 DisplayName 匹配，分两批查询以避免全量枚举）
Write-Host '正在检测并删除旧版规则（兼容模式）...' -ForegroundColor Cyan
$legacyExact    = Get-NetFirewallRule -DisplayName 'Sogou Pinyin Service' -ErrorAction SilentlyContinue
$legacyWildcard = Get-NetFirewallRule -DisplayName 'blocked * via script'  -ErrorAction SilentlyContinue
$legacyRules    = @($legacyExact) + @($legacyWildcard) | Where-Object { $_ }
if ($legacyRules) {
    $legacyCount = ($legacyRules | Measure-Object).Count
    $legacyRules | Remove-NetFirewallRule -ErrorAction SilentlyContinue
    Write-Host "  已删除 $legacyCount 条旧版规则。" -ForegroundColor Green
}
else {
    Write-Host '  未找到旧版规则。' -ForegroundColor Gray
}

Write-Host ''
Write-Host '=== 卸载完成！防火墙阻断规则已清除，搜狗输入法可恢复联网。===' -ForegroundColor Green
