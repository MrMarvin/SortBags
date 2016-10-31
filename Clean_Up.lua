local _G, _M, _F = getfenv(0), {}, CreateFrame'Frame'
setfenv(1, setmetatable(_M, {__index=_G}))
_F:Hide()

do
	local delay = 0
	_F:SetScript('OnUpdate', function()
		delay = delay - arg1
		if delay <= 0 then
			delay = .2
			UPDATE()
		end
	end)
end

_F:SetScript('OnEvent', function() _M[event](this) end)
_F:RegisterEvent'ADDON_LOADED'

local function set(...)
	local t = {}
	for i = 1, arg.n do
		t[arg[i]] = true
	end
	return t
end

local function union(...)
	local t = {}
	for i = 1, arg.n do
		for k in arg[i] do
			t[k] = true
		end
	end
	return t
end

_G.Clean_Up_Settings = {
	reversed = false,
	ignored = {},
	BAGS = {},
	BANK = {},
}

BAGS = {
	containers = {0, 1, 2, 3, 4},
	tooltip = 'Clean Up Bags',
}
BANK = {
	containers = {-1, 5, 6, 7, 8, 9, 10},
	tooltip = 'Clean Up Bank',
}

ITEM_TYPES = {GetAuctionItemClasses()}

MOUNT = set(
	-- rams
	5864, 5872, 5873, 18785, 18786, 18787, 18244, 19030, 13328, 13329,
	-- horses
	2411, 2414, 5655, 5656, 18778, 18776, 18777, 18241, 12353, 12354,
	-- sabers
	8629, 8631, 8632, 18766, 18767, 18902, 18242, 13086, 19902, 12302, 12303, 8628, 12326,
	-- mechanostriders
	8563, 8595, 13321, 13322, 18772, 18773, 18774, 18243, 13326, 13327,
	-- kodos
	15277, 15290, 18793, 18794, 18795, 18247, 15292, 15293,
	-- wolves
	1132, 5665, 5668, 18796, 18797, 18798, 18245, 12330, 12351,
	-- raptors
	8588, 8591, 8592, 18788, 18789, 18790, 18246, 19872, 8586, 13317,
	-- undead horses
	13331, 13332, 13333, 13334, 18791, 18248, 13335,
	-- qiraji battle tanks
	21218, 21321, 21323, 21324, 21176
)

SPECIAL = set(5462, 17696, 17117, 13347, 13289, 11511)

KEY = set(9240, 17191, 13544, 12324, 16309, 12384, 20402)

TOOL = set(7005, 12709, 19727, 5956, 2901, 6219, 10498, 6218, 6339, 11130, 11145, 16207, 9149, 15846, 6256, 6365, 6367)

ENCHANTING_REAGENT = set(
	-- dust
	10940, 11083, 11137, 11176, 16204,
	-- essence
	10938, 10939, 10998, 11082, 11134, 11135, 11174, 11175, 16202, 16203,
	-- shard
	10978, 11084, 11138, 11139, 11177, 11178, 14343, 14344,
	-- crystal
	20725
)

CLASSES = {
	-- arrow
	{
		containers = {2101, 5439, 7278, 11362, 3573, 3605, 7371, 8217, 2662, 19319, 18714},
		items = set(2512, 2515, 3030, 3464, 9399, 11285, 12654, 18042, 19316),
	},
	-- bullet
	{
		containers = {2102, 5441, 7279, 11363, 3574, 3604, 7372, 8218, 2663, 19320},
		items = set(2516, 2519, 3033, 3465, 4960, 5568, 8067, 8068, 8069, 10512, 10513, 11284, 11630, 13377, 15997, 19317),
	},
	-- soul
	{
		containers = {22243, 22244, 21340, 21341, 21342},
		items = set(6265),
	},
	-- ench
	{
		containers = {22246, 22248, 22249},
		items = union(
			ENCHANTING_REAGENT,
			-- rods
			set(6218, 6339, 11130, 11145, 16207)
		),
	},
	-- herb
	{
		containers = {22250, 22251, 22252},
		items = set(765, 785, 2447, 2449, 2450, 2452, 2453, 3355, 3356, 3357, 3358, 3369, 3818, 3819, 3820, 3821, 4625, 8831, 8836, 8838, 8839, 8845, 8846, 13463, 13464, 13465, 13466, 13467, 13468),
	},
}

