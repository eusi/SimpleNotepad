local addonName, app = ...
local skin = {}
local platform = app.platform
app.skin = skin
-- Palette and tracked regions are updated without rebuilding the window.
skin.colors = {
    editor = {17/255, 17/255, 17/255}, toolbar = {27/255, 28/255, 36/255},
    rail = {16/255, 16/255, 16/255}, tab = {22/255, 23/255, 28/255},
    selected = {37/255, 39/255, 51/255}, border = {57/255, 58/255, 64/255},
    button = {17/255, 18/255, 22/255}, hover = {32/255, 33/255, 39/255},
    text = {238/255, 238/255, 238/255}, muted = {150/255, 150/255, 156/255},
    blue = {0, 170/255, 1}, active = {21/255, 31/255, 41/255},
}
local defaults, fills, labels, fillByTexture, bevels = {}, {}, {}, {}, {}
local buttons, scrolls, outlines = {}, {}, {}
for key,color in pairs(skin.colors) do defaults[key]={unpack(color)} end

function skin:Paint(texture,color)
    local fill=fillByTexture[texture]
    if fill then fill.color=color end
    if self.wow and fill then
        local marble=color == self.colors.editor
        -- Repeat the material beyond its edges instead of smearing the last pixel.
        texture:SetTexture(marble and "Interface\\FrameGeneral\\UI-Background-Marble" or "Interface\\FrameGeneral\\UI-Background-Rock", "REPEAT", "REPEAT")
        texture:SetHorizTile(true); texture:SetVertTile(true)
        local size=marble and 256 or 128
        texture:SetTexCoord(0,math.max(1,fill.parent:GetWidth())/size,0,math.max(1,fill.parent:GetHeight())/size)
        -- The native materials are already dark. Lift the tint so their grain
        -- remains visible instead of multiplying it by a near-black flat color.
        texture:SetVertexColor(math.min(1,color[1]*2+0.45),math.min(1,color[2]*2+0.45),math.min(1,color[3]*2+0.45))
        -- Native materials contain transparent pixels; always back them with color.
        if not fill.base then
            fill.base=fill.parent:CreateTexture(nil,"BACKGROUND",nil,-1)
            fill.base:SetAllPoints(texture)
        end
        platform:Color(fill.base,color); fill.base:Show()
        texture:SetAlpha(self.lightBackground and 0.25 or 1)
    else
        if fill and fill.base then fill.base:Hide() end
        texture:SetAlpha(1)
        texture:SetHorizTile(false); texture:SetVertTile(false)
        texture:SetTexCoord(0,1,0,1); texture:SetVertexColor(1,1,1)
        platform:Color(texture,color)
    end
end

function skin:ResizeTextures()
    if self.wow then for _,fill in ipairs(fills) do self:Paint(fill.texture,fill.color) end end
end

function skin:Configure(options)
    self.wow=options.style == "wow"
    self.lightBackground=false
    for key,color in pairs(defaults) do
        for index=1,3 do self.colors[key][index]=color[index] end
    end
    local profile=options.styleColors and options.styleColors[options.style] or {}
    local shade=(self.wow and 72 or 24)/255
    local background=profile.backgroundColor or {shade,shade,shade}
    if background then
        local offsets={editor=0,toolbar=0.045,rail=-0.01,tab=0.02,selected=0.095,border=0.16,button=0.015,hover=0.10,active=0.07}
        for key,offset in pairs(offsets) do
            for index=1,3 do self.colors[key][index]=math.max(0,math.min(1,background[index]+offset)) end
        end
        local brightness=background[1]*0.299+background[2]*0.587+background[3]*0.114
        if brightness > 0.55 then
            self.lightBackground=true
            self.colors.text[1],self.colors.text[2],self.colors.text[3]=0.08,0.08,0.08
            self.colors.muted[1],self.colors.muted[2],self.colors.muted[3]=0.25,0.25,0.25
        end
    end
    local accent=profile.accentColor or {0,238/255,1}
    if accent then for index=1,3 do self.colors.blue[index]=accent[index] end end
    for _,fill in ipairs(fills) do self:Paint(fill.texture,fill.color) end
    for _,edge in ipairs(bevels) do edge:SetShown(self.wow) end
    for _,label in ipairs(labels) do label.font:SetTextColor(unpack(label.muted and self.colors.muted or self.colors.text)) end
    for _,button in ipairs(buttons) do self:ButtonState(button) end
    for _,scroll in ipairs(scrolls) do self:StyleScroll(scroll) end
    for _,edge in ipairs(outlines) do platform:Color(edge,self.colors.border) end
