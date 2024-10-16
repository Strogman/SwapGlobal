Prey = {
	Credits = "System remake: Westwol ~ Packet logic: Cjaker ~  Formulas: slavidodo",
	Version = "4.0",
	LastUpdate = "07/07/19",
}

CONST_PREY_SLOT_FIRST = 0
CONST_PREY_SLOT_SECOND = 1
CONST_PREY_SLOT_THIRD = 2

CONST_MONSTER_TIER_BRONZE = 0
CONST_MONSTER_TIER_SILVER = 1
CONST_MONSTER_TIER_GOLD = 2
CONST_MONSTER_TIER_GOLD = 3
CONST_MONSTER_TIER_PLATINUM = 4

CONST_BONUS_DAMAGE_BOOST = 0
CONST_BONUS_DAMAGE_REDUCTION = 1
CONST_BONUS_XP_BONUS = 2
CONST_BONUS_IMPROVED_LOOT = 3

Prey.Config = {
	ListRerollPrice = 2000
}

Prey.S_Packets = {
	ShowDialog = 0xED,
	PreyRerollPrice = 0xE9,
	PreyData = 0xE8,
	PreyTimeLeft = 0xE7
}

Prey.StateTypes = {
	LOCKED = 0,
	INACTIVE = 1,
	ACTIVE = 2,
	SELECTION = 3,
	SELECTION_CHANGE_MONSTER = 4
}

Prey.UnlockTypes = {
	PREMIUM_OR_STORE = 0,
	STORE = 1,
	NONE = 2
}

Prey.Actions = {
	NEW_LIST = 0,
	NEW_BONUS = 1,
	SELECT = 2,
	NEW_BONUS_WILDCARD = 3,
}

Prey.C_Packets = {
	RequestData = 0xED,
	PreyAction = 0xEB
}

Prey.Bonuses = {
	[CONST_BONUS_DAMAGE_BOOST] = {step = 2, min = 7, max = 25},
	[CONST_BONUS_DAMAGE_REDUCTION] = {step = 2, min = 12, max = 30},
	[CONST_BONUS_XP_BONUS] = {step = 3, min = 13, max = 40},
	[CONST_BONUS_IMPROVED_LOOT] = {step = 3, min = 13, max = 40}
}

