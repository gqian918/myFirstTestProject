------------------------------------------------------
--	Author: 	Guo Qian
--	Date: 		18 March 2013 (Monday)
--	copyright: 	@2013 GamEver
------------------------------------------------------


local modifiedFiles = {}

function CheckModifiedFiles()
	os.execute("git diff " .. arg[1] .. " > diff.info")
	local fileCounter = 1
	for fileLine in io.lines("diff.info") do
		--[[ 
		if there are different files, the output text must be "diff --git a/filename b/filename"
		so the pattern is " --git a/"
		PS: I don't know why string.find can NOT find "diff --git" 
		--]]
		if string.find(fileLine, ' --git a/') then 
			local startPos, endPos = string.find(fileLine, "a/.*%s")
			startPos = startPos + 2 -- ignore 'a/'
			local fileName = string.sub(fileLine, startPos, endPos)
			local fileInfo = {}
			fileInfo.name = fileName
			modifiedFiles[fileCounter] = fileInfo
			fileCounter = fileCounter + 1
		end
	end

end

function CreateModifiedFileList(filename)
	file = io.open(filename, 'w+')
	file:write("modifiedFiles = {\n")

	for k, v in pairs(modifiedFiles) do
		file:write("\t['" .. k .. "'] = {\n")
		file:write("\t\tname = " .. v.name .. ",\n")
		file:write("\t},\n")
	end
	file:write("}\n")
	file:close()
end

CheckModifiedFiles()
CreateModifiedFileList("ModifiedFileList.lua")
os.execute("rm diff.info")