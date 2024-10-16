local deathListEnabled = true

local function addAssistsPoints(attackerId, target)
	if not attackerId or type(attackerId) ~= 'number' then
		return
	end

	if not target or type(target) ~= 'userdata' or not target:isPlayer() then
		return
	end

	local ignoreIds = {attackerId, target:getId()}
	for id in pairs(target:getDamageMap()) do
		local tmpPlayer = Player(id)
		if tmpPlayer and not isInArray(ignoreIds, id) then
			tmpPlayer:setStorageValue(STORAGEVALUE_ASSISTS, math.max(0, tmpPlayer:getStorageValue(STORAGEVALUE_ASSISTS)) + 1)
		end
	end
end

function onDeath(player, corpse, killer, mostDamageKiller, unjustified, mostDamageUnjustified)
	local playerId = player:getId()
	if nextUseStaminaTime[playerId] ~= nil then
		nextUseStaminaTime[playerId] = nil
	end
	
	AutoLootList:onLogout(player:getId(), player:getGuid())

	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, 'You are dead.')
	if player:getStorageValue(Storage.SvargrondArena.Pit) > 0 then
		player:setStorageValue(Storage.SvargrondArena.Pit, 0)
	end
	
	-- Cupcakes storage [itemid = stg]
	for i = 31719, 31720 do
		player:setStorageValue(i, -1)
	end

	if not deathListEnabled then
		return
	end

	local byPlayer = 0
	local killerName
	if killer ~= nil then
		if killer:isPlayer() then
			byPlayer = 1
		else
			local master = killer:getMaster()
			if master and master ~= killer and master:isPlayer() then
				killer = master
				byPlayer = 1
			end
		end
		killerName = killer:isMonster() and killer:getType():getNameDescription() or killer:getName()
	else
		killerName = 'field item'
	end

	local byPlayerMostDamage = 0
	local mostDamageKillerName
	if mostDamageKiller ~= nil then
		if mostDamageKiller:isPlayer() then
			byPlayerMostDamage = 1
		else
			local master = mostDamageKiller:getMaster()
			if master and master ~= mostDamageKiller and master:isPlayer() then
				mostDamageKiller = master
				byPlayerMostDamage = 1
			end
		end
		mostDamageName = mostDamageKiller:isMonster() and mostDamageKiller:getType():getNameDescription() or mostDamageKiller:getName()
	else
		mostDamageName = 'field item'
	end

	local playerGuid = player:getGuid()
	db.query('INSERT INTO `player_deaths` (`player_id`, `time`, `level`, `killed_by`, `is_player`, `mostdamage_by`, `mostdamage_is_player`, `unjustified`, `mostdamage_unjustified`) VALUES (' .. playerGuid .. ', ' .. os.time() .. ', ' .. player:getLevel() .. ', ' .. db.escapeString(killerName) .. ', ' .. byPlayer .. ', ' .. db.escapeString(mostDamageName) .. ', ' .. byPlayerMostDamage .. ', ' .. (unjustified and 1 or 0) .. ', ' .. (mostDamageUnjustified and 1 or 0) .. ')')
	local resultId = db.storeQuery('SELECT `player_id` FROM `player_deaths` WHERE `player_id` = ' .. playerGuid)

	local deathRecords = 0
	local tmpResultId = resultId
	while tmpResultId ~= false do
		tmpResultId = result.next(resultId)
		deathRecords = deathRecords + 1
	end

	if resultId ~= false then
		result.free(resultId)
	end

	if byPlayer == 1 then

		addAssistsPoints(killer:getId(), player)
		player:setStorageValue(STORAGEVALUE_DEATHS, math.max(0, player:getStorageValue(STORAGEVALUE_DEATHS)) + 1)
		killer:setStorageValue(STORAGEVALUE_KILLS, math.max(0, killer:getStorageValue(STORAGEVALUE_KILLS)) + 1)
		
		player:setStorageValue(STORAGE_DEATH_COUNT, math.max(0, player:getStorageValue(STORAGE_DEATH_COUNT)) + 1)
		killer:setStorageValue(STORAGE_KILL_COUNT, math.max(0, killer:getStorageValue(STORAGE_KILL_COUNT)) + 1)
		
		if killer:getLevel() >= CONFIG_GUILD_MONSTERS.killingPlayer.level then
			local g = killer:getGuild()
			if g then
				local pts = CONFIG_GUILD_MONSTERS.killingPlayer.pts
				g:setGuildPoints(g:getGuildPoints() + pts)
				g:broadcastMessage(string.format(CONFIG_GUILD_MONSTERS.killingPlayer.msg, killer:getName(), pts), MESSAGE_EVENT_ADVANCE)
			end
		end

		local targetGuild = player:getGuild()
		targetGuild = targetGuild and targetGuild:getId() or 0
		if targetGuild ~= 0 then
			local killerGuild = killer:getGuild()
			killerGuild = killerGuild and killerGuild:getId() or 0
			if killerGuild ~= 0 and targetGuild ~= killerGuild and isInWar(playerId, killer.uid) then
				local warId = false
				local frags = false
				resultId = db.storeQuery('SELECT `id`, `frags_limit` FROM `guild_wars` WHERE `status` = 1 AND ((`guild1` = ' .. killerGuild .. ' AND `guild2` = ' .. targetGuild .. ') OR (`guild1` = ' .. targetGuild .. ' AND `guild2` = ' .. killerGuild .. '))')
				if resultId ~= false then
					warId = result.getNumber(resultId, 'id')
					frags = result.getNumber(resultId, 'frags_limit')
					result.free(resultId)
				end

				if warId ~= false then
					db.asyncQuery('INSERT INTO `guildwar_kills` (`killer`, `target`, `killerguild`, `targetguild`, `time`, `warid`) VALUES (' .. db.escapeString(killerName) .. ', ' .. db.escapeString(player:getName()) .. ', ' .. killerGuild .. ', ' .. targetGuild .. ', ' .. os.time() .. ', ' .. warId .. ')')
					addEvent(function(warid, guildid, guildid2, frags)
						db.asyncStoreQuery("SELECT COUNT(*) as 'count' FROM `guildwar_kills` WHERE warid = ".. warid .." AND `killerguild` = " .. guildid .. ";",function(query)
							if(query) then
								local count = result.getNumber(query, 'count')
								if count >= frags then
									db.asyncQuery("UPDATE `guild_wars` SET `status` = 4, `ended` = " .. os.time() .. " WHERE id = " .. warid)
									if Guild(guildid) then
										Guild(guildid):broadcastMessage("War is over, please relog")
									end
									if Guild(guildid2) then
										Guild(guildid2):broadcastMessage("War is over, please relog")
									end
									print(string.format("The war between '%s' and '%s' has ended.", Guild(guildid):getName(), Guild(guildid2):getName()))
									Game.broadcastMessage(string.format("The war between '%s' and '%s' has ended. Winner: %s", Guild(guildid):getName(), Guild(guildid2):getName(), Guild(guildid):getName()))
								end
							end

						end)
					end, 500, warId, killerGuild, targetGuild, frags)
				end
			end
		end
	end
end
