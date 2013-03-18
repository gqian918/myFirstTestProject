------------------------------------------------------
--	Author: 	Guo Qian
--	Date: 		18 March 2013 (Monday)
--	copyright: 	@2013 GamEver
------------------------------------------------------

------------------------------- configuration --------------------------
dofile = function (n)
  local f, err = loadfile(n)
  if f then
  	return f(), err
  else
  	return nil, err
  end 
end

ext.dofile = function (n)
	ext.UpdateAutoUpdateFile(n, '', 0, 0)
	dofile(n)
end

function ext.getFontFile(fontName)
	return "sob/DroidSansFallback2.ttf"
end

function ext.http.requestDownload(varTable)
	
	ext.http.requestBasic({
		varTable[1],
		body = varTable.body,
		format = varTable.format,
		method = varTable.method,
		mode = 'download',
		timeout = varTable.timeout,
		localpath = varTable.localpath,
		header = {
			['User-Agent'] = 'Vulcan client',
			['Accept-Encoding'] = 'gzip',
		},
		callback = varTable.callback,
		progressCallback = varTable.progressCallback,
		authCallback = varTable.authCallback,
	})

end

math.randomseed(os.time())
ext.http.quest_index = math.random(10000)

function ext.http.request(varTable)

	local urlParam = ''
	local urlBody = varTable.body or ''
	local urlMethod = varTable.method or "get"
	
	if varTable.param ~= nil then
		local empty = true
		for k,v in pairs(varTable.param) do
			urlParam = urlParam..tostring(k)..'='..tostring(v)..'&'
			empty = false
		end
        print('http params : ', urlParam)
		if not empty then
			urlParam = ext.ENC2(urlParam)
			urlParam = 'data='..urlParam
		end
	end
	
	if urlMethod == "post" then
		urlBody = urlParam
		urlParam = ''
	end
	
	local questIndexString = ext.ENC2(tostring(ext.http.quest_index))
	ext.http.quest_index = ext.http.quest_index + 1
	local sig = varTable[1]..urlParam..ext.GetAKEY()..questIndexString..ext.GetUDID()
	sig = ext.ENC1(sig)

	local httpheader = {
		['User-Agent'] = 'Vulcan client',
		['Accept-Encoding'] = 'gzip',
		['requestindex'] = questIndexString,
		['Udid'] = ext.GetUDID(),
		['sig'] = sig,
		['Appid'] = ext.GetBundleIdentifier(),
		['resv'] = AutoUpdate.localVersion,
		['clientv'] = ext.GetAppVersion(),
		['Locale'] = ext.GetGameLocale(),
		['shiqu'] = ext.GetTimeZone(),
	}

	if varTable.header ~= nil then
		for k,v in pairs(varTable.header) do
			httpheader[k] = v
		end
	end

	ext.http.requestBasic({
		varTable[1],
		param = urlParam,
		body = urlBody,--varTable.body,
		format = varTable.format,
		method = varTable.method,
		mode = varTable.mode,
		timeout = varTable.timeout,
		localpath = varTable.localpath,
		header = httpheader,
		callback = varTable.callback,
		progressCallback = varTable.progressCallback,
		authCallback = varTable.authCallback,
	})

end

function ext.onAlertCanceled(tag)
	if tag == 1 then
		AutoUpdate.ipAddrAttempedTime = 0
		AutoUpdate.isDownloadFinish = true
	end
end

function ext.GetGameLocale()
	return ext.DeviceToGameLocale(ext.GetDeviceLanguage())
end

function ext.DeviceToGameLocale(str)
	print("current locales:"..str)
	if string.find(str, "en") == 1 then
		return "en"
	elseif string.find(str, "zh_Hans") == 1 then
		return "cn"
	elseif string.find(str, "zh_Hant") == 1 then
		return "zh"
	elseif string.find(str, "ja") == 1 then
		return "jp"
	elseif string.find(str, "de") == 1 then
		return "ger"
	elseif string.find(str, "fr") == 1 then
		return "fr"
	elseif string.find(str, "ko") == 1 then
		return "kr"
	elseif string.find(str, "it") == 1 then
		return "it"
	elseif string.find(str, "pt") == 1 then
		return "po"
	elseif string.find(str, "es") == 1 then
		return "sp"
	elseif string.find(str, "ru") == 1 then
		return "ru"
	else
		return "en"
	end
