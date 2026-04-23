# data/factions/faction_narrative_data.gd
# 势力剧情叙事数据
# 各势力背景故事和叙事事件

class_name FactionNarrativeData
extends Node

# 势力背景故事（随声望等级解锁）
const FACTION_BACKSTORIES: Dictionary = {
	"星火殿": {
		"intro": "星火殿，宇宙中最古老的修炼势力之一。传说其始祖在星陨之夜中顿悟，领悟了毁灭与新生的奥秘。",
		"理念": "追求力量，超越凡人——这是星火殿千年传承的核心信条。",
		"历史": "一万年前，星火殿的先祖在宇宙边缘发现了太初核心的碎片，从中领悟了星火的奥秘。此后，星火殿便成为追求力量者的圣地。",
		FactionQuestData.FactionReputationLevel.STRANGER: "星火殿的长老们对新来者保持警惕，你需要证明自己的价值。",
		FactionQuestData.FactionReputationLevel.FRIENDLY: "你已经获得了星火殿的初步认可。殿中的典籍开始向你敞开。",
		FactionQuestData.FactionReputationLevel.TRUSTED: "星火殿的长老们视你为同道中人，你已被允许进入星火殿的禁地——陨星熔炉。",
		FactionQuestData.FactionReputationLevel.REVERED: "你的名字已被刻入星火殿的名册，成为传说的一部分。",
		FactionQuestData.FactionReputationLevel.IDOLIZED: "星火殿的至高奥义开始向你揭开面纱，你看到了凡人难以想象的力量境界。",
		FactionQuestData.FactionReputationLevel.Zealot: "你已成为星火殿的化身，你的意志与星火同在，直至宇宙终结。"
	},
	"寒霜阁": {
		"intro": "寒霜阁，以冰霜之道著称，秉持秩序与平衡的理念，在宇宙中传承着古老的秘法。",
		"理念": "掌控秘法，秩序与平衡——寒霜阁相信，只有在绝对的秩序中，才能实现真正的和谐。",
		"历史": "寒霜阁起源于宇宙初开时的第一次大冻结。始祖在那场浩劫中领悟了寒霜之道，创立了寒霜阁，守护着秘法的传承。",
		FactionQuestData.FactionReputationLevel.STRANGER: "寒霜阁的大门对陌生人紧闭，你需要获得邀请才能踏入。",
		FactionQuestData.FactionReputationLevel.FRIENDLY: "你已被允许进入寒霜阁的外殿学习，但真正的秘法仍隐藏在深处。",
		FactionQuestData.FactionReputationLevel.TRUSTED: "寒霜阁的长老们开始向你传授控制之道的奥秘。",
		FactionQuestData.FactionReputationLevel.REVERED: "你已经触及了寒霜阁的核心秘法——绝对零度的秘密。",
		FactionQuestData.FactionReputationLevel.IDOLIZED: "寒霜阁的终极奥义在你面前展现，你看到了宇宙秩序的本源。",
		FactionQuestData.FactionReputationLevel.Zealot: "你已成为寒霜之道的化身，宇宙的秩序因你而更加稳固。"
	},
	"机魂教": {
		"intro": "机魂教，一个将机械与灵魂融合的势力。他们相信，肉身终将腐朽，唯有机械与灵魂的结合才能永恒。",
		"理念": "机械至上，科技复兴——这是机魂教对宇宙的解答。",
		"历史": "机魂教诞生于一次失败的炼金实验。当古老的机械被注入了灵魂，它们开始拥有了自己的意志。机魂教由此诞生，探索着机械与生命的终极奥秘。",
		FactionQuestData.FactionReputationLevel.STRANGER: "机魂教的成员对外人保持谨慎，他们的机械造物可能对外来者充满敌意。",
		FactionQuestData.FactionReputationLevel.FRIENDLY: "你已被允许参观机魂教的工坊，但仍有许多禁区不可踏入。",
		FactionQuestData.FactionReputationLevel.TRUSTED: "机魂教的工程师们开始向你展示他们的核心科技——灵魂矩阵。",
		FactionQuestData.FactionReputationLevel.REVERED: "你已经理解了机魂教的真正理想——将灵魂从肉体的束缚中解放。",
		FactionQuestData.FactionReputationLevel.IDOLIZED: "机魂教的最高机密——永生熔炉，向你揭开了它神秘的面纱。",
		FactionQuestData.FactionReputationLevel.Zealot: "你已成为机魂与机械的完美结合体，超越了生与死的界限。"
	},
	"守墓人": {
		"intro": "守墓人，守护着宇宙最古老秘密的神秘势力。他们隐藏在虚空之中，等待着某个命中注定的时刻。",
		"理念": "守护秘密，阻止外人离去——守墓人的使命是保护不应该被知晓的真相。",
		"历史": "守墓人的起源已不可考据。有人说他们是最古老的宇宙文明的后裔，有人说他们是虚空本身意志的化身。唯一确定的是，他们守护着太初核心最深处的秘密。",
		FactionQuestData.FactionReputationLevel.STRANGER: "守墓人是虚空中的幽影，他们会毫不留情地消灭任何闯入者。",
		FactionQuestData.FactionReputationLevel.FRIENDLY: "守墓人开始用异样的眼光注视你，似乎在评估你的资格。",
		FactionQuestData.FactionReputationLevel.TRUSTED: "守墓人的一些秘密开始向你透露，但仍有更深的真相隐藏着。",
		FactionQuestData.FactionReputationLevel.REVERED: "你已经触及了守墓人守护的核心秘密——关于宇宙诞生与终结的真相。",
		FactionQuestData.FactionReputationLevel.IDOLIZED: "守墓人的真正目的在你眼前展现，你看到了凡人永远无法理解的景象。",
		FactionQuestData.FactionReputationLevel.Zealot: "你已成为守墓人的一员，永恒地守护着这个宇宙最深的秘密。"
	}
}

