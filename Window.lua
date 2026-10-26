local _, app = ...
local L = app.L
local book, skin = app.journal, app.skin
local view = {mode = "note", tabButtons = {}, rows = {}, headerProgress = 1, fade = 1}
local HEADER_HEIGHT, TAB_HEIGHT, MIN_HEIGHT = 28, 22, 96

local function strip(text) return text:match("^%s*(.-)%s*$") end
local function show(frame, visible) frame:SetShown(visible) end

-- Note actions and tab navigation.
function view:CloseSearch()
    self.search:ClearFocus(); self.searchPanel:Hide()
    self.searchState=nil
end

function view:Select(index)
    if self:CommitRename() == false then return end
    book:Select(index); self.mode = "note"; self.picker:Hide()
    self:Refresh()
end

function view:Refresh()
    -- Keep settings usable after reducing the notebook to a single text line.
    if self.mode == "settings" and self.root:GetHeight() < 300 then
        self.noteHeight = self.root:GetHeight(); self.root:SetHeight(300)
    elseif self.mode ~= "settings" and self.noteHeight then
        local height = self.noteHeight; self.noteHeight = nil; self.root:SetHeight(height)
    end
    self.writing = true
    self.editor:SetText(book:Current().body)
    self.writing = false
    show(self.editorScroll, self.mode == "note")
    show(self.preferences, self.mode == "settings")
    self:Tabs(); self:List()
end

function view:CommitRename(cancel)
    if self.creatingNew then
        local name = strip(self.rename:GetText())
        if not cancel and name == "" then self.rename:SetFocus(); return false end
        self.creatingNew = nil
        self.rename:ClearFocus(); self.renamePanel:Hide()
        if not cancel then
            book:Add(name); self.mode = "note"; self:Refresh(); self.editor:SetFocus()
        end
        return true
    end
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
    if self:CommitRename() == false then return end
    self.renaming = book.data.pages[index]
    self.renameTitle:SetText(L["Rename note (Enter to save)"])
    self.rename:SetText(self.renaming.name)
    self.renamePanel:Show(); self.rename:SetFocus(); self.rename:HighlightText()
end

function view:NewPage()
    self:CommitRename(true); self:CloseSearch(); self.picker:Hide(); self.editor:ClearFocus()
    self.creatingNew = true
    self.renameTitle:SetText(L["Name for the new note"])
    self.rename:SetText(""); self.renamePanel:Show(); self.rename:SetFocus()
end

function view:Settings()
    if self:CommitRename() == false then return end
    self:CloseSearch(); self.picker:Hide()
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
    if query == "" then self.searchState=nil; return end
    if self:CommitRename()==false then return end
    local folded=app.Fold(query)
    local page=book:Current()
    local previous=self.searchState
    local continuing=previous and previous.query==folded and previous.page==page and previous.body==page.body
    local destination,first,last
    if not continuing or previous.last then
        first,last=app.Find(page.body,query,continuing and previous.last+1 or 1)
        if first or (not continuing and app.Fold(page.name):find(folded,1,true)) then destination=book.data.selected end
    end
    -- Continue within this note, then scan the others and wrap to the first hit.
    if not destination then
        for step=1,#book.data.pages do
            local index=(book.data.selected-1+step)%#book.data.pages+1
            local candidate=book.data.pages[index]
            first,last=app.Find(candidate.body,query)
            if first or app.Fold(candidate.name):find(folded,1,true) then destination=index; break end
        end
    end
    if not destination then
        self.searchState=nil
        self.notice:SetText(L["No matching notes"]); self.notice:Show(); self.noticeTime = 2.2
        self.search:SetFocus()
        return
    end
    self.notice:Hide(); self.noticeTime=nil
    self:Select(destination)
    page=book:Current()
    self.searchState={query=folded,page=page,body=page.body,last=last}
    if first then self.editor:SetCursorPosition(last); self.editor:HighlightText(first-1, last) end
    self.search:SetFocus()
end

