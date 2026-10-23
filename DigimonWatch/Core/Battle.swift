import Foundation

/// 对手。Ver.1 的战斗没有操作空间，纯看数值；
/// 这里给玩家留一个 Crown 蓄力的手感，但胜负仍然主要由力量和阶段决定。
struct Enemy: Codable, Equatable {
    let name: String
    let stage: Stage
    let power: Int        // 1...10
    let sprite: String    // 复用已有资源名

    static let pool: [Enemy] = [
        Enemy(name: "PUNIMON", stage: .baby2, power: 2, sprite: "koromon"),
        Enemy(name: "PAGUMON", stage: .baby2, power: 3, sprite: "betamon"),
        Enemy(name: "GABUMON", stage: .child, power: 4, sprite: "agumon"),
        Enemy(name: "PATAMON", stage: .child, power: 4, sprite: "airdramon"),
        Enemy(name: "GAZIMON", stage: .child, power: 5, sprite: "numemon"),
        Enemy(name: "BIRDRAMON", stage: .adult, power: 6, sprite: "airdramon"),
        Enemy(name: "Kuwagamon", stage: .adult, power: 7, sprite: "tyranomon"),
        Enemy(name: "ETEMON", stage: .adult, power: 7, sprite: "devimon"),
        Enemy(name: "SKULLGREYMON", stage: .perfect, power: 9, sprite: "metalgreymon"),
        Enemy(name: "PIEDMON", stage: .perfect, power: 10, sprite: "devimon"),
    ]

    /// 按玩家阶段挑一个难度相近的对手。
    static func pick(for player: World, roll: Int) -> Enemy {
        let target = max(0, player.stage.rawValue - 1)
        let candidates = pool.filter { abs($0.stage.rawValue - target) <= 1 }
        let list = candidates.isEmpty ? pool : candidates
        return list[abs(roll) % list.count]
    }
}

struct BattleState: Equatable {
    let enemy: Enemy
    var playerHP: Int
    var enemyHP: Int
    var round: Int = 0
    var lines: [String] = []
    var finished = false
    var won: Bool?

    static let maxRounds = 5

    /// 玩家血条：力量心决定，阶段给基础值
    static func playerHP(for w: World) -> Int {
        20 + w.strength * 6 + Int(w.stage.rawValue) * 4
    }

    static func start(world: World, roll: Int) -> BattleState {
        let enemy = Enemy.pick(for: world, roll: roll)
        return BattleState(
            enemy: enemy,
            playerHP: playerHP(for: world),
            enemyHP: 20 + enemy.power * 6,
            lines: ["\(enemy.name) 出现了"]
        )
    }

    /// 打一回合。`charge` 0...1 是 Crown 蓄力，`roll` 是对方出手的随机数。
    mutating func attack(charge: Double, roll: Int, player: World) {
        guard !finished else { return }
        round += 1

        let c = min(1, max(0, charge))
        let base = 4.0 + Double(player.strength) * 1.6 + Double(player.stage.rawValue) * 1.2
        let raw = base * (0.55 + c * 0.7)
        let dealt = max(1, Int(raw) - enemy.power / 2)
        enemyHP = max(0, enemyHP - dealt)

        let variance = abs(roll % 5)
        let taken = max(1, enemy.power * 2 + variance - player.strength / 2)
        // 蓄力越高越容易躲开：满蓄力有概率完全格挡
        let blocked = c > 0.85 && abs(roll % 4) == 0
        if !blocked { playerHP = max(0, playerHP - taken) }

        lines.append("你打出 \(dealt)" + (blocked ? "，格挡了反击" : "，挨了 \(taken)"))

        if enemyHP == 0 || playerHP == 0 || round >= Self.maxRounds {
            finished = true
            won = enemyHP == 0 || (playerHP > 0 && playerHP > enemyHP)
            lines.append(won == true ? "赢了" : "输了")
        }
    }
}