function ItemTypeKey(itemClass)
	return Key(ITEM_TYPES, itemClass) or 0
end

function ItemSubTypeKey(itemClass, itemSubClass)
	return Key({GetAuctionItemSubClasses(ItemTypeKey(itemClass))}, itemClass) or 0
end

function ItemInvTypeKey(itemClass, itemSubClass, itemSlot)
	return Key({GetAuctionInvTypes(ItemTypeKey(itemClass), ItemSubTypeKey(itemSubClass))}, itemSlot) or 0
end

function ADDON_LOADED()
	if arg1 ~= 'Clean_Up' then
		return
	end

	do
		local orig = PickupContainerItem
		function _G.PickupContainerItem(...)
			local container, position = unpack(arg)
			if IsAltKeyDown() then
				local slotKey = SlotKey(container, position)
				Clean_Up_Settings.ignored[slotKey] = true
				Print('Ignoring ' .. slotKey)
			else
				orig(unpack(arg))
			end
		end
	end
    do
        local lastTime, lastSlot
		local orig = UseContainerItem
		function _G.UseContainerItem(...)
			local container, position = unpack(arg)
			local slotKey = SlotKey(container, position)
			if IsAltKeyDown() then
				if Clean_Up_Settings.ignored[slotKey] then
					Clean_Up_Settings.ignored[slotKey] = nil
					Print('No longer ignoring ' .. slotKey)
				end
			else
				orig(unpack(arg))
			end
		end
	end

	SetupSlash()

	CreateFrame('GameTooltip', 'Clean_Up_Tooltip', nil, 'GameTooltipTemplate')
	CreateButtonPlacer()
	CreateButton'BAGS'
	CreateButton'BANK'
end

function UPDATE()
	if Sort() then
		_F:Hide()
	end
	Stack()
end

local itemStacks, itemClasses, itemSortKeys = {}, {}, {}
_F:SetScript('OnShow', function()
	itemStacks, itemClasses, itemSortKeys = {}, {}, {}
	CreateModel()
end)

function Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage(LIGHTYELLOW_FONT_COLOR_CODE .. '[Clean Up] ' .. msg)
end

function LT(a, b)
	local i = 1
	while true do
		if a[i] and b[i] and a[i] ~= b[i] then
			return a[i] < b[i]
		elseif not a[i] and b[i] then
			return true
		elseif not b[i] then
			return false
		end
		i = i + 1
	end
end

function Key(table, value)
	for k, v in table do
		if v == value then
			return k
		end
	end
end

function SlotKey(container, position)
	return container .. ':' .. position
end

function SetupSlash()
  	_G.SLASH_CLEANUPBAGS1 = '/cleanupbags'
	function _G.SlashCmdList.CLEANUPBAGS(arg)
		buttonPlacer.key = 'BAGS'
		buttonPlacer:Show()
	end

	_G.SLASH_CLEANUPBANK1 = '/cleanupbank'
	function _G.SlashCmdList.CLEANUPBANK(arg)
		buttonPlacer.key = 'BANK'
		buttonPlacer:Show()
	end

    _G.SLASH_CLEANUPREVERSE1 = '/cleanupreverse'
    function _G.SlashCmdList.CLEANUPREVERSE(arg)
        Clean_Up_Settings.reversed = not Clean_Up_Settings.reversed
        Print('Sort order: ' .. (Clean_Up_Settings.reversed and 'Reversed' or 'Standard'))
	end
end

function BrushButton(parent)
	local button = CreateFrame('Button', nil, parent)
	button:SetWidth(28)
	button:SetHeight(26)
	button:SetNormalTexture[[Interface\AddOns\Clean_Up\Bags]]
	button:GetNormalTexture():SetTexCoord(.12109375, .23046875, .7265625, .9296875)
	button:SetPushedTexture[[Interface\AddOns\Clean_Up\Bags]]
	button:GetPushedTexture():SetTexCoord(.00390625, .11328125, .7265625, .9296875)
	button:SetHighlightTexture[[Interface\Buttons\ButtonHilight-Square]]
	button:GetHighlightTexture():ClearAllPoints()
	button:GetHighlightTexture():SetPoint('CENTER', 0, 0)
	button:GetHighlightTexture():SetWidth(24)
	button:GetHighlightTexture():SetHeight(23)
	return button
