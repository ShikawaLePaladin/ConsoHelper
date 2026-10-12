-- Conso Helper - UI
-- Compact icon-grid interfaces: status readout, buff selection, settings, shopping list.

ConsoHelper_UI = {}
local UI = ConsoHelper_UI
local CH = ConsoHelper

local ICON_BORDER_INSET = 0.08

-- ============================================================================
-- SHARED WIDGET HELPERS
-- ============================================================================

local function MakeIconTexture(btn, path)
  if not btn.icon then
    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetAllPoints(btn)
  end
  btn.icon:SetTexture(path)
  btn.icon:SetTexCoord(ICON_BORDER_INSET, 1 - ICON_BORDER_INSET, ICON_BORDER_INSET, 1 - ICON_BORDER_INSET)
  return btn.icon
end

local function CreateGridIcon(parent, sizePx)
  local btn = CreateFrame("Button", nil, parent)
  btn:SetWidth(sizePx)
  btn:SetHeight(sizePx)
  btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
  return btn
end

local function BuildEntryTooltip(entry)
  GameTooltip:ClearLines()
  if entry.kind == "item" or entry.kind == "enchant" then
    GameTooltip:SetHyperlink("item:" .. entry.itemID)
    if entry.kind == "enchant" then
      local slotText = (entry.slot == "mainhand") and "Main Hand" or "Off Hand"
      GameTooltip:AddLine("Weapon enchant slot: " .. slotText, 0.6, 0.9, 1, 1)
    end
  else
    GameTooltip:AddLine(entry.name, 1, 1, 1, 1)
    GameTooltip:AddLine("Class buff", 0.6, 0.9, 1, 1)
  end
  if entry.duration and entry.duration > 0 then
    GameTooltip:AddLine("Duration: " .. CH.FormatTime(entry.duration), 0.7, 0.7, 0.7, 1)
  end
  GameTooltip:Show()
end

-- ============================================================================
-- STATUS FRAME (the always-visible tracker readout)
-- ============================================================================

local statusFrame
local statusIcons = {}
local selectionFrame
local arranging = false   -- "arrange" mode: icons can be dragged to a new position (clicks do nothing)
local dropMark

-- Enabled entries in the player's own order (ConsoHelper_Settings.order = list of unique keys),
-- then any enabled entry not in that list (newly enabled) in database order.
local function GetEnabledEntries()
  local byKey = {}
  for _, entry in ipairs(ConsoHelper_Data.buffs) do
    if not entry.header and CH.IsEnabled(entry) then
      byKey[CH.UniqueKey(entry)] = entry
    end
  end
  local list, used = {}, {}
  local order = ConsoHelper_Settings and ConsoHelper_Settings.order
  if order then
    for i = 1, table.getn(order) do
      local k = order[i]
      if byKey[k] and not used[k] then
        table.insert(list, byKey[k])
        used[k] = true
      end
    end
  end
  for _, entry in ipairs(ConsoHelper_Data.buffs) do
    local k = CH.UniqueKey(entry)
    if byKey[k] and not used[k] then
      table.insert(list, byKey[k])
      used[k] = true
    end
  end
  return list
end

local function LayoutStatusFrame()
  local S = ConsoHelper_Settings.settings
  local visible = {}
  for _, btn in ipairs(statusIcons) do
    if btn:IsShown() then table.insert(visible, btn) end
  end

  local count = table.getn(visible)
  local perRow = math.max(1, S.iconsPerRow)
  local step = S.iconSize + S.iconSpacing
  local rows = math.ceil(count / perRow)
  if rows < 1 then rows = 1 end
  local cols = math.min(count, perRow)
  if cols < 1 then cols = 1 end

  local width = cols * step + S.iconSpacing + 8
  local height = rows * step + S.iconSpacing + 22

  statusFrame:SetWidth(width)
  statusFrame:SetHeight(height)
  statusFrame:SetScale(S.scale)

  for i, btn in ipairs(visible) do
    local idx = i - 1
    local col = math.mod(idx, perRow)
    local row = math.floor(idx / perRow)
    btn:ClearAllPoints()
    btn:SetPoint("TOPLEFT", statusFrame, "TOPLEFT",
      S.iconSpacing + col * step, -18 - row * step)
  end
end

local function CreateStatusIcon(entry)
  local btn = CreateGridIcon(statusFrame, ConsoHelper_Settings.settings.iconSize)
  btn.entry = entry
  MakeIconTexture(btn, CH.ResolveIcon(entry))

  btn.glow = btn:CreateTexture(nil, "OVERLAY")
  btn.glow:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
  btn.glow:SetBlendMode("ADD")
  btn.glow:SetVertexColor(1, 0.2, 0.15, 1)
  btn.glow:SetPoint("CENTER", btn, "CENTER", 0, 0)
  btn.glow:SetWidth(ConsoHelper_Settings.settings.iconSize + 10)
  btn.glow:SetHeight(ConsoHelper_Settings.settings.iconSize + 10)
  btn.glow:Hide()

  btn.timerText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  btn.timerText:SetPoint("TOP", btn, "BOTTOM", 0, -1)
  btn.timerText:SetTextColor(1, 1, 0.4, 1)

  btn.countText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  btn.countText:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 1)

  if entry.kind == "enchant" then
    btn.slotText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.slotText:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1)
    btn.slotText:SetText(entry.slot == "mainhand" and "MH" or "OH")
  end

  btn:SetScript("OnEnter", function()
    if not ConsoHelper_Settings.settings.showTooltips then return end
    GameTooltip:SetOwner(btn, "ANCHOR_TOP")
    BuildEntryTooltip(btn.entry)
    UI.OnHoverEnter()
  end)
  btn:SetScript("OnLeave", function()
    GameTooltip:Hide()
    UI.OnHoverLeave()
  end)
  btn:SetScript("OnClick", function()
    if arranging then return end   -- arranging: never use an item by accident
    if btn.entry.kind == "enchant" then
      CH.ApplyEnchant(btn.entry)
    elseif btn.entry.kind == "item" then
      CH.UseItem(btn.entry)
    end
  end)

  -- drag: reorder in arrange mode, otherwise it moves the whole frame like dragging its border
  btn:RegisterForDrag("LeftButton")
  btn:SetScript("OnDragStart", function() UI.ArrangeDragStart(btn) end)
  btn:SetScript("OnDragStop", function() UI.ArrangeDragStop(btn) end)

  btn.arrangeMark = btn:CreateTexture(nil, "OVERLAY")
  btn.arrangeMark:SetTexture("Interface\\Buttons\\WHITE8X8")
  btn.arrangeMark:SetVertexColor(0.3, 0.8, 1, 0.22)
  btn.arrangeMark:SetAllPoints(btn)
  if arranging then btn.arrangeMark:Show() else btn.arrangeMark:Hide() end

  return btn
