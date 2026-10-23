local _, app = ...
local L = app.L
-- Undo is session-local; only pages and options are persisted in SavedVariables.
local journal, snapshots = {}, {}
app.journal = journal

function journal:Load(database)
    self.data = database
    database.pages = database.pages or {{name = L["Notes"], body = ""}}
    if #database.pages == 0 then database.pages[1] = {name = L["Notes"], body = ""} end
    database.options = database.options or {}
    local defaults = {opacity = 0.9, scale = 1, minimap = true, autoHide = false, style = "flat", locked = false, minimizedIcon = true}
    for key, value in pairs(defaults) do
        if database.options[key] == nil then database.options[key] = value end
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
    if #self.data.pages == 1 then
        self.data.pages[1] = {name = L["Notes"], body = "", open = true}
        self.data.selected = 1
        self.data.tabOrder={1}
        return
    end
    local slot=self:TabPosition(index)
    table.remove(self.data.pages, index)
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
