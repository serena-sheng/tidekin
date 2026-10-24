# IP 角色体系：潮线（Whale Line）

> 目标：用一套原创「鲸·潮·深」系角色替换现有数码兽 IP，直接落到 `Evolution.swift` 的六阶段模型与 32×32 像素管线。本文件是规格，不含代码改动。

## 0. 谁 / 在做什么 / 为什么现在
- **谁**：DigiVice 开发者。
- **任务**：把被 5.2.1 判 `blocked` 的数码宝贝二创换成原创「AI 娘化鲸」形象体系。
- **触发**：上架评审结论是「不认二创只认授权」，必须换内容、不能只改名字。

## 1. 现状约束（已核对代码）
- 六阶段枚举：`Tuning.swift` 的 `Stage`（egg/baby1/baby2/child/adult/perfect）。
- 物种是 `String`，映射到 `Resources/Sprites/<id>.png` / `<id>32.png` / `<id>_b.png`（见 `UI/SpriteStore.swift`）。
- 图鉴 `Characters.table`（`Core/Characters.swift`）决定显示名，换 IP 只改这里 + 换 PNG。
- 进化分支：`Evolution.swift` 的 `species(for:)` / `adultSpecies` / `perfectSpecies`。
- 三线驱动：`Tuning.swift` 的 `DriveWeights`（time/health/token），折算成 `driveMinutes`。
- 32×32 管线：`Art/build32_b.py`，材质三阶（高光/中间调/暗部）+ 1px 暗轮廓 + 45° 光源；`BODY` 材质现含 `blue`/`cyan`/`cream`，已够用，仅需新增一枚深海军蓝 `deep`。

## 2. 边界
- **在范围内**：12 个原创形态的命名、设定、32×32 视觉处方、六阶段进化条件映射、成长弧线。
- **非目标**：不改代码、不重画像素（只给处方）；不修既有 bug；不处理上架申诉文案。

## 3. 命名体系（12 形态，零商标）

| 阶段 | id（=资源名，小写） | 英文 | 中文 | 一句设定 |
|---|---|---|---|---|
| egg | `tideseed` | TIDESEED | 潮种 | 蓝白潮纹蛋，里面是「你与模型关系」的种子 |
| baby1 | spume | SPUME | 沫沫 | 破壳的浮沫团，只会冒泡；你开始消耗 token，它开始「有意识」 |
| baby2 | calf | CALF | 鲸苗 | 长出鲸尾与腹白，追着你的光标游 |
| child | cetal | CETAL | 汐仔 | 被好好照顾的幼鲸，额纹初现光标形 |
| child | mael | MAEL | 涡仔 | 疏于照顾的幼鲸，额纹拧成漩涡、眼神疏离 |
| adult | current | CURRENT | 游潮 | 平衡成长的基准鲸，白腹完整、背鳍流线 |
| adult | breacher | BREACHER | 跃潮 | 训练线点满的跃浪鲸，肌肉化、鳍变刃 |
| adult | abyss | ABYSS | 潜渊 | token 线点满的深潜鲸，体色转暗、额纹亮成光标 |
| adult | drift | DRIFT | 漂雾 | 失养漂流的灰鲸，褪色、乱流、懒散 |
| perfect | kun | KUN | 鲲 | 深线极点：读尽万卷，化鲲待鹏 |
| perfect | kraken | KRAKEN | 沧主 | 力线极点：翻江倒海的深海霸主 |
| perfect | siren | SIREN | 歌潮 | 均衡极点：会唱歌的潮汐精灵 |

> 商标检查：全部为通用英文词 / 中国古代神话（鲲）/ 北欧神话（Kraken）/ 希腊神话（Siren），无 AI 商标、无 Bandai 角色名。`TIDESEED` 为避「Tide Pods」洗衣液商标而刻意弃用 `TIDEPOD`。

## 4. 32×32 视觉处方

