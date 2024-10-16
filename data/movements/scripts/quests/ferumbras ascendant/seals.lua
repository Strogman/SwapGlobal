local config = {
	[24839] = {toPosition = Position(33419, 32841, 11), backPosition = Position(33484, 32775, 12), timer = Storage.FerumbrasAscension.TarbazTimer},
	[24840] = {toPosition = Position(33452, 32356, 13), backPosition = Position(33432, 32330, 14), timer = Storage.FerumbrasAscension.RagiazTimer},
	[24841] = {toPosition = Position(33230, 31493, 13), backPosition = Position(33197, 31438, 13), timer = Storage.FerumbrasAscension.PlagirathTimer},
	[24842] = {toPosition = Position(33380, 32454, 14), backPosition = Position(33399, 32402, 15), timer = Storage.FerumbrasAscension.RazzagornTimer},
	[24843] = {toPosition = Position(33680, 32736, 11), backPosition = Position(33664, 32682, 10), timer = Storage.FerumbrasAscension.ZamuloshTimer},
	[24844] = {toPosition = Position(33593, 32658, 14), backPosition = Position(33675, 32690, 13), timer = Storage.FerumbrasAscension.MazoranTimer},
	[24845] = {toPosition = Position(33436, 32800, 13), backPosition = Position(33477, 32701, 14), timer = Storage.FerumbrasAscension.ShulgraxTimer},
	[24846] = {toPosition = Position(33270, 31474, 14), backPosition = Position(33324, 31374, 14), timer = Storage.FerumbrasAscension.FerumbrasTimer}
}

function onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end
	local storage = config[item.actionid]
	if not storage then
		return true
	end
	if item.actionid == 24844 then
		if Game.getStorageValue(GlobalStorage.FerumbrasAscendantQuest.Elements.Done) >= 4 then
			if player:getStorageValue(storage.timer) <= os.time() then
				player:teleportTo(storage.toPosition)
				player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
			else
				player:teleportTo(Position(33675, 32690, 13))
				player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
				player:say('You have to wait to challange this enemy again!', TALKTYPE_MONSTER_SAY)
				return true
			end
		else
			local pos = position
			pos.y = pos.y + 2
			player:teleportTo(pos)
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, 'You not proven your worth. There is no escape for you here.')
			item:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
			return true
		end
	end
	if item.actionid == 24845 then
		if Game.getStorageValue(GlobalStorage.FerumbrasAscendantQuest.FlowerPuzzleTimer) >= 1 then
			if player:getStorageValue(storage.timer) <= os.time() then
				player:teleportTo(storage.toPosition)
				player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
			else
				player:teleportTo(Position(33477, 32701, 14))
				player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
				player:say('You have to wait to challange this enemy again!', TALKTYPE_MONSTER_SAY)
				return true
			end
		else
			local pos = position
			pos.y = pos.y + 2
			player:teleportTo(pos)
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, 'You not proven your worth. There is no escape for you here.')
			item:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
			return true
		end
	end
	if player:getStorageValue(storage.timer) <= os.time() then
		player:teleportTo(storage.toPosition)
		player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
	else
		player:teleportTo(storage.backPosition)
		player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
		if item.actionid < 24846 then
			player:say('You have to wait to challange this enemy again!', TALKTYPE_MONSTER_SAY)
		else
			player:say('You cannot enter, you must wait fourteen days after preventing the ascension of Ferumbras.', TALKTYPE_MONSTER_SAY)
		end
	end
	return true
end
