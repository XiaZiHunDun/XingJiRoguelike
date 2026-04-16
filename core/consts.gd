# core/consts.gd
# 游戏常量定义 - Phase 0

extends Node

# ==================== ATB相关 ====================
const ATB_MAX_VALUE: float = 1000.0
const ATB_THRESHOLD: float = 5.0  # ATB变化阈值

const BULLET_TIME_SCALE: float = 0.1  # 子弹时间倍率
const TIME_SAND_MAX: int = 3  # 最大时砂
const TIME_SAND_PAUSE_DURATION: float = 3.0  # 时砂暂停持续时间

const SPEED_SOFT_CAP: float = 200.0  # 速度软上限
const SPEED_BONUS_TO_KINETIC: float = 0.01  # 超速转化为动能的比例

# ==================== 属性相关 ====================
const ATB_SOFT_CAP: float = 300.0  # ATB速度软上限 (专家建议: 250→300)
const ATB_OVERFLOW_MULTIPLIER: float = 0.005  # 超ATB软上限转化为伤害的比例(0.5% per point over cap) (专家建议: 1%→0.5%)

# 共鸣系统
const ATB_ULTIMATE_THRESHOLD: float = 300.0  # 速度共鸣高级效果激活所需的ATB速度

const ATTRIBUTE_GROWTH = {
	"体质": 3.0,    # HP = 100 + 体质 * 8
	"精神": 2.5,   # Energy = 5 + 精神 * 0.5
	"敏捷": 2.5    # ATB = 100 + 敏捷 * 3
}

# ATB时机加成
const ATB_PERFECT_TIMING: float = 0.90  # 完美时机阈值
const ATB_HASTY_PENALTY: float = 0.70  # 仓促惩罚阈值
const PERFECT_TIMING_BONUS: float = 0.15  # 完美时机伤害加成
const HASTY_PENALTY: float = 0.20  # 仓促惩罚

# 动能加成
const KINETIC_ENERGY_CAP: float = 0.30  # 动能上限（30%）

# ==================== 战斗相关 ====================
const BASE_PLAYER_HP: int = 100
const BASE_PLAYER_ATTACK: int = 10
const BASE_PLAYER_SPEED: float = 100.0

const BASE_MAX_HP: int = 100
const BASE_MAX_ENERGY: float = 5.0

const ENERGY_MAX: int = 5  # 能量上限
const ENERGY_RESTORE_PER_TURN: int = 3  # 每ATB满恢复能量

# ==================== 装备相关 ====================
const GEM_SLOT_COUNT: int = 3  # 灵石槽数量
const ACTION_QUEUE_MAX_SIZE: int = 3  # 行动队列最大长度

# 稀有度对应词缀数量
const AFFIX_COUNT_BY_RARITY = {
	Enums.Rarity.WHITE: [1, 1],
	Enums.Rarity.GREEN: [1, 2],
	Enums.Rarity.BLUE: [2, 2],
	Enums.Rarity.PURPLE: [2, 3],
	Enums.Rarity.ORANGE: [3, 3],
	Enums.Rarity.RED: [3, 4]
}

# ==================== UI相关 ====================
const MAX_HAND_SIZE: int = 8  # 最大手牌数量

# ==================== 局外成长 ====================
const STARDUST_MAX_BONUS: float = 0.15  # 星尘最大加成（15%）

# 记忆碎片：与 UI/事件总线同步时的参考上限（经济系统定稿后可替换为真实上限）
const MEMORY_FRAGMENTS_REFERENCE_MAX: int = 9999