**贯穿全弧线的识别元素**（保证读起来是同一只）：
- 白腹（`cream` 材质，中间调 `#EAE8E0`）
- 额头光标纹「▍」（`cyan` 材质，`#3CC8C8`，随成长变长、变亮——AI 提示符语汇）
- 蓝白配色 + 左 45° 光源

| 形态 | 主色 hex（中间调） | 动物特征 | 识别元素保留 | 与上一阶段差异 |
|---|---|---|---|---|
| TIDESEED 潮种 | `#2A7AB0` | 蛋，白潮纹缠绕 | 内隐一点 `#3CC8C8` 光标光点 | 无（起点） |
| SPUME 沫沫 | `#7FD0E8` | 浮沫团，无尾 | 顶部一小撮亮光 | 变浅、变软、无尾 |
| CALF 鲸苗 | `#2A7AB0` | 小鲸尾 + 首次出现白腹 | 白腹确立 | 长尾 + 白腹 |
| CETAL 汐仔 | `#2A7AB0` | 幼鲸，鳍成形 | 额纹短光标「▍」初现 | 额纹首次亮起 |
| MAEL 涡仔 | `#3A5B8C` | 幼鲸，纹路成漩涡 | 白腹保留、额纹变灰 | 主色暗一档，纹路改漩涡 |
| CURRENT 游潮 | `#2A7AB0` | 标准鲸，背鳍流线 | 白腹完整、额纹加长 | 体量放大、背鳍成流线 |
| BREACHER 跃潮 | `#1E6BB8` | 跃浪鲸，鳍刃化、肌肉线 | 白腹 + 额纹变白 | 主色更深、鳍变刃 |
| ABYSS 潜渊 | `#1C3A66`（新 `deep`） | 深潜鲸，全身转暗 | 额纹高亮 `#6BE0FF` | 转深海军蓝、额纹最亮 |
| DRIFT 漂雾 | `#7A8A99` | 灰鲸，乱流纹、眼神涣散 | 白腹褪成灰 | 褪色、软塌、乱纹 |
| KUN 鲲 | `#14283F` | 巨尾鳍如鹏翼 | 全身光标纹发光 | 体量最大、尾鳍展开成翼 |
| KRAKEN 沧主 | `#1C3A66` | 深海霸主，白角/触腕 | 额纹高亮、白腹 | 角与触腕、眼神锐利 |
| SIREN 歌潮 | `#2A7AB0` | 优雅鲸，声纹环绕 | 白腹 + 额纹 | 全身 `#3CC8C8` 声波纹 |

> 像素画师可直接按此表排布：每种形态 = 一个 32×32 标签图（材质名标注），复用 `Art/build32_b.py` 的 `BODY`/`FLAT`/`EYE_MATS` 打光渲染；仅 ABYSS/KUN 需在 `BODY` 新增 `"deep"` 三阶。

## 5. 进化条件映射（六阶段 → 新体系）

| 现有槽位 | 新形态 | 判定（改写 `Evolution.swift`） |
|---|---|---|
| egg | TIDESEED | 不变 |
| baby1 | SPUME | 不变（`eggHatchMinutes`） |
| baby2 | CALF | 不变（`baby1Minutes`） |
| child | CETAL / MAEL | `careMistakes <= 3 ? cetal : mael`（沿用原 `AGUMON:BETAMON` 逻辑，只换名） |
| adult | 四选一 | 见下方 `adultSpecies` 新逻辑 |
| perfect | 三选一 | `battles >= 15 && winRate >= 0.4` 门槛不变，`adult → perfect` 映射换名 |

**`adultSpecies` 新逻辑（替换现有 7 分支）**：

```
if careMistakes > 3            → DRIFT        // 失养
else if trainCount >= 32       → BREACHER     // 训练线（沿用原 GREYMON/DEVIMON 门槛）
else if totalTokens >= deepPathTokens → ABYSS // token 线（新增门槛）
else                           → CURRENT      // 均衡默认
```

**`perfectSpecies` 新映射**：
```
breacher → kraken；current → siren；abyss/drift → kun（沉到底，殊途同归）
```

