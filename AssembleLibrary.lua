--[[
Lua Library Assembler

Attempts to gather dependent Lua libraries into a single Lua file.

This works by replacing the Lua library searcher function in package.loaders
with a proxy function. This pretty much does the same thing as the former,
except it also reads the contents of a found file, which gets added to the
assembled file.

This returns a function that, when called with a file name as an argument,
allows the assembled content to be written to the given file. So, the general
prodecure for assembling a library is to require the assembler, with an output
filename, then require the library you wish to assemble. Example:

    require 'AssembleLibrary' "library-assembled.lua"
    -- do stuff normally
    require 'library'
    -- etc

If a library happens to load dependencies only when needed, then you will have
to use it in whatever way necessary to make sure they are loaded. If the
library comes with a unit test, that should do the job.

]]

local outputFile = nil
local assembledFile = [==[
local loaderEnv = {}
for k,v in pairs(_G) do loaderEnv[k] = v end

local LuaLibraries = {}
table.insert(loaderEnv.package.loaders,1,function(name)
	if LuaLibraries[name] then
		return LuaLibraries[name]
	else
		return "\n\tno module '"..name.."'"
	end
end)

function loader(name,func)
	setfenv(func,loaderEnv)
	LuaLibraries[name] = func
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
	if not loadedModules[name] then
		local wrapper = string.format(moduleWrapper,name,content)
		if outputFile then
			outputFile:write(wrapper)
			outputFile:flush()
		else
			-- do this in case the user chooses not to call the assemble function immediately
			assembledFile = assembledFile .. wrapper
		end
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

return function(filename)
	if not outputFile then
		outputFile = io.open(filename,'w')
		if outputFile then
			outputFile:write(assembledFile)
			outputFile:flush()
		end
	end
end