end

function ext.isLangFR()
	if ext.GetGameLocale() == "fr" then return true end
	return false
end

function ext.changeFontSize(oldSize, fontName)
	return oldSize
end

function ext.AdjustFontBaseLine(baseline, fontName)
	return baseline
end

---------------------------AutoUpdate logic-----------------------------
local ENABLE_AUTO_UPDATE = true

if not ENABLE_AUTO_UPDATE then
    ext.GetAppVersion = function()
        return '9.9.9'
    end
end


ext.RegisteFlashClass('FlashDownloading_t')
ext.RegisteFlashClass('FlashLogo_t')
function FlashDownloading_t:fscommand(cmd, arg)
	print(cmd)
	if cmd == 'ERROR_OK' then
		AutoUpdate.errorstr = nil
		AutoUpdate.showerror = false
		
		if AutoUpdate.localAppVersion < AutoUpdate.serverAppVersion then
			ext.http.openURL(AutoUpdate.appStoreUrl)
		end
		g_loadingBgInSplash:InvokeASCallback("_root", "lua2fs_closeErroHint")

	elseif cmd == 'STARTUPDATE' then
		AutoUpdate.canStartUpdate = true
		AutoUpdate:setState(AutoUpdate.stateCheckLocalFile)
	elseif cmd == 'ENDUPDATE' then	
		AutoUpdate.canEndUpdate = true
	end
end

function FlashLogo_t:fscommand(cmd, arg)
	print(cmd)
	if cmd == "FS_CMD_CHANGE_TO_LOADING" then
		AutoUpdate.m_logoShowEnd = true
		g_loadingBgInSplash:InvokeASCallback("_root", "lua2fs_enterLoading")
		AutoUpdate.m_logoFx = nil
	end
end

AutoUpdate = {
	inited = false,
	currentState = nil,
	fileCorrupted = false,
	totleTaskNum = -1,
	finishedTaskNum = 0,
	currentTaskPercent = 0,
	isDownloadFinish = true,
	errorstr = nil,
	showerror = false,
	localVersion = 0,
	serverVersion = 0,
	localAppVersion = 0,
	serverAppVersion = 0,
	url = '',
	appStoreUrl = '',
	m_logoFx = nil,
	m_logoShowEnd = false,

	isProgressBarVisible = false,
	needUpdate = false,
	canStartUpdate = false,
	canEndUpdate = false,
	--isDownloadAllowed = false,
	--structPrompt = {},


	statePlayVideo = {},
	stateCheckLocalFile = {},
	stateCheckConfig = {},
	stateCheckVersion = {},
	stateDownloadFilelist = {},
	stateDownloadNewFiles = {
		currentTask = nil,
	},
	stateWrongAppVersion = {},
	stateEnterGame = {},
	TOTAL_LOADING_FRAME = 60,
	m_current_loading_frame = 0,
	m_current_start_downloading = false
}

function AutoUpdate:setState(state)
	local AutoUpdate = AutoUpdate
	AutoUpdate.currentState = state
	if AutoUpdate.currentState.GainFocus ~= nil then
		AutoUpdate.currentState:GainFocus()
	end
end

function AutoUpdate.LoadText()
	if AutoUpdate.gameloader ~= nil then
		return
	end

	AutoUpdate.gameloader = LuaLoader:new()
	ext.dofile('ST.ryc')

	local textLoaded = false
	-- if GameSettingUserData then
	-- 	textLoaded = AutoUpdate.gameloader:LoadGameText(GameSettingUserData["Local"], {'menu'})
	-- end

	if not textLoaded then
		textLoaded = AutoUpdate.gameloader:LoadGameText(ext.GetGameLocale(), {'menu'})
	end

	if not textLoaded then
		AutoUpdate.gameloader:LoadGameText('en',{'menu'})
	end
end

