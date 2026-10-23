local addonName, app = ...
local platform = {}
app.platform = platform
-- Both the minimap launcher and the minimized window use this same artwork.
app.iconTexture = "Interface\\AddOns\\"..addonName.."\\Media\\logo.tga"

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
