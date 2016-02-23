--[[
    Resource finalization utility functions.
    
    Copyright (C) 2009, 2010 ePoint Systems Ltd
    Author: Rooslan S. Khayrov
    
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 2 of the License, or
    (at your option) any later version.
    
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
    
    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]--

module("epoint.scope", package.seeall)

function bracket(arg, final, action)
    local result = { pcall(action, arg) }
    pcall(final, arg)
    if not result[1] then
        error(unpack(result, 2))
    end
    return unpack(result, 2)
end

function with_file(handle, action)
    return bracket(handle, handle.close, action)
end
