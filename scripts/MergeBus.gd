extends Node
## MergeBus (autoload singleton)
## Глобальная шина событий слияния. Развязывает Cube и MergeLogic:
## Cube только сообщает о слиянии, MergeLogic выполняет работу.

signal merge_requested(cube_a: Node, cube_b: Node)
signal merge_completed(new_cube: Node, old_tier: int, new_tier: int, position: Vector2)
signal combo_step(combo_count: int, multiplier: float, position: Vector2)


func request_merge(a: Node, b: Node) -> void:
	merge_requested.emit(a, b)
