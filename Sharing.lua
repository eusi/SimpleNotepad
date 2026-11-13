local _, app = ...
local L, book = app.L, app.journal
local share = {inbox = {}, transfers = {}, blocked = {}, recent = {}, seen = {}}
app.sharing = share
local PREFIX, CHUNK, LIMIT = "SNP_NOTE1", 200, 32902
-- Allow five seconds of arrival jitter beyond the receiver's per-sender limit.
local RECEIVE_INTERVAL, SEND_INTERVAL = 30, 35

local function checksum(text)
    local a,b = 1,0
    for i=1,#text do a=(a+text:byte(i))%65521; b=(b+a)%65521 end
    return a.."-"..b
end

local function canonical(name)
    if type(name)~="string" or name=="" then return end
    if RegionalUniqueNamesEnabled and RegionalUniqueNamesEnabled() then
        -- Forever's identity includes the surname, not a realm suffix.
        -- Keep word boundaries: "Al Ice" must not become "Alice".
        return name:gsub("^%s+",""):gsub("%s+$",""):gsub("%s+"," "):lower()
    end
    if not name:find("-",1,true) then name=name.."-"..(GetRealmName() or "") end
    return name:gsub("%s",""):lower()
end

local function unitName(unit)
    if RegionalUniqueNamesEnabled and RegionalUniqueNamesEnabled() then
        -- UnitFullName's second return is a realm. The unmodified unit-name
        -- API supplies the surname used in CHAT_MSG_ADDON on Forever.
        local name,surname=(UnitNameUnmodified or UnitName)(unit)
        if type(name)~="string" or name=="" then return end
        if type(surname)=="string" and surname~="" and not name:find(" ",1,true) then
            name=name.." "..surname
        end
        return canonical(name)
    end
    local name,realm=(UnitFullName or UnitName)(unit)
    if not name then return end
    return canonical(name.."-"..(realm and realm~="" and realm or GetRealmName() or ""))
end

function share:Channel()
    if IsInGroup and IsInGroup(LE_PARTY_CATEGORY_INSTANCE or 2) then return "INSTANCE_CHAT" end
    if IsInRaid and IsInRaid() then return "RAID" end
    if IsInGroup and IsInGroup() then return "PARTY" end
end

function share:Member(sender)
    local key=canonical(sender)
    if not key or key==unitName("player") then return end
    local raid=IsInRaid and IsInRaid()
    for i=1,(raid and 40 or 4) do
        local unit=(raid and "raid" or "party")..i
        if unitName(unit)==key then return key end
    end
end

function share:Changed()
    if app.SharingChanged then app:SharingChanged() end
end

function share:Status(key)
    self.receiptDisplay=nil
    self.status=L[key]; self:Changed()
end

function share:ReceiptStatus(receipt)
    if receipt.count>0 then
        self.status=string.format(L["Received by %d players."],receipt.count)
    elseif GetTime()<receipt.deadline then
        self.status=L["Sent. Waiting for receipt confirmations..."]
    else
        self.status=L["No receipt confirmation. Recipients must enable receiving in the \"Receive\" tab to receive notes."]
    end
    self.receiptDisplay=receipt; self:Changed()
end

function share:TickAcknowledgements(now)
    local queue=self.acknowledgements
    local ack=queue and queue[1]
    if not ack or now<ack.next then return end
    if now>=ack.expires or self:Channel()~=ack.channel or self:Roster()~=ack.roster then
        table.remove(queue,1); return
    end
    local result=app.platform:SendNotePacket(PREFIX,ack.message,ack.channel)
    if result=="retry" then ack.next=now+1 else table.remove(queue,1) end
end

function share:TransportError()
    local platform=app.platform
    if not platform.noteError then self:Status("Note sharing is unavailable on this client."); return end
    local key=platform.noteError
    self.status=platform.noteErrorDetail and string.format(L[key],platform.noteErrorDetail) or L[key]
    self:Changed()
end

