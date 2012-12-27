--[[
Lua Library Assembler

Attempts to consolidate the many files of a Lua library into a single Lua file.

Usage:
    require 'AssembleLibrary'

    -- do stuff normally
    require 'library'
    -- etc

    require 'AssembleLibrary' ()
    -- outputs to 'library.lua' with 'library' as root

Specify root library:

    require 'AssembleLibrary' ('library.sublib.subfunc')

Specify exact name of output file:

    require 'AssembleLibrary' (nil, 'library.lua')

Specify both:

    require 'AssembleLibrary' ('library.sublib.subfunc', 'library.lua')

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

return function(rootLib,fileName)
	rootLib = rootLib or firstLib
	fileName = fileName or (rootLib .. '.lua')
	local file = io.open(fileName,'w')
	if file then
		file:write(assembledFile)
		file:write(string.format("return Libraries[%q](%q)\n",rootLib,rootLib))
		file:flush()
		file:close()
	end
end
