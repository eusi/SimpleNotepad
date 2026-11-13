local addonName, app = ...
local platform = {}
app.platform = platform
local clientInterface=GetBuildInfo and select(4,GetBuildInfo())
platform.isForever=type(clientInterface)=="number" and clientInterface>=16000 and clientInterface<17000
local metadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
app.version = metadata and metadata(addonName,"Version") or ""
-- Both the minimap launcher and the minimized window use this same artwork.
app.iconTexture = "Interface\\AddOns\\"..addonName.."\\Media\\logo.tga"

-- Minimap addons advertise rounded quadrants through GetMinimapShape.
local minimapCorners={
    ROUND={true,true,true,true}, SQUARE={false,false,false,false},
    ["CORNER-TOPLEFT"]={false,false,false,true}, ["CORNER-TOPRIGHT"]={false,false,true,false},
    ["CORNER-BOTTOMLEFT"]={false,true,false,false}, ["CORNER-BOTTOMRIGHT"]={true,false,false,false},
    ["SIDE-LEFT"]={false,true,false,true}, ["SIDE-RIGHT"]={true,false,true,false},
    ["SIDE-TOP"]={false,false,true,true}, ["SIDE-BOTTOM"]={true,true,false,false},
    ["TRICORNER-TOPLEFT"]={false,true,true,true}, ["TRICORNER-TOPRIGHT"]={true,false,true,true},
    ["TRICORNER-BOTTOMLEFT"]={true,true,false,true}, ["TRICORNER-BOTTOMRIGHT"]={true,true,true,false},
}
function platform:MinimapOffset(angle,width,height,shape)
    local x,y=math.cos(math.rad(angle)),math.sin(math.rad(angle))
    local quadrant=1+(x<0 and 1 or 0)+(y>0 and 2 or 0)
    local corners=minimapCorners[shape] or minimapCorners.ROUND
    local factor=corners[quadrant] and 1 or 1/math.max(math.abs(x),math.abs(y))
    return x*(width/2+8)*factor,y*(height/2+8)*factor
end

local function noteFailure(self,key,detail)
    self.noteError=key; self.noteErrorDetail=detail
    return false
end

local function enumResult(values,result)
    if type(values)=="table" then
        for name,value in pairs(values) do
            if value==result then return name.." ("..tostring(result)..")" end
        end
    end
    return tostring(result)
end

function platform:RegisterNotePrefix(prefix)
    self.noteError=nil; self.noteErrorDetail=nil
    local register=(C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix) or RegisterAddonMessagePrefix
    local send=(C_ChatInfo and C_ChatInfo.SendAddonMessage) or SendAddonMessage
    if type(register)~="function" or type(send)~="function" then
        return noteFailure(self,"Note sharing API is missing on this client.")
    end
    local ok,result=pcall(register,prefix)
    if not ok then return noteFailure(self,"Note sharing API error: %s",tostring(result)) end
    -- A prefix may already have been registered by this addon or another listener.
    local registered=C_ChatInfo and C_ChatInfo.IsAddonMessagePrefixRegistered
    if type(registered)=="function" then
        local checked,exists=pcall(registered,prefix)
        if checked and exists==true then return true end
    end
    if result==false then return noteFailure(self,"Note sharing could not initialize (%s).","registration rejected") end
    local values=Enum and Enum.RegisterAddonMessagePrefixResult
    if type(result)=="number" then
        if result==(values and values.Success or 0) or result==(values and values.DuplicatePrefix or 1) then return true end
        return noteFailure(self,"Note sharing could not initialize (%s).",enumResult(values,result))
    end
    return true
end