# 里程碑叙事事件
const MILESTONE_NARRATIVES: Dictionary = {
	# 加入势力时的叙事
	"join_starfire_temple": {
		"title": "星火殿的接纳",
		"text": "火焰在你的眼前跳跃，仿佛在欢迎你的到来。\n\n星火殿的长老站在你面前，他的眼中燃烧着永恒的星火。\n\n「从今日起，你便是星火殿的一员。记住我们的信条——追求力量，超越凡人。这条路艰辛而孤独，但你将获得与之匹配的荣耀。」\n\n他将一枚星火徽章交到你手中，金属的触感温热如初生的星辰。"
	},
	"join_frost_hall": {
		"title": "寒霜阁的邀请",
		"text": "寒气在你周围凝聚，却没有一丝寒意。\n\n寒霜阁的大门前，冰雪自动为你让路。\n\n「欢迎来到寒霜阁。」一个冰冷却不带敌意的声音在你耳边响起。「我们在这里等待了很久，等待一个能够理解秩序之美的人。」\n\n冰晶在你掌心形成，化作寒霜阁的徽记。"
	},
	"join_machine_cult": {
		"title": "机魂教的融合",
		"text": "齿轮的咔嗒声在你周围响起，仿佛某种古老机械正在苏醒。\n\n机魂教的工程师们从阴影中走出，他们的眼中闪烁着机械的光芒。\n\n「你的灵魂波动与我们的频率相符。」为首者说道，「加入我们，让机械与灵魂的融合成就永恒的存在。」\n\n一枚刻有齿轮纹路的徽章嵌入你的胸口，你感受到了机械之心跳。"
	},
	"join_graveyard_keeper": {
		"title": "守墓人的审视",
		"text": "黑暗在你周围涌动，时间仿佛失去了意义。\n\n当你睁开眼时，你已站在一片无垠的虚空中。守墓人的身影若隐若现。\n\n「你看到了我们。」他们的声音如同来自深渊的低语。「很好。现在你要做出选择——是成为秘密的守护者，还是成为永恒的守望者？」\n\n一枚漆黑的徽章落入你手中，冰冷刺骨。"
	},

	# 声望等级提升叙事
	"reach_trusted_starfire_temple": {
		"title": "陨星熔炉",
		"text": "星火殿的长老带你穿过了层层火海，来到一个被星火环绕的熔炉前。\n\n「这是陨星熔炉，」他说道，「这里诞生了星火殿最强大的神器，也只有被认可的人才能踏入此地。」\n\n熔炉中的火焰呈现出一种你从未见过的颜色——深邃的蓝紫色，那是星辰毁灭时的色彩。"
	},
	"reach_revered_starfire_temple": {
		"title": "星火殿的名册",
		"text": "你翻开那本古老的名册，看到无数耀眼的名字。\n\n从最初的星火殿始祖，到历代最强大的修炼者，每一个名字都曾照亮过一个时代。\n\n现在，你将自己的名字刻在了其中。光芒闪烁，你感受到一股力量注入你的灵魂。"
	},
	"reach_trusted_frost_hall": {
		"title": "寒霜核心",
		"text": "寒霜阁的秘法长老带你来到了一个由纯粹寒气凝聚的空间。\n\n「这是绝对零度的第一道裂缝。」她轻声说道，「只有真正理解寒霜之道的人才能看到它。」\n\n你凝视着那道裂缝，感受到一股来自宇宙本源的寒意，却也从中看到了秩序的美丽。"
	},
	"reach_revered_machine_cult": {
		"title": "灵魂矩阵",
		"text": "机魂教的首席工程师向你展示了一个悬浮在空中的复杂装置。\n\n「这就是灵魂矩阵——我们最伟大的发明。」他骄傲地说，「它证明了灵魂可以被量化、被储存、被转移。」\n\n矩阵中的光点如同星辰般闪烁，每一个光点都是一个被封存的灵魂。"
	},
	"reach_trusted_graveyard_keeper": {
		"title": "虚空真言",
		"text": "守墓人的领袖第一次向你揭示了他们的秘密语言。\n\n「这是虚空真言，」他的声音中带着一丝敬意，「学会它，你就能听到宇宙诞生时的第一道回声。」\n\n你开始理解那些古老的声音，感受到时间在你的周围扭曲。"
	},

	# 任务完成叙事
	"complete_first_quest_starfire_temple": {
		"title": "星火初成",
		"text": "星火殿的任务已经完成，长老对你点了点头。\n\n「这是你作为星火殿一员迈出的第一步。」他说道，「不要骄傲，前方的路还很长。」\n\n但你从他的眼中看到了认可的光芒。"
	},
	"complete_first_quest_frost_hall": {
		"title": "寒霜初凝",
		"text": "寒霜阁的任务圆满完成。\n\n「不错。」秘法长老的语气依然冰冷，但你能感受到其中的肯定。「继续努力，你还有很大的进步空间。」\n\n一丝寒气从你的指尖散发，你感受到了寒霜之力的觉醒。"
	},
	"complete_first_quest_machine_cult": {
		"title": "机械之心",
		"text": "机魂教的任务顺利达成。\n\n「合格。」工程师简短地评价，但他的眼中有着掩饰不住的满意。「你的灵魂与机械的契合度超出了我们的预期。」\n\n你感觉到胸口的徽章跳动得更加有力。"
	},
	"complete_first_quest_graveyard_keeper": {
		"title": "墓穴的低语",
		"text": "守墓人的任务已完成。\n\n黑暗中，你听到了那些沉睡者的低语。它们在诉说着古老的秘密，那些不应该被凡人知晓的真相。\n\n你开始理解守墓人为何如此执着地守护着这些秘密。"
	},

	# 最高声望叙事
	"reach_zealot_starfire_temple": {
		"title": "星火与我",
		"text": "当你的声望达到狂热时，星火殿的长老们全部出现在你面前。\n\n「你是我们等待的那个人。」他们齐声说道，「从现在起，星火即是你的名讳。」\n\n你感受到星辰的力量在你体内燃烧，你看到了力量的真谛。"
	},
	"reach_zealot_frost_hall": {
		"title": "冰封之王",
		"text": "寒霜阁的所有长老向你鞠躬。\n\n「你是秩序的化身。」他们说道，「从现在起，你便是寒霜阁意志的延伸。」\n\n你感受到了绝对零度的真谛，宇宙的秩序在你眼中变得无比清晰。"
	},
	"reach_zealot_machine_cult": {
		"title": "机械神降",
		"text": "所有的机械在你面前轰鸣，仿佛在迎接它们的新神。\n\n「灵魂与机械的完美融合。」机魂教的成员们齐声高呼，「你就是我们的未来！」\n\n你感受到自己已经超越了生与死的界限，成为了永恒的存在。"
	},
	"reach_zealot_graveyard_keeper": {
		"title": "永恒守望",
		"text": "虚空在你周围敞开它的怀抱。\n\n「你已不再是凡人。」守墓人的声音回荡在永恒之中，「你是秘密的守护者，是时间的守望者。」\n\n你成为了守墓人的一员，永恒地注视着这个宇宙最深处的真相。"
	}
}

# 获取势力背景故事
static func get_backstory(faction_name: String, reputation_level: int) -> String:
	if not FACTION_BACKSTORIES.has(faction_name):
		return ""

	var backstories = FACTION_BACKSTORIES[faction_name]
	var level = clampi(reputation_level, 0, 5)

	# 优先返回对应等级的解锁故事
	if backstories.has(level):
		return backstories[level]

	return ""

# 获取势力介绍（始终显示）
static func get_intro(faction_name: String) -> String:
	if not FACTION_BACKSTORIES.has(faction_name):
		return ""
	return FACTION_BACKSTORIES[faction_name].get("intro", "")

# 获取势力理念（始终显示）
static func get_philosophy(faction_name: String) -> String:
	if not FACTION_BACKSTORIES.has(faction_name):
		return ""
	return FACTION_BACKSTORIES[faction_name].get("理念", "")

# 获取里程碑叙事
static func get_milestone_narrative(milestone_id: String) -> Dictionary:
	if MILESTONE_NARRATIVES.has(milestone_id):
		return MILESTONE_NARRATIVES[milestone_id]
	return {}

# 检查里程碑是否已触发（用于存档）
static func get_all_milestone_ids() -> Array:
	return MILESTONE_NARRATIVES.keys()
