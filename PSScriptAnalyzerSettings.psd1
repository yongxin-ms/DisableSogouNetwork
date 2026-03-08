@{
    # 排除对交互式脚本使用 Write-Host 的警告（本项目为终端交互脚本，Write-Host 为有意为之）
    ExcludeRules = @(
        'PSAvoidUsingWriteHost',
        'PSUseShouldProcessForStateChangingFunctions'
    )
}
