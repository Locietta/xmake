--!A cross-platform build utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2018, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        mconfdialog.lua
--

-- load modules
local log          = require("ui/log")
local rect         = require("ui/rect")
local event        = require("ui/event")
local action       = require("ui/action")
local curses       = require("ui/curses")
local window       = require("ui/window")
local menuconf     = require("ui/menuconf")
local boxdialog    = require("ui/boxdialog")
local inputdialog  = require("ui/inputdialog")
local choicedialog = require("ui/choicedialog")

-- define module
local mconfdialog = mconfdialog or boxdialog()

-- init dialog
function mconfdialog:init(name, bounds, title)

    -- init window
    boxdialog.init(self, name, bounds, title)

    -- init text
    self:text():text_set([[Arrow keys navigate the menu. <Enter> selects submenus ---> (or empty submenus ----). 
Pressing <Y> includes, <N> excludes. Enter <Esc> to go back or exit, <?> for Help, </> for Search. Legend: [*] built-in  [ ] excluded
]])

    -- init buttons
    self:button_add("select", "< Select >", function (v, e) self:menuconf():event_on(event.command {"cm_enter"}) end)
    self:button_add("exit", "< Exit >", function (v, e) self:quit() end)
    self:button_add("help", "< Help >", function (v, e) end)
    self:button_add("save", "< Save >", function (v, e) self:action_on(action.ac_on_save) end)
    self:button_add("load", "< Load >", function (v, e) self:action_on(action.ac_on_load) end)
    self:buttons():select(self:button("select"))

    -- insert menu config
    self:box():panel():insert(self:menuconf())

    -- disable to select to box (disable Tab switch and only response to buttons)
    self:box():option_set("selectable", false)

    -- init input dialog
    local dialog_input = inputdialog:new("mconfdialog.input", rect {0, 0, math.min(80, self:width()), math.min(8, self:height())}, "input dialog")
    dialog_input:background_set(self:frame():background())
    dialog_input:frame():background_set("cyan")
    dialog_input:textedit():option_set("multiline", false)
    dialog_input:button_add("ok", "< Ok >", function (v) 
        local config = dialog_input:extra("config")
        if config.kind == "string" then
            config.value = dialog_input:textedit():text()
        elseif config.kind == "number" then
            local value = tonumber(dialog_input:textedit():text())
            if value ~= nil then
                config.value = value
            end
        end
        dialog_input:quit() 
    end)
    dialog_input:button_add("help", "< Help >", function (v) 
        -- TODO
    end)
    dialog_input:button_select("ok")

    -- init choice dialog
    local dialog_choice = choicedialog:new("mconfdialog.choice", rect {0, 0, math.min(80, self:width()), math.min(16, self:height())}, "input dialog")
    dialog_choice:background_set(self:frame():background())
    dialog_choice:frame():background_set("cyan")
    dialog_choice:box():frame():background_set("cyan")

    -- on selected
    self:menuconf():action_set(action.ac_on_selected, function (v, config)

        -- show input dialog
        if config.kind == "string" or config.kind == "number" then
            dialog_input:extra_set("config", config)
            dialog_input:title():text_set(config:prompt())
            dialog_input:textedit():text_set(tostring(config.value))
            if config.kind == "string" then
                dialog_input:text():text_set("Please enter a string value. Use the <TAB> key to move from the input fields to buttons below it.")
            else
                dialog_input:text():text_set("Please enter a decimal value. Fractions will not be accepted.  Use the <TAB> key to move from the input field to the buttons below it.")
            end
            self:insert(dialog_input, {centerx = true, centery = true})

        -- show choice dialog
        elseif config.kind == "choice" then
            dialog_choice:title():text_set(config:prompt())
            dialog_choice:choicebox():load(config.values, config.value)
            dialog_choice:choicebox():action_set(action.ac_on_selected, function (v, index, value)
                config.value = index
            end)
            self:insert(dialog_choice, {centerx = true, centery = true})
        end
    end)
end

-- get menu config
function mconfdialog:menuconf()
    if not self._MENUCONF then
        local bounds = self:box():panel():bounds()
        self._MENUCONF = menuconf:new("mconfdialog.menuconf", rect:new(math.floor(bounds:width() / 3), 0, bounds:width(), bounds:height()))
        self._MENUCONF:state_set("focused", true) -- we can select and highlight selected item
    end
    return self._MENUCONF
end

-- on event
function mconfdialog:event_on(e)

    -- load config first
    if e.type == event.ev_idle then
        if not self._LOADED then
            self:action_on(action.ac_on_load)
            self._LOADED = true
        end
    -- select config
    elseif e.type == event.ev_keyboard then
        if e.key_name == "Down" or e.key_name == "Up" or e.key_name == " " then
            return self:menuconf():event_on(e)
        end
    end
    return boxdialog.event_on(self, e) 
end

-- return module
return mconfdialog