function AutoUpdate.LoadFlash()
	if g_loadingBgInSplash ~= nil then
		return
	end

	g_loadingBgInSplash = FlashDownloading_t:new()
	g_loadingBgInSplash:Load("sob/loadingScreen.rys")
	local hint = AutoUpdate.gameloader:GetGameText('LC_MENU_LOADING_CONNECTING')
	g_loadingBgInSplash:InvokeASCallback("_root", "lua2fs_setLoadingString", hint)
	g_loadingBgInSplash:InvokeASCallback("_root", "loadingProcess", 1)
	print("LOADING LOADING SUCESSS~~~~~")
end

function AutoUpdate.LoadLogo()
   AutoUpdate.m_logoFx = FlashLogo_t:new()
   AutoUpdate.m_logoFx:Load("sob/Logo.rys")
   print("LOADING logo")
end

-----------------------------statePlayVideo-----------------------------

function AutoUpdate.statePlayVideo:GainFocus()
	self.dt = 0
	AutoUpdate.LoadLogo()
	self.m_current_loading_frame = 0
end

function AutoUpdate.statePlayVideo:Update(dt)
	if g_loadingBgInSplash == nil then
		AutoUpdate.LoadText()
		AutoUpdate.LoadFlash()
	end
end

-----------------------------stateCheckLocalFile-----------------------------

function AutoUpdate.stateCheckLocalFile:GainFocus()
	dofile('oo.ryc')
	AutoUpdate.localVersion = originfilelist.version
	ext.dofile('lff.ryc')

	local _,_,AppVer1,AppVer2,AppVer3 = string.find(ext.GetAppVersion(), '(%d+).(%d+).(%d+)')
	AutoUpdate.localAppVersion = tonumber(AppVer3) + 100*tonumber(AppVer2)+10000*tonumber(AppVer1)

	if localfilelist ~= nil and localfilelist.appversion ~= nil and localfilelist.appversion == AutoUpdate.localAppVersion then
		AutoUpdate.localVersion = localfilelist.version
		for k, v in pairs(localfilelist) do
			if type(v) == 'table' then
				local originfile = originfilelist[k]
				if originfile == nil then
					originfilelist[k] = {
						version = 0,
						serverversion = 0,
						crc = '',
					}
					originfile = originfilelist[k]
				end
				
				if v.version >= originfile.version then
					originfile.version = v.version
					originfile.serverversion = v.serverversion
					originfile.crc = v.crc	
					ext.UpdateAutoUpdateFile(k, v.crc, v.version, v.serverversion)
				end
			end
		end
	end
		localfilelist = nil
	
	for k, v in pairs(originfilelist) do
		if type(v) == 'table' then
			local crc = ext.crc32.crc32(k)
			if crc ~= v.crc then
				print('File:'..k..' crc check failed! '..crc..'/'..v.crc)
				v.version = 0
				AutoUpdate.fileCorrupted = true
			end
		end
	end
end

function AutoUpdate.stateCheckLocalFile:Update(dt)
    if not ENABLE_AUTO_UPDATE then
        AutoUpdate.fileCorrupted = false
        AutoUpdate.localVersion = 9999
	end

	AutoUpdate:setState(AutoUpdate.stateCheckConfig)
end
-----------------------------stateCheckConfig------------------------------
function AutoUpdate.stateCheckConfig:GainFocus()
	local AutoUpdate = AutoUpdate
	AutoUpdate.ipAddrAttempedTime = 0
	AutoUpdate.isDownloadFinish = true
	ext.DisableIdleTimer(true)
end

function AutoUpdate.stateCheckConfig:Update(dt)
	local destIpAddrPool = {"176.32.71.133"}
	--local destIpAddrPool = {"42.121.7.158"}

	if AutoUpdate.isDownloadFinish == true then
		AutoUpdate.isDownloadFinish = false
		local destIpAddr = destIpAddrPool[AutoUpdate.ipAddrAttempedTime + 1]
		print("AutoUpdate.ipAddrAttempedTime ", AutoUpdate.ipAddrAttempedTime )
		AutoUpdate.ipAddrAttempedTime = AutoUpdate.ipAddrAttempedTime + 1

		ext.http.request({"http://" .. destIpAddr .. ":9981/servers/update_addr",
			callback = function(statusCode, content, errstr)
						--print("content = ", content)
						print("errstr = ", errstr)
						print("statusCode = ", statusCode)
						AutoUpdate.isDownloadFinish = true
				   		if statusCode ~= 200 then
				   			if statusCode == 298 then
					   			AutoUpdate.isDownloadFinish = false
					   			ext.showAlert(content.error, 1)
				   			else
					   			if AutoUpdate.ipAddrAttempedTime == #destIpAddrPool then
					   				AutoUpdate.ipAddrAttempedTime = 0
					   				AutoUpdate.errorstr = AutoUpdate.gameloader:GetGameText('LC_MENU_SERVER_ERROR')--..'[1800]'
					   			end
					   		end	
				   		else
				   			AutoUpdate.url = content.update_server .. "/"
							AutoUpdate:setState(AutoUpdate.stateCheckVersion)
						end
			end
		})	
	end
