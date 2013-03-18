------------------------------------------------------
--	Author: 	Guo Qian
--	Date: 		18 March 2013 (Monday)
--	copyright: 	@2013 GamEver
------------------------------------------------------
--require "lfs"

local ignoreFileList = {
	"CreateModifiedFileList.lua",
	"CreateModifiedFileList.sh",
	"CreateOriginalFileList.lua",
	"CreateOriginalFileList.sh",
	".",
	"..",
	".git"
}

local acceptableFileType = {
'.ttf',
'.rys',
'.mp3',
'.mp4',
'.wav',
'.png',
'.ryk',
'.cnryn',
'.enryn',
'.zhryn',
'.rysid',
'.lua'
}

local originalFileList = {}

local lfs = require "lfs"

function TraverseAllFiles(path)
	local fullPath
	for item in lfs.dir(path) do 
		--print("heihei: " .. item)
		if not IsFileInIgnoreList(item) then
			fullPath = path .. "/" .. item
			local itemType = lfs.attributes(fullPath, "mode")
			if itemType == "directory" then 
				TraverseAllFiles(fullPath)
			elseif itemType == "file" then
				if IsAcceptableFile(item) then
					print("item: " .. fullPath)
					local fileInfo = {}
					fileInfo.a = 1
					fileInfo.b = 2
					originalFileList[fullPath] = fileInfo
				end
			end
		end
	end
end

function IsFileInIgnoreList(fileName)
	for k, v in pairs(ignoreFileList) do
		if v == fileName then
			return true
		end
	end

	return false
end

function IsAcceptableFile(fileName)
	for k, v in pairs(acceptableFileType) do
		if string.find(fileName, v) then
			return true
		end
	end
	return false
end

function CreateOriginalFileList(filename)
	file = io.open(filename, 'w+')
	file:write("originalFileList = {\n")

	for k, v in pairs(originalFileList) do
		file:write("\t['" .. k .. "'] = {\n")
		file:write("\t\tname = " .. v.a .. ",\n")
		file:write("\t},\n")
	end
	file:write("}\n")
	file:close()
end

TraverseAllFiles(".")
CreateOriginalFileList("OriginalFileList.lua")


