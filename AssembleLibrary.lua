--[[
Lua Library Assembler

Attempts to consolidate the many files of a Lua library into a single Lua file.

This works by replacing the Lua library searcher function in package.loaders
with a proxy function. This pretty much does the same thing as the former,
except it also reads the contents of a found file, which gets added to the
assembled file.

This module sets up the searcher function, and returns a function that, when
called with a file name as an argument, allows the assembled content to be
written to the given file. So, the general prodecure for assembling a library
is to require the assembler, require the library you wish to assemble, then
call the assembler with the file to output to. Example:

    require 'AssembleLibrary'

    -- do stuff normally
    require 'library'
    -- etc

    require 'AssembleLibrary' ("library-assembled.lua")

A second argument to the assembler function specifies the root library, which
allows the assembled file to be used as a library itself. If no second
argument is given, the name of the first library that was required will be
used.

If a library happens to load dependencies only when needed, then you will have
to use it in whatever way necessary to make sure they are loaded. If the
library comes with a unit test, that should do the job.


]]

local firstLib
local assembledFile = [==[
local loaderEnv = {}
for k,v in pairs(_G) do loaderEnv[k] = v end

local Libraries = {}
table.insert(loaderEnv.package.loaders,1,function(name)
	if Libraries[name] then
		return Libraries[name]
	else
		return "\n\tno module '"..name.."'"
	end
end)

function loader(name,func)
	setfenv(func,loaderEnv)
	Libraries[name] = func
end

----------------------------------------------------------------
----------------------------------------------------------------
----------------------------------------------------------------
----------------------------------------------------------------

]==]

local moduleWrapper =
[==[loader(%q,function(...)
%s
end)

]==]

local loadedModules = {}
local function appendModuleContent(name,content)
	if not firstLib then
		firstLib = name
	end
	if not loadedModules[name] then
		assembledFile = assembledFile .. string.format(moduleWrapper,name,content)
		loadedModules[name] = true
	end
end

do	-- replace lua library searcher
	local DIR_SEP = package.config:sub(1,1)
	local TEMPLATE_SEP = package.config:sub(3,3)
	local SUBST = package.config:sub(5,5)
	package.loaders[2] = function(name)
		local err_msg = ""
		local loader
		local name_path = name:gsub('%.',DIR_SEP)
		for path in package.path:gmatch("[^"..TEMPLATE_SEP.."]+") do
			path = path:gsub(SUBST,name_path)
			local file = io.open(path,'r')
			if file then
				local content = file:read('*a')
				appendModuleContent(name,content)
				file:close()
				loader,err = loadstring(content)
				if not loader then
					-- fake a syntax error
					-- note that stack trace will not be fooled
					loader = function()
						error(path..":"..err:match("^%[.-%](.*)$"),0)
					end
				end
			else
				err_msg = err_msg .. "\n\tno file '"..path.."'"
			end
		end
		return loader or err_msg
	end
end

return function(filename,rootLib)
	rootLib = rootLib or firstLib
	local file = io.open(filename,'w')
	if file then
		file:write(assembledFile)
		file:write(string.format("return Libraries[%q](%q)\n",rootLib,rootLib))
		file:flush()
		file:close()
	end
end
