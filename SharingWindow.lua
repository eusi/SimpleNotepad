local _,app = ...
local L,skin,view,share=app.L,app.skin,app.view,app.sharing
local function shown(frame,value) frame:SetShown(not not value) end
local function label(parent,caption,muted)
    local text=skin:Label(parent,caption or "",muted)
    text:SetJustifyH("LEFT"); text:SetWordWrap(false)
    return text
end
local function divider(parent)
    local line=CreateFrame("Frame",nil,parent)
    line:SetHeight(1); skin:Fill(line,skin.colors.border)
    return line
end

function share:GroupContext()
    if app.devPreview then return L["raid"],20,"RAID" end
    local channel=self:Channel()
    if not channel then return end
    local category=channel=="INSTANCE_CHAT" and (LE_PARTY_CATEGORY_INSTANCE or 2) or (LE_PARTY_CATEGORY_HOME or 1)
    local raid=IsInRaid and IsInRaid(category)
    local count=GetNumGroupMembers and GetNumGroupMembers(category)
    if not count or count<1 then
        count=raid and GetNumRaidMembers and GetNumRaidMembers()
            or (GetNumPartyMembers and GetNumPartyMembers() or 0)+1
    end
    return raid and L["raid"] or L["party"],count,raid and "RAID" or "PARTY"
end
local function button(parent,caption,width,callback,tooltip)
    local control=skin:Button(parent,nil,tooltip,callback,width)
    control.settings=true -- Same background treatment as the Settings controls.
    control.label=label(control,caption); control.label:SetPoint("CENTER")
    skin:ButtonState(control)
    return control
end
local function action(parent,icon,tooltip,callback)
    local control=button(parent,"",24,callback,tooltip)
    control:SetSize(24,24); control.icon=skin:Icon(control,icon); control.icon:SetSize(12,12)
    return control
end
local function contains(list,value)
    for _,candidate in ipairs(list) do if candidate==value then return true end end
end
local function plain(text)
    return (text:gsub("||","\001"):gsub("|H.-|h(.-)|h","%1")
        :gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
        :gsub("|T.-|t",""):gsub("|A.-|a",""):gsub("\001","|"))
end
local function paintSubtab(control)
    skin:Paint(control.fill,control.hovered and skin.colors.hover or control.active and skin.colors.selected or skin.colors.tab)
end
local function fitExcerpt(font,text,width)
    local body=text:sub(1,-4)
    font:SetWidth(0); font:SetText(body.."...")
    while font:GetStringWidth()>width and #body>0 do
        body=body:gsub("[%z\1-\127\194-\244][\128-\191]*$","")
        font:SetText(body.."...")
    end
    font:SetWidth(width)
end

