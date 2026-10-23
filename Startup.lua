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
    SimpleNotepad_DB = SimpleNotepad_DB or {}
    app.journal:Load(SimpleNotepad_DB)
    app:BuildWindow()
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
    local function position()
        local angle=math.rad(app.journal.data.options.minimapAngle or 225)
        local radius=Minimap:GetWidth()/2+8
        launcher:ClearAllPoints()
        launcher:SetPoint("CENTER",Minimap,"CENTER",math.cos(angle)*radius,math.sin(angle)*radius)
    end
    position()
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
    launcher:SetScript("OnDragStop",function(button) button:SetScript("OnUpdate",nil) end)
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
        if message == "search" then app:Search() else app:Toggle() end
    end
    boot:UnregisterEvent("ADDON_LOADED")
end)
