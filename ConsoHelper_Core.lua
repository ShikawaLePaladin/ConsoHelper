-- Conso Helper - Core
-- Settings, bag/aura scanning, icon resolution, weapon enchant handling, minimap button, slash commands.

ConsoHelper = {}
local CH = ConsoHelper

local ADDON_VERSION = "1.1.2"

-- ============================================================================
-- SETTINGS
-- ============================================================================

local function InitDefaults()
  if not ConsoHelper_Settings then ConsoHelper_Settings = {} end
  local S = ConsoHelper_Settings
  S.version = ADDON_VERSION
  if not S.enabledBuffs then S.enabledBuffs = {} end
  if not S.buffTracker then S.buffTracker = {} end
  if not S.settings then S.settings = {} end

  local defaults = {
    scale = 1.0,
    updateInterval = 1,
    iconsPerRow = 10,
    iconSize = 26,
    iconSpacing = 4,
    pauseInCombat = true,
    hideInCombat = false,
    showTooltips = true,
    hoverToShow = false,
    lockFrame = false,
    showBackground = true,
    showTitle = true,
    showTimer = true,
    minimapAngle = 225,
    minimapHidden = false,
    shoppingThreshold = 1,
    framePosition = { point = "CENTER", relativeTo = "UIParent", relativePoint = "CENTER", x = 0, y = 32 },
  }
  for k, v in pairs(defaults) do
    if S.settings[k] == nil then S.settings[k] = v end
  end
end

-- ============================================================================
-- HELPERS
-- ============================================================================

function CH.UniqueKey(entry)
  if entry.kind == "enchant" then
    return entry.name .. "_" .. entry.slot
  end
  return entry.name
end

function CH.IsEnabled(entry)
  return CH.enabledSet[CH.UniqueKey(entry)] == true
end

function CH.SetEnabled(entry, value)
  local key = CH.UniqueKey(entry)
  if value then
    CH.enabledSet[key] = true
  else
    CH.enabledSet[key] = nil
  end
end

function CH.RebuildEnabledSet()
  CH.enabledSet = {}
  for _, key in ipairs(ConsoHelper_Settings.enabledBuffs) do
    CH.enabledSet[key] = true
  end
end

function CH.SaveEnabledSet()
  local list = {}
  for _, entry in ipairs(ConsoHelper_Data.buffs) do
    local key = CH.UniqueKey(entry)
    if CH.enabledSet[key] then
      table.insert(list, key)
    end
  end
  ConsoHelper_Settings.enabledBuffs = list
end

function CH.FormatTime(seconds)
  if not seconds or seconds <= 0 then return "" end
  if seconds >= 3600 then
    return string.format("%dh", math.ceil(seconds / 3600))
  elseif seconds >= 60 then
    return string.format("%d:%02d", math.floor(seconds / 60), math.floor(math.mod(seconds, 60)))
  else
    return string.format("%ds", math.floor(seconds))
  end
end

-- ============================================================================
-- ITEM ICON RESOLUTION (dynamic via GetItemInfo, no hardcoded icon paths)
-- ============================================================================

CH.iconCache = {}
CH.pendingIcons = {}
local FALLBACK_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

function CH.ResolveIcon(entry)
  if entry.kind == "spell" then
    return entry.icon
  end

  local cached = CH.iconCache[entry.itemID]
  if cached then return cached end

  local _, _, _, _, _, _, _, _, texture = GetItemInfo(entry.itemID)
  if texture then
    CH.iconCache[entry.itemID] = texture
    CH.pendingIcons[entry.itemID] = nil
    return texture
  end

  CH.pendingIcons[entry.itemID] = true
  return FALLBACK_ICON
end

local function RetryPendingIcons()
  local resolvedAny = false
  for itemID in pairs(CH.pendingIcons) do
    local _, _, _, _, _, _, _, _, texture = GetItemInfo(itemID)
    if texture then
      CH.iconCache[itemID] = texture
      CH.pendingIcons[itemID] = nil
      resolvedAny = true
    end
  end
  if resolvedAny and ConsoHelper_UI and ConsoHelper_UI.RefreshIcons then
    ConsoHelper_UI.RefreshIcons()
  end
end

-- ============================================================================
-- BAG SCANNING (keyed by itemID, parsed from item link - locale independent)
-- ============================================================================

CH.bagCache = {}
local bagCacheTime = 0

local function ParseItemID(itemLink)
  if not itemLink then return nil end
  local _, _, idString = string.find(itemLink, "item:(%d+)")
  if idString then return tonumber(idString) end
  return nil
end

function CH.ScanBags(force)
  local now = GetTime()
  if not force and (now - bagCacheTime) < 2 then return end

  local cache = {}
  for bag = 0, 4 do
    local slots = GetContainerNumSlots(bag)
    if slots and slots > 0 then
      for slot = 1, slots do
        local itemLink = GetContainerItemLink(bag, slot)
        if itemLink then
          local itemID = ParseItemID(itemLink)
          if itemID then
            local _, itemCount = GetContainerItemInfo(bag, slot)
            itemCount = itemCount or 0
            if itemCount < 0 then itemCount = math.abs(itemCount) end
            cache[itemID] = (cache[itemID] or 0) + itemCount
          end
        end
      end
    end
  end
  CH.bagCache = cache
  bagCacheTime = now
