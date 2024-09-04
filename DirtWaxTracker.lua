local ODD_GLOB_OF_WAX_ID = 212493
local PROFANED_TINDERBOX_ID = 221758
local RADIUS_THRESHOLD = 0.005

-- Check if the frame already exists before creating
if not DirtWaxTrackerFrame then
    local f = CreateFrame("Frame", "DirtWaxTrackerFrame", UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(250, 260)
    f:SetPoint("CENTER")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
  
    f.title = f:CreateFontString(nil, "OVERLAY")
    f.title:SetFontObject("GameFontHighlight")
    f.title:SetPoint("TOP", 0, -7) -- -9 + 2 = -7
    f.title:SetText("Dirt Wax Tracker")
  
    local startButton = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
    startButton:SetPoint("TOPRIGHT", f.title, "BOTTOM", 0, -10)
    startButton:SetSize(110, 30)
    startButton:SetText("Start")
    startButton:SetNormalFontObject("GameFontNormal")
    startButton:SetHighlightFontObject("GameFontHighlight")
  
    local showCheckbox = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    showCheckbox:ClearAllPoints()
    showCheckbox:SetPoint("TOPLEFT", startButton, "BOTTOMLEFT", 0, -10)
    showCheckbox.text:SetText("Show Map Icons")
    showCheckbox:SetChecked(true)
  
    local timerFrame = CreateFrame("Frame", nil, f)
    timerFrame:SetSize(300, 50)
    timerFrame:SetPoint("TOP", showCheckbox, "BOTTOM", 0, -10)
  
    local timerText = timerFrame:CreateFontString(nil, "OVERLAY")
    timerText:SetFontObject("GameFontHighlightLarge")
    timerText:SetPoint("TOPLEFT", timerFrame, "TOPLEFT", 140, 4)
    timerText:SetText("00:00:00")
  
    local textFrame = CreateFrame("Frame", "TextFrame", f)
    textFrame:SetSize(250, 200)
    textFrame:SetPoint("TOPLEFT", timerFrame, "BOTTOMLEFT", 141, 35)
  
    local waxCounterText = textFrame:CreateFontString(nil, "OVERLAY")
    waxCounterText:SetFontObject("GameFontHighlight")
    waxCounterText:SetPoint("TOPLEFT", textFrame, "TOPLEFT", 0, -10)
    waxCounterText:SetJustifyH("LEFT")
    waxCounterText:SetText("Odd Glob of Wax: 0")
  
    local tinderboxCounterText = textFrame:CreateFontString(nil, "OVERLAY")
    tinderboxCounterText:SetFontObject("GameFontHighlight")
    tinderboxCounterText:SetPoint("TOPLEFT", waxCounterText, "BOTTOMLEFT", 0, -10)
    tinderboxCounterText:SetJustifyH("LEFT")
    tinderboxCounterText:SetText("Profaned Tinderbox: 0")
  
    local dirtCounterText = textFrame:CreateFontString(nil, "OVERLAY")
    dirtCounterText:SetFontObject("GameFontHighlight")
    dirtCounterText:SetPoint("TOPLEFT", tinderboxCounterText, "BOTTOMLEFT", 0, -10)
    dirtCounterText:SetJustifyH("LEFT")
    dirtCounterText:SetText("Disturbed Dirt: 0")
  
    local waxPerHourText = textFrame:CreateFontString(nil, "OVERLAY")
    waxPerHourText:SetFontObject("GameFontHighlight")
    waxPerHourText:SetPoint("TOPLEFT", dirtCounterText, "BOTTOMLEFT", 0, -10)
    waxPerHourText:SetJustifyH("LEFT")
    waxPerHourText:SetText("Wax/h: 0")
  
    local dirtPerHourText = textFrame:CreateFontString(nil, "OVERLAY")
    dirtPerHourText:SetFontObject("GameFontHighlight")
    dirtPerHourText:SetPoint("TOPLEFT", waxPerHourText, "BOTTOMLEFT", 0, -10)
    dirtPerHourText:SetJustifyH("LEFT")
    dirtPerHourText:SetText("Dirt/h: 0")
  
    local elapsedTime = 0
    local waxCount = 0
    local tinderboxCount = 0
    local dirtCount = 0
    local timerRunning = false
  
    DirtWaxTrackerDB = DirtWaxTrackerDB or {coordinates = {}, showMapIcons = true}
  
    local function UpdateShowMapIcons(self)
        DirtWaxTrackerDB.showMapIcons = self:GetChecked()
        WorldMapFrame:RefreshAllDataProviders()
    end
    showCheckbox:SetScript("OnClick", UpdateShowMapIcons)
  
    local function UpdateTime()
        if timerRunning then
            elapsedTime = elapsedTime + 1
            local hours = math.floor(elapsedTime / 3600)
            local minutes = math.floor((elapsedTime % 3600) / 60)
            local seconds = elapsedTime % 60
            timerText:SetText(format("%02d:%02d:%02d", hours, minutes, seconds))
  
            if elapsedTime % 5 == 0 then
                waxPerHourText:SetText(format("Wax/h: %d", math.floor(waxCount / (elapsedTime / 3600))))
                dirtPerHourText:SetText(format("Dirt/h: %d", math.floor(dirtCount / (elapsedTime / 3600))))
            end
        end
    end
  
    local function StartSession()
        elapsedTime = 0
        waxCount = 0
        tinderboxCount = 0
        dirtCount = 0
        timerRunning = true
        waxCounterText:SetText("Odd Glob of Wax: 0")
        tinderboxCounterText:SetText("Profaned Tinderbox: 0")
        dirtCounterText:SetText("Disturbed Dirt: 0")
        waxPerHourText:SetText("Wax/h: 0")
        dirtPerHourText:SetText("Dirt/h: 0")
        timerText:SetText("00:00:00")
        startButton:SetText("Restart")
    end
  
    startButton:SetScript("OnClick", StartSession)
    f:SetScript("OnUpdate", UpdateTime)
  
    local function IsCoordinateNear(existingX, existingY, newX, newY, threshold)
        local dx = existingX - newX
        local dy = existingY - newY
        return (dx * dx + dy * dy) < (threshold * threshold)
    end
  
    local function OnEvent(self, event, ...)
        if event == "CHAT_MSG_LOOT" then
            local arg1 = ...
            local itemId, quantity = strmatch(arg1, "item:(%d+).-(%d*)")
            itemId = tonumber(itemId)
            quantity = tonumber(quantity) or 1
  
            local mapId = C_Map.GetBestMapForUnit("player")
            local position = C_Map.GetPlayerMapPosition(mapId, "player")
  
            if position then
                local x, y = position:GetXY()
  
                local shouldAdd = true
                for _, coord in ipairs(DirtWaxTrackerDB.coordinates) do
                    if coord.mapId == mapId and IsCoordinateNear(coord.x, coord.y, x, y, RADIUS_THRESHOLD) then
                        shouldAdd = false
                        break
                    end
                end
  
                if shouldAdd then
                    table.insert(DirtWaxTrackerDB.coordinates, {mapId = mapId, x = x, y = y})
                end
  
                if itemId == ODD_GLOB_OF_WAX_ID then
                    waxCount = waxCount + quantity
                    waxCounterText:SetText("Odd Glob of Wax: " .. waxCount)
                    dirtCount = dirtCount + 1
                    dirtCounterText:SetText("Disturbed Dirt: " .. dirtCount)
                elseif itemId == PROFANED_TINDERBOX_ID then
                    tinderboxCount = tinderboxCount + quantity
                    tinderboxCounterText:SetText("Profaned Tinderbox: " .. tinderboxCount)
                end
            end
        end
    end
  
    f:RegisterEvent("CHAT_MSG_LOOT")
    f:SetScript("OnEvent", OnEvent)
  
    local function CreateWorldMapMarkers()
        if not WorldMapFrame then return end
        
        for _, coord in ipairs(DirtWaxTrackerDB.coordinates) do
            if DirtWaxTrackerDB.showMapIcons then
                local pin = CreateFrame("Frame", nil, WorldMapFrame.ScrollContainer.Child)
                pin:SetSize(16, 16)
                pin:SetPoint("CENTER", WorldMapFrame.ScrollContainer.Child, "TOPLEFT", coord.x * WorldMapFrame.ScrollContainer.Child:GetWidth(), -coord.y * WorldMapFrame.ScrollContainer.Child:GetHeight())
                pin.texture = pin:CreateTexture(nil, "BACKGROUND")
                pin.texture:SetAllPoints()
                pin.texture:SetTexture(132386)
            end
        end
    end
  
    WorldMapFrame:HookScript("OnShow", CreateWorldMapMarkers)
  
    SLASH_DIRT1 = "/dirt"
    SlashCmdList["DIRT"] = function(msg)
        if f:IsShown() then
            f:Hide()
        else
            f:Show()
        end
    end
end