end

local function RebuildStatusFrame()
  for _, btn in ipairs(statusIcons) do
    btn:Hide()
    btn:SetParent(nil)
  end
  statusIcons = {}

  for _, entry in ipairs(GetEnabledEntries()) do
    local btn = CreateStatusIcon(entry)
    table.insert(statusIcons, btn)
    btn:Show()
  end

  LayoutStatusFrame()
end

local EXPIRING_SOON_SECONDS = 30
function UI.RefreshIcons()
  for _, btn in ipairs(statusIcons) do
    MakeIconTexture(btn, CH.ResolveIcon(btn.entry))
  end
  if selectionFrame and selectionFrame:IsShown() then
    UI.RefreshSelectionGrid()
  end
end

function UI.UpdateStatus()
  if not statusFrame or not statusFrame:IsShown() then return end
  local S = ConsoHelper_Settings.settings
  if S.pauseInCombat and S.inCombat then return end

  for _, btn in ipairs(statusIcons) do
    local active, remaining = CH.GetBuffState(btn.entry)
    local tex = btn.icon
    local warningSeconds = (S.warningMinutes or 5) * 60
    local critical = active and remaining and remaining <= EXPIRING_SOON_SECONDS
    local warning = active and remaining and remaining <= warningSeconds and not critical

    if active and not warning and not critical then
      tex:SetVertexColor(1, 1, 1, 1)
      btn.glow:Hide()
      btn.timerText:SetTextColor(1, 1, 0.4, 1)
      btn.warnedTier = nil
    elseif warning then
      tex:SetVertexColor(1, 1, 1, 1)
      btn.glow:Hide()
      btn.timerText:SetTextColor(1, 0.65, 0.15, 1)
      if btn.warnedTier ~= "warning" and btn.warnedTier ~= "critical" then
        btn.warnedTier = "warning"
        PlaySound("RaidWarning")
        DEFAULT_CHAT_FRAME:AddMessage("|cffFFAA00Conso Helper:|r " .. btn.entry.name .. " expiring in " .. CH.FormatTime(remaining) .. "!")
      end
    elseif critical then
      tex:SetVertexColor(0.8, 0.8, 0.8, 1)
      btn.glow:Hide()
      btn.timerText:SetTextColor(1, 0.25, 0.15, 1)
      btn.warnedTier = "critical"
    else
      tex:SetVertexColor(1, 0.2, 0.2, 1)
      btn.glow:Show()
      btn.warnedTier = nil
    end

    if S.showTimer then
      btn.timerText:SetText(remaining and CH.FormatTime(remaining) or "")
    else
      btn.timerText:SetText("")
    end

    if btn.entry.kind ~= "spell" then
      local count = CH.GetBagCount(btn.entry)
      btn.countText:SetText(count > 0 and count or "")
    end

    if S.showOnlyWhenLow and not arranging then
      local healthy = active and not warning and not critical
      if healthy then btn:Hide() else btn:Show() end
    elseif not btn:IsShown() then
      btn:Show()
    end
  end

  if S.showOnlyWhenLow and not arranging then
    LayoutStatusFrame()
  end
end

local glowTicker = CreateFrame("Frame")
glowTicker:SetScript("OnUpdate", function()
  if not statusFrame or not statusFrame:IsShown() then return end
  local alpha = 0.35 + 0.35 * ((math.sin(GetTime() * 3) + 1) / 2)
  for _, btn in ipairs(statusIcons) do
    if btn.glow and btn.glow:IsShown() then
      btn.glow:SetAlpha(alpha)
    end
  end
end)

function UI.UpdateFrameVisibility()
  if not statusFrame or arranging then return end
  local S = ConsoHelper_Settings.settings
  local shouldHide = (S.hideFrameInCombat and S.inCombat) or (S.raidOnly and not S.inRaid)
  if shouldHide then
    statusFrame:Hide()
  elseif not S.hoverToShow then
    statusFrame:Show()
  end
end

-- Hover-to-show handling
local hoverCount = 0
local hoverHideAt = nil

function UI.OnHoverEnter()
  hoverCount = hoverCount + 1
  hoverHideAt = nil
  if ConsoHelper_Settings.settings.hoverToShow then
    statusFrame:SetAlpha(1)
  end
end

function UI.OnHoverLeave()
  hoverCount = math.max(0, hoverCount - 1)
  if hoverCount == 0 and ConsoHelper_Settings.settings.hoverToShow then
    hoverHideAt = GetTime() + 1.2
  end
end

local hoverTicker = CreateFrame("Frame")
hoverTicker:SetScript("OnUpdate", function()
  if not statusFrame or not ConsoHelper_Settings then return end
  if ConsoHelper_Settings.settings.hoverToShow and hoverHideAt and hoverCount == 0 and not arranging then
    if GetTime() >= hoverHideAt then
      statusFrame:SetAlpha(0)
      hoverHideAt = nil
    end
  end
end)