function app:SharingExcerpt(body)
    local line=plain(body):match("^[^\r\n]*") or ""
    local characters={}
    for character in line:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        if #characters>=80 then break end
        characters[#characters+1]=character
    end
    return table.concat(characters).."..."
end

function view:Sharing()
    if self:CommitRename()==false then return end
    self:CloseSearch(); self.picker:Hide(); self.editor:ClearFocus()
    if self.mode~="sharing" then self.shareSelection=nil end
    if not self.sharingOpen then self.shareSelection=nil; self.sharingSection="send" end
    self.sharingOpen=true; self.mode="sharing"; self:Refresh()
end

function view:PlaceSharingTab(offset)
    shown(self.sharingTab,self.sharingOpen)
    if not self.sharingOpen then return end
    local tab=self.sharingTab
    tab.label:SetWidth(0)
    local width=math.ceil(tab.label:GetStringWidth())
    tab.label:SetWidth(width)
    tab.count:SetText(#share.inbox>0 and tostring(#share.inbox) or "")
    tab.count:SetTextColor(unpack(skin.colors.blue))
    local badgeWidth=#share.inbox>0 and 18 or 0
    tab:SetWidth(width+34+badgeWidth)
    tab:ClearAllPoints(); tab:SetPoint("LEFT",self.tabCanvas,"LEFT",offset,0)
    skin:Paint(tab.fill,self.mode=="sharing" and skin.colors.selected or skin.colors.tab)
    return width+34+badgeWidth
end

function view:SetSharingSection(section)
    if self.durationMenu then self.durationMenu:Hide() end
    self.sharingSection=section
    if section~="receive" and self.previewNote then self:PreviewIncoming(nil) end
    app:SharingChanged()
end

function view:SharingMinimumHeight()
    if self.previewNote and self.sharingSection=="receive" then
        -- Keep all pending rows above the preview and the explanatory footer.
        local rows=math.max(2,math.min(5,#share.inbox))
        return 537+rows*39+(self.options.style=="wow" and 20 or 0)
    end
    return 460
end

function view:ConfirmIncoming(note,block)
    if not contains(share.inbox,note) then return end
    StaticPopup_Show(block and "SIMPLENOTEPAD_BLOCK" or "SIMPLENOTEPAD_REJECT",
        block and note.sender or note.name,nil,{note=note,block=block})
end

function view:PreviewIncoming(note)
    if note and not contains(share.inbox,note) then return end
    self.previewNote=note
    -- Show and size the dock before setting multiline text, so wrapping is
    -- calculated against the final, visible preview width.
    self:LayoutSharing()
    self.previewWriting=true
    self.preview:SetText(note and note.body or "")
    self.previewWriting=false
    self.previewScroll:SetVerticalScroll(0)
    self.previewTitle:SetText(note and string.format(L["Preview: %s"],note.name) or "")
end

function app:SharingClockChanged()
    if not view.receiveLabel then return end
    local receiving=share:Receiving()
    view.receiveLabel:SetText(receiving and L["Stop receiving"] or L["Start receiving"])
    view.receiveState:SetText(receiving and L["Receiving is currently on."] or L["Receiving is currently off."])
    local seconds=receiving and (share.receiveUntil==0 and 0 or math.max(0,math.ceil(share.receiveUntil-GetTime()))) or nil
    local time=seconds and string.format("%d:%02d",math.floor(seconds/60),seconds%60)
    view.receiveTimer:SetText(seconds==nil and "" or share.receiveUntil==0 and L["No time limit"] or string.format(L["%s remaining"],time))
    local minutes=share:Duration()
    view.durationLabel:SetText(minutes==0 and L["Endless"] or string.format(L["%d min"],minutes))
    local group,_,channel=share:GroupContext()
    local wait=share:SendWait()
    local busy=share.outgoing or share.demoSend
    local caption=channel=="RAID" and L["Send to raid"] or L["Send to party"]
    if busy then caption=L["Sending..."]
    elseif wait>0 then caption=string.format(L["Send in %s"],string.format("%d:%02d",math.floor(wait/60),wait%60)) end
    view.sendNoteButton.label:SetText(caption)
    local enabled=view.shareSelection~=nil and group~=nil and not busy and wait==0
    view.sendNoteButton:SetEnabled(enabled); view.sendNoteButton:SetAlpha(enabled and 1 or 0.4)
    if view.sharingPanel then view:LayoutSharing() end
end

function app:SharingChanged()
    if not view.sharingPanel then return end
    local count=#share.inbox
    view.shareCount:SetText(count>0 and tostring(count) or "")
    view.shareCount:SetTextColor(unpack(skin.colors.blue))
    view.incomingHeading:SetWidth(0); view.incomingHeading:SetWidth(math.ceil(view.incomingHeading:GetStringWidth()))
    view.incomingCount:SetText(tostring(count)); view.incomingCount:SetTextColor(unpack(skin.colors.blue))
    view.shareButton.active=view.mode=="sharing" or count>0 or share:Receiving()
    skin:ButtonState(view.shareButton)
    view.receiveSub.count:SetText(count>0 and tostring(count) or "")
    view.receiveSub.count:SetTextColor(unpack(skin.colors.blue))
    self:SharingClockChanged()
    view.sharingStatus:SetText(share.status or "")
    if view.previewNote and not contains(share.inbox,view.previewNote) then view:PreviewIncoming(nil) end
    local receive=view.sharingSection=="receive"
    shown(view.sendingPanel,not receive); shown(view.receivingPanel,receive)
    shown(view.sendSub.accentFrame,not receive); shown(view.receiveSub.accentFrame,receive)
    view.sendSub.active=not receive; view.receiveSub.active=receive
    paintSubtab(view.sendSub); paintSubtab(view.receiveSub)
    view.sendSub.label:SetTextColor(unpack(receive and skin.colors.muted or skin.colors.text))
    view.receiveSub.label:SetTextColor(unpack(receive and skin.colors.text or skin.colors.muted))
    if view.shareSelection and not contains(app.journal.data.pages,view.shareSelection) then view.shareSelection=nil end
    local group,count,channel=share:GroupContext()
    local color=skin.colors.text
    local emphasis=group and string.format("|cff%02x%02x%02x%s|r",math.floor(color[1]*255+0.5),math.floor(color[2]*255+0.5),math.floor(color[3]*255+0.5),group)
    view.sharingGroup:SetText(group and string.format(L["Sharing with your %s · %d players"],emphasis,count)
        or L["Join a party or raid to share notes."])
    self:SharingClockChanged()
    if view.mode=="sharing" then view:SharingLists() end
    view:Tabs(); view:LayoutSharing()
end

function view:SharingLists()
    for index,page in ipairs(app.journal.data.pages) do
        local row=self.sourceRows[index]
        if not row then
            row=button(self.sourceCanvas,"",180,function(control)
                self.shareSelection=control.page; app:SharingChanged()
            end)
            row.label:ClearAllPoints(); row.label:SetPoint("LEFT",8,0)
            row.label:SetPoint("RIGHT",-28,0); row.label:SetJustifyH("LEFT")
            row.selectionMark=row:CreateTexture(nil,"OVERLAY")
            row.selectionMark:SetPoint("TOPLEFT"); row.selectionMark:SetPoint("BOTTOMLEFT"); row.selectionMark:SetWidth(3)
            row.selectionCheck=skin:Icon(row,"accept"); row.selectionCheck:SetSize(12,12)
            row.selectionCheck:ClearAllPoints(); row.selectionCheck:SetPoint("RIGHT",-8,0)
            self.sourceRows[index]=row
        end
        row.page=page; row.label:SetText(page.name)
        row.active=self.shareSelection==page; skin:ButtonState(row)
        app.platform:Color(row.selectionMark,skin.colors.blue); shown(row.selectionMark,row.active)
        row.selectionCheck:SetVertexColor(unpack(skin.colors.blue)); shown(row.selectionCheck,row.active)
        row:ClearAllPoints(); row:SetPoint("TOPLEFT",0,-(index-1)*32); row:SetPoint("TOPRIGHT",0,-(index-1)*32)
        row:Show()
    end
    for index=#app.journal.data.pages+1,#self.sourceRows do self.sourceRows[index]:Hide() end
    self.sourceCanvas:SetHeight(math.max(1,#app.journal.data.pages*32))
    for index,note in ipairs(share.inbox) do
        local row=self.inboxRows[index]
        if not row then
            row=CreateFrame("Frame",nil,self.inboxCanvas); row:SetHeight(38)
            row.open=CreateFrame("Button",nil,row)
            row.name=label(row.open,""); row.name:SetAllPoints()
            row.open:SetScript("OnClick",function() self:PreviewIncoming(row.note) end)
            row.open:SetScript("OnEnter",function(control)
                GameTooltip:SetOwner(control,"ANCHOR_RIGHT"); GameTooltip:SetText(row.note.name)
                GameTooltip:AddLine(row.note.sender,1,1,1); GameTooltip:Show()
            end)
            row.open:SetScript("OnLeave",function() GameTooltip:Hide() end)
            row.excerpt=label(row,"",true)
            row.sender=label(row,"",true)
            row.accept=action(row,"accept",L["Accept"],function()
                if self:CommitRename()==false then return end
                share:Accept(row.note); self:Refresh()
            end)
            row.reject=action(row,"close",L["Reject"],function() self:ConfirmIncoming(row.note,false) end)
            row.block=action(row,"block",L["Block sender"],function() self:ConfirmIncoming(row.note,true) end)
            local line=CreateFrame("Frame",nil,row); line:SetHeight(1)
            line:SetPoint("BOTTOMLEFT"); line:SetPoint("BOTTOMRIGHT"); skin:Fill(line,skin.colors.border)
            self.inboxRows[index]=row
        end
        row.note=note; row.name:SetText(note.name)
        row.excerptText=app:SharingExcerpt(note.body)
        row.sender:SetText(note.sender)
        row:ClearAllPoints(); row:SetPoint("TOPLEFT",0,-(index-1)*39); row:SetPoint("TOPRIGHT",0,-(index-1)*39)
        row:Show()
    end
    for index=#share.inbox+1,#self.inboxRows do self.inboxRows[index]:Hide() end
    self.inboxCanvas:SetHeight(math.max(1,#share.inbox*39))
    shown(self.inboxEmpty,#share.inbox==0)
end

function view:LayoutSharing()
    if not self.sharingPanel or self.sharingLayout then return end
    self.sharingLayout=true
    local preview=self.mode=="sharing" and self.previewNote~=nil and self.sharingSection=="receive"
    if preview then
        self.previewBaseHeight=self.previewBaseHeight or self.root:GetHeight()
        local minimum=self:SharingMinimumHeight()
        if self.root:GetHeight()<minimum then
            self.previewExpandedHeight=minimum; self.root:SetHeight(minimum)
        end
    elseif self.previewBaseHeight then
        local height=self.previewBaseHeight
        local restore=self.mode=="sharing" and self.root:GetHeight()==self.previewExpandedHeight
        self.previewBaseHeight=nil; self.previewExpandedHeight=nil
        if restore then self.root:SetHeight(math.max(400,height)) end
    end
    self.receiveState:SetWidth(0)
    self.receiveState:SetWidth(math.ceil(self.receiveState:GetStringWidth())+2)
    self.receiveTimer:SetWidth(0)
    self.receiveTimer:SetWidth(math.max(1,math.ceil(self.receiveTimer:GetStringWidth())))
    self.durationButton:SetWidth(math.max(86,math.ceil(self.durationLabel:GetStringWidth())+24))
    self.receiveButton:SetWidth(math.max(112,math.ceil(self.receiveLabel:GetStringWidth())+24))
    -- Translated receiving controls must fit even with an unlimited timer.
    local rowWidth=self.receiveState:GetWidth()+self.receiveTimer:GetWidth()+self.durationButton:GetWidth()+self.receiveButton:GetWidth()+42
    self.sharingMinimumWidth=math.max(560,math.ceil(rowWidth+self.root:GetWidth()-self.receivingPanel:GetWidth()))
    if self.mode=="sharing" and self.root:GetWidth()<self.sharingMinimumWidth then
        self.noteWidth=self.noteWidth or self.root:GetWidth()
        self.root:SetWidth(self.sharingMinimumWidth)
    end
    local actionWidth=math.max(160,math.min(210,math.floor(self.sharingPanel:GetWidth()*0.34)))
    local sourceWidth=math.max(100,self.sharingPanel:GetWidth()-actionWidth-24)
    self.sourceScroll:SetWidth(sourceWidth)
    self.sourceCanvas:SetWidth(math.max(1,sourceWidth-22))
    self.sendActionPanel:SetWidth(actionWidth); self.sendNoteButton:SetWidth(actionWidth)
    self.sharingStatus:ClearAllPoints()
    local receive=self.sharingSection=="receive"
    self.sharingStatus:SetPoint("BOTTOMLEFT",0,54)
    self.sharingStatus:SetPoint("BOTTOMRIGHT",0,54)
    self.sharingStatus:SetHeight(32)
    shown(self.sendHint,not receive); shown(self.receiveHint,receive)
    local width=math.max(1,self.inboxScroll:GetWidth())
    self.inboxCanvas:SetWidth(width)
    local available=math.max(3,width-96)
    local nameWidth=math.floor(available*0.30)
    local previewWidth=math.floor(available*0.40)
    local senderWidth=available-nameWidth-previewWidth
    for _,row in ipairs(self.inboxRows) do
        row.open:SetPoint("LEFT",0,0); row.open:SetSize(nameWidth,28)
        row.excerpt:SetPoint("LEFT",nameWidth+5,0)
        local excerptWidth=math.max(1,previewWidth-5)
        if row.excerptWidth~=excerptWidth or row.excerptRendered~=row.excerptText then
            fitExcerpt(row.excerpt,row.excerptText,excerptWidth)
            row.excerptWidth=excerptWidth; row.excerptRendered=row.excerptText
        end
        row.sender:SetPoint("LEFT",nameWidth+previewWidth+10,0); row.sender:SetWidth(senderWidth)
        row.block:SetPoint("RIGHT",0,0); row.reject:SetPoint("RIGHT",-28,0); row.accept:SetPoint("RIGHT",-56,0)
    end
    self.inboxNameHeader:SetWidth(nameWidth)
    self.inboxPreviewHeader:ClearAllPoints(); self.inboxPreviewHeader:SetPoint("TOPLEFT",nameWidth+5,0); self.inboxPreviewHeader:SetWidth(previewWidth)
    self.inboxSenderHeader:ClearAllPoints(); self.inboxSenderHeader:SetPoint("TOPLEFT",nameWidth+previewWidth+10,0); self.inboxSenderHeader:SetWidth(senderWidth)
    shown(self.incomingPreview,preview)
    self.inboxScroll:ClearAllPoints()
    self.inboxScroll:SetPoint("TOPLEFT",self.inboxHeaders,"BOTTOMLEFT",0,-3)
    self.inboxScroll:SetPoint("BOTTOMRIGHT",-22,preview and 212 or 0)
    if self.preview then self.preview:SetWidth(math.max(1,self.previewScroll:GetWidth())) end
    skin:ResizeTextures()
    self.sharingLayout=nil
end

function app:BuildSharingWindow()
    view.sourceRows={}; view.inboxRows={}
    view.sharingSection="send"; view.shareSelection=nil; view.previewNote=nil
    local tab=skin:Button(view.tabCanvas,nil,nil,function() view:Sharing() end)
    view.sharingTab=tab; tab:SetHeight(21)
    tab.label=label(tab,L["Sharing"]); tab.label:SetPoint("LEFT",8,0)
    tab.count=label(tab,""); tab.count:SetPoint("RIGHT",-22,0)
    local close=skin:Button(tab,"close",L["Close sharing"],function()
        view:PreviewIncoming(nil)
        view.sharingOpen=false; view.shareSelection=nil; view.mode="note"; view:Refresh()
    end,12)
    close:SetPoint("RIGHT",-6,0); close:SetHeight(12); close.icon:SetSize(10,10)
    tab.close=close; tab:Hide()

    local panel=CreateFrame("Frame",nil,view.content); view.sharingPanel=panel
    panel:SetPoint("TOPLEFT",view.rail,"BOTTOMLEFT",10,-8); panel:SetPoint("BOTTOMRIGHT",-10,20)
    local subBar=CreateFrame("Frame",nil,panel); view.sharingSubBar=subBar
    subBar:SetPoint("TOPLEFT",view.rail,"BOTTOMLEFT",0,0)
    subBar:SetPoint("TOPRIGHT",view.rail,"BOTTOMRIGHT",0,0); subBar:SetHeight(30)
    local black=subBar:CreateTexture(nil,"BACKGROUND"); black:SetAllPoints()
    app.platform:Color(black,{0,0,0,1}); view.sharingSubBackground=black
    local function subtab(caption,section,x,width)
        local control=skin:Button(subBar,nil,nil,function() view:SetSharingSection(section) end,width)
        control:SetHeight(28); control:SetPoint("TOPLEFT",x,-1); paintSubtab(control)
        control.label=label(control,caption); control.label:SetPoint("LEFT",8,0)
        control.count=label(control,""); control.count:SetPoint("LEFT",control.label,"RIGHT",7,0)
        local line=CreateFrame("Frame",nil,control); line:SetHeight(2)
        line:SetPoint("BOTTOMLEFT"); line:SetPoint("BOTTOMRIGHT"); control.accentFrame=line; control.accent=skin:Fill(line,skin.colors.blue)
        control:SetScript("OnClick",function() view:SetSharingSection(section) end)
        control:SetScript("OnEnter",function() control.hovered=true; paintSubtab(control) end)
        control:SetScript("OnLeave",function() control.hovered=nil; paintSubtab(control) end)
        return control
    end
    view.sendSub=subtab(L["Send"],"send",0,110)
    view.receiveSub=subtab(L["Receive"],"receive",110,140)
    local status=label(panel,"",true); view.sharingStatus=status
    status:SetPoint("BOTTOMLEFT"); status:SetPoint("BOTTOMRIGHT"); status:SetHeight(28); status:SetWordWrap(true)
    local footer=divider(panel); view.sharingFooterLine=footer
    footer:SetPoint("BOTTOMLEFT",0,50); footer:SetPoint("BOTTOMRIGHT",0,50)
    local hint=label(panel,L["Shares this note with your group. Members must enable receiving in SimpleNotepad to view shared notes."],true)
    view.sendHint=hint; hint:SetPoint("BOTTOMLEFT",0,4); hint:SetPoint("BOTTOMRIGHT",0,4)
    hint:SetHeight(40); hint:SetWordWrap(true)
    local receiveHint=label(panel,L["Click a note to preview it before accepting."],true); view.receiveHint=receiveHint
    receiveHint:SetPoint("BOTTOMLEFT",0,4); receiveHint:SetPoint("BOTTOMRIGHT",0,4)
    receiveHint:SetHeight(40); receiveHint:SetWordWrap(true)

    local send=CreateFrame("Frame",nil,panel); view.sendingPanel=send
    send:SetPoint("TOPLEFT",0,-38); send:SetPoint("BOTTOMRIGHT",0,88)
    view.sharingGroup=label(send,"",true); view.sharingGroup:SetPoint("TOPLEFT"); view.sharingGroup:SetPoint("TOPRIGHT"); view.sharingGroup:SetHeight(28)
    local sendDivider=divider(send); view.sendDivider=sendDivider
    sendDivider:SetPoint("TOPLEFT",0,-36); sendDivider:SetPoint("TOPRIGHT",0,-36)
    local notesTitle=label(send,L["1. Select a note"],true); notesTitle:SetPoint("TOPLEFT",0,-52); notesTitle:SetHeight(20); view.chooseNotesLabel=notesTitle
    local list=skin:ScrollFrame(send); view.sourceScroll=list
    list:SetPoint("TOPLEFT",0,-78); list:SetPoint("BOTTOMLEFT"); list:SetWidth(200)
    view.sourceCanvas=CreateFrame("Frame",nil,list); view.sourceCanvas:SetSize(178,1); list:SetScrollChild(view.sourceCanvas)
    list:HookScript("OnSizeChanged",function(_,width) view.sourceCanvas:SetWidth(math.max(1,width-22)) end)
    local actions=CreateFrame("Frame",nil,send); view.sendActionPanel=actions
    actions:SetPoint("TOPRIGHT"); actions:SetPoint("BOTTOMRIGHT"); actions:SetWidth(120)
    view.sendNotesCaption=label(actions,L["2. Send note"],true)
    view.sendNotesCaption:SetPoint("TOPLEFT",0,-52); view.sendNotesCaption:SetPoint("TOPRIGHT",0,-52); view.sendNotesCaption:SetHeight(20)
    view.sendNoteButton=button(actions,L["Send note"],120,function()
        if view:CommitRename()==false or not view.shareSelection then return end
        if not contains(app.journal.data.pages,view.shareSelection) then view.shareSelection=nil; app:SharingChanged(); return end
        share:Send(view.shareSelection)
    end)
    view.sendNoteButton:SetPoint("TOPRIGHT",0,-78)

    local receive=CreateFrame("Frame",nil,panel); view.receivingPanel=receive
    receive:SetPoint("TOPLEFT",0,-38); receive:SetPoint("BOTTOMRIGHT",0,100)
    local receiveDivider=divider(receive); view.receiveDivider=receiveDivider
    receiveDivider:SetPoint("TOPLEFT",0,-36); receiveDivider:SetPoint("TOPRIGHT",0,-36)
    view.durationButton=button(receive,"",130,function()
        shown(view.durationMenu,not view.durationMenu:IsShown())
    end,L["Click to change duration"])
    view.durationLabel=view.durationButton.label
    local menu=CreateFrame("Frame",nil,receive); view.durationMenu=menu
    menu:SetPoint("TOPLEFT",view.durationButton,"BOTTOMLEFT",0,-3); menu:SetSize(145,122)
    menu:SetFrameLevel(view.header:GetFrameLevel()+30); menu:EnableMouse(true)
    skin:Fill(menu,skin.colors.rail); view.durationOptions={}
    local menuWidth=145
    for index,minutes in ipairs({10,30,60,0}) do
        local value=minutes
        local option=button(menu,value==0 and L["Until I stop receiving"] or string.format(L["Duration: %d min"],value),141,function()
            menu:Hide(); share:SetDuration(value)
        end)
        option:SetPoint("TOPLEFT",2,-2-(index-1)*30); view.durationOptions[value]=option
        menuWidth=math.max(menuWidth,math.ceil(option.label:GetStringWidth())+24)
    end
    menu:SetWidth(menuWidth)
    for _,option in pairs(view.durationOptions) do option:SetWidth(menuWidth-4) end
    menu:Hide()
    view.receiveButton=button(receive,L["Start receiving"],136,function() share:SetReceiving(not share:Receiving()) end)
    view.receiveButton:SetPoint("TOPRIGHT"); view.receiveLabel=view.receiveButton.label
    view.receiveState=label(receive,""); view.receiveState:SetPoint("TOPLEFT"); view.receiveState:SetSize(90,28)
    view.receiveTimer=label(receive,"",true); view.receiveTimer:SetPoint("LEFT",view.receiveState,"RIGHT",10,0); view.receiveTimer:SetSize(100,28)
    view.durationButton:SetPoint("RIGHT",view.receiveButton,"LEFT",-10,0)
    view.incomingHeading=label(receive,L["Incoming notes"])
    view.incomingHeading:SetPoint("TOPLEFT",0,-54); view.incomingHeading:SetHeight(20)
    view.incomingCount=label(receive,""); view.incomingCount:SetPoint("LEFT",view.incomingHeading,"RIGHT",8,0)
    local headers=CreateFrame("Frame",nil,receive); view.inboxHeaders=headers
    headers:SetPoint("TOPLEFT",0,-88); headers:SetPoint("TOPRIGHT",-22,-88); headers:SetHeight(18)
    view.inboxNameHeader=label(headers,L["Note"],true); view.inboxNameHeader:SetPoint("TOPLEFT")
    view.inboxPreviewHeader=label(headers,L["Preview"],true)
    view.inboxSenderHeader=label(headers,L["Sender"],true)
    local inbox=skin:ScrollFrame(receive); view.inboxScroll=inbox
    view.inboxCanvas=CreateFrame("Frame",nil,inbox); view.inboxCanvas:SetSize(1,1); inbox:SetScrollChild(view.inboxCanvas)
    inbox:HookScript("OnSizeChanged",function() view:LayoutSharing() end)
    view.inboxEmpty=label(receive,L["No incoming notes"],true); view.inboxEmpty:SetPoint("TOPLEFT",0,-120)
    local preview=CreateFrame("Frame",nil,receive); view.incomingPreview=preview
    preview:SetPoint("BOTTOMLEFT"); preview:SetPoint("BOTTOMRIGHT"); preview:SetHeight(200)
    app.platform:Clip(preview); skin:Fill(preview,skin.colors.editor); skin:Outline(preview)
    local previewHeader=CreateFrame("Frame",nil,preview); previewHeader:SetHeight(26)
    previewHeader:SetPoint("TOPLEFT"); previewHeader:SetPoint("TOPRIGHT"); skin:Fill(previewHeader,skin.colors.toolbar)
    view.previewTitle=label(previewHeader,""); view.previewTitle:SetPoint("TOPLEFT",8,-6); view.previewTitle:SetPoint("TOPRIGHT",-28,-6); view.previewTitle:SetHeight(18)
    local hide=skin:Button(previewHeader,"close",L["Close"],function() view:PreviewIncoming(nil) end,14)
    hide:SetPoint("TOPRIGHT",-6,-6); hide:SetHeight(14)
    view.previewScroll=skin:ScrollFrame(preview)
    view.previewScroll:SetPoint("TOPLEFT",8,-32); view.previewScroll:SetPoint("BOTTOMRIGHT",-26,8)
    local editor=CreateFrame("EditBox",nil,view.previewScroll); view.preview=editor
    editor:SetMultiLine(true); editor:SetAutoFocus(false); editor:SetFontObject("ChatFontNormal")
    editor:SetTextColor(unpack(skin.colors.text)); editor:SetTextInsets(4,4,4,4); editor:SetHeight(1)
    view.previewScroll:SetScrollChild(editor)
    view.previewScroll:HookScript("OnSizeChanged",function(_,width) editor:SetWidth(math.max(1,width)) end)
    editor:SetScript("OnEditFocusGained",function(frame) frame:ClearFocus() end)
    editor:SetScript("OnTextChanged",function(frame)
        if view.previewWriting then return end
        view.previewWriting=true; frame:SetText(view.previewNote and view.previewNote.body or ""); view.previewWriting=false
    end)
    if editor.SetHyperlinksEnabled then editor:SetHyperlinksEnabled(true) end
    editor:SetScript("OnHyperlinkClick",function(_,link,text,mouseButton) if SetItemRef then SetItemRef(link,text,mouseButton) end end)
    local function confirm(_,data) if data then share:Reject(data.block,data.note) end end
    StaticPopupDialogs.SIMPLENOTEPAD_REJECT={
        text=L["Reject note %s?"],button1=YES,button2=NO,OnAccept=confirm,
        timeout=0,whileDead=true,hideOnEscape=true,
    }
    StaticPopupDialogs.SIMPLENOTEPAD_BLOCK={
        text=L["Block %s until reload and discard their pending notes?"],button1=YES,button2=NO,OnAccept=confirm,
        timeout=0,whileDead=true,hideOnEscape=true,
    }
    panel:Hide()
end
