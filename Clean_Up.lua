local _G, _M, _F = getfenv(0), {}, CreateFrame'Frame'
setfenv(1, setmetatable(_M, {__index=_G}))
_F:Hide()
_F:SetScript('OnUpdate', function() _M.UPDATE() end)
_F:SetScript('OnEvent', function() _M[event](this) end)
for _, event in {'ADDON_LOADED', 'MERCHANT_SHOW', 'MERCHANT_CLOSED'} do
	_F:RegisterEvent(event)
end

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
	assignments = {},
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

function Present(...)
	local called
	return function()
		if not called then
			called = true
			return unpack(arg)
		end
	end
end

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
				for item in Present(Item(container, position)) do
					local slotKey = SlotKey(container, position)
					Clean_Up_Settings.assignments[slotKey] = item
					Print(slotKey .. ' assigned to ' .. GetContainerItemLink(container, position))
				end
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
			local slot = SlotKey(container, position)
			if IsAltKeyDown() then
				if Clean_Up_Settings.assignments[slot] then
					Clean_Up_Settings.assignments[slot] = nil
					Print(slot .. ' freed')
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

function MERCHANT_SHOW()
	atMerchant = true
end

function MERCHANT_CLOSED()
	atMerchant = false
end

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
		Go(key)
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
	button:Show()
end

function CreateButtonPlacer()
	local frame = CreateFrame('Button', nil, UIParent)
	buttonPlacer = frame
	frame:SetFrameStrata'FULLSCREEN_DIALOG'
	frame:SetAllPoints()
	frame:Hide()

	local escapeInterceptor = CreateFrame('EditBox', nil, frame)
	escapeInterceptor:SetScript('OnEscapePressed', function() frame:Hide() end)

	local buttonPreview = BrushButton(frame)
	buttonPreview:EnableMouse(false)
	buttonPreview:SetAlpha(.5)

	frame:SetScript('OnShow', function() escapeInterceptor:SetFocus() end)
	frame:SetScript('OnClick', function() this:EnableMouse(false) end)
	frame:SetScript('OnUpdate', function()
		local scale, x, y = buttonPreview:GetEffectiveScale(), GetCursorPosition()
		buttonPreview:SetPoint('CENTER', UIParent, 'BOTTOMLEFT', x/scale, y/scale)
		if not this:IsMouseEnabled() and GetMouseFocus() then
			local parent = GetMouseFocus()
			local parentScale, parentX, parentY = parent:GetEffectiveScale(), parent:GetCenter()
			Clean_Up_Settings[this.key] = {parent=parent:GetName(), position={x/parentScale-parentX, y/parentScale-parentY}}
			UpdateButton(this.key)
			this:EnableMouse(true)
			this:Hide()
		end
	end)
end

function Move(src, dst)
    local texture, _, srcLocked = GetContainerItemInfo(src.container, src.position)
    local _, _, dstLocked = GetContainerItemInfo(dst.container, dst.position)
    
	if texture and not srcLocked and not dstLocked then
		ClearCursor()
       	PickupContainerItem(src.container, src.position)
		PickupContainerItem(dst.container, dst.position)

		if src.state.item == dst.state.item then
			local count = min(src.state.count, Info(dst.state.item).stack - dst.state.count)
			src.state.count = src.state.count - count
			dst.state.count = dst.state.count + count
			if src.state.count == 0 then
				src.state.item = nil
			end
		else
			src.state, dst.state = dst.state, src.state
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
		if dst.item and (dst.state.item ~= dst.item or dst.state.count < dst.count) then
			complete = false

			local sources, rank = {}, {}

			for _, src in model do
				if src.state.item == dst.item
					and src ~= dst
					and not (dst.state.item and src.class and src.class ~= Info(dst.state.item).class)
					and not (src.item and src.state.item == src.item and src.state.count <= src.count)
				then
					rank[src] = abs(src.state.count - dst.count + (dst.state.item == dst.item and dst.state.count or 0))
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
		if src.state.item and src.state.count < Info(src.state.item).stack and src.state.item ~= src.item then
			for _, dst in model do
				if dst ~= src and dst.state.item and dst.state.item == src.state.item and dst.state.count < Info(dst.state.item).stack and dst.state.item ~= dst.item then
					Move(src, dst)
				end
			end
		end
	end
