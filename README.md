# 建立网络防火墙，阻止输入法使用网络

担心输入法收集您的个人隐私么？试试这个工具，一键阻断输入法使用网络，保护您的个人隐私。



### Windows

适用于Win10，Win11

使用方法

1. 先安装搜狗输入法，更新到最新版本，设置好皮肤等一切。
2. 以管理员身份运行 `run.ps1`，输入您的搜狗输入法目录，一般是：`C:\Program Files (x86)\SogouInput`，可以直接回车，此时您的搜狗输入法将不再联网。
4. 如果您想继续让输入法联网，可以删除inbound和outbound中以`Blocked C:\Program Files (x86)\SogouInput via script`命名的几十条防火墙记录。




如果您打开控制面板的Windows Defender 防火墙

![](./.resource/control-panel.png)



会发现对C:\Program Files (x86)\SogouInput里面的所有可执行文件，创建了一系列入站规则，防止外网数据流入

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

