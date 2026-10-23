# DigiVice（Apple Watch 暴龙机复刻）

watchOS 独立 app。复刻初代 Digital Monster Ver.1 的机制，按手表的使用节奏重做输入与时间模型。

## 跑起来

```bash
xcodebuild -scheme DigimonWatch -configuration Debug \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 12 (46mm)' \
  -derivedDataPath ./build CODE_SIGNING_ALLOWED=NO build

D=$(xcrun simctl list devices available | grep "Apple Watch Series 12 (46mm)" | grep -oE '[0-9A-F-]{36}')
xcrun simctl boot $D
xcrun simctl install $D build/Build/Products/Debug-watchsimulator/DigimonWatch.app
xcrun simctl launch $D com.serena.digimonwatch
```

## 内核自测（不需要手表）

```bash
./Tests/run.sh
```

16 项断言覆盖：孵化、阶段推进、失误产生、进化后计数清零、结算幂等、睡眠暂停计时、0 失误 → AGUMON、训练 ≥32 → GREYMON、Perfect 需战斗积累。

## 结构

```
DigimonWatch/
  Core/           纯值类型，无 UI 依赖，可脱离 Xcode 单测
    Tuning.swift     ← 所有玩法数值。改玩法先改这里
    World.swift      状态
    Simulator.swift  时间结算内核（逐分钟推进，睡眠暂停）
    Evolution.swift  Ver.1 进化表
    Persistence.swift 单 JSON，落在 App Group 容器
  UI/
    RootView.swift   主屏 + Crown 选择 + 详情页
    LCDView.swift    16×16 点阵屏（Canvas）+ 心形条
    Sprites.swift    字符画精灵
    Theme.swift      色阶
```

## 三条设计铁律

1. **Core 不知道"现在几点"**：所有时间由参数传入，所以 5 天可以压成 1 秒来测。
2. **Tick 幂等**：同一 `now` 调两次结果一致（已验证）。
3. **跨时段的变化必须产生 SimEvent**，UI 才能解释"你不在时发生了什么"。

## 三线驱动

进化进度不是"分钟"，而是**驱动分钟**：三个源各自折算后加权求和。

| 线 | 输入 | 折算 | 除了进度还影响 |
|---|---|---|---|
| 时间 | 真实清醒分钟 | 1 分钟 = 1 驱动分钟 | 饥饿、力量衰减、便便、睡眠、失误窗口 |
| 健康 | HealthKit 当日步数增量 | 100 步 = 1 驱动分钟 | 每 30 驱动分钟补 1 颗力量心 |
| Token | 手表内对话的 `usage.total_tokens` | 300 token = 1 驱动分钟 | 每 40 驱动分钟补 0.05 努力值 |

权重在 `Tuning.weights`，`time=1, health=0, token=0` 时与经典复刻完全一致。蛋的孵化固定按真实时间走，不受权重影响——关掉时间线是为了不让时间推动进化，不是为了永远孵不出来。

**为什么不让三线都加到同一个进度里**：那样健康线和 token 线只是加速器，时间线照样推着宠物走，等于没做。所以每条线还各自驱动不同的属性：健康补力量、token 补努力。

### Token 数据从哪来

**只统计手表内的对话消耗**，不接任何外部端点。

- 单次问答约 300–600 token，换算 300 token = 1 驱动分钟，也就是「聊一次约长 1–2 分钟」
- 每天计入上限 `Tuning.dailyTokenCap = 20000`，超出不计——否则反复刷对话就能把进化硬刷出来，养成节奏就废了
- 额度按本地日期重置（`tokenDay` / `tokenDayUsed`）

DeepSeek 官方只有 `GET /user/balance` 查余额，没有 token 用量查询接口，所以外部用量本来就拿不到；限定在 app 内反而让账本是精确的。

### 对话

`Core/Drivers/DeepSeekClient.swift`，模型 `deepseek-flash`。`persona(for:)` 把世界状态（阶段、饥饿、力量、心情、便便、伤势）拼成 system prompt，所以它会照着当前状态说话。只带最近 6 轮上下文。

Key 存 Keychain（不是 UserDefaults，手表会同步到 iCloud）。

## 美术资源

**15 张精灵全部自绘**，不含任何官方像素。源码在 `Art/build.py`（字符矩阵 + 统一调色板 + 行宽校验），跑 `python3 Art/build.py` 重新生成到 `Resources/Sprites/`。

风格参照 Digital Monster Color 的 16×16 彩色语言：1px 暗轮廓、左上 45° 光源、每种材质独立 3 级色阶、不用抗锯齿、不用抖动。颜色系沿用（黄/橙/绿/蓝/紫黑），造型原创。

规范见 vault 的 `16x16数码兽像素规范`。

### 已知不足

造型的可识别性还没到位。16×16 上表达"生物结构"靠两件事，目前只做到一半：

- ✅ 每个部件有亮/暗面
- ❌ **部件之间的深缝**（官方用近黑色分隔头/身/四肢，是唯一能表达结构的手段）
- ❌ **剪影的突出物**（角、耳、爪、尾——没有这些就只是一个色块）

Agumon 和 Greymon 的剪影还不够"恐龙"，需要再迭代 2–3 轮。

## 通知

`Core/Schedule.swift` 前向预测"下一个值得叫醒你的时刻"（饥饿归零 / 力量归零 / 进化 / 孵化），`Core/Notifier.swift` 据此只保留**一条**待发通知，每次结算后重排——watchOS 待发配额紧张，不能一次排满。

重排有 5 分钟节流；喂食、训练、新建之后强制重排，否则提醒还指向旧状态。

## 尚未实现（按优先级）

1. **战斗**：Ver.1 的 Perfect 阶段要求 `battles ≥ 15 且胜率 ≥ 40%`，判定已写好，但没有战斗界面与命中率模型。
3. **Complication**：App Group 容器已就位，缺 WidgetKit extension。
4. **音效 / 触感细化**：只有 click 一种反馈。