end

function Go(key)
	containers = _M[key].containers
	CreateModel()
	_F:Show()
end

do
	local items, counts

	local function insert(t, v)
		if Clean_Up_Settings.reversed then
			tinsert(t, v)
		else
			tinsert(t, 1, v)
		end
	end

	local function assign(slot, item)
		if counts[item] > 0 then
			local count = min(counts[item], Info(item).stack)
			slot.item = item
			slot.count = count
			counts[item] = counts[item] - count
			return true
		end
	end

	local function assignCustom()
		for _, slot in model do
			for item in Present(Clean_Up_Settings.assignments[SlotKey(slot.container, slot.position)]) do
				if counts[item] then
					assign(slot, item)
				end
			end
		end
	end

	local function assignSpecial()
		for key, class in CLASSES do
			for _, slot in model do
				if slot.class == key and not slot.item then
					for _, item in items do
						if Info(item).class == key and assign(slot, item) then
							break
						end
				    end
			    end
			end
		end
	end

	local function assignRemaining()
		for _, slot in model do
			if not slot.class and not slot.item then
				for _, item in items do
					if assign(slot, item) then
						break
					end
			    end
		    end
		end
	end

	function CreateModel()
		model = {}
		counts = {}

		for _, container in containers do
			local class = Class(container)
			for position = 1, GetContainerNumSlots(container) do
				local slot = {container=container, position=position, class=class}
				local item = Item(container, position)
				if item then
					local _, count = GetContainerItemInfo(container, position)
					slot.state = {item=item, count=count}
					counts[item] = (counts[item] or 0) + count
				else
					slot.state = {}
				end
				insert(model, slot)
			end
		end
		items = {}
		for item, _ in counts do
			tinsert(items, item)
		end
		sort(items, function(a, b) return LT(Info(a).sortKey, Info(b).sortKey) end)

		assignCustom()
		assignSpecial()
		assignRemaining()
	end
end

do
	local cache = {}
	function Class(container)
		if not cache[container] and container ~= 0 and container ~= BANK_CONTAINER then
			for name in Present(GetBagName(container)) do		
				for class, info in CLASSES do
					for _, itemID in info.containers do
						if name == GetItemInfo(itemID) then
							cache[container] = class
						end
					end	
				end
			end
		end
		return cache[container]
	end
end

do
	local cache = {}

	function Info(item)
		return setmetatable({}, {__index=cache[item]})
	end

	function Item(container, position)
		for link in Present(GetContainerItemLink(container, position)) do
			local _, _, itemID, enchantID, suffixID, uniqueID = strfind(link, 'item:(%d+):(%d*):(%d*):(%d*)')
			itemID = tonumber(itemID)
			local _, _, quality, _, type, subType, stack, invType = GetItemInfo(itemID)
			local charges, usable, soulbound, quest, conjured = TooltipInfo(container, position)

			local key = format('%s:%s:%s:%s:%s:%s', itemID, enchantID, suffixID, uniqueID, charges, (soulbound and 1 or 0))

			if not cache[key] then

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

				-- conjured items
				elseif conjured then
					tinsert(sortKey, 13)

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
				tinsert(sortKey, -charges)
				tinsert(sortKey, suffixID)
				tinsert(sortKey, enchantID)
				tinsert(sortKey, uniqueID)

				cache[key] = {
					stack = stack,
					sortKey = sortKey,
				}

				for class, info in CLASSES do
					if info.items[itemID] then
						cache[key].class = class
					end
				end
			end

			return key
		end
	end
end