local function CreateStatusFrame()
  statusFrame = CreateFrame("Frame", "ConsoHelperStatusFrame", UIParent)
  statusFrame:SetFrameStrata("MEDIUM")
  statusFrame:SetMovable(true)
  statusFrame:EnableMouse(true)
  statusFrame:RegisterForDrag("LeftButton")
  statusFrame:SetScript("OnDragStart", function() if not ConsoHelper_Settings.settings.lockFrame then statusFrame:StartMoving() end end)
  statusFrame:SetScript("OnDragStop", function()
    statusFrame:StopMovingOrSizing()
    local point, _, relativePoint, x, y = statusFrame:GetPoint()
    ConsoHelper_Settings.settings.framePosition = { point = point, relativeTo = "UIParent", relativePoint = relativePoint, x = x, y = y }
  end)
  statusFrame:SetScript("OnEnter", function() UI.OnHoverEnter() end)
  statusFrame:SetScript("OnLeave", function() UI.OnHoverLeave() end)
  statusFrame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 8, edgeSize = 12,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
  })
  statusFrame:SetBackdropColor(0, 0, 0, 0.35)
  statusFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.6)

  statusFrame.title = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  statusFrame.title:SetPoint("TOPLEFT", statusFrame, "TOPLEFT", 4, -3)
  statusFrame.title:SetText("Conso Helper")

  statusFrame.doneBtn = CreateFrame("Button", nil, statusFrame, "UIPanelButtonTemplate")
  statusFrame.doneBtn:SetWidth(44)
  statusFrame.doneBtn:SetHeight(16)
  statusFrame.doneBtn:SetPoint("TOPRIGHT", statusFrame, "TOPRIGHT", -3, -2)
  statusFrame.doneBtn:SetText("Done")
  statusFrame.doneBtn:SetScript("OnClick", function() UI.SetArrange(false) end)
  statusFrame.doneBtn:Hide()

  local pos = ConsoHelper_Settings.settings.framePosition
  statusFrame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)

  UI.ApplyFrameLockVisuals()
end

function UI.ApplyFrameLockVisuals()
  if not statusFrame then return end
  local S = ConsoHelper_Settings.settings
  if S.showBackground then
    statusFrame:SetBackdropColor(0, 0, 0, 0.35)
    statusFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.6)
  else
    statusFrame:SetBackdropColor(0, 0, 0, 0)
    statusFrame:SetBackdropBorderColor(0, 0, 0, 0)
  end
  if S.showTitle then
    statusFrame.title:Show()
  else
    statusFrame.title:Hide()
  end
  if S.hoverToShow then
    statusFrame:SetAlpha(0)
  else
    statusFrame:SetAlpha(1)
  end
end

-- ============================================================================
-- ARRANGE MODE: put each consumable where you want it
-- ============================================================================

-- grid cell under the mouse (1 = first position); also returns the cursor in the status frame's own units
local function CellFromCursor()
  local S = ConsoHelper_Settings.settings
  local cx, cy = GetCursorPosition()
  local es = statusFrame:GetEffectiveScale()
  if type(es) ~= "number" or es <= 0 then es = 1 end
  local left, top = statusFrame:GetLeft(), statusFrame:GetTop()
  if type(left) ~= "number" or type(top) ~= "number" then return 1, 0, 0 end
  local lx = cx / es - left
  local ly = top - cy / es
  local step = S.iconSize + S.iconSpacing
  local perRow = math.max(1, S.iconsPerRow)
  local n = table.getn(statusIcons)
  local col = math.floor((lx - S.iconSpacing) / step)
  local row = math.floor((ly - 18) / step)
  if col < 0 then col = 0 end
  if col > perRow - 1 then col = perRow - 1 end
  if row < 0 then row = 0 end
  local idx = row * perRow + col + 1
  if idx > n then idx = n end
  if idx < 1 then idx = 1 end
  return idx, lx, ly
end

local function HideDropMark()
  if dropMark then dropMark:Hide() end
end

local function ShowDropMark(idx)
  local S = ConsoHelper_Settings.settings
  if not dropMark then
    dropMark = statusFrame:CreateTexture(nil, "ARTWORK")
    dropMark:SetTexture("Interface\\Buttons\\WHITE8X8")
    dropMark:SetVertexColor(0.3, 0.8, 1, 0.45)
  end
  local perRow = math.max(1, S.iconsPerRow)
  local step = S.iconSize + S.iconSpacing
  local col = math.mod(idx - 1, perRow)
  local row = math.floor((idx - 1) / perRow)
  dropMark:ClearAllPoints()
  dropMark:SetWidth(S.iconSize)
  dropMark:SetHeight(S.iconSize)
  dropMark:SetPoint("TOPLEFT", statusFrame, "TOPLEFT", S.iconSpacing + col * step, -18 - row * step)
  dropMark:Show()
end

-- keys of the icons as currently shown, in order (also handy for tests)
function UI.GetOrder()
  local keys = {}
  for _, btn in ipairs(statusIcons) do table.insert(keys, CH.UniqueKey(btn.entry)) end
  return keys
end

function UI.GetIcons() return statusIcons end

-- put the consumable with this key at position toIndex (1 = first), shifting the others
function UI.MoveEntry(key, toIndex)
  local keys = {}
  for _, e in ipairs(GetEnabledEntries()) do
    local k = CH.UniqueKey(e)
    if k ~= key then table.insert(keys, k) end
  end
  if toIndex < 1 then toIndex = 1 end
  if toIndex > table.getn(keys) + 1 then toIndex = table.getn(keys) + 1 end
  table.insert(keys, toIndex, key)
  ConsoHelper_Settings.order = keys
  RebuildStatusFrame()
end

function UI.ResetOrder()
  ConsoHelper_Settings.order = nil
  if statusFrame then RebuildStatusFrame() end
  DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00Conso Helper:|r Icon order reset to the default order.")
end

function UI.ArrangeDragStart(btn)
  if not arranging then
    -- not arranging: dragging an icon moves the frame, like dragging its border
    local f = statusFrame:GetScript("OnDragStart")
    if f then f() end
    return
  end
  btn.dragging = true
  GameTooltip:Hide()
  btn:SetFrameLevel(statusFrame:GetFrameLevel() + 12)
  btn:SetScript("OnUpdate", function()
    local idx, lx, ly = CellFromCursor()
    this:ClearAllPoints()
    this:SetPoint("CENTER", statusFrame, "TOPLEFT", lx, -ly)
    ShowDropMark(idx)
  end)
end

function UI.ArrangeDragStop(btn)
  if not arranging then
    local f = statusFrame:GetScript("OnDragStop")
    if f then f() end
    return
  end
  btn:SetScript("OnUpdate", nil)
  if not btn.dragging then return end
  btn.dragging = false
  local idx = CellFromCursor()
  HideDropMark()
  UI.MoveEntry(CH.UniqueKey(btn.entry), idx)
end

