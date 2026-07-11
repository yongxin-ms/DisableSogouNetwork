# 建立网络防火墙，阻止搜狗输入法使用网络

你可能低估了输入法的风险，去搜一下“搜狗输入法 安全”吧

[人民网：这些被下架的输入法该醒醒了](http://opinion.people.com.cn/n1/2021/0616/c431649-32132196.html)

[网安：搜狗输入法有严重漏洞 请立即升级](https://www.wangan.com/p/11v78fa939048b1d)

[蓝点网：7 年后搜狗输入法依然存在严重问题 上传用户输入内容且加密系统可被监听](https://www.landiannews.com/archives/99829.html)

担心输入法收集您的个人隐私么？试试这个工具，一键阻断输入法使用网络，保护您的个人隐私。



*****************************************************

## Update

为了不被打扰的使用输入法，防止各种不小心误升级（比如使用了代理），对当前用户禁用了以下程序的执行权限：

- SogouPlayLauncher.exe
- SGWangzai.exe
- SGSmartAssistant.exe
- SGDownload.exe
- PinyinUp.exe

这样及时使用了代理，即使误点击，输入法也不会被更新、被改变，避免被各种广告等骚扰。

*******************************************************



### Windows

适用于 Win10，Win11

#### 使用方法

1. 先安装搜狗输入法，更新到最新版本，设置好皮肤等一切。
2. 以管理员身份运行 `run.ps1`，按提示输入搜狗输入法目录（一般是 `C:\Program Files (x86)\SogouInput`），直接回车使用默认路径。执行完毕后搜狗输入法将不再联网。
3. 如需恢复联网，以管理员身份运行 `uninstall.ps1`，脚本会自动删除所有本工具创建的防火墙规则，无需输入任何路径。

#### 高级用法

```powershell
# 仅阻断出站流量（不阻断入站）
.\run.ps1 -DirectionMode OutboundOnly

# 指定自定义目录
.\run.ps1 -MainFolder "D:\SogouInput"

# 同时指定额外目录（覆盖默认的 ExtraFolders）
.\run.ps1 -ExtraFolders @('C:\Windows\SysWOW64\IME\SogouPY', 'D:\OtherSogouDir')
```

#### 防火墙规则管理

所有由 `run.ps1` 创建的规则均归入分组 **`DisableSogouNetwork`**，可在
「Windows Defender 防火墙 → 高级安全设置」中按分组筛选查看，也可通过以下 PowerShell 命令管理：

```powershell
# 查看所有已创建的规则
Get-NetFirewallRule -Group 'DisableSogouNetwork'

# 手动批量删除所有规则
Remove-NetFirewallRule -Group 'DisableSogouNetwork'
```

重复运行 `run.ps1` 不会导致规则膨胀——每次运行前会自动清除同组旧规则再重新创建。

如果您打开控制面板的 Windows Defender 防火墙

![](./.resource/control-panel.png)

会发现对 C:\Program Files (x86)\SogouInput 里面的所有可执行文件，创建了一系列入站规则，防止外网数据流入

![](./.resource/inbound.png)

创建了一系列出站规则，防止内网数据流出

![](./.resource/outbound.png)

因为禁用了网络，此时您的今日输入不会更新到您其他电脑上

![](./.resource/input-update-disabled.png)

因为禁用了网络，输入法升级会失败

![](./.resource/upgrade-disabled.png)

如果想取消，运行 `uninstall.ps1` 即可一键清除所有阻断规则。

### iPhone

如果您用的是苹果手机，在设置->搜狗输入法，关闭无线数据即可

![](./.resource/iOS.PNG)



#### 热心老板请我喝杯咖啡，请随意！

| ![pay_tencent](./.resource/pay_tencent.png) | ![pay_ali](./.resource/pay_ali.png) |
| ------------------------------------------- | ----------------------------------- |

**如果你觉得这个工具有用，麻烦请 Star，如果您有意见或者建议，欢迎提 Issue！**

您的支持是我坚持的动力，感谢！

[![Powered by DartNode](https://dartnode.com/branding/DN-Open-Source-sm.png)](https://dartnode.com "Powered by DartNode - Free VPS for Open Source")

## Star History

[![Star History](https://raw.githubusercontent.com/yongxin-ms/DisableSogouNetwork/metrics/metrics.svg)](https://github.com/yongxin-ms/DisableSogouNetwork/stargazers)
