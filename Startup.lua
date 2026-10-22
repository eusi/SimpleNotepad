local addonName, app = ...
local L = app.L
BINDING_HEADER_SIMPLENOTEPAD = "SimpleNotepad"
BINDING_NAME_SIMPLENOTEPAD_TOGGLE = L["Show/hide SimpleNotepad"]
BINDING_NAME_SIMPLENOTEPAD_SEARCH = L["Search notes"]
local boot = CreateFrame("Frame")
boot:RegisterEvent("ADDON_LOADED")
boot:SetScript("OnEvent", function(_, _, name)
    if name ~= addonName then return end
    SimpleNotepad_DB = SimpleNotepad_DB or {}
    app.journal:Load(SimpleNotepad_DB)
    app:BuildWindow()
    local launcher = CreateFrame("Button", nil, Minimap)
    app.launcher = launcher
    launcher:SetSize(28, 28); launcher:SetPoint("TOPLEFT", -12, 0)
    launcher:SetNormalTexture("Interface\\Icons\\INV_Misc_Note_01")
    launcher:SetScript("OnClick", function() app:Toggle() end)
    launcher:SetShown(app.journal.data.options.minimap)
    SLASH_SIMPLENOTEPAD1 = "/snp"
    SLASH_SIMPLENOTEPAD2 = "/simplenotepad"
    SlashCmdList.SIMPLENOTEPAD = function(message)
        if message == "search" then app:Search() else app:Toggle() end
    end
    boot:UnregisterEvent("ADDON_LOADED")
end)
