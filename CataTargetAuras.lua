if not CLASSIC_API_VERSION then
	DEFAULT_CHAT_FRAME:AddMessage("CataTargetAuras requires ClassicAPI. https://github.com/brues-code/ClassicAPI/releases")
	return
end

local _G = getfenv(0)
local MAX_TARGET_DEBUFFS = 16
local MAX_TARGET_BUFFS = 32
local AURA_START_X = 5
local AURA_START_Y = 32
local AURA_OFFSET_Y = 3
local LARGE_AURA_SIZE = 21
local SMALL_AURA_SIZE = 17
local AURA_ROW_WIDTH = 122
local TOT_AURA_ROW_WIDTH = 101
local NUM_TOT_AURA_ROWS = 2

local largeBuffList = {}
local largeDebuffList = {}

function TargetDebuffButton_Update()
	TargetFrame_UpdateAuras(TargetFrame)
end

TargetofTargetFrame:HookScript("OnShow", function() TargetFrame_UpdateAuras(TargetFrame) end)
TargetofTargetFrame:HookScript("OnHide", function() TargetFrame_UpdateAuras(TargetFrame) end)

TargetFrame.totFrame = TargetofTargetFrame
TargetFrame.showAuraCount = true
TargetFrame.TOT_AURA_ROW_WIDTH = TOT_AURA_ROW_WIDTH
TargetFrame.buffs = CreateFrame("Frame", "TargetFrameBuffs", TargetFrame)
TargetFrame.buffs:SetWidth(10)
TargetFrame.buffs:SetHeight(10)
TargetFrame.buffs:Hide()
TargetFrame.debuffs = CreateFrame("Frame", "TargetFrameDebuffs", TargetFrame)
TargetFrame.debuffs:SetWidth(10)
TargetFrame.debuffs:SetHeight(10)
TargetFrame.debuffs:Hide()

