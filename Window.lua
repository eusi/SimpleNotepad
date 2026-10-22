local _, app = ...
local L = app.L
local book, skin = app.journal, app.skin
local view = {mode = "note", tabButtons = {}, rows = {}, headerProgress = 1, fade = 1}

local function strip(text) return text:match("^%s*(.-)%s*$") end
local function show(frame, visible) frame:SetShown(visible) end

function view:CloseSearch()
    self.search:ClearFocus(); self.searchPanel:Hide()
end

function view:Select(index)
    self:CommitRename()
    book:Select(index); self.mode = "note"; self.picker:Hide()
    self:Refresh()
end

function view:Refresh()
    self.writing = true
    self.editor:SetText(book:Current().body)
    self.writing = false
    show(self.editorScroll, self.mode == "note")
    show(self.preferences, self.mode == "settings")
    self:Tabs(); self:List()
end

function view:CommitRename(cancel)
    if not self.renaming then return end
    local page = self.renaming
    self.renaming = nil
    if not cancel then
        for index, candidate in ipairs(book.data.pages) do
            if candidate == page then book:Rename(index, self.rename:GetText()); break end
        end
    end
    self.rename:ClearFocus(); self.renamePanel:Hide()
end

function view:Rename(index)
    self:CommitRename()
    self.renaming = book.data.pages[index]
    self.rename:SetText(self.renaming.name)
    self.renamePanel:Show(); self.rename:SetFocus(); self.rename:HighlightText()
end

function view:NewPage()
    self:CommitRename(); book:Add(); self.mode = "note"
    self.picker:Hide(); self:Refresh(); self.editor:SetFocus()
end

function view:Settings()
    self:CommitRename(); self:CloseSearch(); self.picker:Hide()
    self.settingsOpen = true; self.mode = "settings"; self:Refresh()
end

function view:Search()
    if not self.root:IsShown() or (self.animation and not self.animation.opening) then self:Animate(true) end
    self.headerProgress = 1; self.idle = 0; self:Layout()
    self.picker:Hide()
    if self.searchPanel:IsShown() then self:CloseSearch(); return end
    self.searchPanel:Show(); self.search:SetFocus(); self.search:HighlightText()
end

function view:Find()
    local query = strip(self.search:GetText())
    if query == "" then return end
    local matches = book:Search(query)
    self:CloseSearch()
    if #matches == 0 then
        self.notice:SetText(L["No matching notes"]); self.notice:Show(); self.noticeTime = 2.2
        return
    end
    local destination = matches[1]
    for _, index in ipairs(matches) do if index > book.data.selected then destination = index; break end end
    self:Select(destination); self.editor:SetFocus()
    local first, last = app.Find(book:Current().body, query)
    if first then self.editor:SetCursorPosition(last); self.editor:HighlightText(first-1, last) end
end