function share:EnsureReady()
    -- A failed startup registration must not disable sharing for the entire session.
    if not self.ready then self.ready=app.platform:RegisterNotePrefix(PREFIX) end
    return self.ready
end

function share:Receiving()
    return self.receiveUntil and (self.receiveUntil==0 or GetTime()<self.receiveUntil) and self:Channel()~=nil
end

function share:Duration()
    local minutes=book.data.options.receiveDuration
    if minutes==0 or minutes==10 or minutes==30 or minutes==60 then return minutes end
    return 10
end

function share:SetDuration(minutes)
    if minutes~=0 and minutes~=10 and minutes~=30 and minutes~=60 then return false end
    local receiving=self:Receiving()
    book.data.options.receiveDuration=minutes
    if receiving then self:SetReceiving(true) else self:Changed() end
    return true
end

function share:MinutesLeft()
    if not self:Receiving() then return nil end
    if self.receiveUntil==0 then return 0 end
    return math.max(1,math.ceil((self.receiveUntil-GetTime())/60))
end

function share:SetReceiving(enabled)
    if enabled and not self:Channel() then self:Status("Join a party or raid first."); return false end
    if enabled and not self:EnsureReady() then self:TransportError(); return false end
    local minutes=self:Duration()
    self.receiveUntil=enabled and (minutes==0 and 0 or GetTime()+minutes*60) or nil
    self.transfers={}
    self.status=nil; self:Changed()
end

function share:Duplicate(body)
    for _,page in ipairs(book.data.pages) do if page.body==body then return true end end
    for _,note in ipairs(self.inbox) do if note.body==body then return true end end
end

local function pendingIndex(inbox,note)
    if note==nil then return #inbox>0 and 1 or nil end
    for index,candidate in ipairs(inbox) do if candidate==note then return index end end
end

function share:Accept(note)
    local index=pendingIndex(self.inbox,note)
    if not index then return false end
    note=table.remove(self.inbox,index)
    if not note then return false end
    -- Recheck after removing the pending entry: the notebook may have changed.
    if self:Duplicate(note.body) then self:Status("This note already exists."); return false end
    local name,base,suffix=note.name,note.name,2
    local function exists(value)
        for _,page in ipairs(book.data.pages) do if page.name==value then return true end end
    end
    while exists(name) do name=base.." ("..suffix..")"; suffix=suffix+1 end
    book:Add(name); book:Current().body=note.body
    self:Status("Note accepted as a new copy.")
    return true
end

function share:Reject(block,note)
    local index=pendingIndex(self.inbox,note)
    if not index then return false end
    note=self.inbox[index]
    if not note then return end
    if block then
        self.blocked[note.key]=true; self.transfers[note.key]=nil
        for i=#self.inbox,1,-1 do
            if self.inbox[i].key==note.key then table.remove(self.inbox,i) end
        end
    else table.remove(self.inbox,index) end
    if block then self:Status("Sender blocked until reload.") else self:Status("Note rejected.") end
end

function share:SendWait()
    return self.lastSend and math.max(0,math.ceil(self.lastSend+SEND_INTERVAL-GetTime())) or 0
end