end

-----------------------------stateCheckVersion-----------------------------

function AutoUpdate.stateCheckVersion:GainFocus()
	local AutoUpdate = AutoUpdate
	AutoUpdate.totleTaskNum = -1
	AutoUpdate.isDownloadFinish = true
	AutoUpdate.m_current_start_downloading = false
	--AutoUpdate.canStartUpdate = true
end

local urlAddrTable = {
         --TODO
	["com.gamever.ageofwars"] = "https://itunes.apple.com/app/id580495654",
	["com.gamever.ageofwars.deluxe"] = "https://itunes.apple.com/app/id597244475"
}

function AutoUpdate.stateCheckVersion:Update(dt)
	if AutoUpdate.isDownloadFinish then
		AutoUpdate.isDownloadFinish = false
		local fullUrlOfVer = AutoUpdate.url .. "ver.txt"

		ext.http.request({fullUrlOfVer,
			callback = function(statusCode, content, errstr)
				local AutoUpdate = AutoUpdate
				AutoUpdate.isDownloadFinish = true
				if errstr ~= nil then
					AutoUpdate.errorstr = AutoUpdate.gameloader:GetGameText('LC_MENU_CONNECTION_ERROR')..'['..statusCode..']'
					return
				end
				if statusCode ~= 200 then
					AutoUpdate.errorstr = AutoUpdate.gameloader:GetGameText('LC_MENU_SERVER_ERROR')--..'[1800]'
					return
				end
				local _,_,filetag,serverVersion,AppVer1,AppVer2,AppVer3 = string.find(content, '(%a+)\n(%d+)\n(%d+).(%d+).(%d+)')
				
				--print("GetDeluxeVersionString: ", ext.GetDeluxeVersionString())
				--if ext.GetBundleIdentifier() == "com.tap4fun.spartanwar.deluxe" then
				--	AutoUpdate.appStoreUrl = "https://itunes.apple.com/us/app/spartan-war-deluxe/id552663538?ls=1&mt=8"
				--if ext.GetBundleIdentifier() == "com.tap4fun.spartanwar.elite" then
				--	AutoUpdate.appStoreUrl = "https://itunes.apple.com/us/app/spartan-wars-elite-edition/id581641031?ls=1&mt=8"
				--else
				--	AutoUpdate.appStoreUrl = "https://itunes.apple.com/us/app/spartan-war-empire-of-honor/id553141004?ls=1&mt=8"
				--end

				AutoUpdate.appStoreUrl = urlAddrTable[ext.GetBundleIdentifier()]

				print("AutoUpdate.appStoreUrl: ", AutoUpdate.appStoreUrl)

				if filetag ~= 'tag' then
					AutoUpdate.errorstr = AutoUpdate.gameloader:GetGameText('LC_MENU_SERVER_ERROR')--..'[1801]'
					return
				end
				AutoUpdate.serverVersion = tonumber(serverVersion)
				AutoUpdate.serverAppVersion = tonumber(AppVer3) + 100*tonumber(AppVer2)+10000*tonumber(AppVer1)

				print("----------------------")
				print(AutoUpdate.localAppVersion)
				print(AutoUpdate.serverAppVersion)
				print(AutoUpdate.localVersion)
				print(AutoUpdate.serverVersion)
				print(tostring(AutoUpdate.fileCorrupted))
				if AutoUpdate.localAppVersion < AutoUpdate.serverAppVersion then
					AutoUpdate:setState(AutoUpdate.stateWrongAppVersion)
				elseif (AutoUpdate.localVersion < AutoUpdate.serverVersion) or AutoUpdate.fileCorrupted then
					AutoUpdate:setState(AutoUpdate.stateDownloadFilelist)
					AutoUpdate.needUpdate = true
					AutoUpdate.m_current_start_downloading = true
					print("goto downloading file list")
					--g_loadingBgInSplash:SetText("LC_MENU_CHECKINGFORNEW_CHAR", AutoUpdate.gameloader:GetGameText('LC_MENU_DOWNINGNEW_CHAR'))
				else
				    print("goto enterGame")
				    AutoUpdate.m_current_start_downloading = true
					AutoUpdate:setState(AutoUpdate.stateEnterGame)
				end
			end
		})
      end