function UI.SetArrange(on)
  if not statusFrame then return end
  arranging = on and true or false
  for _, btn in ipairs(statusIcons) do
    if arranging then
      btn:Show()
      btn.arrangeMark:Show()
    else
      btn.arrangeMark:Hide()
      btn:SetScript("OnUpdate", nil)
      btn.dragging = false
    end
  end
  if arranging then
    statusFrame:Show()
    statusFrame:SetAlpha(1)
    statusFrame.title:SetText("Drag to reorder")
    statusFrame.title:Show()
    statusFrame.doneBtn:Show()
    DEFAULT_CHAT_FRAME:AddMessage("|cff00CCFFConso Helper:|r arrange mode - drag the icons where you want them, then click Done (or /conso order).")
  else
    HideDropMark()
    statusFrame.doneBtn:Hide()
    statusFrame.title:SetText("Conso Helper")
    UI.ApplyFrameLockVisuals()
    UI.UpdateFrameVisibility()
  end
  LayoutStatusFrame()
  UI.UpdateStatus()
end

function UI.ToggleArrange() UI.SetArrange(not arranging) end
function UI.IsArranging() return arranging end

-- ============================================================================
-- BUFF SELECTION WINDOW (compact icon grid, replaces the old giant checklist)
-- ============================================================================

local tempEnabled = {}
local SELECT_ICON_SIZE = 28
local SELECT_COLUMNS = 11
local SELECT_STEP = SELECT_ICON_SIZE + 6

local function CreateSelectionIcon(parent, entry)
  local btn = CreateGridIcon(parent, SELECT_ICON_SIZE)
  MakeIconTexture(btn, CH.ResolveIcon(entry))
  btn.entry = entry

  local glow = btn:CreateTexture(nil, "BACKGROUND")
  glow:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
  glow:SetBlendMode("ADD")
  glow:SetVertexColor(1, 0.82, 0.2, 0.9)
  glow:SetPoint("CENTER", btn, "CENTER", 0, 0)
  glow:SetWidth(SELECT_ICON_SIZE + 10)
  glow:SetHeight(SELECT_ICON_SIZE + 10)
  btn.glow = glow

  local check = btn:CreateTexture(nil, "OVERLAY")
  check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
  check:SetWidth(16)
  check:SetHeight(16)
  check:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 3, -3)
  btn.check = check

  local key = CH.UniqueKey(entry)
  if tempEnabled[key] == true then check:Show(); glow:Show() else check:Hide(); glow:Hide() end

  btn:SetScript("OnClick", function()
    local k = CH.UniqueKey(btn.entry)
    tempEnabled[k] = not tempEnabled[k] or nil
    if tempEnabled[k] == true then
      btn.check:Show()
      btn.glow:Show()
    else
      btn.check:Hide()
      btn.glow:Hide()
    end
  end)
  btn:SetScript("OnEnter", function()
    GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
    BuildEntryTooltip(btn.entry)
  end)
  btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

  return btn
end

local function BuildSelectionContent(content, filterText)
  local yOffset = 0
  local currentCat = nil
  local colIndex = 0
  local headerPending = false
  local filter = (filterText and filterText ~= "") and string.lower(filterText) or nil
  local anyMatch = false

  for _, entry in ipairs(ConsoHelper_Data.buffs) do
    local matches = (not filter) or string.find(string.lower(entry.name), filter, 1, true)

    if entry.cat ~= currentCat then
      currentCat = entry.cat
      if colIndex > 0 then yOffset = yOffset + SELECT_STEP end
      colIndex = 0
      headerPending = true
    end

    if matches then
      anyMatch = true
      if headerPending then
        if yOffset > 0 then yOffset = yOffset + 6 end
        local header = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        header:SetPoint("TOPLEFT", content, "TOPLEFT", 4, -yOffset)
        header:SetTextColor(0.6, 0.85, 1, 1)
        header:SetText(ConsoHelper_Data.categoryLabels[currentCat] or currentCat)
        yOffset = yOffset + 16
        headerPending = false
      end

      local btn = CreateSelectionIcon(content, entry)
      btn:SetPoint("TOPLEFT", content, "TOPLEFT", 4 + colIndex * SELECT_STEP, -yOffset)

      colIndex = colIndex + 1
      if colIndex >= SELECT_COLUMNS then
        colIndex = 0
        yOffset = yOffset + SELECT_STEP
      end
    end
  end

  if colIndex > 0 then yOffset = yOffset + SELECT_STEP end

  if filter and not anyMatch then
    local label = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", content, "TOPLEFT", 4, -4)
    label:SetTextColor(0.8, 0.8, 0.8, 1)
    label:SetText("No consumable matches \"" .. filterText .. "\"")
    yOffset = 26
  end

  return yOffset + 10
end