end

-- Reusable controls.
function skin:Fill(parent, color, layer)
    local texture = parent:CreateTexture(nil, layer or "BACKGROUND")
    texture:SetAllPoints()
    local fill={texture=texture,color=color,parent=parent}
    fills[#fills+1]=fill; fillByTexture[texture]=fill
    self:Paint(texture,color)
    return texture
end

function skin:Label(parent, text, muted)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetText(text)
    label:SetTextColor(unpack(muted and self.colors.muted or self.colors.text))
    labels[#labels+1]={font=label,muted=muted}
    return label
end

function skin:Icon(parent, name)
    -- Antialiased 64px assets avoid jagged rotated one-pixel texture strokes.
    local texture=parent:CreateTexture(nil,"ARTWORK")
    texture:SetSize(14,14); texture:SetPoint("CENTER")
    texture:SetTexture("Interface\\AddOns\\"..addonName.."\\Media\\"..name..".tga")
    texture:SetVertexColor(unpack(self.colors.text))
    labels[#labels+1]={font={SetTextColor=function(_,...) texture:SetVertexColor(...) end}}
    return texture
end

function skin:Button(parent, icon, tooltip, callback, width)
    local button = CreateFrame("Button", nil, parent)
    button.plain=icon ~= nil
    button.settings=parent.settingsCard
    button:SetSize(width or (icon and 18 or 28),icon and 18 or 28)
    button.fill = self:Fill(button, self.colors.button)
    if button.plain then button.fill:Hide() end
    -- Light upper edges and dark lower edges give the native stone material
    -- the shallow inset/button treatment used by WoW panels.
    for index=1,(button.plain and 0 or 4) do
        local edge=button:CreateTexture(nil,"BORDER")
        if index <= 2 then edge:SetHeight(1) else edge:SetWidth(1) end
        if index == 1 then edge:SetPoint("TOPLEFT"); edge:SetPoint("TOPRIGHT")
        elseif index == 2 then edge:SetPoint("BOTTOMLEFT"); edge:SetPoint("BOTTOMRIGHT")
        elseif index == 3 then edge:SetPoint("TOPLEFT"); edge:SetPoint("BOTTOMLEFT")
        else edge:SetPoint("TOPRIGHT"); edge:SetPoint("BOTTOMRIGHT") end
        platform:Color(edge,(index == 1 or index == 3) and {0.46,0.40,0.29,0.65} or {0.02,0.02,0.02,0.9})
        edge:SetShown(self.wow); bevels[#bevels+1]=edge
    end
    if icon then button.icon = self:Icon(button, icon) end
    buttons[#buttons+1]=button
    button:SetScript("OnEnter", function(self)
        self.hovered=true
        if not self.plain then skin:Paint(self.fill,skin.colors.hover) end
        skin:ButtonState(self)
        if tooltip then
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText(tooltip); GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", function(self)
        self.hovered=false
        if not self.plain then skin:Paint(self.fill,self.active and skin.colors.active or skin.colors.button) end
        skin:ButtonState(self)
        GameTooltip:Hide()
    end)
    button:SetScript("OnClick", callback)
    if button.settings then self:ButtonState(button) end
    return button
end

function skin:ButtonState(button)
    if button.plain then
        button.fill:Hide()
        button.icon:SetVertexColor(unpack((button.active or button.hovered) and self.colors.blue or self.colors.text))
    elseif button.settings then
        local color=button.hovered and self.colors.hover or button.active and self.colors.active or self.colors.button
        if not self.wow then
            local offset=(button.hovered and 0.20 or button.active and 0.16 or 0.12)*(self.lightBackground and -1 or 1)
            color={}
            for index=1,3 do color[index]=math.max(0,math.min(1,self.colors.editor[index]+offset)) end
        end
        self:Paint(button.fill,color)
    end
end

function skin:Outline(parent)
    local edges={}
    for index=1,4 do
        local edge=parent:CreateTexture(nil,"OVERLAY")
        platform:Color(edge,self.colors.border)
        if index <= 2 then edge:SetHeight(1) else edge:SetWidth(1) end
        if index == 1 then edge:SetPoint("TOPLEFT"); edge:SetPoint("TOPRIGHT")
        elseif index == 2 then edge:SetPoint("BOTTOMLEFT"); edge:SetPoint("BOTTOMRIGHT")
        elseif index == 3 then edge:SetPoint("TOPLEFT"); edge:SetPoint("BOTTOMLEFT")
        else edge:SetPoint("TOPRIGHT"); edge:SetPoint("BOTTOMRIGHT") end
        edges[index]=edge
        outlines[#outlines+1]=edge
    end
    return edges
end

-- Shared scrollbar visuals and state for all scrollable panes.
function skin:StyleScroll(scroll)
    local bar=scroll.bar
    bar:SetWidth(self.wow and 14 or 6)
    if self.wow then
        bar:GetThumbTexture():SetTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
        bar:GetThumbTexture():SetTexCoord(0.2,0.8,0.125,0.875)
        bar:GetThumbTexture():SetVertexColor(1,1,1)
    else
        platform:Color(bar:GetThumbTexture(),self.colors.muted)
        bar:GetThumbTexture():SetTexCoord(0,1,0,1)
        bar:GetThumbTexture():SetVertexColor(1,1,1)
    end
    scroll:UpdateScrollBar()
end

function skin:ScrollFrame(parent)
    local scroll=CreateFrame("ScrollFrame",nil,parent)
    local bar=CreateFrame("Slider",nil,scroll)
    scroll.bar=bar
    bar:SetOrientation("VERTICAL"); bar:EnableMouse(true)
    bar:SetPoint("TOPLEFT",scroll,"TOPRIGHT",4,0)
    bar:SetPoint("BOTTOMLEFT",scroll,"BOTTOMRIGHT",4,0)
    self:Fill(bar,self.colors.rail)
    bar:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
    bar:SetValueStep(1); app.platform:Slider(bar)
    function scroll:UpdateScrollBar()
        -- Slider and ScrollFrame callbacks can trigger each other.
        if self.syncing then return end
        self.syncing=true
        local range=math.max(0,self:GetVerticalScrollRange())
        bar:SetMinMaxValues(0,range)
        local value=math.max(0,math.min(range,self:GetVerticalScroll()))
        bar:SetValue(value)
        if value ~= self:GetVerticalScroll() then self:SetVerticalScroll(value) end
        bar:SetShown(range > 0)
        local height=math.max(1,self:GetHeight())
        local thumbHeight=skin.wow and math.min(24,height) or math.min(height,math.max(18,height*height/(height+range)))
        bar:GetThumbTexture():SetSize(skin.wow and 14 or 6,thumbHeight)
        self.syncing=false
    end
    bar:SetScript("OnValueChanged",function(_,value)
        if not scroll.syncing then scroll:SetVerticalScroll(value) end
    end)
    scroll:SetScript("OnVerticalScroll",function(frame) frame:UpdateScrollBar() end)
    scroll:SetScript("OnScrollRangeChanged",function(frame) frame:UpdateScrollBar() end)
    scroll:SetScript("OnSizeChanged",function(frame) frame:UpdateScrollBar() end)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel",function(frame,delta)
        frame:SetVerticalScroll(math.max(0,math.min(frame:GetVerticalScrollRange(),frame:GetVerticalScroll()-delta*40)))
    end)
    scrolls[#scrolls+1]=scroll
    self:StyleScroll(scroll)
    return scroll
end