function TargetFrame_UpdateAuras(self)
	local numBuffs = 0
	local selfName = self:GetName()
	local canAssist = UnitCanAssist("player", self.unit)
	
	local filter
	if ( SHOW_CASTABLE_BUFFS == "1" and canAssist ) then
		filter = "RAID"
	end
	
	for i = 1, MAX_TARGET_BUFFS do
		local name, icon, count, debuffType, duration, expirationTime, caster, canStealOrPurge = C_UnitAuras.UnitBuff(self.unit, i, filter)
		local frameName = selfName.."Buff"..i
		local frame = _G[frameName]
		if ( not frame ) then
			if ( not icon ) then
				break
			else
				-- frame = CreateFrame("Button", frameName, self, "TargetBuffFrameTemplate")
				frame = CreateFrame("Button", frameName, self, "TargetBuffButtonTemplate")
				frame.unit = self.unit
			end
		end
		if ( icon and ( not self.maxBuffs or i <= self.maxBuffs ) ) then
			frame:SetID(i)
			frame.id = i
			-- set the icon
			local frameIcon = _G[frameName.."Icon"]
			frameIcon:SetTexture(icon)

			-- set the count
			local frameCount = _G[frameName.."Count"]
			if not frameCount then
				frameCount = frame:CreateFontString(frameName.."Count", "ARTWORK", "NumberFontNormalSmall")
				frameCount:SetJustifyH("RIGHT")
				frameCount:SetPoint("BOTTOMRIGHT", 3, 0)
			end
			if ( count > 1 and self.showAuraCount ) then
				frameCount:SetText(count)
				frameCount:Show()
			else
				frameCount:Hide()
			end
			
			-- Handle cooldowns
			local frameCooldown = _G[frameName.."Cooldown"]
			if not frameCooldown then
				frameCooldown = CreateFrame("Cooldown", frameName.."Cooldown", frame, "CooldownFrameTemplate")
				frameCooldown:SetReverse(true)
				frameCooldown:SetDrawEdge(true)
				frameCooldown:SetPoint("CENTER", frame, "CENTER", 0, -1)
			end

			if ( duration > 0 ) then
				frameCooldown:Show()
				CooldownFrame_SetTimer(frameCooldown, expirationTime - duration, duration, 1)
			else
				frameCooldown:Hide()
			end

			-- Show stealable frame if the target is not the current player and the buff is stealable.
			local frameStealable = _G[frameName.."Stealable"]
			if not frameStealable then
				frameStealable = frame:CreateTexture(frameName.."Stealable", "OVERLAY")
				frameStealable:SetWidth(24)
				frameStealable:SetHeight(24)
				frameStealable:SetPoint("CENTER", frame, "CENTER", 0, 0)
				frameStealable:SetTexture("Interface\\AddOns\\TargetFrameBuff\\UI-TargetingFrame-Stealable")
				frameStealable:SetBlendMode("ADD")
			end
			if ( not playerIsTarget and canStealOrPurge ) then
				frameStealable:Show()
			else
				frameStealable:Hide()
			end

			-- set the buff to be big if the buff is cast by the player or his pet
			largeBuffList[i] = caster == "player" or caster == "pet"

			numBuffs = numBuffs + 1

			frame:ClearAllPoints()
			frame:Show()
		else
			frame:Hide()
		end
	end

	local color
	local frameBorder
	local numDebuffs = 0
	-- local isEnemy = UnitCanAttack("player", self.unit)
	
	if ( SHOW_DISPELLABLE_DEBUFFS == "1" and canAssist ) then
		filter = "RAID"
	else
		filter = nil
	end
	
	local frameNum = 1
	local index = 1
	
	while ( frameNum <= (self.maxDebuffs or MAX_TARGET_DEBUFFS) ) do
		local name, icon, count, debuffType, duration, expirationTime, caster = C_UnitAuras.UnitDebuff(self.unit, index, filter)
		if not name then break end
		if ( TargetFrame_ShouldShowDebuff(self.unit, index, filter) ) then
			local frameName = selfName.."Debuff"..frameNum
			local frame = _G[frameName]
			if ( icon ) then
				if ( not frame ) then
					-- frame = CreateFrame("Button", frameName, self, "TargetDebuffFrameTemplate")
					frame = CreateFrame("Button", frameName, self, "TargetDebuffButtonTemplate")
					frame.unit = self.unit
				end
				frame:SetID(index)
				frame.id = index
				-- set the icon
				local frameIcon = _G[frameName.."Icon"]
				frameIcon:SetTexture(icon)

				-- set the count
				local frameCount = _G[frameName.."Count"]
				if not frameCount then
					frameCount = frame:CreateFontString("$parentCount", "ARTWORK", "NumberFontNormalSmall")
					frameCount:SetJustifyH("RIGHT")
					frameCount:SetPoint("BOTTOMRIGHT", 3, 0)
				end
				if ( count > 1 and self.showAuraCount ) then
					frameCount:SetText(count)
					frameCount:Show()
				else
					frameCount:Hide()
				end

				-- Handle cooldowns
				local frameCooldown = _G[frameName.."Cooldown"]
				if not frameCooldown then
					frameCooldown = CreateFrame("Cooldown", "$parentCooldown", frame, "CooldownFrameTemplate")
					frameCooldown:SetReverse(true)
					frameCooldown:SetDrawEdge(true)
					frameCooldown:SetPoint("CENTER", frame, "CENTER", 0, -1)
				end
				if ( duration > 0 ) then
					frameCooldown:Show()
					CooldownFrame_SetTimer(frameCooldown, expirationTime - duration, duration, 1)
				else
					frameCooldown:Hide()
				end

				-- set debuff type color
				if ( debuffType ) then
					color = DebuffTypeColor[debuffType]
				else
					color = DebuffTypeColor["none"]
				end
				frameBorder = _G[frameName.."Border"]
				frameBorder:SetVertexColor(color.r, color.g, color.b)

				-- set the debuff to be big if the buff is cast by the player or his pet
				largeDebuffList[index] = caster == "player" or caster == "pet"

				numDebuffs = numDebuffs + 1

				frame:ClearAllPoints()
				frame:Show()
				
				frameNum = frameNum + 1
			end
		end
		index = index + 1
	end
	
	for i = frameNum, MAX_TARGET_DEBUFFS do
		local frame = _G[selfName.."Debuff"..i]
		if ( frame ) then
			frame:Hide()
		else
			break
		end
	end
	
	self.auraRows = 0
	
	local mirrorAurasVertically = false
	if ( self == TargetFrame and TARGET_FRAME_BUFFS_ON_TOP ) then
		mirrorAurasVertically = true
	end
	local haveTargetofTarget
	if ( self.totFrame ) then
		haveTargetofTarget = self.totFrame:IsShown()
	end
	self.spellbarAnchor = nil
	local maxRowWidth
	-- update buff positions
	maxRowWidth = ( haveTargetofTarget and self.TOT_AURA_ROW_WIDTH ) or AURA_ROW_WIDTH
	TargetFrame_UpdateAuraPositions(self, selfName.."Buff", numBuffs, numDebuffs, largeBuffList, TargetFrame_UpdateBuffAnchor, maxRowWidth, 3, mirrorAurasVertically)
	-- update debuff positions
	maxRowWidth = ( haveTargetofTarget and self.auraRows < NUM_TOT_AURA_ROWS and self.TOT_AURA_ROW_WIDTH ) or AURA_ROW_WIDTH
	TargetFrame_UpdateAuraPositions(self, selfName.."Debuff", numDebuffs, numBuffs, largeDebuffList, TargetFrame_UpdateDebuffAnchor, maxRowWidth, 4, mirrorAurasVertically)
	-- update the spell bar position
	if ( self.spellbar ) then
		-- Target_Spellbar_AdjustPosition(self.spellbar)
	end