Prey.MonsterList = {
	[CONST_MONSTER_TIER_BRONZE] = {
		"Rotworm", "Carrion Worm", "Skeleton", "Ghoul", "Cyclops", "Cyclops Drone", "Cyclops Smith", "Dark Magician",
		"Beholder", "Dragon", "Dragon Hatchling", "Dwarf", "Dwarf Guard", "Dwarf Geomancer", "Dwarf Soldier", "Earth Elemental",
		"Fire Elemental", "Gargoyle", "Merlkin", "Minotaur", "Minotaur Guard", "Minotaur Mage", "Minotaur Archer", "Nomad",
		"Amazon", "Hunter", "Orc", "Orc Berserker", "Orc Leader", "Orc Shaman", "Orc Spearman", "Orc Warlord", "Panda",
		"Rotworm Queen", "Tarantula", "Scarab", "Skeleton Warrior", "Smuggler"
	},
	[CONST_MONSTER_TIER_SILVER] = {
		 "Pirate Buccaneer", "Pirate Ghost", "Pirate Marauder", "Pirate Skeleton", "Dragon Lord Hatchling", "Frost Dragon Hatchling",
		"Behemoth", "Faun", "Dark Faun", "Dragon Lord", "Frost Dragon", "Hydra", "Hero", "Bullwark", "Giant Spider", "Crystal Spider",
		"Deepling Brawler", "Deepling Elite", "Deepling Guard", "Deepling Master Librarian", "Deepling Tyrant", "Deepling Warrior",
		"Wyrm", "Elder Wyrm", "Fleshslicer", "Frost Giant", "Ghastly Dragon", "Ice Golem", "Infernalist", "Warlock", "Lich",
		"Lizard Chosen", "Lizard Dragon Priest", "Lizard High Guard", "Lizard Legionnaire", "Lizard Zaogun", "Massive Energy Elemental",
		"Massive Fire Elemental", "Massive Water Elemental", "Minotaur Amazon", "Execowtioner", "Minotaur Hunter", "Mooh'Tah Warrior",
		"Mutated Bat", "Mutated Human", "Necromancer", "Nightmare", "Nightmare Scion", "Ogre Brute", "Ogre Savage", "Ogre Shaman",
		"Orclops Doomhauler", "Orclops Ravager", "Quara Constrictor", "Quara Constrictor Scout", "Quara Hydromancer", "Quara Mantassin",
		"Quara Pincher", "Quara Predator", "Sea Serpent", "Shaper Matriarch", "Silencer", "Spitter", "Worker Golem", "Werewolf",
		"Hellspawn", "Shadow Tentacle", "Vampire Bride", "Dragonling", "Shock Head", "Frazzlemaw",
	},
	[CONST_MONSTER_TIER_GOLD] = {
		"Plaguesmith", "Demon", "Crystal Spider", "Defiler", "Destroyer", "Diamond Servant", "Draken Elite",
		"Draken Spellweaver", "Draken Warmaster", "Draken Abomination", "Feversleep", "Terrorsleep", "Draptor",
		"Grim Reaper", "Guzzlemaw", "Hellfire Fighter", "Hand of Cursed Fate", "Hellhound", "Juggernaut",
		"Sparkion", "Dark Torturer", "Undead Dragon", "Retching Horror", "Choking Fear", "Choking Fear",
		"Shiversleep", "Sight Of Surrender", "Demon Outcast", "Blightwalker", "Grimeleech", "Vexclaw", "Grimeleech",
		"Dawnfire Asura", "Midnight Asura", "Frost Flower Asura", "True Dawnfire Asura", "True Frost Flower Asura",
		"True Midnight Asura"
	}
}

-- Communication functions
function Player.sendResource(self, resourceType, value)
	local typeByte = 0
	if resourceType == "bank" then
		typeByte = 0x00
	elseif resourceType == "inventory" then
		typeByte = 0x01
	elseif resourceType == "prey" then
		typeByte = 0x0A
	elseif resourceType == "unknow" then
		typeByte = 0x14
	end
	local msg = NetworkMessage()
	msg:addByte(0xEE)
	msg:addByte(typeByte)
	msg:addU64(value)
	msg:sendToPlayer(self)
end

function Player.sendErrorDialog(self, error)
	local msg = NetworkMessage()
	msg:addByte(Prey.S_Packets.ShowDialog)
	msg:addByte(0x15)
	msg:addString(error)
	msg:sendToPlayer(self)
end

-- Core functions
function Player.setRandomBonusValue(self, slot, bonus, typeChange)
	local type = self:getPreyBonusType(slot)

	local min = Prey.Bonuses[type].min
	local max = Prey.Bonuses[type].max
	local step = Prey.Bonuses[type].step

	if bonus then
		if typeChange then
			self:setPreyBonusValue(slot, math.random(min, max))
		else
			local oldValue = self:getPreyBonusValue(slot)
			if (oldValue + step >= max) then
				self:setPreyBonusValue(slot, max)
			else
				while (self:getPreyBonusValue(slot) - oldValue < step) do
					self:setPreyBonusValue(slot, math.random(min, max))
				end
			end
		end
	else
		self:setPreyBonusValue(slot, math.random(min, max))
	end

	local grade = math.floor((self:getPreyBonusValue(slot) - min) / (max - min) * 10)
	local minimo = math.max(grade, 1)
	self:setPreyBonusGrade(slot, minimo)
	if (self:getPreyBonusGrade(slot) == 10 and self:getPreyBonusValue(slot) < max) then
		local minimo = math.max(self:getPreyBonusGrade(slot) - 1, 1)
		self:setPreyBonusGrade(slot, minimo)
	end