function share:Send(page)
    local now=GetTime()
    local channel=self:Channel()
    if not channel then self:Status("Join a party or raid first."); return false end
    if self.outgoing or self:SendWait()>0 then
        self:Status("Please wait before sending another note."); return false
    end
    if not page or type(page.name)~="string" or type(page.body)~="string" or #page.name>128 or not page.name:find("%S") or #page.body>32768 or not page.body:find("%S") then
        self:Status("Send a non-empty note (title up to 128 bytes, text up to 32 KB)."); return false
    end
    if not self:EnsureReady() then self:TransportError(); return false end
    local payload=#page.name.."\n"..page.name..page.body
    local encoded=payload:gsub(".",function(c) return string.format("%02x",c:byte()) end)
    self.serial=(self.serial or 0)+1
    local id=tostring(math.floor(now*1000)).."-"..self.serial
    local packets={"1\tB\t"..id.."\t"..#payload.."\t"..checksum(payload)}
    for pos=1,#encoded,CHUNK do
        packets[#packets+1]="1\tD\t"..id.."\t"..(math.floor((pos-1)/CHUNK)+1).."\t"..encoded:sub(pos,pos+CHUNK-1)
    end
    -- Freeze text and recipients at the click; cancel if the roster changes.
    local roster=self:Roster()
    self.receipt={id=id,channel=channel,roster=roster,senders={},count=0}
    self.outgoing={packets=packets,index=1,channel=channel,roster=roster,next=now,expires=now+120}
    self:Status("Sending...")
    return true
end

function share:Roster()
    local names={unitName("player") or ""}
    local raid=IsInRaid and IsInRaid()
    for i=1,(raid and 40 or 4) do
        local name=unitName((raid and "raid" or "party")..i)
        if name then names[#names+1]=name end
    end
    table.sort(names)
    return table.concat(names,",")
end

function share:Receive(prefix,message,channel,sender)
    if prefix~=PREFIX or type(message)~="string" or #message>240 then return end
    if channel~=self:Channel() then return end
    -- A global token bucket also bounds work from modified/spamming clients.
    local now=GetTime()
    self.tokens=math.min(60,(self.tokens or 60)+(now-(self.tokenTime or now))*30)
    self.tokenTime=now
    if self.tokens<1 then return end
    self.tokens=self.tokens-1
    local key=self:Member(sender)
    if not key or self.blocked[key] then return end
    local kind,id,rest=message:match("^1\t([BDA])\t([%d%-]+)\t(.+)$")
    if not id or #id>24 then return end
    if kind=="A" then
        local receipt=self.receipt
        if not receipt or receipt.id~=id or receipt.channel~=channel or receipt.roster~=self:Roster()
            or rest~=unitName("player") or receipt.senders[key]
            or (receipt.deadline and now>=receipt.deadline) then return end
        receipt.senders[key]=true; receipt.count=receipt.count+1

        if self.receiptDisplay==receipt then self:ReceiptStatus(receipt) end
        return
    end
    if not self:Receiving() then return end
    if kind=="B" then
        local size,hash=rest:match("^(%d+)\t(%d+%-%d+)$")
        size=tonumber(size)
        if not size or size<4 or size>LIMIT or #hash>11 or self.transfers[key] then return end
        if self.recent[key] and now-self.recent[key]<RECEIVE_INTERVAL then return end
        local active=0; for _ in pairs(self.transfers) do active=active+1 end
        if active>=2 or active+#self.inbox>=5 then return end
        if not self.startTime or now-self.startTime>=60 then self.startTime=now; self.starts=0 end
        if self.starts>=5 then return end
        self.starts=self.starts+1; self.recent[key]=now
        self.transfers[key]={id=id,size=size,hash=hash,chunks={},count=0,expires=now+90,sender=sender}
        return
    end
    local transfer=self.transfers[key]
    if not transfer or transfer.id~=id then return end
    if now>=transfer.expires then self.transfers[key]=nil; return end
    local index,chunk=rest:match("^(%d+)\t([0-9a-f]+)$")
    index=tonumber(index)
    local total=math.ceil(transfer.size*2/CHUNK)
    if not index or index<1 or index>total then return end
    local expected=index==total and transfer.size*2-(total-1)*CHUNK or CHUNK
    if #chunk~=expected or transfer.chunks[index] then return end
    transfer.chunks[index]=chunk; transfer.count=transfer.count+1
    if transfer.count~=total then return end
    self.transfers[key]=nil
    local payload=table.concat(transfer.chunks):gsub("..",function(hex) return string.char(tonumber(hex,16)) end)
    if #payload~=transfer.size or checksum(payload)~=transfer.hash then return end
    local length,offset=payload:match("^(%d+)\n()")
    length=tonumber(length)
    if not length or length<1 or length>128 or offset+length>#payload then return end
    local name,body=payload:sub(offset,offset+length-1),payload:sub(offset+length)
    if #body>32768 or not name:find("%S") or not body:find("%S") then return end
    if self:Duplicate(body) then return end
    for _,seen in ipairs(self.seen) do if seen==payload then return end end
    self.seen[#self.seen+1]=payload; if #self.seen>32 then table.remove(self.seen,1) end
    self.inbox[#self.inbox+1]={key=key,sender=transfer.sender,name=name,body=body}

    -- One bounded reply only after validation and insertion into the inbox.
    -- Use the same group channel; the target prevents cross-talk between senders.
    self.acknowledgements=self.acknowledgements or {}
    if #self.acknowledgements<5 then
        self.acknowledgements[#self.acknowledgements+1]={
            message="1\tA\t"..id.."\t"..key,channel=channel,roster=self:Roster(),next=now,expires=now+10,
        }
    end
    -- No popup, sound, chat output, focus change or automatic notebook edit.
    self:Changed()
end

function share:Tick()
    local now=GetTime()
    self:TickAcknowledgements(now)
    local receipt=self.receipt
    if receipt and receipt.deadline and now>=receipt.deadline then
        self.receipt=nil
        if self.receiptDisplay==receipt then self:ReceiptStatus(receipt) end
    end
    if self.receiveUntil and self.receiveUntil>0 and now>=self.receiveUntil then self:SetReceiving(false) end
    local remaining=self:Receiving() and (self.receiveUntil==0 and 0 or math.ceil(self.receiveUntil-now)) or nil
    local sendWait=self:SendWait()
    if remaining~=self.lastRemaining or sendWait~=self.lastSendWait then
        self.lastRemaining=remaining; self.lastSendWait=sendWait
        if app.SharingClockChanged then app:SharingClockChanged() else self:Changed() end
    end
    for key,transfer in pairs(self.transfers) do
        if now>=transfer.expires then self.transfers[key]=nil end
    end
    for key,at in pairs(self.recent) do if now-at>=RECEIVE_INTERVAL then self.recent[key]=nil end end
    local outgoing=self.outgoing
    if not outgoing or now<outgoing.next then return end
    if now>=outgoing.expires or self:Channel()~=outgoing.channel or self:Roster()~=outgoing.roster then
        self.outgoing=nil; self.receipt=nil; self:Status("Sending cancelled: group changed or transfer expired."); return
    end
    local result=app.platform:SendNotePacket(PREFIX,outgoing.packets[outgoing.index],outgoing.channel)
    if result=="retry" then outgoing.next=now+1; return end
    if not result then
        self.outgoing=nil
        self.receipt=nil
        self:TransportError(); return
    end
    -- Start protection only after the API accepts a packet, not on click/retry.
    -- Keep it after a partial failure: recipients may already have the header.
    if outgoing.index==1 then self.lastSend=now end
    outgoing.index=outgoing.index+1; outgoing.next=now+0.15
    if outgoing.index>#outgoing.packets then
        self.outgoing=nil
        self.receipt.deadline=now+8
        self:ReceiptStatus(self.receipt)
    end
end

function share:Start()
    self.ready=app.platform:RegisterNotePrefix(PREFIX)
    self.roster=self:Roster(); self.channel=self:Channel()
    local frame=CreateFrame("Frame")
    self.frame=frame
    frame:RegisterEvent("CHAT_MSG_ADDON"); frame:RegisterEvent("GROUP_ROSTER_UPDATE")
    frame:SetScript("OnEvent",function(_,event,...)
        if event=="CHAT_MSG_ADDON" then self:Receive(...)
        elseif self.roster~=self:Roster() or self.channel~=self:Channel() then
            -- Group changes revoke the temporary permission and partial notes.
            self.roster=self:Roster(); self.channel=self:Channel()
            self:SetReceiving(false)
        end
    end)
    local elapsed=0
    frame:SetScript("OnUpdate",function(_,delta)
        elapsed=elapsed+delta
        if elapsed>=0.1 then elapsed=0; self:Tick() end
    end)
end