-- Measure labels instead of fixing tab widths; long tabs remain scrollable.
function view:Tabs()
    -- Keep visible buttons alive: Hide would cancel an in-progress mouse click.
    local count, offset, selectedOffset, selectedWidth, slot = 0, 0, 0, 0, 0
    count=#book.data.tabOrder
    for _,index in ipairs(book.data.tabOrder) do
        local page=book.data.pages[index]
        do
            slot = slot+1
            local pageIndex = index
            local button = self.tabButtons[slot]
            if not button then
                button = skin:Button(self.tabCanvas, nil, nil, function() end)
                button:SetHeight(TAB_HEIGHT-1)
                button.label = skin:Label(button, "")
                button.label:SetPoint("LEFT", 8, 0); button.label:SetJustifyH("LEFT")
                button.sharedIcon = skin:Icon(button,"globe")
                button.sharedIcon:SetSize(10,10)
                button.sharedIcon:ClearAllPoints(); button.sharedIcon:SetPoint("LEFT",8,0)
                button.close = skin:Button(button,"close",L["Close tab temporarily"],function() end,12)
                button.close:SetPoint("RIGHT", -6,0)
                button.close:SetHeight(12)
                button.close.icon:SetSize(10,10)
                button.accent = button:CreateTexture(nil,"OVERLAY")
                app.platform:Color(button.accent,skin.colors.blue); button.accent:SetHeight(2)
                button.accent:SetPoint("TOPLEFT"); button.accent:SetPoint("TOPRIGHT")
                button.sortOutline=skin:Outline(button)
                for edge,texture in ipairs(button.sortOutline) do
                    if edge<=2 then texture:SetHeight(2) else texture:SetWidth(2) end
                    texture:Hide()
                end
                button:SetScript("OnEnter",function(frame)
                    if self.tabPress and self.tabPress.active then return end
                    GameTooltip:SetOwner(frame,"ANCHOR_TOP")
                    GameTooltip:SetText(L["Hold, then drag to reorder"]); GameTooltip:Show()
                end)
                button:SetScript("OnLeave",function() GameTooltip:Hide() end)
                button:SetScript("OnMouseDown",function(frame,mouseButton)
                    frame.suppressClick=nil
                    if mouseButton~="LeftButton" or self.animation or self.creatingNew then return end
                    local x,y=GetCursorPosition()
                    self.tabPress={index=frame.pageIndex,button=frame,x=x,y=y,elapsed=0}
                end)
                button:SetScript("OnMouseUp",function() self:EndTabDrag() end)
                self.tabButtons[slot] = button
            end
            local active = self.mode == "note" and index == book.data.selected
            button.pageIndex=index
            local sorting=self.tabPress and self.tabPress.active and self.tabPress.index==index
            button:SetAlpha(1)
            for _,edge in ipairs(button.sortOutline) do app.platform:Color(edge,skin.colors.blue); show(edge,sorting) end
            button:ClearAllPoints(); button:SetPoint("LEFT", self.tabCanvas,"LEFT",offset,0)
            skin:Paint(button.fill,active and skin.colors.selected or skin.colors.tab)
            app.platform:Color(button.accent,skin.colors.blue)
            local shared=book:IsShared(index)
            show(button.sharedIcon,shared)
            button.sharedIcon:SetVertexColor(unpack(skin.colors.blue))
            button.label:ClearAllPoints(); button.label:SetPoint("LEFT",shared and 22 or 8,0)
            button.label:SetText(page.name)
            button.label:SetWidth(0)
            local nameWidth=math.ceil(button.label:GetStringWidth())
            local tabWidth=nameWidth+16+(count > 1 and 18 or 0)+(shared and 14 or 0)
            button.label:SetWidth(nameWidth)
            button:SetWidth(tabWidth)
            button.label:SetTextColor(unpack(active and skin.colors.text or skin.colors.muted))
            show(button.accent, active); show(button.close, count > 1)
            button:SetScript("OnClick", function(frame)
                if frame.suppressClick then frame.suppressClick=nil; return end
                self:Select(pageIndex)
            end)
            button.close:SetScript("OnClick", function() self:CommitRename(); book:Close(pageIndex); self:Refresh() end)
            button:Show()
            if active then selectedOffset,selectedWidth = offset,tabWidth end
            offset = offset+tabWidth+1
        end
    end
    for unused=slot+1,#self.tabButtons do self.tabButtons[unused]:Hide() end
    show(self.settingsTab, self.settingsOpen)
    if self.settingsOpen then
        self.settingsTab:ClearAllPoints(); self.settingsTab:SetPoint("LEFT", self.tabCanvas,"LEFT",offset,0)
        skin:Paint(self.settingsTab.fill,self.mode == "settings" and skin.colors.selected or skin.colors.tab)
        self.settingsTab.label:SetWidth(0)
        local nameWidth=math.ceil(self.settingsTab.label:GetStringWidth())
        local tabWidth=nameWidth+34
        self.settingsTab.label:SetWidth(nameWidth); self.settingsTab:SetWidth(tabWidth)
        if self.mode == "settings" then selectedOffset,selectedWidth = offset,tabWidth end
        offset = offset+tabWidth+1
    end
    self.tabCanvas:SetWidth(math.max(1,offset))
    local width = self.tabScroll:GetWidth()
    local current = self.tabScroll:GetHorizontalScroll()
    if self.tabPress and self.tabPress.active then
        -- Do not snap back to the selected note while sorting another tab.
    elseif selectedWidth > width or selectedOffset < current then current = selectedOffset
    elseif selectedOffset+selectedWidth > current+width then current = selectedOffset+selectedWidth-width end
    self.tabScroll:SetHorizontalScroll(math.max(0, math.min(current, math.max(0,offset-width))))
