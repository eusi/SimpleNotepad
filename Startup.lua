local addonName, app = ...
local L = app.L
-- WoW loads Bindings.xml automatically; its labels must exist at file load.
BINDING_HEADER_SIMPLENOTEPAD = "SimpleNotepad"
BINDING_NAME_SIMPLENOTEPAD_TOGGLE = L["Show/hide SimpleNotepad"]
BINDING_NAME_SIMPLENOTEPAD_SEARCH = L["Search notes"]
-- SavedVariables are ready when this addon's ADDON_LOADED event fires.
local boot = CreateFrame("Frame")
boot:RegisterEvent("ADDON_LOADED")
boot:SetScript("OnEvent", function(_, _, name)
    if name ~= addonName then return end
    local accountKey=app.devPreview and "SimpleNotepad_DevDB" or "SimpleNotepad_DB"
    local characterKey=app.devPreview and "SimpleNotepad_DevCharacterDB" or "SimpleNotepad_CharacterDB"
    if type(_G[accountKey]) ~= "table" then _G[accountKey] = {} end
    if type(_G[characterKey]) ~= "table" then _G[characterKey] = {} end
    if app.PrepareDevData then app:PrepareDevData(_G[accountKey],_G[characterKey]) end
    app.journal:LoadCharacter(_G[accountKey], _G[characterKey])
    app:BuildWindow()
    if app.sharing then app.sharing:Start() end
    -- The minimap itself clips children to its mask on Retail. Keep the launcher
    -- outside that mask and explicitly above the minimap artwork.
    local launcher = CreateFrame("Button", "SimpleNotepadMinimapButton", MinimapCluster or UIParent)
    app.launcher = launcher
    launcher:SetSize(31,31); launcher:SetFrameStrata("MEDIUM")
    launcher:SetFrameLevel(Minimap:GetFrameLevel()+10)
    local background=launcher:CreateTexture(nil,"BACKGROUND")
    background:SetSize(25,25); background:SetPoint("CENTER")
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    local icon=launcher:CreateTexture(nil,"ARTWORK")
    icon:SetSize(20,20); icon:SetPoint("CENTER")
    icon:SetTexture(app.iconTexture)
    app.launcherIcon=icon
    local border=launcher:CreateTexture(nil,"OVERLAY")
    border:SetSize(54,54); border:SetPoint("TOPLEFT")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    local lastWidth,lastHeight,lastShape,lastScale,lastLauncherScale
    local function position()
        local shape=GetMinimapShape and GetMinimapShape() or "ROUND"
        local width,height=Minimap:GetWidth(),Minimap:GetHeight()
        local mapScale,buttonScale=Minimap:GetEffectiveScale(),launcher:GetEffectiveScale()
        -- The launcher lives outside the map's clipping/scaling hierarchy.
        -- Express the map's displayed size in the launcher's coordinate space.
        local scale=mapScale/buttonScale
        local x,y=app.platform:MinimapOffset(app.journal.data.options.minimapAngle or 225,width*scale,height*scale,shape)
        lastWidth,lastHeight,lastShape,lastScale,lastLauncherScale=width,height,shape,mapScale,buttonScale
        launcher:ClearAllPoints()
        launcher:SetPoint("CENTER",Minimap,"CENTER",x,y)
    end
    app.PositionMinimapButton=position
    local poll=0
    local function watch(_,elapsed)
        poll=poll+elapsed
        if poll<0.5 then return end
        poll=0
        local shape=GetMinimapShape and GetMinimapShape() or "ROUND"
        if lastWidth~=Minimap:GetWidth() or lastHeight~=Minimap:GetHeight() or lastShape~=shape
            or lastScale~=Minimap:GetEffectiveScale() or lastLauncherScale~=launcher:GetEffectiveScale() then position() end
    end
    position()
    launcher:SetScript("OnUpdate",watch)
    launcher:RegisterForDrag("LeftButton")
    launcher:SetScript("OnMouseDown",function(button) button.dragged=nil end)
    launcher:SetScript("OnDragStart",function(button)
        button.dragged=true; GameTooltip:Hide()
        button:SetScript("OnUpdate",function()
            local x,y=GetCursorPosition(); local scale=Minimap:GetEffectiveScale()
            local cx,cy=Minimap:GetCenter()
            app.journal.data.options.minimapAngle=math.deg(math.atan2(y/scale-cy,x/scale-cx))
            position()
        end)
    end)
    launcher:SetScript("OnDragStop",function(button) button:SetScript("OnUpdate",watch); position() end)
    launcher:SetScript("OnClick", function(button)
        if not button.dragged then app:Toggle() end
        button.dragged=nil
    end)
    launcher:SetScript("OnEnter",function(button)
        GameTooltip:SetOwner(button,"ANCHOR_LEFT"); GameTooltip:SetText("SimpleNotepad")
        GameTooltip:AddLine(L["Click to open. Drag to move."],1,1,1); GameTooltip:Show()
    end)
    launcher:SetScript("OnLeave",function() GameTooltip:Hide() end)
    launcher:SetShown(app.journal.data.options.minimap)
    SLASH_SIMPLENOTEPAD1 = "/snp"
    SLASH_SIMPLENOTEPAD2 = "/simplenotepad"
    SLASH_SIMPLENOTEPAD3 = "/sn"
    SlashCmdList.SIMPLENOTEPAD = function(message)
        message=(message or ""):lower():match("^%s*(.-)%s*$")
        if message == "search" then app:Search() else app:Toggle() end
    end
    boot:UnregisterEvent("ADDON_LOADED")
end)
