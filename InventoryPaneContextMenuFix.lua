 --***********************************************************
--**                LEMMY/ROBERT JOHNSON                   **
--***********************************************************
local MAXIMUM_RENAME_LENGTH = 28
local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local IMAGE_SIZE = 20

function ISRecipeTooltip.layoutContents(self, x, y)
	if self.contents then
		return self.contentsWidth, self.contentsHeight
	end

	self:getContainers()
	self:getAvailableItemsType()
	
	self.contents = {}
	local marginLeft = 20
	local marginTop = 10
	local marginBottom = 10
	local y1 = y + marginTop
	local lineHeight = math.max(FONT_HGT_SMALL, 20 + 2)
	local textDY = (lineHeight - FONT_HGT_SMALL) / 2
	local imageDY = (lineHeight - IMAGE_SIZE) / 2
	local singleSources = {}
	local multiSources = {}
	local allSources = {}

	for j=1,self.recipe:getSource():size() do
		local source = self.recipe:getSource():get(j-1)
		if source:getItems():size() == 1 then
			table.insert(singleSources, source)
		else
			table.insert(multiSources, source)
		end
	end

	-- Display singleSources before multiSources
	for _,source in ipairs(singleSources) do
		table.insert(allSources, source)
	end

	for _,source in ipairs(multiSources) do
		table.insert(allSources, source)
	end

	local maxSingleSourceLabelWidth = 0
	for _,source in ipairs(singleSources) do
		local txt = self:getSingleSourceText(source)
		local width = getTextManager():MeasureStringX(UIFont.Small, txt)
		maxSingleSourceLabelWidth = math.max(maxSingleSourceLabelWidth, width)
	end

	for _,source in ipairs(allSources) do
		local txt = ""
		local x1 = x + marginLeft
		if source:getItems():size() > 1 then
			if source:isDestroy() then
				txt = getText("IGUI_CraftUI_SourceDestroyOneOf")
			elseif source:isKeep() then
				txt = getText("IGUI_CraftUI_SourceKeepOneOf")
			else
				txt = getText("IGUI_CraftUI_SourceUseOneOf")
			end
			self:addText(x1, y1 + textDY, txt)
			y1 = y1 + lineHeight
		else
			txt = self:getSingleSourceText(source)
			self:addText(x1, y1 + textDY, txt)
			x1 = x1 + maxSingleSourceLabelWidth + 10
		end

		local itemDataList = {}

		for k=1,source:getItems():size() do
			local itemData = {}
			itemData.fullType = source:getItems():get(k-1)
			itemData.available = true
			local item = nil
			if itemData.fullType == "Water" then
				item = ISInventoryPaneContextMenu.getItemInstance("Base.WaterDrop")
			else
				if instanceof(self.recipe, "MovableRecipe") and (itemData.fullType == "Base."..self.recipe:getWorldSprite()) then
					item = ISInventoryPaneContextMenu.getItemInstance("Moveables.Moveable")
				else
					item = ISInventoryPaneContextMenu.getItemInstance(itemData.fullType)
				end
                --this reads the worldsprite so the generated item will have correct icon
                if instanceof(item, "Moveable") and instanceof(self.recipe, "MovableRecipe") then
                    item:ReadFromWorldSprite(self.recipe:getWorldSprite());
                end
			end
			itemData.texture = ""
			if item then
				itemData.texture = item:getTex():getName()
				if itemData.fullType == "Water" then
					if source:getCount() == 1 then
						itemData.name = getText("IGUI_CraftUI_CountOneUnit", getText("ContextMenu_WaterName"))
					else
						itemData.name = getText("IGUI_CraftUI_CountUnits", getText("ContextMenu_WaterName"), source:getCount())
					end
				elseif source:getItems():size() > 1 then -- no units
					itemData.name = item:getDisplayName()
				elseif not source:isDestroy() and item:IsDrainable() then
					if source:getCount() == 1 then
						itemData.name = getText("IGUI_CraftUI_CountOneUnit", item:getDisplayName())
					else
						itemData.name = getText("IGUI_CraftUI_CountUnits", item:getDisplayName(), source:getCount())
					end
				elseif not source:isDestroy() and source:getUse() > 0 then -- food
					if source:getUse() == 1 then
						itemData.name = getText("IGUI_CraftUI_CountOneUnit", item:getDisplayName())
					else
						itemData.name = getText("IGUI_CraftUI_CountUnits", item:getDisplayName(), source:getUse())
					end
				elseif source:getCount() > 1 then
					itemData.name = getText("IGUI_CraftUI_CountNumber", item:getDisplayName(), source:getCount())
				else
					itemData.name = item:getDisplayName()
				end
			else
				itemData.name = itemData.fullType
			end
			local countAvailable = self.typesAvailable[itemData.fullType] or 0
			if countAvailable < source:getCount() then
				itemData.available = false
				itemData.r = 0.54
				itemData.g = 0.54
				itemData.b = 0.54
			end
			table.insert(itemDataList, itemData)
		end

		table.sort(itemDataList, function(a,b)
			if a.available and not b.available then return true end
			if not a.available and b.available then return false end
			return not string.sort(a.name, b.name)
		end)

		-- Hack for "Dismantle Digital Watch" and similar recipes.
		-- Recipe sources include both left-hand and right-hand versions of the same item.
		-- We only want to display one of them.
		---[[
------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------
-------------------------I deleted this part, this tooltip is useless for the ripped sheets / sheet rope----------------------------
------------------------------------------------------------------------------------------------------------------------------------

	end

	if self.recipe:getTooltip() then
		local x1 = x + marginLeft
		local tooltip = getText(self.recipe:getTooltip())
		self:addText(x1, y1 + 8, tooltip)
	end

	self.contentsX = x
	self.contentsY = y
	self.contentsWidth = 0
	self.contentsHeight = 0
	for _,v in ipairs(self.contents) do
		self.contentsWidth = math.max(self.contentsWidth, v.x + v.width - x)
		self.contentsHeight = math.max(self.contentsHeight, v.y + v.height + marginBottom - y)
	end
	return self.contentsWidth, self.contentsHeight
end
