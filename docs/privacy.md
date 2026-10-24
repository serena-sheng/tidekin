# 隐私政策 / Privacy Policy

最后更新：2026-10-24

Tidekin（中文名：潮线）是一个 Apple Watch 独立应用。本文说明它处理哪些数据、怎么处理、以及你有哪些控制权。

## 一、本地存储的数据

以下数据只存在于你的设备（以及 app 与表盘小组件共享的 App Group 容器）里，不会上传到我们：

| 数据 | 用途 | 位置 |
|---|---|---|
| 宠物状态（阶段、饥饿、力量、体重、便便、失误计数等） | 游戏功能 | App Group 的 `world.json` |
| 每日步数与 token 计数的本地累加 | 成长进度 | `UserDefaults` |
| 举报记录（你主动点「举报最近一条」时的对话原文） | 留证 | App Group 的 `reports.log` |
| 你在设置里填写的对话服务 API Key | 直连该服务 | 系统 Keychain |

我们**没有服务器**，不接收上述任何内容。

## 二、健康数据

应用会请求读取「步数」（HealthKit Step Count），仅用于把当天步数换算成力量心与成长进度。

- 只读，不写入健康数据
- 换算在本机完成
- 不上传、不共享、不用于广告或画像
- 你可以在「设置 → 健康 → 数据访问」里随时撤销

## 三、对话功能

TALK 功能是可选的，且需要你自己填写第三方对话服务的 API Key。

当你发送消息时，以下内容会直接发往**你在设置里配置的那个服务**（我们不经手）：

- 你输入的文字
- 宠物的当前状态（物种、阶段、饥饿、力量、心情等），作为让回复符合设定的上下文
- 最近 6 条对话，作为上下文

首次使用前会出现告知页，明确说明接收方与用途；不点同意不会发送任何内容。

对方服务如何存储与使用这些内容，取决于该服务自己的条款。你可以在 `consent.talk.accepted` 之外随时清空 app 数据来中止。

## 四、我们不做什么

- 不建账号，不收集邮箱或手机号
- 不做遥测、埋点、崩溃上报
- 不投放广告，不接入任何广告 SDK
- 不追踪你跨 app 或跨网站的行为
- 不读取你在其他应用或网页里的 AI 用量——没有那个接口，也没有那个权限
- 不把 API Key 发送给除你配置的服务之外的任何地方

## 五、通知

若你允许通知，应用会在本地安排提醒（饿了、要进化、受伤等），只用 `UNUserNotificationCenter` 的本地通知，不经过推送服务器。

## 六、儿童

本应用不面向 13 岁以下儿童，不含儿童专区。内容分级建议为 12+。

## 七、数据删除

- 删除 app 会一并删除 App Group 容器里的宠物数据、举报记录
- Keychain 里的 API Key 可通过「设置 → 保存 Key」清空后覆盖，或删除 app 时一并移除
- 我们没有云端副本，所以不需要额外申请删除

## 八、变更

若本政策有实质变更，会更新本文顶部的日期，并在仓库的 commit 记录中可查。

## 九、联系

通过 GitHub Issues 反馈：<https://github.com/serena-sheng/tidekin/issues>

---

# Privacy Policy (English summary)

Tidekin is a standalone Apple Watch app. **We operate no servers and collect nothing.**

- Pet state, step counts, token counters and report logs stay on your device (App Group container / UserDefaults).
- Your chat service API key is stored in the system Keychain and used only to call the service you configured.
- Step counts are read from HealthKit, converted on-device, never uploaded.
- The optional chat feature sends your text plus the pet's current state to **the third-party service you configured** — not to us. A consent screen explains this before the first message.
- No accounts, no analytics, no ads, no cross-app tracking.

Contact: <https://github.com/serena-sheng/tidekin/issues>
