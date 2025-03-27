# 建立网络防火墙，阻止搜狗输入法使用网络

你可能低估了输入法的风险，去搜一下“搜狗输入法 安全”吧

[人民网：这些被下架的输入法该醒醒了](http://opinion.people.com.cn/n1/2021/0616/c431649-32132196.html)

[网安：搜狗输入法有严重漏洞 请立即升级](https://www.wangan.com/p/11v78fa939048b1d)

[蓝点网：7 年后搜狗输入法依然存在严重问题 上传用户输入内容且加密系统可被监听](https://www.landiannews.com/archives/99829.html)

担心输入法收集您的个人隐私么？试试这个工具，一键阻断输入法使用网络，保护您的个人隐私。

### Windows

适用于 Win10，Win11

使用方法

1. 先安装搜狗输入法，更新到最新版本，设置好皮肤等一切。
2. 以管理员身份运行 `run.ps1`，输入您的搜狗输入法目录，一般是：`C:\Program Files (x86)\SogouInput`，可以直接回车，执行完毕后您的搜狗输入法将不再联网。
3. 如果您想继续让输入法联网，可以以管理员身份运行`uninstall.ps1`，输入您的搜狗输入法目录，一般是：`C:\Program Files (x86)\SogouInput`，可以直接回车，执行完毕后您的搜狗输入法的网络即可恢复联网。

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

如果想取消，删除这些入站规则和出站规则即可。

### iPhone

如果您用的是苹果手机，在设置->搜狗输入法，关闭无线数据即可

![](./.resource/iOS.PNG)

#### 热心老板请我喝杯咖啡，请随意！

| ![pay_tencent](./.resource/pay_tencent.png) | ![pay_ali](./.resource/pay_ali.png) |
| ------------------------------------------- | ----------------------------------- |

**如果你觉得这个工具有用，麻烦请 Star，如果您有意见或者建议，欢迎提 Issue！**

您的支持是我坚持的动力，感谢！

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=yongxin-ms/DisableSogouNetwork&type=Date)](https://www.star-history.com/#yongxin-ms/DisableSogouNetwork&Date)



## 以下是开源项目的赞助名单：



| 赞助时间               | 赞助人   | 赞助金额                                              | 赞助渠道&留言 |
| ---------------------- | -------- | ----------------------------------------------------- | ------------- |
| 2025年3月27日 09:38:42 | 阿游 | **6.66** |**微信赞赏码：感谢大佬分享，把这输入法治得服服帖帖😍**|
|                        |          |                                                       |               |