end

-----------------------------stateWrongAppVersion-----------------------------

function AutoUpdate.stateWrongAppVersion:Update(dt)
	if not AutoUpdate.canStartUpdate then
		return
	end

	AutoUpdate.errorstr = AutoUpdate.gameloader:GetGameText("LC_MENU_NEW_VERSION")
end

-----------------------------stateDownloadFilelist-----------------------------

function AutoUpdate.stateDownloadFilelist:GainFocus()
	local AutoUpdate = AutoUpdate
	AutoUpdate.totleTaskNum = -1
	AutoUpdate.isDownloadFinish = true
end

function AutoUpdate.stateDownloadFilelist:Update(dt)
	if not AutoUpdate.canStartUpdate then
		return
	end

	local AutoUpdate = AutoUpdate
	
	if AutoUpdate.totleTaskNum == -1 then
		if AutoUpdate.isDownloadFinish then
			AutoUpdate.isDownloadFinish = false

			ext.http.requestDownload({AutoUpdate.url..'ff.ryc',
				localpath = 'ff.ryc',
				progressCallback = function(percent)
					print('ff.ryc percent:' .. percent)
				end,
				callback = function(statusCode, filename, errstr)
					local AutoUpdate = AutoUpdate
					AutoUpdate.isDownloadFinish = true
					if errstr ~= nil then
						AutoUpdate.errorstr = AutoUpdate.gameloader:GetGameText('LC_MENU_CONNECTION_ERROR')--..'['..statusCode..']'
						return
					end
					if statusCode ~= 200 then
						AutoUpdate.errorstr = AutoUpdate.gameloader:GetGameText('LC_MENU_SERVER_ERROR')--..'[1802]'
						return
					end
					if filename ~= nil then
						local ret, err = dofile(filename)
						if err then
							AutoUpdate.errorstr = AutoUpdate.gameloader:GetGameText('LC_MENU_SERVER_ERROR')--..'[1803]'
							return
						end

						if originfilelist == nil then
							AutoUpdate.errorstr = AutoUpdate.gameloader:GetGameText('LC_MENU_SERVER_ERROR')--..'[1804]'
							return
						end
						
						if filelist == nil then
							AutoUpdate.errorstr = AutoUpdate.gameloader:GetGameText('LC_MENU_SERVER_ERROR')--..'[1805]'
							return
						end
						
						AutoUpdate.serverVersion = filelist.version
						AutoUpdate.totleTaskNum = 0
						AutoUpdate.finishedTaskNum = 0
						local originfilelist = originfilelist
					
						for k, v in pairs(filelist) do
							if type(v) == 'table' then
								local originfile = originfilelist[k]
								if originfile == nil then
									originfilelist[k] = {
										version = 0,
										serverversion = 0,
										crc = '',
									}
									originfile = originfilelist[k]
								end
								
								if originfile.crc ~= v.crc then
									originfile.version = 0
								end
								
								originfile.crc = v.crc
								originfile.serverversion = v.serverversion
							end
						end
						filelist = nil
						
						
						for k, v in pairs(originfilelist) do
							if type(v) == 'table' then
								if ( v.serverversion > v.version ) then
										AutoUpdate.totleTaskNum = AutoUpdate.totleTaskNum + 1
									end
								end
							end
						
						print('-----------totleTaskNum:' .. AutoUpdate.totleTaskNum)
					end
				end
			})
		end
	else
		AutoUpdate:setState(AutoUpdate.stateDownloadNewFiles)
	end