local function CreateSelectionFrame()
  local contentWidth = SELECT_COLUMNS * SELECT_STEP + 8
  local width = contentWidth + 42
  local height = 480

  selectionFrame = CreateFrame("Frame", "ConsoHelperSelectionFrame", UIParent)
  selectionFrame:SetWidth(width)
  selectionFrame:SetHeight(height)
  selectionFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
  selectionFrame:SetFrameStrata("DIALOG")
  selectionFrame:SetMovable(true)
  selectionFrame:EnableMouse(true)
  selectionFrame:RegisterForDrag("LeftButton")
  selectionFrame:SetScript("OnDragStart", function() selectionFrame:StartMoving() end)
  selectionFrame:SetScript("OnDragStop", function() selectionFrame:StopMovingOrSizing() end)
  selectionFrame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 8, edgeSize = 24,
    insets = { left = 8, right = 8, top = 8, bottom = 8 },
  })
  selectionFrame:SetBackdropColor(0.05, 0.08, 0.12, 0.95)
  selectionFrame:SetBackdropBorderColor(0.6, 0.75, 1, 1)

  selectionFrame.title = selectionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  selectionFrame.title:SetPoint("TOP", selectionFrame, "TOP", 0, -10)
  selectionFrame.title:SetText("Select Buffs & Consumables")

  local closeX = CreateFrame("Button", nil, selectionFrame)
  closeX:SetWidth(24)
  closeX:SetHeight(24)
  closeX:SetPoint("TOPRIGHT", selectionFrame, "TOPRIGHT", -6, -6)
  closeX:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
  closeX:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
  closeX:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
  closeX:SetScript("OnClick", function() selectionFrame:Hide() end)

  local searchLabel = selectionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  searchLabel:SetPoint("TOPLEFT", selectionFrame, "TOPLEFT", 14, -32)
  searchLabel:SetText("Search:")

  local searchBox = CreateFrame("EditBox", "ConsoHelperSearchBox", selectionFrame, "ConsoHelperEditBoxTemplate")
  searchBox:SetWidth(180)
  searchBox:SetHeight(20)
  searchBox:SetPoint("LEFT", searchLabel, "RIGHT", 6, 0)
  searchBox:SetJustifyH("LEFT")
  searchBox:SetMaxLetters(40)
  searchBox:SetScript("OnTextChanged", function() UI.RefreshSelectionGrid() end)
  searchBox:SetScript("OnEscapePressed", function() this:SetText(""); this:ClearFocus() end)
  selectionFrame.searchBox = searchBox

  local clearBtn = CreateFrame("Button", nil, selectionFrame, "UIPanelButtonTemplate")
  clearBtn:SetWidth(50)
  clearBtn:SetHeight(20)
  clearBtn:SetPoint("LEFT", searchBox, "RIGHT", 6, 0)
  clearBtn:SetText("Clear")
  clearBtn:SetScript("OnClick", function() searchBox:SetText(""); searchBox:ClearFocus() end)

  local scrollFrame = CreateFrame("ScrollFrame", "ConsoHelperSelectScroll", selectionFrame)
  scrollFrame:SetPoint("TOPLEFT", selectionFrame, "TOPLEFT", 12, -58)
  scrollFrame:SetPoint("BOTTOMRIGHT", selectionFrame, "BOTTOMRIGHT", -30, 40)
  scrollFrame:EnableMouseWheel(true)

  local scrollbar = CreateFrame("Slider", "ConsoHelperSelectScrollBar", scrollFrame, "UIPanelScrollBarTemplate")
  scrollbar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 4, -16)
  scrollbar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 4, 16)
  scrollbar:SetMinMaxValues(0, 1)
  scrollbar:SetValueStep(1)
  scrollbar:SetValue(0)
  scrollbar:SetWidth(16)
  scrollbar:SetScript("OnValueChanged", function() scrollFrame:SetVerticalScroll(this:GetValue()) end)

  scrollFrame:SetScript("OnMouseWheel", function()
    local step = 40
    local val = scrollbar:GetValue()
    local minV, maxV = scrollbar:GetMinMaxValues()
    if arg1 > 0 then
      scrollbar:SetValue(math.max(minV, val - step))
    else
      scrollbar:SetValue(math.min(maxV, val + step))
    end
  end)

  local content = CreateFrame("Frame", nil, scrollFrame)
  content:SetWidth(contentWidth)
  scrollFrame:SetScrollChild(content)
  selectionFrame.scrollbar = scrollbar
  selectionFrame.content = content

  local saveBtn = CreateFrame("Button", nil, selectionFrame, "UIPanelButtonTemplate")
  saveBtn:SetWidth(120)
  saveBtn:SetHeight(24)
  saveBtn:SetPoint("BOTTOMRIGHT", selectionFrame, "BOTTOMRIGHT", -14, 10)
  saveBtn:SetText("Save & Close")
  saveBtn:SetScript("OnClick", function()
    CH.enabledSet = tempEnabled
    CH.SaveEnabledSet()
    RebuildStatusFrame()
    DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00Conso Helper:|r Selection saved.")
    selectionFrame:Hide()
  end)

  local cancelBtn = CreateFrame("Button", nil, selectionFrame, "UIPanelButtonTemplate")
  cancelBtn:SetWidth(90)
  cancelBtn:SetHeight(24)
  cancelBtn:SetPoint("RIGHT", saveBtn, "LEFT", -8, 0)
  cancelBtn:SetText("Cancel")
  cancelBtn:SetScript("OnClick", function() selectionFrame:Hide() end)
end

function UI.RefreshSelectionGrid()
  if not selectionFrame then return end

  local kids = { selectionFrame.content:GetChildren() }
  for _, kid in ipairs(kids) do kid:Hide(); kid:SetParent(nil) end
  local regions = { selectionFrame.content:GetRegions() }
  for _, region in ipairs(regions) do
    if region.GetObjectType and region:GetObjectType() == "FontString" then region:Hide() end
  end

  local filterText = selectionFrame.searchBox and selectionFrame.searchBox:GetText() or ""
  local totalHeight = BuildSelectionContent(selectionFrame.content, filterText)
  selectionFrame.content:SetHeight(totalHeight)
  local visibleHeight = selectionFrame:GetHeight() - 98
  local scrollRange = math.max(0, totalHeight - visibleHeight)
  selectionFrame.scrollbar:SetMinMaxValues(0, scrollRange)
  selectionFrame.scrollbar:SetValue(0)
end

function UI.ToggleSelection()
  if not selectionFrame then CreateSelectionFrame() end
  if selectionFrame:IsShown() then
    selectionFrame:Hide()
    return
  end

  tempEnabled = {}
  for k in pairs(CH.enabledSet) do tempEnabled[k] = true end
  if selectionFrame.searchBox then selectionFrame.searchBox:SetText("") end

  UI.RefreshSelectionGrid()

  selectionFrame:Show()
end

-- ============================================================================
-- SETTINGS PANEL (compact two-column layout)
-- ============================================================================

local settingsFrame

local sliderCounter = 0

local function AddSliderRow(parent, label, x, y, min, max, step, getValue, onChange)
  local text = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  text:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)

  sliderCounter = sliderCounter + 1
  local slider = CreateFrame("Slider", "ConsoHelperSliderRow" .. sliderCounter, parent, "OptionsSliderTemplate")
  slider:SetWidth(150)
  slider:SetHeight(14)
  slider:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 2, -4)
  slider:SetMinMaxValues(min, max)
  slider:SetValueStep(step)
  getglobal(slider:GetName() .. "Low"):SetText(tostring(min))
  getglobal(slider:GetName() .. "High"):SetText(tostring(max))
  getglobal(slider:GetName() .. "Text"):SetText("")
  slider:SetValue(getValue())

  slider:SetScript("OnValueChanged", function()
    text:SetText(label .. ": " .. tostring(this:GetValue()))
    onChange(this:GetValue())
  end)
  text:SetText(label .. ": " .. tostring(getValue()))

  return slider, y - 38