end

function TargetFrame_ShouldShowDebuff(unit, index, filter)
	--This is an enemy
	if ( SHOW_ALL_ENEMY_DEBUFFS == "1" or not UnitCanAttack("player", unit) ) then
		return true
	else
		local name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, shouldConsolidate, spellId, canApplyAura, isBossDebuff, isCastByPlayer = C_UnitAuras.UnitDebuff(unit, index, filter)

		-- local hasCustom, alwaysShowMine, showForMySpec = SpellGetVisibilityInfo(spellId, "ENEMY_TARGET")
		-- if ( hasCustom ) then
		-- 	return showForMySpec or (alwaysShowMine and (unitCaster == "player" or unitCaster == "pet" or unitCaster == "vehicle") )
		-- else
			return not isCastByPlayer or unitCaster == "player" or unitCaster == "pet" or unitCaster == "vehicle"
		-- end
	end
end

function TargetFrame_UpdateAuraPositions(self, auraName, numAuras, numOppositeAuras, largeAuraList, updateFunc, maxRowWidth, offsetX, mirrorAurasVertically)
	-- a lot of this complexity is in place to allow the auras to wrap around the target of target frame if it's shown

	-- Position auras
	local size
	local offsetY = AURA_OFFSET_Y
	-- current width of a row, increases as auras are added and resets when a new aura's width exceeds the max row width
	local rowWidth = 0
	local firstBuffOnRow = 1
	for i=1, numAuras do
		-- update size and offset info based on large aura status
		if ( largeAuraList[i] ) then
			size = LARGE_AURA_SIZE
			offsetY = AURA_OFFSET_Y + AURA_OFFSET_Y
		else
			size = SMALL_AURA_SIZE
		end

		-- anchor the current aura
		if ( i == 1 ) then
			rowWidth = size
			self.auraRows = self.auraRows + 1
		else
			rowWidth = rowWidth + size + offsetX
		end
		if ( rowWidth > maxRowWidth ) then
			-- this aura would cause the current row to exceed the max row width, so make this aura
			-- the start of a new row instead
			updateFunc(self, auraName, i, numOppositeAuras, firstBuffOnRow, size, offsetX, offsetY, mirrorAurasVertically)

			rowWidth = size
			self.auraRows = self.auraRows + 1
			firstBuffOnRow = i
			offsetY = AURA_OFFSET_Y

			if ( self.auraRows > NUM_TOT_AURA_ROWS ) then
				-- if we exceed the number of tot rows, then reset the max row width
				-- note: don't have to check if we have tot because AURA_ROW_WIDTH is the default anyway
				maxRowWidth = AURA_ROW_WIDTH
			end
		else
			updateFunc(self, auraName, i, numOppositeAuras, i - 1, size, offsetX, offsetY, mirrorAurasVertically)
		end
	end
end

function TargetFrame_UpdateBuffAnchor(self, buffName, index, numDebuffs, anchorIndex, size, offsetX, offsetY, mirrorVertically)
	--For mirroring vertically
	local point, relativePoint
	local startY, auraOffsetY
	if ( mirrorVertically ) then
		point = "BOTTOM"
		relativePoint = "TOP"
		startY = -15
		if ( self.threatNumericIndicator and self.threatNumericIndicator:IsShown() ) then
			startY = startY + self.threatNumericIndicator:GetHeight()
		end
		offsetY = - offsetY
		auraOffsetY = -AURA_OFFSET_Y
	else
		point = "TOP"
		relativePoint="BOTTOM"
		startY = AURA_START_Y
		auraOffsetY = AURA_OFFSET_Y
	end
	
	local buff = _G[buffName..index]
	if ( index == 1 ) then
		if ( UnitIsFriend("player", self.unit) or numDebuffs == 0 ) then
			-- unit is friendly or there are no debuffs...buffs start on top
			buff:SetPoint(point.."LEFT", self, relativePoint.."LEFT", AURA_START_X, startY)			
		else
			-- unit is not friendly and we have debuffs...buffs start on bottom
			buff:SetPoint(point.."LEFT", self.debuffs, relativePoint.."LEFT", 0, -offsetY)
		end
		self.buffs:SetPoint(point.."LEFT", buff, point.."LEFT", 0, 0)
		self.buffs:SetPoint(relativePoint.."LEFT", buff, relativePoint.."LEFT", 0, -auraOffsetY)
		self.spellbarAnchor = buff
	elseif ( anchorIndex ~= (index-1) ) then
		-- anchor index is not the previous index...must be a new row
		buff:SetPoint(point.."LEFT", _G[buffName..anchorIndex], relativePoint.."LEFT", 0, -offsetY)
		self.buffs:SetPoint(relativePoint.."LEFT", buff, relativePoint.."LEFT", 0, -auraOffsetY)
		self.spellbarAnchor = buff
	else
		-- anchor index is the previous index
		buff:SetPoint(point.."LEFT", _G[buffName..anchorIndex], point.."RIGHT", offsetX, 0)
	end

	-- Resize
	buff:SetWidth(size)
	buff:SetHeight(size)
