# data/save/save_slots_list.gd
# 包装槽位数组为 Resource，供 ResourceSaver 持久化（不能直接保存 Array）

class_name SaveSlotsList
extends Resource

@export var slots: Array[SaveSlot] = []