end

-----------------------------stateDownloadNewFiles-----------------------------

function AutoUpdate.stateDownloadNewFiles:GainFocus()
	AutoUpdate.isDownloadFinish = true
	AutoUpdate.finishedTaskNum = 0
	--AutoUpdate.isDownloadAllowed = false

	--if ext.IsNetConnected() then
	--	if ext.IsReachableWifi() then 
	--		AutoUpdate.isDownloadAllowed = true
	--	else
	--		AutoUpdate:ShowPromptMenu("guagua", function() AutoUpdate.isDownloadAllowed = true end, nil)
	--	end
	--end
end

function AutoUpdate.stateDownloadNewFiles:Update(dt)
	if not AutoUpdate.isDownloadFinish then
		return
	end 
	
	--if not AutoUpdate.isDownloadAllowed then
	--	return 
	--end
	
	for k, v in pairs(originfilelist) do
		if type(v) == 'table' then
			if ( v.serverversion > v.version ) then
				self.currentTask = v
				AutoUpdate.isDownloadFinish = false
				
				ext.http.requestDownload({AutoUpdate.url..k,
					localpath = k,
					progressCallback = function(percent)
						AutoUpdate.currentTaskPercent = percent
					end,
					callback = function(statusCode, filename, errstr)
						local AutoUpdate = AutoUpdate
						local stateDownloadNewFiles = AutoUpdate.stateDownloadNewFiles
						AutoUpdate.isDownloadFinish = true
						AutoUpdate.currentTaskPercent = 0

						if errstr ~= nil then
							AutoUpdate.errorstr = AutoUpdate.gameloader:GetGameText('LC_MENU_CONNECTION_ERROR')--..'['..statusCode..']'
							return
						end
						if statusCode ~= 200 then
							AutoUpdate.errorstr = AutoUpdate.gameloader:GetGameText('LC_MENU_SERVER_ERROR')--..'[1806]'
							return
						end
						if filename ~= nil then
							local crcresult = ext.crc32.crc32(filename)
							print('crcresult:'..crcresult)
							local currentTask = stateDownloadNewFiles.currentTask
							if crcresult ~= currentTask.crc then
								AutoUpdate.errorstr = AutoUpdate.gameloader:GetGameText('LC_MENU_CRC_ERROR')
								return
							else
								currentTask.version = currentTask.serverversion
								AutoUpdate.finishedTaskNum = AutoUpdate.finishedTaskNum + 1
								print('file:'..filename..' updated to version:'..currentTask.serverversion)
								ext.UpdateAutoUpdateFile(filename, currentTask.crc, currentTask.version, currentTask.serverversion)
								ext.SaveFileTable('lff.ryc', AutoUpdate.localVersion, AutoUpdate.localAppVersion)
							end
						end
					end
				})
	
				return
			end
		end
	end
	
	AutoUpdate.localVersion = AutoUpdate.serverVersion
	ext.SaveFileTable('lff.ryc', AutoUpdate.localVersion, AutoUpdate.localAppVersion)
	AutoUpdate.fileCorrupted = false
	AutoUpdate:setState(AutoUpdate.stateEnterGame)
end

-----------------------------stateEnterGame-----------------------------

function AutoUpdate.stateEnterGame:GainFocus()
	if g_loadingBgInSplash ~= nil then
		   local hint = AutoUpdate.gameloader:GetGameText('LC_MENU_LOADING_ENTERING')
		   g_loadingBgInSplash:InvokeASCallback("_root", "lua2fs_setLoadingString", hint)--TODO XLS
	       AutoUpdate.canEndUpdate = true
		--g_loadingBgInSplash:InvokeASCallback("_root", "finish")
	end
	ext.DisableIdleTimer(false)
end

function AutoUpdate.stateEnterGame:Update(dt)
	--if (not AutoUpdate.needUpdate or AutoUpdate.canEndUpdate) and ext.video.isMovieFinished() then
	if AutoUpdate.canEndUpdate and AutoUpdate.m_current_loading_frame == AutoUpdate.TOTAL_LOADING_FRAME then
		AutoUpdate.gameloader = nil
	    if g_loadingBgInSplash then
			g_loadingBgInSplash:clearFonts()
		end
		dofile('GameEngineUpdate.ryc')
	end