end

-- A short hold arms sorting; movement before the hold remains an ordinary click.
function view:EndTabDrag()
    local press=self.tabPress
    if not press then return end
    if press.active then press.button.suppressClick=true end
    self.tabPress=nil
    if press.active then
        self.notice:Hide()
        for _,button in ipairs(self.tabButtons) do
            for _,edge in ipairs(button.sortOutline) do edge:Hide() end
        end
    end
end

function view:UpdateTabDrag(elapsed)
    local press=self.tabPress
    if not press then return end
    if not IsMouseButtonDown("LeftButton") or self.animation then self:EndTabDrag(); return end
    local x,y=GetCursorPosition()
    local scale=self.tabScroll:GetEffectiveScale()
    if not press.active then
        if math.abs(x-press.x)/scale>5 or math.abs(y-press.y)/scale>5 then self.tabPress=nil; return end
        press.elapsed=press.elapsed+elapsed
        if press.elapsed<0.5 then return end
        press.active=true; GameTooltip:Hide(); self:Tabs()
        self.noticeTime=nil; self.notice:SetText(L["Drag left or right to reorder"]); self.notice:Show()
    end
    x,y=x/scale,y/scale
    local bottom,top=self.tabScroll:GetBottom(),self.tabScroll:GetTop()
    if y<bottom-12 or y>top+12 then return end
    local left,right=self.tabScroll:GetLeft(),self.tabScroll:GetRight()
    local scroll=self.tabScroll:GetHorizontalScroll()
    local edge=x<left+16 and -1 or x>right-16 and 1 or 0
    if edge~=0 then
        self.tabScroll:SetHorizontalScroll(math.max(0,math.min(math.max(0,self.tabCanvas:GetWidth()-self.tabScroll:GetWidth()),scroll+edge*120*elapsed)))
    end
    local position=book:TabPosition(press.index)
    if not position then self:EndTabDrag(); return end
    local target=position
    for slot=1,#book.data.tabOrder do
        local button=self.tabButtons[slot]
        local center=button:GetLeft()+button:GetWidth()/2
        if slot<position and x<center then target=math.min(target,slot)
        elseif slot>position and x>center then target=math.max(target,slot) end
    end
    if book:MoveTab(press.index,target) then self:Tabs() end
end