end

function CH.GetBagCount(entry)
  if not entry.itemID then return 0 end
  return CH.bagCache[entry.itemID] or 0
end

local function FindBagSlot(itemID)
  for bag = 0, 4 do
    local slots = GetContainerNumSlots(bag)
    if slots and slots > 0 then
      for slot = 1, slots do
        local itemLink = GetContainerItemLink(bag, slot)
        if itemLink and ParseItemID(itemLink) == itemID then
          return bag, slot
        end
      end
    end
  end
  return nil
end

function CH.UseItem(entry)
  local bag, slot = FindBagSlot(entry.itemID)
  if bag then
    UseContainerItem(bag, slot)
    return true
  end
  DEFAULT_CHAT_FRAME:AddMessage("|cffFF6B6BConso Helper:|r " .. entry.name .. " not found in bags.")
  return false
end

function CH.ApplyEnchant(entry)
  local bag, slot = FindBagSlot(entry.itemID)
  if not bag then
    DEFAULT_CHAT_FRAME:AddMessage("|cffFF6B6BConso Helper:|r " .. entry.name .. " not found in bags.")
    return false
  end

  local invSlot = (entry.slot == "mainhand") and 16 or 17
  local slotLabel = (entry.slot == "mainhand") and "MAIN HAND" or "OFF HAND"
  local slotButton = (entry.slot == "mainhand") and CharacterMainHandSlot or CharacterSecondaryHandSlot

  if not GetInventoryItemTexture("player", invSlot) then
    DEFAULT_CHAT_FRAME:AddMessage("|cffFF6B6BNo weapon equipped in " .. slotLabel .. " slot.|r")
    return false
  end

  UseContainerItem(bag, slot)

  if slotButton then
    slotButton:Click()
  else
    EquipCursorItem(invSlot)
  end

  DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00" .. entry.name .. " applied to your " .. slotLabel .. " weapon.|r")
  return true
end

-- ============================================================================
-- WEAPON ENCHANT STATE
-- ============================================================================

function CH.HasWeaponEnchant(slot)
  local hasMainHand, _, _, hasOffHand = GetWeaponEnchantInfo()
  if slot == "mainhand" then return hasMainHand and true or false end
  if slot == "offhand" then return hasOffHand and true or false end
  return false
end

function CH.GetWeaponEnchantRemaining(slot)
  local hasMainHand, mainExpire, _, hasOffHand, offExpire = GetWeaponEnchantInfo()
  if slot == "mainhand" and hasMainHand and mainExpire then
    return mainExpire / 1000
  elseif slot == "offhand" and hasOffHand and offExpire then
    return offExpire / 1000
  end
  return nil
end

-- ============================================================================
-- BUFF/AURA TRACKING (timestamp based, persisted across reload for consumables)
-- ============================================================================

-- Texture path casing returned by UnitBuff doesn't always match GetItemInfo's casing
-- for the same file, so everything is compared lower-cased.
-- Buff NAMES are also collected via a hidden scanning tooltip (SetUnitBuff), because
-- for several consumables the aura texture differs per server while the aura name is
-- stable (e.g. Cerebral Cortex Compound -> "Infallible Mind").
local activeAuraTextures = {}
local activeAuraNames = {}

local scanTip = CreateFrame("GameTooltip", "ConsoHelperScanTooltip", nil, "GameTooltipTemplate")
scanTip:SetOwner(UIParent, "ANCHOR_NONE")

local function Trim(s)
  if not s then return s end
  return string.gsub(s, "^%s*(.-)%s*$", "%1")
end

CH.lastAuraScan = {}

local function RefreshActiveAuras()
  activeAuraTextures = {}
  activeAuraNames = {}
  CH.lastAuraScan = {}

  for i = 1, 32 do
    local texture = UnitBuff("player", i)
    if not texture then break end
    activeAuraTextures[string.lower(texture)] = true

    scanTip:ClearLines()
    scanTip:SetUnitBuff("player", i)
    local nameLine = ConsoHelperScanTooltipTextLeft1
    local name = nameLine and Trim(nameLine:GetText())
    if name and name ~= "" then
      activeAuraNames[string.lower(name)] = true
    end

    table.insert(CH.lastAuraScan, { texture = texture, name = name })
  end
end

local function AuraTextureMatches(entry, resolvedIcon)
  if activeAuraTextures[string.lower(resolvedIcon)] then return true end
  if entry.buffIcon and activeAuraTextures[string.lower(entry.buffIcon)] then return true end
  if entry.raidbuffIcon and activeAuraTextures[string.lower(entry.raidbuffIcon)] then return true end
  if activeAuraNames[string.lower(entry.name)] then return true end
  if entry.buffName and activeAuraNames[string.lower(entry.buffName)] then return true end
  return false
end

