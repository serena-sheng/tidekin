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

## 尚未实现（按优先级）

1. **通知**：Call 目前只在 app 内显示，离开 app 就静默。需要 `UNUserNotificationCenter` 排下一个事件（滚动续排，单个）。
2. **战斗**：Ver.1 的 Perfect 阶段要求 `battles ≥ 15 且胜率 ≥ 40%`，判定已写好，但没有战斗界面与命中率模型。
3. **Complication**：App Group 容器已就位，缺 WidgetKit extension。
4. **音效 / 触感细化**：只有 click 一种反馈。