end

function Player.getMonsterTier(self)
	if self:getLevel() > 0 and self:getLevel() < 60 then
		return CONST_MONSTER_TIER_BRONZE
	elseif self:getLevel() >= 60 and self:getLevel() < 160 then
		return CONST_MONSTER_TIER_SILVER
	elseif self:getLevel() >= 160 then
		return CONST_MONSTER_TIER_GOLD
	end
end

function Player.createMonsterList(self)
	-- Do not allow repeated monsters
	local repeatedList = {}
	local CONST_PREY_SLOT_LAST = self:getPreyUnlocked(CONST_PREY_SLOT_THIRD) == 1 and CONST_PREY_SLOT_THIRD or CONST_PREY_SLOT_SECOND
	for slot = CONST_PREY_SLOT_FIRST, CONST_PREY_SLOT_LAST do
		if (self:getPreyCurrentMonster(slot) ~= '') then
			repeatedList[#repeatedList + 1] = self:getPreyCurrentMonster(slot)
		end
		if (self:getPreyMonsterList(slot) ~= '') then
			local currentList = self:getPreyMonsterList(slot):split(";")
			for i = 1, #currentList do
				repeatedList[#repeatedList + 1] = currentList[i]
			end
		end
	end
	-- Generating monsterList
	local monsters = {}
	while (#monsters ~= 9) do
		local randomMonster = Prey.MonsterList[self:getMonsterTier()][math.random(#Prey.MonsterList[self:getMonsterTier()])]
		-- Verify that monster actually exists
		if MonsterType(randomMonster) and not table.contains(monsters, randomMonster) and not table.contains(repeatedList, randomMonster) then
			monsters[#monsters + 1] = randomMonster
		end
	end
	return table.concat(monsters, ";")
end

function Player.resetPreySlot(self, slot, from)
	self:setPreyMonsterList(slot, self:createMonsterList())
	self:setPreyState(slot, from)
	return sendPreyData(self:getId(), slot)
end

function Player.getMinutesUntilFreeReroll(self, slot)
	local currentTime = os.time()
	if (self:getPreyNextUse(slot) <= currentTime) then
		return 0
	end
	return math.floor((self:getPreyNextUse(slot) - currentTime))
end

function Player.getRerollPrice(self)
	return (self:getLevel() / 2) * 100
end

local function sendHunting(player)
local msg = NetworkMessage()
msg:addByte(0xbb)
msg:addByte(0x00)

msg:addByte(0x02)
msg:addU16(0x09)
msg:addU16(1880)
msg:addByte(0x00)

msg:addU16(1507)
msg:addByte(0x00)

msg:addU16(1120)
msg:addByte(0x00)

msg:addU16(526)
msg:addByte(0x00)

msg:addU16(389)
msg:addByte(0x00)

msg:addU16(1532)
msg:addByte(0x00)

msg:addU16(68)
msg:addByte(0x00)

msg:addU16(1667)
msg:addByte(0x00)

msg:addU16(50)
msg:addByte(0x00)


-- ###########################################################################[parseHeader]: 0xbb
msg:addByte(0xBB)
msg:addByte(0x01)
msg:addByte(0x00)
msg:addByte(0x00)
-- ###########################################################################[parseHeader]: 0xbb
msg:addByte(0xBB)
msg:addByte(0x02)
msg:addByte(0x00)
msg:addByte(0x01)

msg:sendToPlayer(player)
end

function onRecvbyte(player, msg, byte)
	if (byte == Prey.C_Packets.RequestData) then
		player:sendPreyData()
		if player:getClient().version >= 1230 then
			sendHunting(player)
		end
		-- player:sendPreyData(CONST_PREY_SLOT_SECOND)
		-- -- if player:getPreyUnlocked(CONST_PREY_SLOT_THIRD) == 1 then
		-- 	player:sendPreyData(CONST_PREY_SLOT_THIRD)
		-- -- end
	elseif (byte == Prey.C_Packets.PreyAction) then
		player:preyAction(msg)
	end
end

function Player.preyAction(self, msg)
	if self:getClient().version < 1150 then
		self:sendErrorDialog("For best performance, use client 12.")
		return false
	end

	local slot = msg:getByte()
	local action = msg:getByte()

	if not slot then
		return self:sendErrorDialog("Sorry, there was an issue, please relog-in.")
	end

	-- Verify whether the slot is unlocked
	if (self:getPreyUnlocked(slot) ~= 1) then
		return self:sendErrorDialog("Sorry, you don't have this slot unlocked yet.")
	end

	-- Listreroll
	if (action == Prey.Actions.NEW_LIST) then

		-- Verifying state
		if (self:getPreyState(slot) ~= Prey.StateTypes.ACTIVE and self:getPreyState(slot) ~= Prey.StateTypes.SELECTION and self:getPreyState(slot) ~= Prey.StateTypes.SELECTION_CHANGE_MONSTER) then
			return self:sendErrorDialog("This is slot is not even active.")
		end

		-- If free reroll is available
		if (self:getMinutesUntilFreeReroll(slot) == 0) then
			self:setPreyNextUse(slot, os.time() + 20 * 60 * 60)
		elseif (not self:removeMoneyNpc(self:getRerollPrice())) then
			return self:sendErrorDialog("You do not have enough money to perform this action.")
		end

		self:setPreyCurrentMonster(slot, "")
		self:setPreyMonsterList(slot, self:createMonsterList())
		self:setPreyState(slot, Prey.StateTypes.SELECTION_CHANGE_MONSTER)

	elseif (action == Prey.Actions.NEW_BONUS_WILDCARD) then
		-- Verifying state
		if (self:getPreyState(slot) ~= Prey.StateTypes.ACTIVE and self:getPreyState(slot) ~= Prey.StateTypes.SELECTION and self:getPreyState(slot) ~= Prey.StateTypes.SELECTION_CHANGE_MONSTER) then
			return self:sendErrorDialog("This is slot is not even active.")
		end

		local preyWildCards = self:getPreyBonusRerolls()
		-- If free reroll is available
		if (self:getMinutesUntilFreeReroll(slot) == 0) then
			self:setPreyNextUse(slot, os.time() + 20 * 60 * 60)
		elseif (preyWildCards <= 0) then
			return self:sendErrorDialog("You do not have enough prey Wild Cards to perform this action.")
		end

		self:setPreyBonusRerolls(preyWildCards - 5)
		self:setPreyCurrentMonster(slot, "")
		self:setPreyMonsterList(slot, self:createMonsterList())
		self:setPreyState(slot, Prey.StateTypes.SELECTION_CHANGE_MONSTER)
	-- Bonus reroll
	elseif (action == Prey.Actions.NEW_BONUS) then

		-- Verifying state
		if (self:getPreyState(slot) ~= Prey.StateTypes.ACTIVE) then
			return self:sendErrorDialog("This is slot is not even active.")
		end

		if (self:getPreyBonusRerolls() < 1) then
			return self:sendErrorDialog("You don't have any bonus rerolls.")
		end

		-- Removing bonus rerolls
		self:setPreyBonusRerolls(self:getPreyBonusRerolls() - 1)

		-- Calculating new bonus
		local oldType = self:getPreyBonusType(slot)
		self:setPreyBonusType(slot, math.random(CONST_BONUS_DAMAGE_BOOST, CONST_BONUS_IMPROVED_LOOT))
		self:setRandomBonusValue(slot, true, (oldType ~= self:getPreyBonusType(slot) and true or false))

	-- Select monster from list
	elseif (action == Prey.Actions.SELECT) then

		local selectedMonster = msg:getByte()
		local monsterList = self:getPreyMonsterList(slot):split(";")

		-- Verify if the monster exists.
		local monster = MonsterType(monsterList[selectedMonster + 1])
		if not monster then
			return sendPreyData(self:getId(), slot)
		end

		-- Verifying slot state
		if (self:getPreyState(slot) ~= Prey.StateTypes.SELECTION and self:getPreyState(slot) ~= Prey.StateTypes.SELECTION_CHANGE_MONSTER) then
			return self:sendErrorDialog("This slot can't select monsters.")
		end

		-- Proceeding to prey monster selection
		self:selectPreyMonster(slot, monsterList[selectedMonster + 1])
	end

	-- Perfom slot update
	return sendPreyData(self:getId(), slot)
end

function Player.selectPreyMonster(self, slot, monster)

	-- Verify if the monster exists.
	local monster = MonsterType(monster)
	if not monster then
		return sendPreyData(self:getId(), slot)
	end

	local msg = NetworkMessage()

	-- Only first/expired selection list gets new prey bonus
	if (self:getPreyState(slot) == Prey.StateTypes.SELECTION) then
		-- Generating random prey type
		self:setPreyBonusType(slot, math.random(CONST_BONUS_DAMAGE_BOOST, CONST_BONUS_IMPROVED_LOOT))
		-- Generating random bonus stats
		self:setRandomBonusValue(slot, false, false)
	end

	-- Setting current monster
	self:setPreyCurrentMonster(slot, monster:getName())
	-- Setting preySlot state
	self:setPreyState(slot, Prey.StateTypes.ACTIVE)
	-- Cleaning up monsterList
	self:setPreyMonsterList(slot, "")
	-- Time left
	self:setPreyTimeLeft(slot, 7200) -- 2 hours
end

function sendPreyData(playerId, slot)
	local player = Player(playerId)
	if not player then
		return true
	end
	local version = player:getClient().version
	local slotState = player:getPreyState(slot)
	local msg = NetworkMessage()
	msg:addByte(Prey.S_Packets.PreyData) -- packet header
	msg:addByte(slot) -- slot number
	msg:addByte(slotState) -- slot state

	-- This slot will preserve the same bonus and % but the monster might be changed
	if slotState == Prey.StateTypes.SELECTION_CHANGE_MONSTER then

		-- This values have to be stored on each slot
		msg:addByte(player:getPreyBonusType(slot))
		msg:addU16(player:getPreyBonusValue(slot))
		msg:addByte(player:getPreyBonusGrade(slot))

		-- MonsterList already exists in the slot
		local monsterList = player:getPreyMonsterList(slot):split(";")
		msg:addByte(#monsterList)
		for i = 1, #monsterList do
			local monster = MonsterType(monsterList[i])
			if monster then
				msg:addString(monster:getName())
				msg:addU16(monster:getOutfit().lookType or 21)
				msg:addByte(monster:getOutfit().lookHead or 0x00)
				msg:addByte(monster:getOutfit().lookBody or 0x00)
				msg:addByte(monster:getOutfit().lookLegs or 0x00)
				msg:addByte(monster:getOutfit().lookFeet or 0x00)
				msg:addByte(monster:getOutfit().lookAddons or 0x00)
			else
				-- Reset slot as it got bugged
				return player:resetPreySlot(slot, Prey.StateTypes.SELECTION_CHANGE_MONSTER)
			end
		end


	-- This slot will have a new monsterList and a random bonus
	elseif slotState == Prey.StateTypes.SELECTION then

		-- If list is empty, then we will create a new one and assign it to the monsterList or timeleft = 0
		local preyMonsterList = player:getPreyMonsterList(slot)
		if preyMonsterList == '' then
			player:setPreyMonsterList(slot, player:createMonsterList())
			-- Resending this preySlot as there was a change.
			return sendPreyData(playerId, slot)
		end

		local monsterList = preyMonsterList:split(";")
		msg:addByte(#monsterList)
		for i = 1, #monsterList do
			local monster = MonsterType(monsterList[i])
			if monster then
				msg:addString(monster:getName())
				msg:addU16(monster:getOutfit().lookType or 21)
				msg:addByte(monster:getOutfit().lookHead or 0x00)
				msg:addByte(monster:getOutfit().lookBody or 0x00)
				msg:addByte(monster:getOutfit().lookLegs or 0x00)
				msg:addByte(monster:getOutfit().lookFeet or 0x00)
				msg:addByte(monster:getOutfit().lookAddons or 0x00)
			else
				-- Reset slot as it got bugged
				return player:resetPreySlot(slot, Prey.StateTypes.SELECTION)
			end
		end

	-- This slot is active and will show current monster and bonus
	elseif slotState == Prey.StateTypes.ACTIVE then

		-- Getting current monster
		local monster = MonsterType(player:getPreyCurrentMonster(slot))
		if monster then
			msg:addString(monster:getName())
			msg:addU16(monster:getOutfit().lookType or 21)
			msg:addByte(monster:getOutfit().lookHead or 0x00)
			msg:addByte(monster:getOutfit().lookBody or 0x00)
			msg:addByte(monster:getOutfit().lookLegs or 0x00)
			msg:addByte(monster:getOutfit().lookFeet or 0x00)
			msg:addByte(monster:getOutfit().lookAddons or 0x00)
			msg:addByte(player:getPreyBonusType(slot))
			msg:addU16(player:getPreyBonusValue(slot))
			msg:addByte(player:getPreyBonusGrade(slot))
			msg:addU16(player:getPreyTimeLeft(slot))
		else
			-- Reset slot as it got expired or bugged.
			return player:resetPreySlot(slot, Prey.StateTypes.SELECTION)
		end

	-- This slot is inactive and will not take any extra bytes
	elseif slotState == Prey.StateTypes.INACTIVE then


	elseif slotState == Prey.StateTypes.LOCKED then
		if slot == 1 then
			msg:addByte(0x00)
		else
			msg:addByte(0x01) -- Store unlock method
		end
	end

	-- Resources and times are always sent
	msg:addU32(player:getMinutesUntilFreeReroll(slot)) -- next prey reroll here
	-- Client 11.9+ compat, feature unavailable.
	if version >= 1190  then -- and version < 1220 or (version >= 1220 and slotState ~= Prey.StateTypes.LOCKED) then
		msg:addByte(0x00) -- preyWildCards
	end

	msg:sendToPlayer(player)
end

function Player.sendPreyData(self)
	-- if self:getPreyState(slot) == 0x00 and slot == 0 then
	-- 	self:setPreyState(slot, 0x01)
	-- end

	local version = self:getClient().version
	for slotid = 1, 3 do
		local slot = slotid - 1
		if slotid == 3 and self:getPreyUnlocked(CONST_PREY_SLOT_THIRD) ~= 1 then
			self:setPreyState(slot, Prey.StateTypes.LOCKED)
		end
		sendPreyData(self:getId(), slot, version)
	end
	
	local msg = NetworkMessage()
	msg:addByte(0xEC)
	-- List reroll price

	msg:addByte(Prey.S_Packets.PreyRerollPrice)
	msg:addU32(self:getRerollPrice())
	-- Client 11.9+ compat, feature unavailable.
	if self:getClient().version >= 1190 then
		msg:addByte(0x01) -- bomus reroll
		msg:addByte(0x05)
	end

	if version >= 1230 then
		msg:addU32(800)
		msg:addU32(800)
		msg:addByte(2)
		msg:addByte(1)
	end

	if version >= 1220 then
		msg:addByte(0xe6)
		msg:addByte(0x00)
		msg:addU16(0x00)
	end
	self:sendResource("prey", self:getPreyBonusRerolls())
	self:sendResource("bank", self:getBankBalance())
	self:sendResource("inventory", self:getMoney())
	self:sendResource("unknow", 0)
	-- Sending message to client
	msg:sendToPlayer(self)
end