function platform:SendNotePacket(prefix,message,channel)
    self.noteError=nil; self.noteErrorDetail=nil
    local info=C_ChatInfo
    if info and info.InChatMessagingLockdown and info.InChatMessagingLockdown() then
        return noteFailure(self,"WoW currently blocks addon messages (chat lockdown).")
    end
    -- Forever can report this flag while normal sends succeed; use the actual send result there.
    -- A real chat lockdown and an API rejection still stop the transfer.
    if not self.isForever and info and info.AreOutgoingAddonChatMessagesRestricted and info.AreOutgoingAddonChatMessagesRestricted() then
        return noteFailure(self,"WoW blocks outgoing addon messages on this realm.")
    end
    local send=(info and info.SendAddonMessage) or SendAddonMessage
    if type(send)~="function" then return noteFailure(self,"Note sharing API is missing on this client.") end
    local ok,result=pcall(send,prefix,message,channel)
    if not ok then return noteFailure(self,"Note sharing API error: %s",tostring(result)) end
    if result==false then return noteFailure(self,"Sending failed (%s).","send rejected") end
    local values=Enum and Enum.SendAddonMessageResult
    if type(result)=="number" then
        if result==(values and values.AddonMessageThrottle or 3) or result==(values and values.ChannelThrottle or 8) then return "retry" end
        if result==(values and values.Success or 0) then return true end
        if result==(values and values.AddOnMessageLockdown or 11) then
            return noteFailure(self,"WoW currently blocks addon messages (chat lockdown).")
        end
        if result==(values and values.NotInGroup or 5) then return noteFailure(self,"Join a party or raid first.") end
        return noteFailure(self,"Sending failed (%s).",enumResult(values,result))
    end
    return true -- Legacy clients return nil or a boolean.
end

-- Feature checks isolate widget differences between current WoW clients.
function platform:Color(texture,color)
    if texture.SetColorTexture then texture:SetColorTexture(unpack(color))
    else texture:SetTexture(unpack(color)) end
end

function platform:ResizeBounds(frame,width,height)
    if frame.SetResizeBounds then frame:SetResizeBounds(width,height)
    elseif frame.SetMinResize then frame:SetMinResize(width,height) end
end

function platform:Slider(slider)
    if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
end

function platform:Hyperlinks(editor)
    if editor.SetHyperlinksEnabled then editor:SetHyperlinksEnabled(true) end
    editor:SetScript("OnHyperlinkClick",function(_,link,text,button)
        if SetItemRef then SetItemRef(link,text,button) end
    end)
    -- Handle the focused note before chat can steal focus. Return true so bag
    -- clicks do not also fall through to stack splitting after inserting a link.
    local function wrap(original)
        return function(link,...)
            if type(link)=="string" and link~="" and editor:IsShown() and editor:HasFocus() then
                editor:Insert(link)
                if app.CommitNoteInput then app:CommitNoteInput(editor) end
                return true
            end
            return original(link,...)
        end
    end
    local modern=ChatFrameUtil and ChatFrameUtil.InsertLink
    local legacy=ChatEdit_InsertLink
    if type(modern)=="function" then ChatFrameUtil.InsertLink=wrap(modern) end
    if type(legacy)=="function" then
        ChatEdit_InsertLink=(legacy==modern) and ChatFrameUtil.InsertLink or wrap(legacy)
    end
end

function platform:Clip(frame)
    if frame.SetClipsChildren then frame:SetClipsChildren(true) end
end

function platform:ChooseColor(color, changed, cancelled)
    local picker=ColorPickerFrame
    if not picker then return end
    if picker:IsShown() then picker:Hide() end
    local function update() changed(picker:GetColorRGB()) end
    if picker.SetupColorPickerAndShow then
        picker:SetupColorPickerAndShow({
            r=color[1],g=color[2],b=color[3],hasOpacity=false,
            swatchFunc=update,opacityFunc=update,cancelFunc=cancelled,
        })
    else
        -- Older pickers use callback fields instead of an options table.
        picker.func=update; picker.cancelFunc=cancelled; picker.hasOpacity=false
        picker:SetColorRGB(unpack(color)); picker:Show()
    end
end