end

local function AddCheckRow(parent, label, x, y, getValue, onChange)
  local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  cb:SetWidth(20)
  cb:SetHeight(20)
  cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  cb:SetChecked(getValue())

  local text = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  text:SetPoint("LEFT", cb, "RIGHT", 2, 0)
  text:SetText(label)

  cb:SetScript("OnClick", function() onChange(this:GetChecked() == 1) end)
  return cb, y - 24
end

local function CreateSettingsFrame()
  local width, height = 360, 450
  settingsFrame = CreateFrame("Frame", "ConsoHelperSettingsFrame", UIParent)
  settingsFrame:SetWidth(width)
  settingsFrame:SetHeight(height)
  settingsFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  settingsFrame:SetFrameStrata("DIALOG")
  settingsFrame:SetMovable(true)
  settingsFrame:EnableMouse(true)
  settingsFrame:RegisterForDrag("LeftButton")
  settingsFrame:SetScript("OnDragStart", function() settingsFrame:StartMoving() end)
  settingsFrame:SetScript("OnDragStop", function() settingsFrame:StopMovingOrSizing() end)
  settingsFrame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 8, edgeSize = 24,
    insets = { left = 8, right = 8, top = 8, bottom = 8 },
  })
  settingsFrame:SetBackdropColor(0.05, 0.08, 0.12, 0.95)
  settingsFrame:SetBackdropBorderColor(0.6, 0.75, 1, 1)

  settingsFrame.title = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  settingsFrame.title:SetPoint("TOP", settingsFrame, "TOP", 0, -10)
  settingsFrame.title:SetText("Conso Helper Settings")

  local closeX = CreateFrame("Button", nil, settingsFrame)
  closeX:SetWidth(24)
  closeX:SetHeight(24)
  closeX:SetPoint("TOPRIGHT", settingsFrame, "TOPRIGHT", -6, -6)
  closeX:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
  closeX:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
  closeX:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
  closeX:SetScript("OnClick", function() settingsFrame:Hide() end)

  local S = ConsoHelper_Settings.settings
  local leftX, rightX = 16, 190
  local leftY, rightY = -36, -36

  local _, ny = AddSliderRow(settingsFrame, "Scale", leftX, leftY, 50, 200, 5,
    function() return S.scale * 100 end,
    function(v) S.scale = v / 100; if statusFrame then statusFrame:SetScale(S.scale) end end)
  leftY = ny

  _, ny = AddSliderRow(settingsFrame, "Update interval (s)", leftX, leftY, 1, 10, 1,
    function() return S.updateInterval end,
    function(v) S.updateInterval = v end)
  leftY = ny

  _, ny = AddSliderRow(settingsFrame, "Icons per row", leftX, leftY, 1, 20, 1,
    function() return S.iconsPerRow end,
    function(v) S.iconsPerRow = v; LayoutStatusFrame() end)
  leftY = ny

  _, ny = AddSliderRow(settingsFrame, "Icon size", leftX, leftY, 16, 40, 1,
    function() return S.iconSize end,
    function(v)
      S.iconSize = v
      RebuildStatusFrame()
    end)
  leftY = ny

  _, ny = AddSliderRow(settingsFrame, "Icon spacing", leftX, leftY, 0, 20, 1,
    function() return S.iconSpacing end,
    function(v) S.iconSpacing = v; LayoutStatusFrame() end)
  leftY = ny

  _, ny = AddSliderRow(settingsFrame, "Expiry warning (min)", leftX, leftY, 1, 15, 1,
    function() return S.warningMinutes end,
    function(v) S.warningMinutes = v end)
  leftY = ny

  _, ny = AddCheckRow(settingsFrame, "Pause updates in combat", rightX, rightY,
    function() return S.pauseInCombat end,
    function(v) S.pauseInCombat = v end)
  rightY = ny

  _, ny = AddCheckRow(settingsFrame, "Hide frame in combat", rightX, rightY,
    function() return S.hideFrameInCombat end,
    function(v) S.hideFrameInCombat = v end)
  rightY = ny

  _, ny = AddCheckRow(settingsFrame, "Show tooltips", rightX, rightY,
    function() return S.showTooltips end,
    function(v) S.showTooltips = v end)
  rightY = ny

  _, ny = AddCheckRow(settingsFrame, "Hover to show", rightX, rightY,
    function() return S.hoverToShow end,
    function(v) S.hoverToShow = v; UI.ApplyFrameLockVisuals() end)
  rightY = ny

  _, ny = AddCheckRow(settingsFrame, "Lock frame (prevent dragging)", rightX, rightY,
    function() return S.lockFrame end,
    function(v) S.lockFrame = v end)
  rightY = ny

  _, ny = AddCheckRow(settingsFrame, "Show background", rightX, rightY,
    function() return S.showBackground end,
    function(v) S.showBackground = v; UI.ApplyFrameLockVisuals() end)
  rightY = ny

  _, ny = AddCheckRow(settingsFrame, "Show \"Conso Helper\" title", rightX, rightY,
    function() return S.showTitle end,
    function(v) S.showTitle = v; UI.ApplyFrameLockVisuals() end)
  rightY = ny

  _, ny = AddCheckRow(settingsFrame, "Show timer text", rightX, rightY,
    function() return S.showTimer end,
    function(v) S.showTimer = v end)
  rightY = ny

  _, ny = AddCheckRow(settingsFrame, "Show only in raid", rightX, rightY,
    function() return S.raidOnly end,
    function(v) S.raidOnly = v; UI.UpdateFrameVisibility() end)
  rightY = ny

  _, ny = AddCheckRow(settingsFrame, "Show only when missing/low", rightX, rightY,
    function() return S.showOnlyWhenLow end,
    function(v)
      S.showOnlyWhenLow = v
      if not v then
        for _, btn in ipairs(statusIcons) do btn:Show() end
        LayoutStatusFrame()
      end
    end)
  rightY = ny

  local arrangeBtn = CreateFrame("Button", nil, settingsFrame, "UIPanelButtonTemplate")
  arrangeBtn:SetWidth(150)
  arrangeBtn:SetHeight(24)
  arrangeBtn:SetPoint("BOTTOMLEFT", settingsFrame, "BOTTOMLEFT", 14, 70)
  arrangeBtn:SetText("Arrange Icons...")
  arrangeBtn:SetScript("OnClick", function() settingsFrame:Hide(); UI.SetArrange(true) end)

  local orderBtn = CreateFrame("Button", nil, settingsFrame, "UIPanelButtonTemplate")
  orderBtn:SetWidth(150)
  orderBtn:SetHeight(24)
  orderBtn:SetPoint("LEFT", arrangeBtn, "RIGHT", 6, 0)
  orderBtn:SetText("Reset Order")
  orderBtn:SetScript("OnClick", function() UI.ResetOrder() end)

  local selectBtn = CreateFrame("Button", nil, settingsFrame, "UIPanelButtonTemplate")
  selectBtn:SetWidth(150)
  selectBtn:SetHeight(24)
  selectBtn:SetPoint("BOTTOMLEFT", settingsFrame, "BOTTOMLEFT", 14, 40)
  selectBtn:SetText("Select Buffs...")
  selectBtn:SetScript("OnClick", function() UI.ToggleSelection() end)

  local shopBtn = CreateFrame("Button", nil, settingsFrame, "UIPanelButtonTemplate")
  shopBtn:SetWidth(150)
  shopBtn:SetHeight(24)
  shopBtn:SetPoint("LEFT", selectBtn, "RIGHT", 6, 0)
  shopBtn:SetText("Shopping List...")
  shopBtn:SetScript("OnClick", function() UI.ToggleShoppingList() end)

  local resetBtn = CreateFrame("Button", nil, settingsFrame, "UIPanelButtonTemplate")
  resetBtn:SetWidth(150)
  resetBtn:SetHeight(24)
  resetBtn:SetPoint("BOTTOMLEFT", settingsFrame, "BOTTOMLEFT", 14, 10)
  resetBtn:SetText("Reset Settings")
  resetBtn:SetScript("OnClick", function() UI.ToggleResetConfirm() end)

  local closeBtn = CreateFrame("Button", nil, settingsFrame, "UIPanelButtonTemplate")
  closeBtn:SetWidth(150)
  closeBtn:SetHeight(24)
  closeBtn:SetPoint("LEFT", resetBtn, "RIGHT", 6, 0)
  closeBtn:SetText("Close")
  closeBtn:SetScript("OnClick", function() settingsFrame:Hide() end)