end

------------------------------------------------------------------------

function AutoUpdate:Update(dt)
	if self.inited == false then
		self.inited = true
			AutoUpdate:setState(AutoUpdate.statePlayVideo)
		return
	end
	
	if g_loadingBgInSplash ~= nil then
		if self.errorstr ~= nil then
			if not self.showerror then
				self.showerror = true
				--g_loadingBgInSplash:SetText("SC_NET_ERROR_INFO", self.errorstr)
				g_loadingBgInSplash:InvokeASCallback("_root", "lua2fs_showErroHint", self.errorstr)
				print("update error:"..self.errorstr)
			end
			return
		end
	
		if AutoUpdate.m_current_start_downloading then
			if self.totleTaskNum ~= -1 then
				--local files = AutoUpdate.gameloader:GetGameText('LC_MENU_FILES_CHAR')
				local files = ""
				local hint = AutoUpdate.gameloader:GetGameText('LC_MENU_LOADING_UPDATING')
				local present = math.ceil(self.finishedTaskNum/self.totleTaskNum * 100) 
				files = hint.." "..present.. "%"
				--g_loadingBgInSplash:SetText("LC_MENU_FILES_CHAR", files)
				--g_loadingBgInSplash:SetText("SC_NET_PERCENT", tostring(math.floor(self.currentTaskPercent))..'%')
				g_loadingBgInSplash:InvokeASCallback("_root", "lua2fs_setLoadingString", files)
				--g_loadingBgInSplash:InvokeASCallback("_root", "loadingProcess", self.currentTaskPercent)
				print("file down self.currentTaskPercent:"..self.currentTaskPercent)
				self.m_current_loading_frame = math.floor(self.finishedTaskNum/self.totleTaskNum * self.TOTAL_LOADING_FRAME)
			else
				self.m_current_loading_frame = self.m_current_loading_frame + 1
			end
			if self.m_current_loading_frame >= self.TOTAL_LOADING_FRAME then
				self.m_current_loading_frame = self.TOTAL_LOADING_FRAME
			end
			g_loadingBgInSplash:InvokeASCallback("_root", "loadingProcess", self.m_current_loading_frame)
		end
	end

	AutoUpdate.currentState:Update(dt)
end

-----------------------------Globa callback-----------------------------

function Update(dt)
	AutoUpdate:Update(dt)
	
	if g_loadingBgInSplash ~= nil and AutoUpdate.m_logoShowEnd then
		g_loadingBgInSplash:Update(dt)
	end

	if AutoUpdate.m_logoFx ~= nil and not AutoUpdate.m_logoShowEnd then
		AutoUpdate.m_logoFx:Update(dt)
	end
end

function Render()
	if g_loadingBgInSplash ~= nil and AutoUpdate.m_logoShowEnd then
		g_loadingBgInSplash:Render()	
	end

	if AutoUpdate.m_logoFx ~= nil and not AutoUpdate.m_logoShowEnd then
		AutoUpdate.m_logoFx:Render()
	end

	-- if AutoUpdate.needUpdate and AutoUpdate.isProgressBarVisible == false then
	-- 	AutoUpdate.isProgressBarVisible = true
	-- 	g_loadingBgInSplash:InvokeASCallback("_root", "showProgressBar", true)
	-- end
end

function OnTouchPressed(x,y)
	if g_loadingBgInSplash ~= nil then
		g_loadingBgInSplash:OnTouchPressed(x, y)
	end
end

function OnTouchMoved(x,y)
	if g_loadingBgInSplash ~= nil then
		g_loadingBgInSplash:OnTouchMoved(x, y)
	end
end

function OnTouchReleased(x,y)
	if g_loadingBgInSplash ~= nil then
		g_loadingBgInSplash:OnTouchReleased(x, y)
	end
end


function OnPause()
end

function OnResume()
end

function OnMultiTouchBegin(x1, y1, x2, y2)
end

function OnMultiTouchMove(x1, y1, x2, y2)
end

function OnMultiTouchEnd(x1, y1, x2, y2)
end