function view:Tabs()
    for _, button in ipairs(self.tabButtons) do button:Hide() end
    local count, offset, selectedOffset, slot = 0, 0, 0, 0
    for _, page in ipairs(book.data.pages) do if page.open then count = count+1 end end
    for index, page in ipairs(book.data.pages) do
        if page.open then
            slot = slot+1
            local pageIndex = index
            local button = self.tabButtons[slot]
            if not button then
                button = skin:Button(self.tabCanvas, nil, nil, function() end, 150)
                button:SetHeight(35)
                button.label = skin:Label(button, "")
                button.label:SetPoint("LEFT", 10, 0); button.label:SetWidth(110); button.label:SetJustifyH("LEFT")
                button.close = skin:Button(button,"close",L["Close tab (keep note)"],function() end,22)
                button.close:SetPoint("RIGHT", -3,0)
                button.accent = button:CreateTexture(nil,"OVERLAY")
                app.platform:Color(button.accent,skin.colors.blue); button.accent:SetHeight(2)
                button.accent:SetPoint("TOPLEFT"); button.accent:SetPoint("TOPRIGHT")
                button:SetScript("OnEnter",nil); button:SetScript("OnLeave",nil)
                self.tabButtons[slot] = button
            end
            local active = self.mode == "note" and index == book.data.selected
            button:ClearAllPoints(); button:SetPoint("LEFT", self.tabCanvas,"LEFT",offset,0)
            app.platform:Color(button.fill,active and skin.colors.selected or skin.colors.tab)
            button.label:SetText(#book.data.pages > 1 and page.name or "")
            button.label:SetTextColor(unpack(active and skin.colors.text or skin.colors.muted))
            show(button.accent, active); show(button.close, count > 1)
            button:SetScript("OnClick", function() self:Select(pageIndex) end)
            button:SetScript("OnDoubleClick", function() self:Rename(pageIndex) end)
            button.close:SetScript("OnClick", function() self:CommitRename(); book:Close(pageIndex); self:Refresh() end)
            button:Show()
            if active then selectedOffset = offset end
            offset = offset+151
        end
    end
    show(self.settingsTab, self.settingsOpen)
    if self.settingsOpen then
        self.settingsTab:ClearAllPoints(); self.settingsTab:SetPoint("LEFT", self.tabCanvas,"LEFT",offset,0)
        app.platform:Color(self.settingsTab.fill,self.mode == "settings" and skin.colors.selected or skin.colors.tab)
        if self.mode == "settings" then selectedOffset = offset end
        offset = offset+136
    end
    self.tabCanvas:SetWidth(math.max(1,offset))
    local width = self.tabScroll:GetWidth()
    local current = self.tabScroll:GetHorizontalScroll()
    if selectedOffset < current then current = selectedOffset
    elseif selectedOffset+150 > current+width then current = selectedOffset+150-width end
    self.tabScroll:SetHorizontalScroll(math.max(0, math.min(current, math.max(0,offset-width))))
end

function view:List()
    for _, row in ipairs(self.rows) do row:Hide() end
    for index, page in ipairs(book.data.pages) do
        local pageIndex, pageObject = index, page
        local row = self.rows[index]
        if not row then
            row = CreateFrame("Frame",nil,self.listBody); row:SetSize(252,32)
            row.open = skin:Button(row,nil,nil,function() end,190)
            row.open:SetPoint("LEFT"); row.label = skin:Label(row.open, "")
            row.label:SetPoint("LEFT",6,0); row.label:SetWidth(178); row.label:SetJustifyH("LEFT")
            row.rename = skin:Button(row,"rename",L["Rename note"],function() end)
            row.rename:SetPoint("RIGHT",-29,0)
            row.delete = skin:Button(row,"close",L["Permanently delete note"],function() end)
            row.delete:SetPoint("RIGHT")
            self.rows[index] = row
        end
        row:SetPoint("TOPLEFT",0,-(index-1)*33)
        row.label:SetText((page.open and "* " or "  ")..page.name)
        row.open:SetScript("OnClick",function() self:Select(pageIndex) end)
        row.rename:SetScript("OnClick",function() self:Rename(pageIndex) end)
        row.delete:SetScript("OnClick",function()
            StaticPopup_Show("SIMPLENOTEPAD_DELETE",nil,nil,pageObject)
        end)
        row:Show()
    end
    self.listBody:SetHeight(math.max(1,#book.data.pages*33))
end

function view:Layout()
    local toolbarHeight = 5+40*self.headerProgress
    self.header:SetAlpha(self.headerProgress)
    show(self.header,self.headerProgress > 0.01)
    self.header:ClearAllPoints()
    self.header:SetPoint("TOPLEFT",0,45*(self.headerProgress-1))
    self.header:SetPoint("TOPRIGHT",0,45*(self.headerProgress-1))
    self.rail:ClearAllPoints()
    self.rail:SetPoint("TOPLEFT",0,-toolbarHeight); self.rail:SetPoint("TOPRIGHT",0,-toolbarHeight)
    show(self.reveal,self.options.autoHide)
    local width = self.root:GetWidth()
    show(self.undo,width >= 440); show(self.redo,width >= 480)
    self.tabScroll:SetWidth(math.max(1,width-40))
    if self.editor then self.editor:SetWidth(math.max(1,self.editorScroll:GetWidth())) end
    if self.tabCanvas then self:Tabs() end
end

function view:ApplyOpacity()
    self.root:SetAlpha(self.options.opacity*self.fade)
end

function view:SaveBounds()
    self.root:StopMovingOrSizing()
    if self.animation then return end
    local scale = self.root:GetEffectiveScale()/UIParent:GetEffectiveScale()
    local x,y = self.root:GetCenter()
    local cx,cy = UIParent:GetCenter()
    self.options.x,self.options.y = x*scale-cx,y*scale-cy
    self.options.width,self.options.height = self.root:GetSize()
end

function view:Animate(opening, minimized)
    self:CommitRename(); self:CloseSearch(); self.picker:Hide(); self.editor:ClearFocus()
    local homeX,homeY=self.options.x or 0,self.options.y or 0
    local homeScale=self.options.scale
    local miniScale=math.min(36/self.root:GetWidth(),36/self.root:GetHeight())
    local targetX,targetY,targetScale=homeX,homeY,homeScale
    if minimized then
        targetX=homeX-self.root:GetWidth()*homeScale/2+18
        targetY=homeY+self.root:GetHeight()*homeScale/2-18
        targetScale=miniScale
        self.badge:ClearAllPoints()
        self.badge:SetPoint("CENTER",UIParent,"CENTER",targetX,targetY)
    elseif not opening then targetScale=homeScale*0.88 end
    if opening then
        local wasMinimized=self.badge:IsShown()
        self.badge:Hide()
        if not self.root:IsShown() then
            self.fade=0; self:ApplyOpacity()
            if not wasMinimized then
                self.root:SetScale(homeScale*0.88)
                self.root:ClearAllPoints()
                self.root:SetPoint("CENTER",UIParent,"CENTER",homeX/(homeScale*0.88),homeY/(homeScale*0.88))
            end
        end
        self.root:Show()
    end
    local scale=self.root:GetEffectiveScale()/UIParent:GetEffectiveScale()
    local x,y=self.root:GetCenter()
    local cx,cy=UIParent:GetCenter()
    self.animation = {
        opening=opening,minimized=minimized,start=self.fade,elapsed=0,
        startScale=scale,endScale=targetScale,
        startX=x*scale-cx,startY=y*scale-cy,endX=targetX,endY=targetY,
    }
    self.root:SetClampedToScreen(false)
end

function view:Tick(elapsed)
    if self.noticeTime then
        self.noticeTime = self.noticeTime-elapsed
        if self.noticeTime <= 0 then self.notice:Hide(); self.noticeTime = nil end
    end
    local hovering = MouseIsOver(self.header) or MouseIsOver(self.reveal)
    local focused = self.search:HasFocus() or self.rename:HasFocus()
    if hovering or focused or self.picker:IsShown() or not self.options.autoHide then self.idle = 0
    else self.idle = (self.idle or 0)+elapsed end
    local target = self.options.autoHide and (self.idle or 0)>0.45 and 0 or 1
    if self.headerProgress ~= target then
        local amount = elapsed/0.2
        self.headerProgress = target == 1 and math.min(1,self.headerProgress+amount) or math.max(0,self.headerProgress-amount)
        self:Layout()
    end
    if not self.animation then return end
    local animation = self.animation
    animation.elapsed = animation.elapsed+elapsed
    local progress = math.min(1,animation.elapsed/0.22)
    local eased=progress*progress*(3-2*progress)
    local destination = animation.opening and 1 or 0
    self.fade = animation.start+(destination-animation.start)*eased
    self:ApplyOpacity()
    local scale=animation.startScale+(animation.endScale-animation.startScale)*eased
    local x=animation.startX+(animation.endX-animation.startX)*eased
    local y=animation.startY+(animation.endY-animation.startY)*eased
    self.root:SetScale(scale)
    self.root:ClearAllPoints(); self.root:SetPoint("CENTER",UIParent,"CENTER",x/scale,y/scale)
    if progress == 1 then
        self.animation = nil
        self.root:SetClampedToScreen(true)
        if not animation.opening then
            self.root:Hide()
            show(self.badge,animation.minimized)
        end
    end
end

function view:BuildHeader()
    local header = CreateFrame("Frame",nil,self.root)
    self.header = header; header:SetHeight(45)
    header:SetFrameLevel(self.root:GetFrameLevel()+10)
    skin:Fill(header,skin.colors.toolbar)
    header:EnableMouse(true); header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart",function() if not self.animation then self.root:StartMoving() end end)
    header:SetScript("OnDragStop",function() self:SaveBounds() end)
    local function left(icon,tip,offset,callback)
        local button=skin:Button(header,icon,tip,callback); button:SetPoint("LEFT",offset,0); return button
    end
    left("list",L["All notes"],8,function()
        self:CloseSearch(); show(self.picker,not self.picker:IsShown())
    end)
    left("previous",L["Previous note"],47,function() self:Select(math.max(1,book.data.selected-1)) end)
    left("next",L["Next note"],79,function() self:Select(math.min(#book.data.pages,book.data.selected+1)) end)
    self.searchButton = left("search",L["Search notes"],111,function() self:Search() end)
    self.undo = left("undo",L["Undo (Ctrl+Z)"],143,function() if self.mode == "note" then book:Restore(-1); self:Refresh() end end)
    self.redo = left("redo",L["Redo (Ctrl+Y)"],175,function() if self.mode == "note" then book:Restore(1); self:Refresh() end end)
    local function right(icon,tip,offset,callback)
        local button = skin:Button(header,icon,tip,callback); button:SetPoint("RIGHT",offset,0); return button
    end
    right("close",L["Close"],-8,function() self:Animate(false,false) end)
    right("minimize",L["Minimize"],-40,function() self:Animate(false,true) end)
    right("settings",L["Settings"],-72,function() self:Settings() end)
    self.autoButton = right("autoHide",L["Auto-hide toolbar"],-104,function()
        self.options.autoHide = not self.options.autoHide
        self.autoButton.active = self.options.autoHide; self.idle = 0; self:Layout()
    end)
    self.autoButton.active = self.options.autoHide
    app.platform:Color(self.autoButton.fill,self.options.autoHide and skin.colors.active or skin.colors.button)
    self.reveal = CreateFrame("Button",nil,self.root)
    self.reveal:SetPoint("TOPLEFT"); self.reveal:SetPoint("TOPRIGHT"); self.reveal:SetHeight(5)
    self.reveal:SetFrameLevel(header:GetFrameLevel()+3)
    skin:Fill(self.reveal,skin.colors.border)
    self.reveal:SetScript("OnEnter",function() self.idle = 0 end)
    self.reveal:SetScript("OnClick",function() self.options.autoHide=false; self.autoButton.active=false; self:Layout() end)
end

function view:BuildTabs()
    self.rail = CreateFrame("Frame",nil,self.root); self.rail:SetHeight(36)
    skin:Fill(self.rail,skin.colors.rail)
    local plus=skin:Button(self.rail,"plus",L["New note"],function() self:NewPage() end,38)
    plus:SetPoint("RIGHT"); plus:SetHeight(35)
    self.tabScroll=CreateFrame("ScrollFrame",nil,self.rail)
    self.tabScroll:SetPoint("TOPLEFT"); self.tabScroll:SetHeight(35)
    self.tabCanvas=CreateFrame("Frame",nil,self.tabScroll); self.tabCanvas:SetSize(1,35)
    self.tabScroll:SetScrollChild(self.tabCanvas); self.tabScroll:EnableMouseWheel(true)
    self.tabScroll:SetScript("OnMouseWheel",function(frame,delta)
        frame:SetHorizontalScroll(math.max(0,math.min(math.max(0,self.tabCanvas:GetWidth()-frame:GetWidth()),frame:GetHorizontalScroll()-delta*80)))
    end)
    self.settingsTab=skin:Button(self.tabCanvas,nil,nil,function() self:Settings() end,135)
    self.settingsTab:SetHeight(35)
    local label=skin:Label(self.settingsTab,L["Settings"]); label:SetPoint("LEFT",12,0)
    label:SetWidth(90); label:SetJustifyH("LEFT")
    local close=skin:Button(self.settingsTab,"close",L["Close settings"],function()
        self.settingsOpen=false; self.mode="note"; self:Refresh()
    end,22)
    close:SetPoint("RIGHT",-3,0); self.settingsTab:Hide()
end

function view:BuildEditor()
    self.editorScroll=CreateFrame("ScrollFrame",nil,self.root,"UIPanelScrollFrameTemplate")
    self.editorScroll:SetPoint("TOPLEFT",self.rail,"BOTTOMLEFT",12,-10)
    self.editorScroll:SetPoint("BOTTOMRIGHT",-28,12)
    local editor=CreateFrame("EditBox",nil,self.editorScroll)
    self.editor=editor; editor:SetMultiLine(true); editor:SetAutoFocus(false)
    editor:SetFontObject("ChatFontNormal"); editor:SetTextColor(unpack(skin.colors.text))
    editor:SetTextInsets(4,4,4,4); app.platform:Hyperlinks(editor); editor:SetHeight(1)
    self.editorScroll:SetScrollChild(editor)
    self.editorScroll:SetScript("OnSizeChanged",function(_,width) editor:SetWidth(math.max(1,width)) end)
    editor:SetScript("OnTextChanged",function(frame) if not self.writing then book:Record(frame:GetText()) end end)
    editor:SetScript("OnMouseDown",function() self:CloseSearch(); self.picker:Hide(); self:CommitRename() end)
    editor:SetScript("OnEscapePressed",function(frame) frame:ClearFocus() end)
    editor:SetScript("OnTabPressed",function(frame) frame:Insert("    ") end)
    editor:SetScript("OnKeyDown",function(_,key)
        if not IsControlKeyDown() then return end
        if key=="Z" then book:Restore(-1); self:Refresh()
        elseif key=="Y" then book:Restore(1); self:Refresh()
        elseif key=="F" then self:Search()
        elseif key=="N" then self:NewPage() end
    end)
    editor:SetScript("OnCursorChanged",function(_,_,y,_,height)
        local top,position=-y,self.editorScroll:GetVerticalScroll()
        if top<position then self.editorScroll:SetVerticalScroll(math.max(0,top))
        elseif top+height>position+self.editorScroll:GetHeight() then
            self.editorScroll:SetVerticalScroll(math.max(0,top+height-self.editorScroll:GetHeight()))
        end
    end)
end

function view:BuildPopovers()
    self.picker=CreateFrame("Frame",nil,self.root)
    self.picker:SetPoint("TOPLEFT",self.header,"BOTTOMLEFT",8,0); self.picker:SetSize(290,240)
    self.picker:SetFrameLevel(self.header:GetFrameLevel()+20); self.picker:EnableMouse(true)
    skin:Fill(self.picker,skin.colors.rail); self.picker:Hide()
    local scroll=CreateFrame("ScrollFrame",nil,self.picker,"UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",5,-5); scroll:SetPoint("BOTTOMRIGHT",-28,5)
    self.listBody=CreateFrame("Frame",nil,scroll); self.listBody:SetSize(252,1); scroll:SetScrollChild(self.listBody)
    self.searchPanel=CreateFrame("Frame",nil,self.header)
    self.searchPanel:SetPoint("TOPLEFT",self.searchButton,"BOTTOMLEFT",0,-8)
    self.searchPanel:SetSize(235,40); self.searchPanel:SetFrameLevel(self.header:GetFrameLevel()+30)
    self.searchPanel:EnableMouse(true); skin:Fill(self.searchPanel,skin.colors.tab)
    self.search=CreateFrame("EditBox",nil,self.searchPanel)
    self.search:SetPoint("TOPLEFT",8,-7); self.search:SetPoint("BOTTOMRIGHT",-8,7)
    self.search:SetAutoFocus(false); self.search:SetFontObject("ChatFontNormal")
    self.search:SetTextColor(unpack(skin.colors.text)); self.search:SetTextInsets(5,5,0,0)
    skin:Fill(self.search,skin.colors.hover)
    self.search:SetScript("OnEnterPressed",function() self:Find() end)
    self.search:SetScript("OnEscapePressed",function() self:CloseSearch() end)
    self.searchPanel:Hide()
    self.renamePanel=CreateFrame("Frame",nil,self.root)
    self.renamePanel:SetPoint("CENTER"); self.renamePanel:SetSize(280,90)
    self.renamePanel:SetFrameLevel(self.header:GetFrameLevel()+40); self.renamePanel:EnableMouse(true)
    skin:Fill(self.renamePanel,skin.colors.toolbar)
    local label=skin:Label(self.renamePanel,L["Rename note (Enter to save)"]); label:SetPoint("TOPLEFT",12,-12)
    label:SetWidth(256); label:SetHeight(28); label:SetJustifyH("LEFT")
    self.rename=CreateFrame("EditBox",nil,self.renamePanel)
    self.rename:SetPoint("TOPLEFT",12,-46); self.rename:SetPoint("BOTTOMRIGHT",-12,15)
    self.rename:SetAutoFocus(false); self.rename:SetFontObject("ChatFontNormal")
    self.rename:SetTextColor(unpack(skin.colors.text)); self.rename:SetTextInsets(5,5,0,0)
    skin:Fill(self.rename,skin.colors.button)
    self.rename:SetScript("OnEnterPressed",function() self:CommitRename(); self:Refresh() end)
    self.rename:SetScript("OnEscapePressed",function() self:CommitRename(true); self:Refresh() end)
    self.rename:SetScript("OnEditFocusLost",function() self:CommitRename(); self:Refresh() end)
    self.renamePanel:Hide()
    self.notice=skin:Label(self.root,""); self.notice:SetPoint("TOPRIGHT",self.rail,"BOTTOMRIGHT",-15,-12); self.notice:Hide()
end

function view:BuildSettings()
    self.preferences=CreateFrame("Frame",nil,self.root)
    self.preferences:SetPoint("TOPLEFT",self.rail,"BOTTOMLEFT",0,0); self.preferences:SetPoint("BOTTOMRIGHT")
    local card=CreateFrame("Frame",nil,self.preferences); card:SetSize(260,175); card:SetPoint("CENTER")
    local title=skin:Label(card,L["Settings"]); title:SetPoint("TOPLEFT",0,0)
    local function slider(caption,value,low,high,offset,callback)
        local label=skin:Label(card,caption); label:SetPoint("TOPLEFT",0,offset)
        local amount=skin:Label(card,""); amount:SetPoint("TOPRIGHT",0,offset)
        local range=CreateFrame("Slider",nil,card)
        range:SetOrientation("HORIZONTAL"); range:SetPoint("TOPLEFT",0,offset-22); range:SetSize(260,12)
        skin:Fill(range,skin.colors.hover)
        range:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
        range:GetThumbTexture():SetSize(8,16); range:GetThumbTexture():SetVertexColor(unpack(skin.colors.blue))
        range:SetMinMaxValues(low,high); range:SetValueStep(0.01); app.platform:Slider(range)
        range:SetValue(value); amount:SetText(math.floor(value*100+0.5).."%")
        range:SetScript("OnValueChanged",function(_,number)
            amount:SetText(math.floor(number*100+0.5).."%"); callback(number)
        end)
        return range
    end
    self.opacitySlider=slider(L["Window opacity"],self.options.opacity,0.1,1,-35,function(value)
        self.options.opacity=value; self:ApplyOpacity()
    end)
    self.scaleSlider=slider(L["Window scale"],self.options.scale,0.65,1.5,-90,function(value)
        local cx,cy=UIParent:GetCenter()
        local oldScale=self.root:GetEffectiveScale()/UIParent:GetEffectiveScale()
        local x,y=self.root:GetCenter(); self.options.x,self.options.y=x*oldScale-cx,y*oldScale-cy
        self.options.scale=value; self.root:SetScale(value)
        self.root:ClearAllPoints(); self.root:SetPoint("CENTER",UIParent,"CENTER",self.options.x/value,self.options.y/value)
    end)
    local minimap=skin:Button(card,nil,nil,function(button)
        self.options.minimap=not self.options.minimap
        if app.launcher then show(app.launcher,self.options.minimap) end
        button.label:SetText(self.options.minimap and L["Minimap icon: on"] or L["Minimap icon: off"])
    end,260)
    minimap:SetPoint("TOPLEFT",0,-140); minimap.label=skin:Label(minimap,self.options.minimap and L["Minimap icon: on"] or L["Minimap icon: off"])
    minimap.label:SetPoint("CENTER"); self.preferences:Hide()
end

function app:BuildWindow()
    view.options=book.data.options
    view.root=CreateFrame("Frame",nil,UIParent)
    view.root:SetSize(view.options.width or 680,view.options.height or 450)
    view.root:SetScale(view.options.scale)
    view.root:SetPoint("CENTER",UIParent,"CENTER",(view.options.x or 0)/view.options.scale,(view.options.y or 0)/view.options.scale)
    view.root:SetFrameStrata("DIALOG"); view.root:SetClampedToScreen(true)
    view.root:SetMovable(true); view.root:SetResizable(true); view.root:EnableMouse(true)
    app.platform:Clip(view.root)
    app.platform:ResizeBounds(view.root,360,300)
    skin:Fill(view.root,skin.colors.editor)
    view:BuildHeader(); view:BuildTabs(); view:BuildEditor(); view:BuildPopovers(); view:BuildSettings()
    view.badge=skin:Button(UIParent,nil,L["Restore SimpleNotepad"],function() view:Animate(true) end,36)
    view.badge.label=skin:Label(view.badge,"N"); view.badge.label:SetPoint("CENTER")
    view.badge:SetPoint("CENTER"); view.badge:SetFrameStrata("DIALOG"); view.badge:Hide()
    local grip=skin:Button(view.root,"resize",L["Resize"],function() end,16)
    grip:SetHeight(16); grip:SetPoint("BOTTOMRIGHT",-2,2)
    grip:SetScript("OnMouseDown",function() if not view.animation then view.root:StartSizing("BOTTOMRIGHT") end end)
    grip:SetScript("OnMouseUp",function() view:SaveBounds() end)
    view.root:SetScript("OnSizeChanged",function() view:Layout() end)
    view.root:SetScript("OnMouseDown",function() view:CloseSearch(); view.picker:Hide(); view:CommitRename(); view:Refresh() end)
    view.root:SetScript("OnUpdate",function(_,elapsed) view:Tick(elapsed) end)
    StaticPopupDialogs.SIMPLENOTEPAD_DELETE={
        text=L["Permanently delete this note?"],button1=YES,button2=NO,
        OnAccept=function(_,page)
            view:CommitRename()
            for index,candidate in ipairs(book.data.pages) do if candidate==page then book:Remove(index); break end end
            view:Refresh()
        end,
        timeout=0,whileDead=true,hideOnEscape=true,
    }
    view:Layout(); view:Refresh(); view:ApplyOpacity(); view.root:Hide()
end

function app:Toggle()
    local opening = not view.root:IsShown() or (view.animation and not view.animation.opening)
    view:Animate(opening,false)
end

function app:Search() view:Search() end