end

function UI.ToggleSettings()
  if not settingsFrame then CreateSettingsFrame() end
  if settingsFrame:IsShown() then settingsFrame:Hide() else settingsFrame:Show() end
end

-- ============================================================================
-- RESET CONFIRMATION
-- ============================================================================

local resetFrame

local function CreateResetFrame()
  resetFrame = CreateFrame("Frame", "ConsoHelperResetFrame", UIParent)
  resetFrame:SetWidth(320)
  resetFrame:SetHeight(140)
  resetFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  resetFrame:SetFrameStrata("DIALOG")
  resetFrame:SetFrameLevel(200)
  resetFrame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 8, edgeSize = 24,
    insets = { left = 8, right = 8, top = 8, bottom = 8 },
  })
  resetFrame:SetBackdropColor(0.1, 0.02, 0.02, 0.95)
  resetFrame:SetBackdropBorderColor(1, 0.3, 0.3, 1)

  local text = resetFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  text:SetPoint("TOP", resetFrame, "TOP", 0, -20)
  text:SetWidth(280)
  text:SetText("Reset all Conso Helper settings and buff selections to default?")

  local confirmBtn = CreateFrame("Button", nil, resetFrame, "UIPanelButtonTemplate")
  confirmBtn:SetWidth(110)
  confirmBtn:SetHeight(26)
  confirmBtn:SetPoint("BOTTOMLEFT", resetFrame, "BOTTOMLEFT", 30, 16)
  confirmBtn:SetText("Reset")
  confirmBtn:SetScript("OnClick", function()
    ConsoHelper_Settings = nil
    ReloadUI()
  end)

  local cancelBtn = CreateFrame("Button", nil, resetFrame, "UIPanelButtonTemplate")
  cancelBtn:SetWidth(110)
  cancelBtn:SetHeight(26)
  cancelBtn:SetPoint("BOTTOMRIGHT", resetFrame, "BOTTOMRIGHT", -30, 16)
  cancelBtn:SetText("Cancel")
  cancelBtn:SetScript("OnClick", function() resetFrame:Hide() end)
end

function UI.ToggleResetConfirm()
  if not resetFrame then CreateResetFrame() end
  if resetFrame:IsShown() then resetFrame:Hide() else resetFrame:Show() end
end

-- ============================================================================
-- SHOPPING LIST
-- ============================================================================

local shoppingFrame

local function BuildShoppingRows(content)
  local yOffset = 0
  local anyMissing = false

  for _, entry in ipairs(ConsoHelper_Data.buffs) do
    if not entry.header and entry.kind ~= "spell" and CH.IsEnabled(entry) then
      local count = CH.GetBagCount(entry)
      local threshold = ConsoHelper_Settings.settings.shoppingThreshold
      if count < threshold then
        anyMissing = true
        local row = CreateFrame("Frame", nil, content)
        row:SetWidth(320)
        row:SetHeight(22)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOffset)

        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetWidth(18)
        icon:SetHeight(18)
        icon:SetPoint("LEFT", row, "LEFT", 0, 0)
        icon:SetTexture(CH.ResolveIcon(entry))
        icon:SetTexCoord(ICON_BORDER_INSET, 1 - ICON_BORDER_INSET, ICON_BORDER_INSET, 1 - ICON_BORDER_INSET)

        local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("LEFT", icon, "RIGHT", 6, 0)
        label:SetText(entry.name .. " |cffFF8888(have " .. count .. ", need " .. (threshold - count) .. " more)|r")

        yOffset = yOffset + 24
      end
    end
  end

  if not anyMissing then
    local label = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    label:SetTextColor(0.4, 1, 0.4, 1)
    label:SetText("All tracked consumables are well stocked!")
    yOffset = 24
  end

  return yOffset
end

