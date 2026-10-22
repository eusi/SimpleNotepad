local _, app = ...
local platform = {}
app.platform = platform

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
    if hooksecurefunc and type(ChatEdit_InsertLink)=="function" then
        hooksecurefunc("ChatEdit_InsertLink",function(link)
            if link and editor:HasFocus() then editor:Insert(link) end
        end)
    end
end

function platform:Clip(frame)
    if frame.SetClipsChildren then frame:SetClipsChildren(true) end
end
