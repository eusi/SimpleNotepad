local _, app = ...
local L = app.L
local journal, snapshots = {}, {}
app.journal = journal

function journal:Load(database)
    self.data = database
    database.pages = database.pages or {{name = L["Notes"], body = ""}}
    if #database.pages == 0 then database.pages[1] = {name = L["Notes"], body = ""} end
    database.options = database.options or {}
    local defaults = {opacity = 0.96, scale = 1, minimap = true, autoHide = false}
    for key, value in pairs(defaults) do
        if database.options[key] == nil then database.options[key] = value end
    end
    database.selected = math.max(1, math.min(database.selected or 1, #database.pages))
    for _, page in ipairs(database.pages) do
        if page.open == nil then page.open = true end
    end
    self:Current().open = true
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

function journal:Add()
    local pages = self.data.pages
    pages[#pages + 1] = {name = string.format(L["Note %d"], #pages + 1), body = "", open = true}
    self.data.selected = #pages
end

function journal:Select(index)
    self.data.selected = index
    self:Current().open = true
end

function journal:Close(index)
    local replacement
    for position, page in ipairs(self.data.pages) do
        if position ~= index and page.open then replacement = position; break end
    end
    if not replacement then return false end
    self.data.pages[index].open = false
    if self.data.selected == index then self.data.selected = replacement end
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
        return
    end
    table.remove(self.data.pages, index)
    if index < self.data.selected then self.data.selected = self.data.selected - 1 end
    self.data.selected = math.min(self.data.selected, #self.data.pages)
    self:Current().open = true
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
