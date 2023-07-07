--
-- automaticWaterFill
--
-- @author  Lars Hansen
-- @date 	07/01/2023
-- @node	This Script automatically fills all animal pens that need water

automaticWaterFill = {}

local debugMode = false
refillInterval = 4 -- Refill water every [refillInterval] hours

function automaticWaterFill:loadMap(mapFilename)
	if g_currentMission:getIsServer() then
		g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.hourChanged, self)
	end
end

function automaticWaterFill:deleteMap()
	if g_currentMission:getIsServer() then
		g_messageCenter:unsubscribe(MessageType.HOUR_CHANGED, self)
	end
end

function automaticWaterFill:FillAllPens()
	waterPricePerLiter = g_currentMission.economyManager:getPricePerLiter(FillType.WATER)
	for _,clusterHusbandry in pairs(g_currentMission.husbandrySystem.clusterHusbandries) do
		local farmId = g_currentMission.player.farmId
		local costs = self:doForHusbandry(clusterHusbandry, farmId)

		if (costs ~= nil and costs > 0) then
			g_currentMission:addMoney(-costs, farmId, MoneyType.PURCHASE_WATER, true, true)
		end
	end
	return 0
end

function automaticWaterFill:doForHusbandry(clusterHusbandry, farmId)
	local currentCost = 0
	if (clusterHusbandry ~= nil) then
		currentCost = currentCost + self:giveWater(clusterHusbandry, farmId)
	end 
	return currentCost
end

function automaticWaterFill:giveWater(clusterHusbandry, farmId)
	local freeCapacity = clusterHusbandry.placeable:getHusbandryFreeCapacity(FillType.WATER)
	printdbg("Free capacity for water = %d l", freeCapacity)

	if (freeCapacity ~= nil and freeCapacity > 0) then
		clusterHusbandry.placeable:addHusbandryFillLevelFromTool(farmId, freeCapacity, FillType.WATER, nil)
	end
	
	local cost = freeCapacity * waterPricePerLiter
	return cost
end

function automaticWaterFill:hourChanged()

	local modHour = math.fmod(g_currentMission.environment.currentHour, refillInterval)
	if modHour == 0 then
		self:FillAllPens()
	end
end

-- Add the ModEventListener to the gamewa
addModEventListener(automaticWaterFill)

function printdbg(str, ...)
	if debugMode then
		print(string.format(str, ...))
	end
end