end

function CreateButton(key)
	local settings = Clean_Up_Settings[key]
	local button = BrushButton()
	_M[key].button = button
	button:SetScript('OnUpdate', function()
		if settings.parent and getglobal(settings.parent) then
			UpdateButton(key)
			this:SetScript('OnUpdate', nil)
		end
	end)
	button:SetScript('OnClick', function()
		PlaySoundFile[[Interface\AddOns\Clean_Up\UI_BagSorting_01.ogg]]
		containers = _M[key].containers
		_F:Show()
	end)
	button:SetScript('OnEnter', function()
		GameTooltip:SetOwner(this)
		GameTooltip:AddLine(_M[key].tooltip)
		GameTooltip:Show()
	end)
	button:SetScript('OnLeave', function()
		GameTooltip:Hide()
	end)
end

function UpdateButton(key)
	local button, settings = _M[key].button, Clean_Up_Settings[key]
	button:SetParent(settings.parent)
	button:SetPoint('CENTER', unpack(settings.position))
	button:SetScale(settings.scale)
	button:Show()
end

function CreateButtonPlacer()
	local frame = CreateFrame('EditBox', nil, UIParent)
	buttonPlacer = frame
	frame:EnableMouseWheel(true)
	frame:SetTextColor(0, 0, 0, 0)
	frame:SetFrameStrata'FULLSCREEN_DIALOG'
	frame:SetAllPoints()
	frame:Hide()
	local targetMarker = frame:CreateTexture()
	targetMarker:SetTexture(1, 1, 0, .5)

	local buttonPreview = BrushButton(frame)
	buttonPreview:EnableMouse(false)
	buttonPreview:SetAlpha(.5)

	function TargetNext()
		local f = frame.target
		while true do
			f = EnumerateFrames(f)
			if f and f:GetName() and f:GetCenter() then
				local scale, x, y = f:GetEffectiveScale(), GetCursorPosition()
				if f:GetLeft() * scale <= x and f:GetRight() * scale >= x and f:GetBottom() * scale <= y and f:GetTop() * scale >= y then
					frame.target = f
					targetMarker:SetAllPoints(f)
					buttonPreview:SetScale(scale * this.scale)
					RaidWarningFrame:AddMessage(f:GetName())
					return f
				end
			end
		end
	end

	frame:SetScript('OnShow', function()
		this.scale = 1
		this.target = nil
		TargetNext()
	end)
	frame:SetScript('OnEscapePressed', function() this:Hide() end)
	frame:SetScript('OnMouseWheel', function()
		this.scale = max(0, this.scale + arg1 * .05)
		buttonPreview:SetScale(this.target:GetEffectiveScale() * this.scale)
	end)
	frame:SetScript('OnMouseDown', function()
		if arg1 == 'LeftButton' then
			this:Hide()
			local x, y = GetCursorPosition()
			local targetScale, targetX, targetY = this.target:GetEffectiveScale(), this.target:GetCenter()
			Clean_Up_Settings[this.key] = {parent=this.target:GetName(), position={(x/targetScale-targetX)/this.scale, (y/targetScale-targetY)/this.scale}, scale=this.scale}
			UpdateButton(this.key)
		elseif arg1 == 'RightButton' then
			this.target = TargetNext(this.target)
		end
	end)
	frame:SetScript('OnUpdate', function()
		local scale, x, y = buttonPreview:GetEffectiveScale(), GetCursorPosition()
		buttonPreview:SetPoint('CENTER', UIParent, 'BOTTOMLEFT', x/scale, y/scale)
	end)
end