-- Returns: isActive (bool), remainingSeconds (number or nil)
function CH.GetBuffState(entry)
  if entry.kind == "enchant" then
    local active = CH.HasWeaponEnchant(entry.slot)
    return active, active and CH.GetWeaponEnchantRemaining(entry.slot) or nil
  end

  local resolvedIcon = CH.ResolveIcon(entry)
  local key = CH.UniqueKey(entry)
  local tracker = ConsoHelper_Settings.buffTracker

  if AuraTextureMatches(entry, resolvedIcon) then
    if entry.duration and entry.duration > 0 then
      if not tracker[key] then
        tracker[key] = { start = GetTime(), duration = entry.duration }
      end
      local remaining = tracker[key].duration - (GetTime() - tracker[key].start)
      if remaining <= 0 then
        tracker[key] = nil
        return true, nil
      end
      return true, remaining
    end
    return true, nil
  end

  -- Not currently showing as an aura (class buffs without a duration entry never show a timer;
  -- items rely purely on the live aura scan so a manually-removed buff clears immediately).
  if tracker[key] then tracker[key] = nil end
  return false, nil
end

-- ============================================================================
-- UPDATE TICKER
-- ============================================================================

local tickerFrame = CreateFrame("Frame")
local elapsedAccum = 0
local pendingIconAccum = 0

tickerFrame:SetScript("OnUpdate", function()
  elapsedAccum = elapsedAccum + arg1
  pendingIconAccum = pendingIconAccum + arg1

  if pendingIconAccum >= 1 then
    pendingIconAccum = 0
    RetryPendingIcons()
  end

  local interval = ConsoHelper_Settings and ConsoHelper_Settings.settings.updateInterval or 1
  if elapsedAccum >= interval then
    elapsedAccum = 0
    RefreshActiveAuras()
    CH.ScanBags(false)
    if ConsoHelper_UI and ConsoHelper_UI.UpdateStatus then
      ConsoHelper_UI.UpdateStatus()
    end
  end
end)

-- ============================================================================
-- COMBAT STATE
-- ============================================================================

local combatFrame = CreateFrame("Frame")
combatFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
combatFrame:SetScript("OnEvent", function()
  ConsoHelper_Settings.settings.inCombat = (event == "PLAYER_REGEN_DISABLED")
  if ConsoHelper_UI and ConsoHelper_UI.OnCombatStateChanged then
    ConsoHelper_UI.OnCombatStateChanged()
  end
end)

-- ============================================================================
-- SLASH COMMANDS
-- ============================================================================

local function PrintDebug()
  DEFAULT_CHAT_FRAME:AddMessage("|cff00CCFFConso Helper debug - active auras:|r")
  if table.getn(CH.lastAuraScan) == 0 then
    DEFAULT_CHAT_FRAME:AddMessage("  (none)")
  end
  for i, aura in ipairs(CH.lastAuraScan) do
    DEFAULT_CHAT_FRAME:AddMessage("  " .. i .. ". |cffFFFF00" .. (aura.name or "?") .. "|r - " .. tostring(aura.texture))
  end

  DEFAULT_CHAT_FRAME:AddMessage("|cff00CCFFTracked consumables/enchants:|r")
  for _, entry in ipairs(ConsoHelper_Data.buffs) do
    if entry.kind ~= "spell" and CH.IsEnabled(entry) then
      local active = CH.GetBuffState(entry)
      local color = active and "|cff55ff55" or "|cffff5555"
      local icon = CH.ResolveIcon(entry)
      local extra = entry.buffName and (" buffName=" .. entry.buffName) or ""
      DEFAULT_CHAT_FRAME:AddMessage("  " .. color .. tostring(active) .. "|r " .. entry.name .. " (icon=" .. tostring(icon) .. extra .. ")")
    end
  end
end

SLASH_CONSOHELPER1 = "/conso"
SLASH_CONSOHELPER2 = "/ch"
SlashCmdList["CONSOHELPER"] = function(msg)
  msg = string.lower(msg or "")
  if msg == "config" or msg == "settings" then
    ConsoHelper_UI.ToggleSettings()
  elseif msg == "shop" or msg == "shopping" then
    ConsoHelper_UI.ToggleShoppingList()
  elseif msg == "reset" then
    ConsoHelper_UI.ToggleResetConfirm()
  elseif msg == "debug" then
    PrintDebug()
  else
    ConsoHelper_UI.ToggleSelection()
  end
end

-- ============================================================================
-- INIT
-- ============================================================================

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("VARIABLES_LOADED")
initFrame:SetScript("OnEvent", function()
  InitDefaults()
  CH.RebuildEnabledSet()
  CH.ScanBags(true)
  RefreshActiveAuras()
  if ConsoHelper_UI and ConsoHelper_UI.OnReady then
    ConsoHelper_UI.OnReady()
  end
  DEFAULT_CHAT_FRAME:AddMessage("|cff00CCFFConso Helper|r loaded. Type |cffFFFF00/conso|r to select buffs, |cffFFFF00/conso config|r for settings.")
end)