**三线权重（`Tuning.DriveWeights`）**：`time=1, health=1, token=1` 默认值**不变**（不破坏既有节奏）；新增一个 Tuning 字段 `deepPathTokens: Int = 6000`（童年期累计消耗 token 达到即入潜渊线，约 10–20 次对话）。**token 线自此多一层含义**：既是成长加速，也决定「人格方向」（深线）。

## 6. 成长弧线：鲸 → 鲲

蛋（潮种，内隐光标光点）→ 破壳成浮沫（无尾、只会冒泡）→ 长尾 + 白腹（鲸苗，确立「鲸」的身份）→ 幼鲸额纹初现光标（好好照顾=汐仔/疏于照顾=涡仔）→ **三线驱动的成人分化**：练得多=跃潮、聊得多（token 多）=潜渊、均衡=游潮、失养=漂雾 → **战斗淬炼的完全体**：潜渊与漂雾沉到最深处化鲲（读尽万卷待鹏），跃潮成沧主（深海霸主），游潮成歌潮（会唱歌的潮汐精灵）。形象从「一团会冒泡的浮沫」一步步长成「能带你潜入海底的鲲」——**你喂给它的 token，就是它变大的水**。

## 7. 波及面（实现时同步替换，本文件不改）
- `Core/Characters.swift`：`table` 全部 12 条换名。
- `Core/Evolution.swift`：`species(for:)`/`adultSpecies`/`perfectSpecies` 按 §5 改。
- `Core/Battle.swift`：敌方名单（PUNIMON/PAGUMON/GABUMON/PATAMON/GAZIMON/BIRDRAMON/Kuwagamon/ETEMON/SKULLGREYMON/PIEDMON）也含商标名，需一并原创化并复用新 `sprite` 资源名。
- `Drivers/DeepSeekClient.swift`：人格提示词里的 `w.species` 与「数码兽」措辞需换成「住在手表里的鲸」。
- `Resources/Sprites/`：替换 12 组 `<id>32.png` / `<id>32_b.png`（旧 16×16 兜底可删）。
- 通知文案（`Core/Schedule.swift`）与显示文案引用 `w.species`，自动跟随，无需硬编码改名。

## 8. 验收标准（QA 可查，不含"读心"）
1. `grep -riE "deepseek|chatgpt|claude|gemini|kimi|agumon|greymon|devimon|koromon|botamon|betamon|tyranomon|meramon|numemon|seadramon|airdramon|metalgreymon|mamemon|monzaemon|digitama"` 在 `DigimonWatch/` 与 `Resources/Sprites/` 下返回 **0 命中**（含文件名、`Characters.swift`、`Evolution.swift`、`Battle.swift`、`DeepSeekClient.swift`、通知文案）。
2. `Characters.table` 恰好 12 条，id 全小写、无重复，每个 id 在 `Resources/Sprites/` 有 `32.png` + `32_b.png` 一对。
3. 每个形态的眨眼帧与睁眼帧仅眼睛像素不同（对齐 `Art/build32_b.py` 的 `check_blink`）。
4. 单测/模拟：`careMistakes=4` 的 child→adult 产出 `drift`；`trainCount=32` 产出 `breacher`；`totalTokens>=deepPathTokens` 产出 `abyss`；其余产出 `current`。
5. `adult`（abyss/drift）→ `kun`、`breacher`→`kraken`、`current`→`siren`，且 `battles<15` 时不进化（沿用现有 `isEligible`）。
6. 12 形态缩到一张 contact sheet 目视：额纹、白腹、蓝白配色三要素在每个形态连续可辨（不中断）。

## 9. 最可能出错的两处 + 最便宜的检查
1. **商标残留**（旧数码兽名/新 AI 商标藏在文件名或提示词里）→ 一条 `grep -riE` 禁令清单（§8.1）即覆盖。
2. **识别元素断裂**（12 只读起来不是同一只）→ 全部 32×32 精灵拼一张 contact sheet，肉眼扫三要素连续性（§8.6）。