function Move(src, dst)
    local texture, _, srcLocked = GetContainerItemInfo(src.container, src.position)
    local _, _, dstLocked = GetContainerItemInfo(dst.container, dst.position)
    
	if texture and not srcLocked and not dstLocked then
		ClearCursor()
       	PickupContainerItem(src.container, src.position)
		PickupContainerItem(dst.container, dst.position)

		if src.item == dst.item then
			local count = min(src.count, itemStacks[dst.item] - dst.count)
			src.count = src.count - count
			dst.count = dst.count + count
			if src.count == 0 then
				src.item = nil
			end
		else
			src.item, dst.item = dst.item, src.item
			src.count, dst.count = dst.count, src.count
		end

		return true
    end
end

function TooltipInfo(container, position)
	local chargesPattern = '^' .. gsub(gsub(ITEM_SPELL_CHARGES_P1, '%%d', '(%%d+)'), '%%%d+%$d', '(%%d+)') .. '$'

	Clean_Up_Tooltip:SetOwner(UIParent, 'ANCHOR_NONE')
	Clean_Up_Tooltip:ClearLines()

	if container == BANK_CONTAINER then
		Clean_Up_Tooltip:SetInventoryItem('player', BankButtonIDToInvSlotID(position))
	else
		Clean_Up_Tooltip:SetBagItem(container, position)
	end

	local charges, usable, soulbound, quest, conjured
	for i = 1, Clean_Up_Tooltip:NumLines() do
		local text = getglobal('Clean_Up_TooltipTextLeft' .. i):GetText()

		local _, _, chargeString = strfind(text, chargesPattern)
		if chargeString then
			charges = tonumber(chargeString)
		elseif strfind(text, '^' .. ITEM_SPELL_TRIGGER_ONUSE) then
			usable = true
		elseif text == ITEM_SOULBOUND then
			soulbound = true
		elseif text == ITEM_BIND_QUEST then
			quest = true
		elseif text == ITEM_CONJURED then
			conjured = true
		end
	end

	return charges or 1, usable, soulbound, quest, conjured
end

function Sort()
	local complete = true

	for _, dst in model do
		if dst.targetItem and (dst.item ~= dst.targetItem or dst.count < dst.targetCount) then
			complete = false

			local sources, rank = {}, {}

			for _, src in model do
				if src.item == dst.targetItem
					and src ~= dst
					and not (dst.item and src.class and src.class ~= itemClasses[dst.item])
					and not (src.targetItem and src.item == src.targetItem and src.count <= src.targetCount)
				then
					rank[src] = abs(src.count - dst.targetCount + (dst.item == dst.targetItem and dst.count or 0))
					tinsert(sources, src)
				end
			end

			sort(sources, function(a, b) return rank[a] < rank[b] end)

			for _, src in sources do
				if Move(src, dst) then
					break
				end
			end
		end
	end

	return complete
end

function Stack()
	for _, src in model do
		if src.item and src.count < itemStacks[src.item] and src.item ~= src.targetItem then
			for _, dst in model do
				if dst ~= src and dst.item and dst.item == src.item and dst.count < itemStacks[dst.item] and dst.item ~= dst.targetItem then
					Move(src, dst)
				end
			end
		end
	end
end

do
	local counts

	local function insert(t, v)
		if Clean_Up_Settings.reversed then
			tinsert(t, v)
		else
			tinsert(t, 1, v)
		end
	end

	local function assign(slot, item)
		if counts[item] > 0 then
			local count
			if Clean_Up_Settings.reversed and mod(counts[item], itemStacks[item]) ~= 0 then
				count = mod(counts[item], itemStacks[item])
			else
				count = min(counts[item], itemStacks[item])
			end
			slot.targetItem = item
			slot.targetCount = count
			counts[item] = counts[item] - count
			return true
		end
	end

	function CreateModel()
		model, counts = {}, {}
		for _, container in containers do
			local class = ContainerClass(container)
			for position = 1, GetContainerNumSlots(container) do
				if not  Clean_Up_Settings.ignored[SlotKey(container, position)] then
					local slot = {container=container, position=position, class=class}
					local item = Item(container, position)
					if item then
						local _, count = GetContainerItemInfo(container, position)
						slot.item = item
						slot.count = count
						counts[item] = (counts[item] or 0) + count
					end
					insert(model, slot)
				end
			end
		end

		local free = {}
		for item, count in counts do
			local stacks = ceil(count / itemStacks[item])
			free[item] = stacks
			if itemClasses[item] then
				free[itemClasses[item]] = (free[itemClasses[item]] or 0) + stacks
			end
		end
		for _, slot in model do
			if slot.class and free[slot.class] then
				free[slot.class] = free[slot.class] - 1
			end
		end

		local items = {}
		for item in counts do
			tinsert(items, item)
		end
		sort(items, function(a, b) return LT(itemSortKeys[a], itemSortKeys[b]) end)

		for _, slot in model do
			if slot.class then
				for _, item in items do
					if itemClasses[item] == slot.class and assign(slot, item) then
						break
					end
				end
			else
				for _, item in items do
					if (not itemClasses[item] or free[itemClasses[item]] > 0) and assign(slot, item) then
						if itemClasses[item] then
							free[itemClasses[item]] = free[itemClasses[item]] - 1
						end
						break
					end
				end
			end
		end
	end