end

function TargetFrame_UpdateDebuffAnchor(self, debuffName, index, numBuffs, anchorIndex, size, offsetX, offsetY, mirrorVertically)
	local buff = _G[debuffName..index]
	local isFriend = UnitIsFriend("player", self.unit)
	
	--For mirroring vertically
	local point, relativePoint
	local startY, auraOffsetY
	if ( mirrorVertically ) then
		point = "BOTTOM"
		relativePoint = "TOP"
		startY = -15
		if ( self.threatNumericIndicator and self.threatNumericIndicator:IsShown() ) then
			startY = startY + self.threatNumericIndicator:GetHeight()
		end
		offsetY = - offsetY
		auraOffsetY = -AURA_OFFSET_Y
	else
		point = "TOP"
		relativePoint="BOTTOM"
		startY = AURA_START_Y
		auraOffsetY = AURA_OFFSET_Y
	end
	
	if ( index == 1 ) then
		if ( isFriend and numBuffs > 0 ) then
			-- unit is friendly and there are buffs...debuffs start on bottom
			buff:SetPoint(point.."LEFT", self.buffs, relativePoint.."LEFT", 0, -offsetY)
		else
			-- unit is not friendly or there are no buffs...debuffs start on top
			buff:SetPoint(point.."LEFT", self, relativePoint.."LEFT", AURA_START_X, startY)
		end
		self.debuffs:SetPoint(point.."LEFT", buff, point.."LEFT", 0, 0)
		self.debuffs:SetPoint(relativePoint.."LEFT", buff, relativePoint.."LEFT", 0, -auraOffsetY)
		if ( ( isFriend ) or ( not isFriend and numBuffs == 0) ) then
			self.spellbarAnchor = buff
		end
	elseif ( anchorIndex ~= (index-1) ) then
		-- anchor index is not the previous index...must be a new row
		buff:SetPoint(point.."LEFT", _G[debuffName..anchorIndex], relativePoint.."LEFT", 0, -offsetY)
		self.debuffs:SetPoint(relativePoint.."LEFT", buff, relativePoint.."LEFT", 0, -auraOffsetY)
		if ( ( isFriend ) or ( not isFriend and numBuffs == 0) ) then
			self.spellbarAnchor = buff
		end
	else
		-- anchor index is the previous index
		buff:SetPoint(point.."LEFT", _G[debuffName..(index-1)], point.."RIGHT", offsetX, 0)
	end

	-- Resize
	buff:SetWidth(size)
	buff:SetHeight(size)
	local debuffFrame =_G[debuffName..index.."Border"]
	debuffFrame:SetWidth(size+2)
	debuffFrame:SetHeight(size+2)
end



function TargetofTarget_Update()
	local self = TargetofTargetFrame
	local parent = TargetFrame
	local show = false

	if ( SHOW_TARGET_OF_TARGET == "1" and UnitExists(parent.unit) and UnitExists(self.unit) and ( not UnitIsUnit(PlayerFrame.unit, parent.unit) ) and ( UnitHealth(parent.unit) > 0 ) ) then
		if ( ( SHOW_TARGET_OF_TARGET_STATE == "5" ) or
		     ( SHOW_TARGET_OF_TARGET_STATE == "4" and ( (GetNumRaidMembers() > 0) or (GetNumPartyMembers() > 0) ) ) or
		     ( SHOW_TARGET_OF_TARGET_STATE == "3" and ( (GetNumRaidMembers() == 0) and (GetNumPartyMembers() == 0) ) ) or
		     ( SHOW_TARGET_OF_TARGET_STATE == "2" and ( (GetNumPartyMembers() > 0) and (GetNumRaidMembers() == 0) ) ) or
		     ( SHOW_TARGET_OF_TARGET_STATE == "1" and ( GetNumRaidMembers() > 0 ) ) ) then
			show = true
		end
	end

	if ( show ) then
		if ( not self:IsShown() ) then
			self:Show()
		end
		UnitFrameHealthBar_Update(self.healthbar, self.unit)
		UnitFrameManaBar_Update(self.manabar, self.unit)
		TargetofTarget_CheckDead(self)
		TargetofTargetPortrait:SetAlpha(1.0)
		RefreshBuffs(self, 0, self.unit)
	else
		if ( self:IsShown() ) then
			self:Hide()
		end
	end
end