local function CreateShoppingFrame()
  shoppingFrame = CreateFrame("Frame", "ConsoHelperShoppingFrame", UIParent)
  shoppingFrame:SetWidth(380)
  shoppingFrame:SetHeight(420)
  shoppingFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  shoppingFrame:SetFrameStrata("DIALOG")
  shoppingFrame:SetMovable(true)
  shoppingFrame:EnableMouse(true)
  shoppingFrame:RegisterForDrag("LeftButton")
  shoppingFrame:SetScript("OnDragStart", function() shoppingFrame:StartMoving() end)
  shoppingFrame:SetScript("OnDragStop", function() shoppingFrame:StopMovingOrSizing() end)
  shoppingFrame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 8, edgeSize = 24,
    insets = { left = 8, right = 8, top = 8, bottom = 8 },
  })
  shoppingFrame:SetBackdropColor(0.05, 0.08, 0.12, 0.95)
  shoppingFrame:SetBackdropBorderColor(0.6, 0.75, 1, 1)

  shoppingFrame.title = shoppingFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  shoppingFrame.title:SetPoint("TOP", shoppingFrame, "TOP", 0, -10)
  shoppingFrame.title:SetText("Shopping List")

  local closeX = CreateFrame("Button", nil, shoppingFrame)
  closeX:SetWidth(24)
  closeX:SetHeight(24)
  closeX:SetPoint("TOPRIGHT", shoppingFrame, "TOPRIGHT", -6, -6)
  closeX:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
  closeX:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
  closeX:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
  closeX:SetScript("OnClick", function() shoppingFrame:Hide() end)

  local scrollFrame = CreateFrame("ScrollFrame", "ConsoHelperShopScroll", shoppingFrame)
  scrollFrame:SetPoint("TOPLEFT", shoppingFrame, "TOPLEFT", 14, -36)
  scrollFrame:SetPoint("BOTTOMRIGHT", shoppingFrame, "BOTTOMRIGHT", -30, 14)
  scrollFrame:EnableMouseWheel(true)

  local scrollbar = CreateFrame("Slider", "ConsoHelperShopScrollBar", scrollFrame, "UIPanelScrollBarTemplate")
  scrollbar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 4, -16)
  scrollbar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 4, 16)
  scrollbar:SetMinMaxValues(0, 1)
  scrollbar:SetValueStep(1)
  scrollbar:SetValue(0)
  scrollbar:SetWidth(16)
  scrollbar:SetScript("OnValueChanged", function() scrollFrame:SetVerticalScroll(this:GetValue()) end)
  scrollFrame:SetScript("OnMouseWheel", function()
    local val = scrollbar:GetValue()
    local minV, maxV = scrollbar:GetMinMaxValues()
    if arg1 > 0 then scrollbar:SetValue(math.max(minV, val - 30))
    else scrollbar:SetValue(math.min(maxV, val + 30)) end
  end)

  local content = CreateFrame("Frame", nil, scrollFrame)
  content:SetWidth(330)
  scrollFrame:SetScrollChild(content)
  shoppingFrame.scrollbar = scrollbar
  shoppingFrame.content = content
end

function UI.ToggleShoppingList()
  if not shoppingFrame then CreateShoppingFrame() end
  if shoppingFrame:IsShown() then
    shoppingFrame:Hide()
    return
  end

  CH.ScanBags(true)
  local kids = { shoppingFrame.content:GetChildren() }
  for _, kid in ipairs(kids) do kid:Hide(); kid:SetParent(nil) end
  local regions = { shoppingFrame.content:GetRegions() }
  for _, r in ipairs(regions) do r:Hide() end

  local h = BuildShoppingRows(shoppingFrame.content)
  shoppingFrame.content:SetHeight(math.max(h, 1))
  local visible = shoppingFrame:GetHeight() - 50
  shoppingFrame.scrollbar:SetMinMaxValues(0, math.max(0, h - visible))
  shoppingFrame.scrollbar:SetValue(0)

  shoppingFrame:Show()
end

-- ============================================================================
-- MINIMAP BUTTON
-- ============================================================================

local function CreateMinimapButton()
  local btn = CreateFrame("Button", "ConsoHelperMinimapButton", Minimap)
  btn:SetWidth(31)
  btn:SetHeight(31)
  btn:SetFrameStrata("MEDIUM")
  btn:SetFrameLevel(8)
  btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  btn:RegisterForDrag("LeftButton")

  local icon = btn:CreateTexture(nil, "BACKGROUND")
  icon:SetTexture("Interface\\Icons\\INV_Potion_93")
  icon:SetWidth(18)
  icon:SetHeight(18)
  icon:SetPoint("CENTER", btn, "CENTER", 0, 1)

  local border = btn:CreateTexture(nil, "OVERLAY")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetWidth(53)
  border:SetHeight(53)
  border:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)

  local function UpdatePosition()
    local angle = math.rad(ConsoHelper_Settings.settings.minimapAngle)
    local radius = 80
    btn:SetPoint("CENTER", Minimap, "CENTER", -math.cos(angle) * radius, math.sin(angle) * radius)
  end

  btn:SetScript("OnDragStart", function() btn.dragging = true end)
  btn:SetScript("OnDragStop", function() btn.dragging = false end)
  btn:SetScript("OnUpdate", function()
    if btn.dragging then
      local mx, my = GetCursorPosition()
      local scale = Minimap:GetEffectiveScale()
      mx, my = mx / scale, my / scale
      local cx, cy = Minimap:GetCenter()
      local angle = math.deg(math.atan2(my - cy, mx - cx))
      ConsoHelper_Settings.settings.minimapAngle = angle
      UpdatePosition()
    end
  end)
  btn:SetScript("OnClick", function()
    if arg1 == "RightButton" then
      UI.ToggleSettings()
    else
      UI.ToggleSelection()
    end
  end)
  btn:SetScript("OnEnter", function()
    GameTooltip:SetOwner(btn, "ANCHOR_LEFT")
    GameTooltip:AddLine("Conso Helper")
    GameTooltip:AddLine("Left-click: select buffs", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Right-click: settings", 0.8, 0.8, 0.8)
    GameTooltip:Show()
  end)
  btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

  UpdatePosition()
  return btn
end

-- ============================================================================
-- READY
-- ============================================================================

function UI.OnReady()
  CreateStatusFrame()
  RebuildStatusFrame()
  CreateMinimapButton()
  UI.UpdateFrameVisibility()
end
