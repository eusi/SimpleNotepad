local _, app = ...
local skin = {}
local platform = app.platform
app.skin = skin
skin.colors = {
    editor = {17/255, 17/255, 17/255}, toolbar = {27/255, 28/255, 36/255},
    rail = {16/255, 16/255, 16/255}, tab = {22/255, 23/255, 28/255},
    selected = {37/255, 39/255, 51/255}, border = {57/255, 58/255, 64/255},
    button = {17/255, 18/255, 22/255}, hover = {32/255, 33/255, 39/255},
    text = {238/255, 238/255, 238/255}, muted = {150/255, 150/255, 156/255},
    blue = {0, 170/255, 1}, active = {21/255, 31/255, 41/255},
}

function skin:Fill(parent, color, layer)
    local texture = parent:CreateTexture(nil, layer or "BACKGROUND")
    texture:SetAllPoints()
    platform:Color(texture,color)
    return texture
end

function skin:Label(parent, text, muted)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetText(text)
    label:SetTextColor(unpack(muted and self.colors.muted or self.colors.text))
    return label
end

-- Small vector icons use standard textures, independent of fonts and game atlases.
local shapes = {
    plus = {{3,8,13,8},{8,3,8,13}}, close = {{4,4,12,12},{4,12,12,4}},
    previous = {{10,3,5,8},{5,8,10,13}}, next = {{6,3,11,8},{11,8,6,13}},
    list = {{5,4,13,4},{5,8,13,8},{5,12,13,12},{2,4,2.1,4},{2,8,2.1,8},{2,12,2.1,12}},
    undo = {{7,3,3,7},{3,7,7,11},{3,7,10,7},{10,7,13,10},{13,10,13,13}},
    redo = {{9,3,13,7},{13,7,9,11},{13,7,6,7},{6,7,3,10},{3,10,3,13}},
    rename = {{3,11,11,3},{11,3,14,6},{14,6,6,14},{6,14,2,15},{2,15,3,11},{9,5,12,8}},
    minimize = {{3,11,13,11}}, autoHide = {{2,6,2,2},{2,2,14,2},{14,2,14,6},{5,10,8,7},{8,7,11,10},{8,7,8,15}},
    resize = {{6,14,14,6},{10,14,14,10}},
}

local function stroke(parent, x1, y1, x2, y2)
    local texture = parent:CreateTexture(nil, "ARTWORK")
    local dx, dy = x2-x1, y2-y1
    if texture.SetRotation then
        texture:SetSize(math.max(1.5, math.sqrt(dx*dx+dy*dy)), 1.5)
        texture:SetPoint("CENTER", parent, "CENTER", (x1+x2)/2-8, 8-(y1+y2)/2)
        platform:Color(texture,skin.colors.text)
        texture:SetRotation(math.atan2(-dy, dx))
    else
        local steps=math.max(1,math.ceil(math.max(math.abs(dx),math.abs(dy))))
        for step=0,steps do
            local pixel=step==0 and texture or parent:CreateTexture(nil,"ARTWORK")
            pixel:SetSize(1.5,1.5)
            pixel:SetPoint("CENTER",parent,"CENTER",x1+dx*step/steps-8,8-y1-dy*step/steps)
            platform:Color(pixel,skin.colors.text)
        end
    end
end

function skin:Icon(parent, name)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(16,16); frame:SetPoint("CENTER")
    for _, points in ipairs(shapes[name] or {}) do stroke(frame, unpack(points)) end
    if name == "search" or name == "settings" then
        local radius = name == "search" and 4.5 or 4
        local center = name == "search" and 6.5 or 8
        for index=0,15 do
            local angle, nextAngle = index*math.pi/8, (index+1)*math.pi/8
            stroke(frame, center+radius*math.cos(angle), center+radius*math.sin(angle),
                center+radius*math.cos(nextAngle), center+radius*math.sin(nextAngle))
        end
        if name == "search" then stroke(frame,10,10,14,14)
        else
            for index=0,7 do
                local angle = index*math.pi/4
                stroke(frame,8+5*math.cos(angle),8+5*math.sin(angle),8+7*math.cos(angle),8+7*math.sin(angle))
            end
        end
    end
    return frame
end

function skin:Button(parent, icon, tooltip, callback, width)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width or 28,28)
    button.fill = self:Fill(button, self.colors.button)
    if icon then button.icon = self:Icon(button, icon) end
    button:SetScript("OnEnter", function(self)
        platform:Color(self.fill,skin.colors.hover)
        if tooltip then
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText(tooltip); GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", function(self)
        platform:Color(self.fill,self.active and skin.colors.active or skin.colors.button)
        GameTooltip:Hide()
    end)
    button:SetScript("OnClick", callback)
    return button
end