function view:List()
    for _, row in ipairs(self.rows) do row:Hide() end
    for index, page in ipairs(book.data.pages) do
        local pageIndex, pageObject = index, page
        local row = self.rows[index]
        if not row then
            row = CreateFrame("Frame",nil,self.listBody); row:SetSize(252,32)
            row.open = skin:Button(row,nil,nil,function() end,160)
            row.open:SetPoint("LEFT"); row.label = skin:Label(row.open, "")
            row.label:SetPoint("LEFT",6,0); row.label:SetWidth(148); row.label:SetJustifyH("LEFT"); row.label:SetWordWrap(false)
            row.share = skin:Button(row,"globe",nil,function() end)
            row.share:SetPoint("RIGHT",-58,0)
            row.share:SetScript("OnEnter",function(button)
                button.hovered=true; skin:ButtonState(button)
                GameTooltip:SetOwner(button,"ANCHOR_RIGHT")
                GameTooltip:SetText(row.shared and L["Shared with all characters. Click to make character-only."] or L["Character-only note. Click to share with all characters."])
                GameTooltip:Show()
            end)
            row.rename = skin:Button(row,"rename",L["Rename note"],function() end)
            row.rename:SetPoint("RIGHT",-29,0)
            row.delete = skin:Button(row,"close",L["Permanently delete note"],function() end)
            row.delete:SetPoint("RIGHT")
            self.rows[index] = row
        end
        row:SetPoint("TOPLEFT",0,-(index-1)*33)
        row.label:SetText((page.open and "* " or "  ")..page.name)
        row.shared=book:IsShared(index); row.share.active=row.shared; skin:ButtonState(row.share)
        row.share.icon:SetAlpha(row.shared and 1 or 0.45)
        row.share:SetScript("OnClick",function()
            if self:CommitRename()==false then return end
            book:SetShared(pageIndex,not book:IsShared(pageIndex))
            self.searchState=nil; GameTooltip:Hide(); self:Refresh()
        end)
        row.open:SetScript("OnClick",function() self:Select(pageIndex) end)
        row.rename:SetScript("OnClick",function() self:Rename(pageIndex) end)
        row.delete:SetScript("OnClick",function()
            StaticPopupDialogs.SIMPLENOTEPAD_DELETE.text=book:IsShared(pageIndex) and L["Permanently delete this shared note for all characters?"] or L["Permanently delete this note?"]
            StaticPopup_Show("SIMPLENOTEPAD_DELETE",nil,nil,pageObject)
        end)
        row:Show()
    end
    self.listBody:SetHeight(math.max(1,#book.data.pages*33))
end

-- Layout, saved bounds and open/minimize animation.
function view:Layout()
    local inset=self.options.style == "wow" and 10 or 0
    self.contentInset=inset
    self.content:ClearAllPoints()
    self.content:SetPoint("TOPLEFT",self.root,"TOPLEFT",inset,-inset)
    self.content:SetPoint("BOTTOMRIGHT",self.root,"BOTTOMRIGHT",-inset,inset)
    app.platform:ResizeBounds(self.root,360,MIN_HEIGHT+2*inset)
    if self.root:GetHeight() < MIN_HEIGHT+2*inset then self.root:SetHeight(MIN_HEIGHT+2*inset) end
    local toolbarHeight = 5+(HEADER_HEIGHT-5)*self.headerProgress
    self.header:SetAlpha(self.headerProgress)
    show(self.header,self.headerProgress > 0.01)
    self.header:ClearAllPoints()
    self.header:SetPoint("TOPLEFT",0,HEADER_HEIGHT*(self.headerProgress-1))
    self.header:SetPoint("TOPRIGHT",0,HEADER_HEIGHT*(self.headerProgress-1))
    self.rail:ClearAllPoints()
    self.rail:SetPoint("TOPLEFT",0,-toolbarHeight); self.rail:SetPoint("TOPRIGHT",0,-toolbarHeight)
    self.rail:SetHeight(math.max(0.01,TAB_HEIGHT*self.headerProgress))
    self.rail:SetAlpha(self.headerProgress)
    show(self.rail,self.headerProgress > 0.01)
    show(self.reveal,self.options.autoHide)
    local width = self.root:GetWidth()-2*inset
    show(self.undo,width >= 300); show(self.redo,width >= 326)
    self.tabScroll:SetWidth(math.max(1,width-28))
    if self.editor then self.editor:SetWidth(math.max(1,self.editorScroll:GetWidth())) end
    if self.tabCanvas then self:Tabs() end
    skin:ResizeTextures()
    skin:ButtonState(self.autoButton)
end

function view:ApplyOpacity()
    self.root:SetAlpha(self.options.opacity*self.fade)
end

function view:ApplyLock()
    local unlocked = not self.options.locked
    self.root:StopMovingOrSizing()
    self.root:SetMovable(unlocked); self.root:SetResizable(unlocked)
    if self.badge then self.badge:StopMovingOrSizing(); self.badge:SetMovable(unlocked) end
    if self.grip then show(self.grip,unlocked) end
    if self.lockButton then self.lockButton.label:SetText(unlocked and L["Lock window"] or L["Unlock window"]) end
end

function view:ApplyBadgeStyle()
    self.badge.icon:SetTexture(app.iconTexture)
    show(self.badge.icon,self.options.minimizedIcon)
    show(self.badge.label,not self.options.minimizedIcon)
    self.badgeStyleButton.label:SetText(self.options.minimizedIcon and L["Minimized button: icon"] or L["Minimized button: SNP"])
end

function view:SaveBounds()
    self.root:StopMovingOrSizing()
    if self.animation then return end
    -- Save offsets in UIParent coordinates so scaling preserves the position.
    local scale = self.root:GetEffectiveScale()/UIParent:GetEffectiveScale()
    local x,y = self.root:GetCenter()
    local cx,cy = UIParent:GetCenter()
    self.options.x,self.options.y = x*scale-cx,y*scale-cy
    self.options.width=self.root:GetWidth()
    self.options.height=self.noteHeight or self.root:GetHeight()
end

function view:Animate(opening, minimized)
    if self:CommitRename() == false then return end
    self:CloseSearch(); self.picker:Hide(); self.editor:ClearFocus()
    local homeX,homeY=self.options.x or 0,self.options.y or 0
    local homeScale=self.options.scale
    local miniScale=math.min(36/self.root:GetWidth(),36/self.root:GetHeight())
    local targetX,targetY,targetScale=homeX,homeY,homeScale
    if minimized then
        targetX=self.options.badgeX or homeX-self.root:GetWidth()*homeScale/2+18
        targetY=self.options.badgeY or homeY+self.root:GetHeight()*homeScale/2-18
        targetScale=miniScale
        self.badge:ClearAllPoints()
        self.badge:SetPoint("CENTER",UIParent,"CENTER",targetX,targetY)
    elseif not opening then targetScale=homeScale*0.88 end
    if opening then
        local wasMinimized=self.badge:IsShown()
        self.badge:Hide()
        if not self.root:IsShown() then
            self.fade=0; self:ApplyOpacity()
            if wasMinimized then
                local x,y=self.badge:GetCenter(); local cx,cy=UIParent:GetCenter()
                local badgeScale=self.badge:GetEffectiveScale()/UIParent:GetEffectiveScale()
                self.root:SetScale(miniScale); self.root:ClearAllPoints()
                self.root:SetPoint("CENTER",UIParent,"CENTER",(x*badgeScale-cx)/miniScale,(y*badgeScale-cy)/miniScale)
            else
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
    self:UpdateTabDrag(elapsed)
    if self.noticeTime then
        self.noticeTime = self.noticeTime-elapsed
        if self.noticeTime <= 0 then self.notice:Hide(); self.noticeTime = nil end
    end
    local hovering = (self.header:IsShown() and self.header:IsMouseOver())
        or (self.rail:IsShown() and self.rail:IsMouseOver()) or self.reveal:IsMouseOver()
    local focused = self.search:HasFocus() or self.rename:HasFocus()
    if hovering or focused or self.tabPress or self.picker:IsShown() or not self.options.autoHide then self.idle = 0
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

-- Toolbar, editor, dialogs and settings.
function view:BuildHeader()
    local header = CreateFrame("Frame",nil,self.content)
    self.header = header; header:SetHeight(HEADER_HEIGHT)
    header:SetFrameLevel(self.root:GetFrameLevel()+10)
    skin:Fill(header,skin.colors.toolbar)
    header:EnableMouse(true); header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart",function()
        if not self.animation and not self.options.locked then self.root:StartMoving() end
    end)
    header:SetScript("OnDragStop",function() self:SaveBounds() end)
    local function left(icon,tip,offset,callback)
        local button=skin:Button(header,icon,tip,callback); button:SetPoint("LEFT",offset,0); return button
    end
    left("list",L["All notes"],6,function()
        self:CloseSearch(); show(self.picker,not self.picker:IsShown())
    end)
    left("previous",L["Previous note"],32,function() self:Select(book:Neighbor(-1)) end)
    left("next",L["Next note"],58,function() self:Select(book:Neighbor(1)) end)
    self.searchButton = left("search",L["Search notes"],84,function() self:Search() end)
    self.undo = left("undo",L["Undo (Ctrl+Z)"],110,function() if self.mode == "note" then book:Restore(-1); self:Refresh() end end)
    self.redo = left("redo",L["Redo (Ctrl+Y)"],136,function() if self.mode == "note" then book:Restore(1); self:Refresh() end end)
    local function right(icon,tip,offset,callback)
        local button = skin:Button(header,icon,tip,callback); button:SetPoint("RIGHT",offset,0); return button
    end
    right("close",L["Close"],-6,function() self:Animate(false,false) end)
    right("minimize",L["Minimize"],-32,function() self:Animate(false,true) end)
    right("settings",L["Settings"],-58,function() self:Settings() end)
    self.autoButton = right("autoHide",L["Auto-hide toolbar"],-84,function()
        self.options.autoHide = not self.options.autoHide
        self.autoButton.active = self.options.autoHide; self.idle = 0; self:Layout()
    end)
    self.autoButton.active = self.options.autoHide
    skin:Paint(self.autoButton.fill,self.options.autoHide and skin.colors.active or skin.colors.button)
    self.reveal = CreateFrame("Button",nil,self.content)
    self.reveal:SetPoint("TOPLEFT"); self.reveal:SetPoint("TOPRIGHT"); self.reveal:SetHeight(5)
    self.reveal:SetFrameLevel(header:GetFrameLevel()+3)
    skin:Fill(self.reveal,skin.colors.border)
    self.reveal:SetScript("OnEnter",function() self.idle = 0 end)
    self.reveal:SetScript("OnClick",function() self.options.autoHide=false; self.autoButton.active=false; self:Layout() end)
end

function view:BuildTabs()
    self.rail = CreateFrame("Frame",nil,self.content); self.rail:SetHeight(TAB_HEIGHT)
    skin:Fill(self.rail,skin.colors.rail)
    local plus=skin:Button(self.rail,"plus",L["New note"],function() self:NewPage() end)
    plus:SetPoint("RIGHT",-4,0)
    self.tabScroll=CreateFrame("ScrollFrame",nil,self.rail)
    self.tabScroll:SetPoint("TOPLEFT"); self.tabScroll:SetHeight(TAB_HEIGHT-1)
    self.tabCanvas=CreateFrame("Frame",nil,self.tabScroll); self.tabCanvas:SetSize(1,TAB_HEIGHT-1)
    self.tabScroll:SetScrollChild(self.tabCanvas); self.tabScroll:EnableMouseWheel(true)
    self.tabScroll:SetScript("OnMouseWheel",function(frame,delta)
        frame:SetHorizontalScroll(math.max(0,math.min(math.max(0,self.tabCanvas:GetWidth()-frame:GetWidth()),frame:GetHorizontalScroll()-delta*80)))
    end)
    self.settingsTab=skin:Button(self.tabCanvas,nil,nil,function() self:Settings() end)
    self.settingsTab:SetHeight(TAB_HEIGHT-1)
    local label=skin:Label(self.settingsTab,L["Settings"]); label:SetPoint("LEFT",8,0)
    self.settingsTab.label=label; label:SetJustifyH("LEFT")
    local close=skin:Button(self.settingsTab,"close",L["Close settings"],function()
        self.settingsOpen=false; self.mode="note"; self:Refresh()
    end,12)
    close:SetPoint("RIGHT",-6,0); close:SetHeight(12); self.settingsTab:Hide()
    close.icon:SetSize(10,10)
    self.settingsTab.close=close
end

function view:BuildEditor()
    self.editorScroll=skin:ScrollFrame(self.content)
    self.editorScroll:SetPoint("TOPLEFT",self.rail,"BOTTOMLEFT",8,-4)
    self.editorScroll:SetPoint("BOTTOMRIGHT",-24,20)
    local editor=CreateFrame("EditBox",nil,self.editorScroll)
    self.editor=editor; editor:SetMultiLine(true); editor:SetAutoFocus(false)
    editor:SetFontObject("ChatFontNormal"); editor:SetTextColor(unpack(skin.colors.text))
    editor:SetTextInsets(4,4,4,4); app.platform:Hyperlinks(editor); editor:SetHeight(1)
    self.editorScroll:SetScrollChild(editor)
    self.editorScroll:EnableMouse(true)
    self.editorScroll:SetScript("OnMouseDown",function(_,button)
        if button ~= "LeftButton" then return end
        self:CloseSearch(); self.picker:Hide(); self:CommitRename()
        editor:SetFocus(); editor:SetCursorPosition(#editor:GetText())
    end)
    self.editorScroll:HookScript("OnSizeChanged",function(_,width) editor:SetWidth(math.max(1,width)) end)
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
    self.picker=CreateFrame("Frame",nil,self.content)
    self.picker:SetPoint("TOPLEFT",self.header,"BOTTOMLEFT",8,0); self.picker:SetSize(290,240)
    self.picker:SetFrameLevel(self.header:GetFrameLevel()+20); self.picker:EnableMouse(true)
    skin:Fill(self.picker,skin.colors.rail); self.picker:Hide()
    local scroll=skin:ScrollFrame(self.picker)
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
    self.searchBorder=skin:Outline(self.search)
    self.search:SetScript("OnEnterPressed",function() self:Find() end)
    self.search:SetScript("OnEscapePressed",function() self:CloseSearch() end)
    self.searchPanel:Hide()
    self.renamePanel=CreateFrame("Frame",nil,self.content)
    self.renamePanel:SetPoint("CENTER"); self.renamePanel:SetSize(280,125)
    self.renamePanel:SetFrameLevel(self.header:GetFrameLevel()+40); self.renamePanel:EnableMouse(true)
    skin:Fill(self.renamePanel,skin.colors.toolbar)
    local label=skin:Label(self.renamePanel,L["Rename note (Enter to save)"]); label:SetPoint("TOPLEFT",12,-12)
    self.renameTitle=label
    label:SetWidth(256); label:SetHeight(28); label:SetJustifyH("LEFT")
    self.rename=CreateFrame("EditBox",nil,self.renamePanel)
    self.rename:SetPoint("TOPLEFT",12,-46); self.rename:SetPoint("TOPRIGHT",-12,-46); self.rename:SetHeight(26)
    self.rename:SetAutoFocus(false); self.rename:SetFontObject("ChatFontNormal")
    self.rename:SetTextColor(unpack(skin.colors.text)); self.rename:SetTextInsets(5,5,0,0)
    skin:Fill(self.rename,skin.colors.button)
    self.rename:SetScript("OnEnterPressed",function() self:CommitRename(); self:Refresh() end)
    self.rename:SetScript("OnEscapePressed",function() self:CommitRename(true); self:Refresh() end)
    self.rename:SetScript("OnEditFocusLost",function()
        if not self.creatingNew then self:CommitRename(); self:Refresh() end
    end)
    local save=skin:Button(self.renamePanel,nil,nil,function() self:CommitRename(); self:Refresh() end,118)
    save:SetPoint("BOTTOMLEFT",12,12)
    skin:Label(save,L["Save"]):SetPoint("CENTER")
    local cancel=skin:Button(self.renamePanel,nil,nil,function() self:CommitRename(true); self:Refresh() end,118)
    cancel:SetPoint("BOTTOMRIGHT",-12,12)
    skin:Label(cancel,L["Cancel"]):SetPoint("CENTER")
    self.renamePanel:Hide()
    self.notice=skin:Label(self.content,""); self.notice:SetPoint("TOPRIGHT",self.rail,"BOTTOMRIGHT",-15,-12); self.notice:Hide()
end

function view:BuildSettings()
    self.preferences=CreateFrame("Frame",nil,self.content)
    self.preferences:SetPoint("TOPLEFT",self.rail,"BOTTOMLEFT",0,0); self.preferences:SetPoint("BOTTOMRIGHT")
    local settingsScroll=skin:ScrollFrame(self.preferences)
    self.settingsScroll=settingsScroll
    settingsScroll:SetPoint("TOPLEFT",24,-16); settingsScroll:SetPoint("BOTTOMRIGHT",-30,16)
    local card=CreateFrame("Frame",nil,settingsScroll); card:SetSize(260,400)
    settingsScroll:SetScrollChild(card)
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
    minimap.label:SetPoint("CENTER")
    self.badgeStyleButton=skin:Button(card,nil,nil,function()
        self.options.minimizedIcon=not self.options.minimizedIcon; self:ApplyBadgeStyle()
    end,260)
    self.badgeStyleButton:SetPoint("TOPLEFT",0,-180)
    self.badgeStyleButton.label=skin:Label(self.badgeStyleButton,""); self.badgeStyleButton.label:SetPoint("CENTER")
    self.lockButton=skin:Button(card,nil,nil,function()
        self.options.locked=not self.options.locked; self:ApplyLock()
    end,260)
    self.lockButton:SetPoint("TOPLEFT",0,-215)
    self.lockButton.label=skin:Label(self.lockButton,""); self.lockButton.label:SetPoint("CENTER")
    self.styleButton=skin:Button(card,nil,nil,function()
        self.options.style=self.options.style == "wow" and "flat" or "wow"
        self:ApplyStyle()
    end,260)
    self.styleButton:SetPoint("TOPLEFT",0,-250)
    self.styleButton.label=skin:Label(self.styleButton,""); self.styleButton.label:SetPoint("CENTER")
    local background=skin:Button(card,nil,nil,function() self:ChooseColor("backgroundColor",skin.colors.editor) end,260)
    background:SetPoint("TOPLEFT",0,-285); skin:Label(background,L["Background color"]):SetPoint("CENTER")
    local accent=skin:Button(card,nil,nil,function() self:ChooseColor("accentColor",skin.colors.blue) end,260)
    accent:SetPoint("TOPLEFT",0,-320); skin:Label(accent,L["Accent color"]):SetPoint("CENTER")
    local reset=skin:Button(card,nil,nil,function()
        if ColorPickerFrame and ColorPickerFrame:IsShown() then ColorPickerFrame:Hide() end
        self.options.style="flat"; self.options.backgroundColor=nil; self.options.accentColor=nil
        self:ApplyStyle()
    end,260)
    reset:SetPoint("TOPLEFT",0,-355); skin:Label(reset,L["Reset appearance"]):SetPoint("CENTER")
    self.preferences:Hide()
end

function view:ChooseColor(key, fallback)
    local original=self.options[key]
    local color=original or fallback
    app.platform:ChooseColor(color,function(r,g,b)
        self.options[key]={r,g,b}; self:ApplyStyle()
    end,function()
        self.options[key]=original; self:ApplyStyle()
    end)
end

function view:ApplyStyle()
    skin:Configure(self.options)
    if self.styleButton then self.styleButton.label:SetText(self.options.style == "wow" and L["Style: WoW"] or L["Style: modern"]) end
    if self.editor then self.editor:SetTextColor(unpack(skin.colors.text)) end
    if self.search then self.search:SetTextColor(unpack(skin.colors.text)) end
    if self.rename then self.rename:SetTextColor(unpack(skin.colors.text)) end
    if self.opacitySlider then self.opacitySlider:GetThumbTexture():SetVertexColor(unpack(skin.colors.blue)) end
    if self.scaleSlider then self.scaleSlider:GetThumbTexture():SetVertexColor(unpack(skin.colors.blue)) end
    if self.autoButton then skin:Paint(self.autoButton.fill,self.options.autoHide and skin.colors.active or skin.colors.button) end
    if self.root then
        if not self.border then
            self.border=CreateFrame("Frame",nil,self.root,BackdropTemplateMixin and "BackdropTemplate" or nil)
            self.border:SetAllPoints(); self.border:EnableMouse(false)
            self.border:SetFrameLevel(self.header:GetFrameLevel()+5)
        end
        if self.border.SetBackdrop then
            self.border:SetBackdrop(self.options.style == "wow" and {
                edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize=24,
            } or nil)
            if self.options.style == "wow" then self.border:SetBackdropBorderColor(0.85,0.72,0.43,1) end
        end
        self:Layout(); self:Refresh()
    end
end

-- Addon entry points; window construction stays hidden until fully initialized.
function app:BuildWindow()
    view.options=book.data.options
    skin:Configure(view.options)
    view.root=CreateFrame("Frame",nil,UIParent)
    -- A failed build must never leave a visible frame intercepting mouse input.
    view.root:Hide()
    view.root:SetSize(math.max(360,view.options.width or 680),math.max(MIN_HEIGHT,view.options.height or 450))
    view.root:SetScale(view.options.scale)
    view.root:SetPoint("CENTER",UIParent,"CENTER",(view.options.x or 0)/view.options.scale,(view.options.y or 0)/view.options.scale)
    view.root:SetFrameStrata("DIALOG"); view.root:SetClampedToScreen(true)
    view.root:SetMovable(true); view.root:SetResizable(true); view.root:EnableMouse(true)
    app.platform:Clip(view.root)
    app.platform:ResizeBounds(view.root,360,MIN_HEIGHT)
    view.content=CreateFrame("Frame",nil,view.root)
    app.platform:Clip(view.content)
    view.backgroundFill=skin:Fill(view.content,skin.colors.editor)
    view:BuildHeader(); view:BuildTabs(); view:BuildEditor(); view:BuildPopovers(); view:BuildSettings()
    view.badge=skin:Button(UIParent,nil,L["Restore SimpleNotepad"],function()
        if not view.badge.dragged then view:Animate(true) end
        view.badge.dragged=nil
    end,36)
    view.badge.label=skin:Label(view.badge,"SNP"); view.badge.label:SetPoint("CENTER")
    view.badge.icon=view.badge:CreateTexture(nil,"ARTWORK")
    view.badge.icon:SetSize(20,20); view.badge.icon:SetPoint("CENTER")
    view.badge:SetPoint("CENTER"); view.badge:SetFrameStrata("DIALOG"); view.badge:Hide()
    view.badge:SetMovable(true); view.badge:SetClampedToScreen(true); view.badge:RegisterForDrag("LeftButton")
    view.badge:SetScript("OnMouseDown",function() view.badge.dragged=nil end)
    view.badge:SetScript("OnDragStart",function(button)
        button.dragged=true
        if not view.options.locked then button:StartMoving() end
    end)
    view.badge:SetScript("OnDragStop",function(button)
        button:StopMovingOrSizing()
        local x,y=button:GetCenter(); local cx,cy=UIParent:GetCenter()
        local scale=button:GetEffectiveScale()/UIParent:GetEffectiveScale()
        view.options.badgeX,view.options.badgeY=x*scale-cx,y*scale-cy
    end)
    local grip=skin:Button(view.root,"resize",L["Resize"],function() end,14)
    view.grip=grip
    grip:SetFrameLevel(view.root:GetFrameLevel()+16)
    grip:SetHeight(14); grip.icon:SetSize(12,12); grip:SetPoint("BOTTOMRIGHT",-4,4)
    grip:SetScript("OnMouseDown",function()
        if not view.animation and not view.options.locked then
            view.noteHeight=nil; view.root:StartSizing("BOTTOMRIGHT")
        end
    end)
    grip:SetScript("OnMouseUp",function() view:SaveBounds() end)
    view.root:SetScript("OnSizeChanged",function() view:Layout() end)
    view.root:SetScript("OnMouseDown",function()
        view:CloseSearch(); view.picker:Hide(); view:CommitRename()
        if view.mode == "note" then view.editor:SetFocus(); view.editor:SetCursorPosition(#view.editor:GetText()) end
    end)
    view.root:SetScript("OnUpdate",function(_,elapsed) view:Tick(elapsed) end)
    view.root:SetScript("OnHide",function() view:EndTabDrag() end)
    StaticPopupDialogs.SIMPLENOTEPAD_DELETE={
        text=L["Permanently delete this note?"],button1=YES,button2=NO,
        OnAccept=function(_,page)
            view:CommitRename()
            for index,candidate in ipairs(book.data.pages) do if candidate==page then book:Remove(index); break end end
            view:Refresh()
        end,
        timeout=0,whileDead=true,hideOnEscape=true,
    }
    view:ApplyStyle(); view:ApplyLock(); view:ApplyBadgeStyle(); view:Layout(); view:Refresh(); view:ApplyOpacity(); view.root:Hide()
end

function app:Toggle()
    local opening = not view.root:IsShown() or (view.animation and not view.animation.opening)
    view:Animate(opening,false)
end

function app:Search() view:Search() end