end

function ContainerClass(container)
	if container ~= 0 and container ~= BANK_CONTAINER then
		local name = GetBagName(container)
		if name then		
			for class, info in CLASSES do
				for _, itemID in info.containers do
					if name == GetItemInfo(itemID) then
						return class
					end
				end	
			end
		end
	end
end

function Item(container, position)
	local link = GetContainerItemLink(container, position)
	if link then
		local _, _, itemID, enchantID, suffixID, uniqueID = strfind(link, 'item:(%d+):(%d*):(%d*):(%d*)')
		itemID = tonumber(itemID)
		local _, _, quality, _, type, subType, stack, invType = GetItemInfo(itemID)
		local charges, usable, soulbound, quest, conjured = TooltipInfo(container, position)

		local key = format('%s:%s:%s:%s:%s:%s', itemID, enchantID, suffixID, uniqueID, charges, (soulbound and 1 or 0))

		local sortKey = {}

		-- hearthstone
		if itemID == 6948 then
			tinsert(sortKey, 1)

		-- mounts
		elseif MOUNT[itemID] then
			tinsert(sortKey, 2)

		-- special items
		elseif SPECIAL[itemID] then
			tinsert(sortKey, 3)

		-- key items
		elseif KEY[itemID] then
			tinsert(sortKey, 4)

		-- tools
		elseif TOOL[itemID] then
			tinsert(sortKey, 5)

		-- soul shards
		elseif itemID == 6265 then
			tinsert(sortKey, 14)

		-- conjured items
		elseif conjured then
			tinsert(sortKey, 15)

		-- soulbound items
		elseif soulbound then
			tinsert(sortKey, 6)

		-- enchanting reagents
		elseif ENCHANTING_REAGENT[itemID] then
			tinsert(sortKey, 7)

		-- other reagents
		elseif type == ITEM_TYPES[9] then
			tinsert(sortKey, 8)

		-- quest items
		elseif quest then
			tinsert(sortKey, 10)

		-- consumables
		elseif usable and type ~= ITEM_TYPES[1] and type ~= ITEM_TYPES[2] and type ~= ITEM_TYPES[8] or type == ITEM_TYPES[4] then
			tinsert(sortKey, 9)

		-- higher quality
		elseif quality > 1 then
			tinsert(sortKey, 11)

		-- common quality
		elseif quality == 1 then
			tinsert(sortKey, 12)

		-- junk
		elseif quality == 0 then
			tinsert(sortKey, 13)
		end
		
		tinsert(sortKey, ItemTypeKey(type))
		tinsert(sortKey, ItemInvTypeKey(type, subType, invType))
		tinsert(sortKey, ItemSubTypeKey(type, subType))
		tinsert(sortKey, -quality)
		tinsert(sortKey, itemID)
		tinsert(sortKey, (Clean_Up_Settings.reversed and 1 or -1) * charges)
		tinsert(sortKey, suffixID)
		tinsert(sortKey, enchantID)
		tinsert(sortKey, uniqueID)

		itemStacks[key] = stack
		itemSortKeys[key] = sortKey

		for class, info in CLASSES do
			if info.items[itemID] then
				itemClasses[key] = class
				break
			end
		end

		return key
	end
end
