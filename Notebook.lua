local _, app = ...
local L = app.L
-- Undo is session-local; only pages and options are persisted in SavedVariables.
local journal, snapshots = {}, {}
app.journal = journal

local function Copy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local result = {}
    seen[value] = result
    for key, item in pairs(value) do result[key] = Copy(item, seen) end
    return result
end

function journal:LoadCharacter(account, character)
    if type(account.options) ~= "table" then account.options = {} end
    if type(account.sharedNotes) ~= "table" then account.sharedNotes = {} end
    if character.storageVersion == nil then
        -- Preserve the old shared notebook as a migration source for other alts.
        if character.pages == nil and type(account.pages) == "table" then
            character.pages = Copy(account.pages)
            character.selected = account.selected
            character.tabOrder = Copy(account.tabOrder)
        end
    end
    character.storageVersion = 2
    if type(character.pages) ~= "table" or #character.pages == 0 then
        character.pages = {{name = L["Notes"], body = "", open = true}}
    end
    local pages, references, mapping, present = {}, {}, {}, {}
    local function Attach(reference)
        local shared = account.sharedNotes[reference.sharedId]
        local page = setmetatable({}, {
            __index = function(_, key)
                if key == "name" or key == "body" then return shared[key] end
                return reference[key]
            end,
            __newindex = function(_, key, value)
                if key == "name" or key == "body" then shared[key] = value
                else reference[key] = value end
            end,
        })
        references[page] = reference
        return page
    end
    self.attachShared = Attach
    for index, stored in ipairs(character.pages) do
        if not stored.sharedId or type(account.sharedNotes[stored.sharedId]) == "table" then
            pages[#pages + 1] = stored.sharedId and Attach(stored) or stored
            mapping[index] = #pages
            if stored.sharedId then present[stored.sharedId] = true end
        end
    end
    local order = {}
    for _, index in ipairs(type(character.tabOrder) == "table" and character.tabOrder or {}) do
        if mapping[index] then order[#order + 1] = mapping[index] end
    end
    character.selected = mapping[character.selected or 1] or 1
    character.tabOrder = order
    local ids = {}
    for id, note in pairs(account.sharedNotes) do
        if type(id) == "number" and id > 0 and id % 1 == 0 and type(note) == "table" and not present[id] then ids[#ids + 1] = id end
    end
    table.sort(ids)
    for _, id in ipairs(ids) do pages[#pages + 1] = Attach({sharedId = id, open = false}) end
    -- This view is not persisted: notes belong to the character, settings to the account.
    local view = setmetatable({}, {
        __index = function(_, key)
            if key == "options" then return account.options end
            if key == "pages" then return pages end
            return character[key]
        end,
        __newindex = function(_, key, value)
            if key == "options" then account.options = value
            elseif key == "pages" then pages = value
            else character[key] = value end
        end,
    })
    self:Load(view, account, character, references)
end

function journal:SyncPages()
    if not self.character then return end
    local stored = {}
    for index, page in ipairs(self.data.pages) do stored[index] = self.sharedRefs[page] or page end
    self.character.pages = stored
end

function journal:IsShared(index)
    return self.sharedRefs and self.sharedRefs[self.data.pages[index]] ~= nil or false
end

function journal:SetShared(index, enabled)
    if not self.account or not self.data.pages[index] then return false end
    enabled = not not enabled
    if self:IsShared(index) == enabled then return true end
    local old = self.data.pages[index]
    local page
    if enabled then
        local id = tonumber(self.account.lastSharedId) or 0
        if id < 0 or id ~= id or id == math.huge then id = 0 end
        repeat id = math.floor(id) + 1 until self.account.sharedNotes[id] == nil
        self.account.lastSharedId = id
        self.account.sharedNotes[id] = {name = old.name, body = old.body}
        page = self.attachShared({sharedId = id, open = old.open})
    else
        local reference = self.sharedRefs[old]
        page = {name = old.name, body = old.body, open = old.open}
        self.account.sharedNotes[reference.sharedId] = nil
        self.sharedRefs[old] = nil
    end
    snapshots[page], snapshots[old] = snapshots[old], nil
    self.data.pages[index] = page
    self:SyncPages()
    return true
end

function journal:StyleColors()
    local options=self.data.options
    return options.styleColors[options.style]
end

function journal:Load(database, account, character, references)
    if database ~= self.data then
        self.account, self.character, self.sharedRefs = account, character, references or {}
    end
    self.data = database
    database.pages = database.pages or {{name = L["Notes"], body = ""}}
    if #database.pages == 0 then database.pages[1] = {name = L["Notes"], body = ""} end
    database.options = database.options or {}
    local defaults = {opacity = 0.9, scale = 1, minimap = true, autoHide = false, style = "flat", locked = false, minimizedIcon = true, automaticBullets = false, showNoteNavigation = false, textColor = "ffcc66"}
    for key, value in pairs(defaults) do
        if database.options[key] == nil then database.options[key] = value end
    end
    local options=database.options
    options.automaticBullets=options.automaticBullets==true
    options.showNoteNavigation=options.showNoteNavigation==true
    if type(options.textColor)~="string" or not options.textColor:match("^%x%x%x%x%x%x$") then options.textColor="ffcc66" end
    if options.style~="wow" then options.style="flat" end
    if type(options.styleColors)~="table" then options.styleColors={} end
    for _,style in ipairs({"flat","wow"}) do
        if type(options.styleColors[style])~="table" then options.styleColors[style]={} end
    end
    -- Keep existing colors on the active style when upgrading from shared colors.
    local profile=self:StyleColors()
    for _,key in ipairs({"backgroundColor","accentColor"}) do
        if profile[key]==nil and type(options[key])=="table" then profile[key]=Copy(options[key]) end
        options[key]=nil
    end
    database.selected = math.max(1, math.min(database.selected or 1, #database.pages))
    for _, page in ipairs(database.pages) do
        if type(page.name) ~= "string" or not page.name:find("%S") then page.name = L["Notes"] end
        if page.open == nil then page.open = true end
    end
    self:Current().open = true
    -- Tab order is independent of the saved note list; closed tabs lose their slot.
    local order,seen={},{}
    for _,index in ipairs(type(database.tabOrder)=="table" and database.tabOrder or {}) do
        if database.pages[index] and database.pages[index].open and not seen[index] then
            order[#order+1]=index; seen[index]=true
        end
    end
    for index,page in ipairs(database.pages) do
        if page.open and not seen[index] then order[#order+1]=index end
    end
    database.tabOrder=order
    self:SyncPages()
end

function journal:Current()
    return self.data.pages[self.data.selected]
end

function journal:Record(body)
    local page = self:Current()
    if page.body == body then return end
    local track = snapshots[page]
    if not track then track = {values = {page.body}, cursor = 1}; snapshots[page] = track end
    for index = #track.values, track.cursor + 1, -1 do track.values[index] = nil end
    track.values[#track.values + 1] = body
    if #track.values > 100 then table.remove(track.values, 1) end
    track.cursor = #track.values
    page.body = body
end

function journal:Restore(direction)
    local page = self:Current()
    local track = snapshots[page]
    if not track then return end
    track.cursor = math.max(1, math.min(#track.values, track.cursor + direction))
    page.body = track.values[track.cursor]
end

function journal:Add(name)
    local pages = self.data.pages
    pages[#pages + 1] = {name = name or string.format(L["Note %d"], #pages + 1), body = "", open = true}
    self.data.selected = #pages
    self.data.tabOrder[#self.data.tabOrder+1]=#pages
    self:SyncPages()
end

function journal:Select(index)
    if not self.data.pages[index] then return end
    self.data.selected = index
    if not self:TabPosition(index) then self.data.tabOrder[#self.data.tabOrder+1]=index end
    self:Current().open = true
end

function journal:TabPosition(index)
    for slot,pageIndex in ipairs(self.data.tabOrder) do if pageIndex==index then return slot end end
end

function journal:MoveTab(index,destination)
    local position=self:TabPosition(index)
    if not position then return false end
    destination=math.max(1,math.min(#self.data.tabOrder,destination))
    if position==destination then return false end
    table.remove(self.data.tabOrder,position)
    table.insert(self.data.tabOrder,destination,index)
    return true
end

function journal:Neighbor(direction)
    local position=self:TabPosition(self.data.selected) or 1
    return self.data.tabOrder[math.max(1,math.min(#self.data.tabOrder,position+direction))]
end

-- Closing a tab keeps the saved page; Remove is the destructive operation.
function journal:Close(index)
    local position=self:TabPosition(index)
    local order=self.data.tabOrder
    if not position or #order<=1 then return false end
    table.remove(order,position)
    self.data.pages[index].open = false
    if self.data.selected == index then self.data.selected = order[math.min(position,#order)] end
    return true
end

function journal:Rename(index, name)
    name = name:match("^%s*(.-)%s*$")
    if name == "" or not self.data.pages[index] then return false end
    self.data.pages[index].name = name
    return true
end

function journal:Remove(index)
    index = index or self.data.selected
    local page = self.data.pages[index]
    if not page then return end
    snapshots[page] = nil
    local reference = self.sharedRefs and self.sharedRefs[page]
    if reference and self.account then
        self.account.sharedNotes[reference.sharedId] = nil
        self.sharedRefs[page] = nil
    end
    if #self.data.pages == 1 then
        self.data.pages[1] = {name = L["Notes"], body = "", open = true}
        self.data.selected = 1
        self.data.tabOrder={1}
        self:SyncPages()
        return
    end
    local slot=self:TabPosition(index)
    table.remove(self.data.pages, index)
    self:SyncPages()
    for position=#self.data.tabOrder,1,-1 do
        local pageIndex=self.data.tabOrder[position]
        if pageIndex==index then table.remove(self.data.tabOrder,position)
        elseif pageIndex>index then self.data.tabOrder[position]=pageIndex-1 end
    end
    if self.data.selected==index and #self.data.tabOrder>0 then
        self.data.selected=self.data.tabOrder[math.min(slot or 1,#self.data.tabOrder)]
        self:Select(self.data.selected)
        return
    end
    if index < self.data.selected then self.data.selected = self.data.selected - 1 end
    self.data.selected = math.min(self.data.selected, #self.data.pages)
    self:Select(self.data.selected)
end

function journal:Search(query)
    local results = {}
    query = app.Fold(query)
    for index, page in ipairs(self.data.pages) do
        if string.find(app.Fold(page.name .. "\n" .. page.body), query, 1, true) then
            results[#results + 1] = index
        end
    end
    return results
end

-- Byte offsets match EditBox cursor/highlight positions, including WoW markup.
local formatting={}
app.formatting=formatting
formatting.palette={"ffffff","b8b8b8","666666","333333","000000",
    "ff3333","754a2a","ff8800","ffff00","33cc33",
    "176b35","008080","00dddd","a1d2f4","0088ff",
    "173b80","4b0082","9933ff","ff00cc","ff99bb"}
local function tokens(text)
    local result,index={},1
    while index<=#text do
        local head=text:sub(index,index+9)
        local value=head:match("^|c%x%x%x%x%x%x%x%x") or head:match("^|r") or head:match("^||")
        local marker=head:sub(1,2)
        if not value and (marker=="|H" or marker=="|T" or marker=="|A") then
            local ending=marker=="|H" and "|h" or marker=="|T" and "|t" or "|a"
            local last=text:find(ending,index+2,true)
            if last and marker=="|H" then last=text:find(ending,last+2,true) end
            if last then value=text:sub(index,last+1) end
        end
        if not value then value=head:match("^[%z\1-\127\194-\244][\128-\191]*") or head:sub(1,1) end
        result[#result+1]={text=value,first=index-1,last=index-1+#value}
        index=index+#value
    end
    return result
end
function formatting:Color(text,first,last,color)
    if type(color)~="string" or not color:match("^%x%x%x%x%x%x$") or first>=last then return text end
    local parts=tokens(text)
    -- Never split UTF-8, escape sequences, hyperlinks or embedded images.
    for _,part in ipairs(parts) do
        if first>part.first and first<part.last then first=part.first end
        if last>part.first and last<part.last then last=part.last end
    end
    first=math.max(0,first); last=math.min(#text,last)
    local active,selected={},{ }
    for _,part in ipairs(parts) do
        if part.first>=last then break end
        local isColor=part.text:match("^|c%x%x%x%x%x%x%x%x$")
        local reset=part.text=="|r"
        if isColor then active={part.text} elseif reset then active={} end
        if part.first>=first and not isColor and not reset then
            selected[#selected+1]=part.text
            -- A link may reset its own color; resume the chosen text color.
            if part.text:find("|r",1,true) then selected[#selected+1]="|cff"..color end
        end
    end
    if #selected==0 then return text end
    local prefix=text:sub(1,first).."|cff"..color
    local result=prefix..table.concat(selected).."|r"..table.concat(active)..text:sub(last+1)
    return result,#prefix,#prefix+#table.concat(selected)
end
function formatting:ContinueBullet(before,after,cursor)
    -- Only a single typed newline continues a list; paste/replacements stay intact.
    if #after~=#before+1 then return end
    local position=cursor or 1
    if not cursor then
        while position<=#before and before:sub(position,position)==after:sub(position,position) do position=position+1 end
    end
    if after:sub(position,position)~="\n" or after:sub(position+1)~=before:sub(position) then return end
    local preceding=before:sub(1,position-1)
    local line=preceding:match("([^\n]*)$")
    local plain=line:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
    local indent,content=plain:match("^([ \t]*)%-[ \t]+(.*)$")
    if not indent then return end
    if content:match("^%s*$") then
        -- A second Enter finishes the list. Keep any color escapes balanced.
        local retained={}
        for _,part in ipairs(tokens(line)) do
            if part.text=="|r" or part.text:match("^|c%x%x%x%x%x%x%x%x$") then retained[#retained+1]=part.text end
        end
        local escapes=table.concat(retained)
        local prefix=preceding:sub(1,#preceding-#line)..escapes
        return prefix..before:sub(position),#prefix
    end
    local prefix=after:sub(1,position)..indent.."- "
    return prefix..after:sub(position+1),#prefix
end
