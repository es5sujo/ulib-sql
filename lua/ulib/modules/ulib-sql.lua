--[[
	
	ULibSQL - by es5sujo (STEAM_0:0:38411376, spam_me@josu.se)
	
	A MySQL data provider for ULib (ver. 2.52+)
	Mostly based on the ULib file 'server/ucl.lua'
	
	Feel free to edit, develop and redistribute as long as you keep it for free and keep this comment
	
]]

if SERVER then
	ulibsql = {}
	
	-- Should ulibsql be activated?
	ulibsql.status = true
	
	-- Activate Transfer-mode? (Used for moving data into the DB the first time - then turn off)
	ulibsql.transfer = false
	
	-- MySQL database settings
	ulibsql.hostname = '127.0.0.1'
	ulibsql.username = 'root'
	ulibsql.password = ''
	ulibsql.database = ''
	ulibsql.port		= 3306
	
	-- Logging?
	ulibsql.log = false
	
	--------------------------------------------------------
	--													  --
	-- Don't edit below unless you know what you're doing --
	--													  --
	--------------------------------------------------------
	
	local ucl = ULib.ucl
	MsgN('[ULib-SQL] Module loaded!')
	
	require('mysqloo')
	
	local db = mysqloo.connect(ulibsql.hostname, ulibsql.username, ulibsql.password, ulibsql.database, ulibsql.port)
	
	function db:onConnected()
		logPrint('[ULib-SQL] Connected!')
		reloadGroups()
		reloadUsers()
	end
	
	function db:onConnectionFailed(err)
		logPrint('[ULib-SQL] Connection failed: ' .. err)
	end
	
	db:connect()
	
	if ulibsql.status or ulibsql.transfer then
		function ucl.saveGroups()
			local qs = [[INSERT INTO groups (`name`, `definition`) VALUES ('%s', '%s') ON DUPLICATE KEY UPDATE `definition` = VALUES(`definition`)]]
			
			for _, groupInfo in pairs(ucl.groups) do
				table.sort(groupInfo.allow)
				
				local group_name = _
				local group_data = ULib.makeKeyValues(groupInfo)
				
				local q = db:query(string.format(qs, group_name, group_data))
				
				function q:onSuccess(data)
					
				end
				
				function q:onError(err)
					logPrint('[Ulib-SQL] Query error: ' .. err)
				end
				
				q:start()
			end
			logPrint('[Ulib-SQL] Saved groups!')
			reloadGroups()
		end
		
		function ucl.saveUsers()
			local qs = [[INSERT INTO player_permissions (`steamid`, `content`, `group`) VALUES ('%s', '%s', '%s') ON DUPLICATE KEY UPDATE `content` = VALUES(`content`), `group` = VALUES(`group`)]]
		
			for _, userInfo in pairs(ucl.users) do
				table.sort(userInfo.allow)
				table.sort(userInfo.deny)
				
				local player_id = _
				local player_data = ULib.makeKeyValues(userInfo)
				local player_group = userInfo.group
				
				local q = db:query(string.format(qs, db:escape(player_id), db:escape(player_data), db:escape(player_group)))
				
				function q:onSuccess(data)
					
				end
				
				function q:onError(err)
					logPrint('[Ulib-SQL] Query error: ' .. err)
				end
				
				q:start()
			end
			logPrint('[Ulib-SQL] Saved users!')
			reloadUsers()
		end
		
		concommand.Add('libsql_save_groups', ucl.saveGroups)
		concommand.Add('libsql_save_users', ucl.saveUsers)
	end

	if not ulibsql.transfer then
		function reloadGroups()
			local needsBackup = false
			local err
			local qs = "SELECT `name`, `definition` FROM groups"
			local q = db:query(qs)
			
			ucl.groups = {}
			
			function q:onSuccess(data)
				if #data > 0 then
					for i = 1, #data do
						ucl.groups[data[i].name] = ULib.parseKeyValues(data[i].definition)
					end
					logPrint('[ULib-SQL] Loaded groups!')
				else
					logPrint('[ULib-SQL] Could not get groups from database...')
				end
				
				if not ucl.groups or not ucl.groups[ ULib.ACCESS_ALL ] then
					needsBackup = true
					-- Totally messed up! Clear it.
					local f = "addons/ulib/" .. ULib.UCL_GROUPS
					if not ULib.fileExists( f ) then
						Msg( "ULIB PANIC: groups.txt is corrupted and I can't find the default groups.txt file!!\n" )
					else
						local err2
						ucl.groups, err2 = ULib.parseKeyValues( ULib.removeCommentHeader( ULib.fileRead( f ), "/" ) )
						if not ucl.groups or not ucl.groups[ ULib.ACCESS_ALL ] then
							Msg( "ULIB PANIC: default groups.txt is corrupt!\n" )
							err = err2
						end
					end
					if ULib.fileExists( ULib.UCL_REGISTERED ) then
						ULib.fileDelete( ULib.UCL_REGISTERED ) -- Since we're regnerating we'll need to remove this
					end
					accessStrings = {}

				else
					-- Check to make sure it passes a basic validity test
					ucl.groups[ ULib.ACCESS_ALL ].inherit_from = nil -- Ensure this is the case
					for groupName, groupInfo in pairs( ucl.groups ) do
						if type( groupName ) ~= "string" then
							needsBackup = true
							ucl.groups[ groupName ] = nil
						else

							if type( groupInfo ) ~= "table" then
								needsBackup = true
								groupInfo = {}
								ucl.groups[ groupName ] = groupInfo
							end

							if type( groupInfo.allow ) ~= "table" then
								needsBackup = true
								groupInfo.allow = {}
							end

							local inherit_from = groupInfo.inherit_from
							if inherit_from and inherit_from ~= "" and not ucl.groups[ groupInfo.inherit_from ] then
								needsBackup = true
								groupInfo.inherit_from = nil
							end

							-- Check for cycles
							local group = ucl.groupInheritsFrom( groupName )
							while group do
								if group == groupName then
									needsBackup = true
									groupInfo.inherit_from = nil
								end
								group = ucl.groupInheritsFrom( group )
							end

							if groupName ~= ULib.ACCESS_ALL and not groupInfo.inherit_from or groupInfo.inherit_from == "" then
								groupInfo.inherit_from = ULib.ACCESS_ALL -- Clean :)
							end

							-- Lower case'ify
							for k, v in pairs( groupInfo.allow ) do
								if type( k ) == "string" and k:lower() ~= k then
									groupInfo.allow[ k:lower() ] = v
									groupInfo.allow[ k ] = nil
								else
									groupInfo.allow[ k ] = v
								end
							end
						end
					end
				end

				if needsBackup then
					Msg( "Groups file was not formatted correctly. Attempting to fix and backing up original\n" )
					if err then
						Msg( "Error while reading groups file was: " .. err .. "\n" )
					end
					Msg( "Original file was backed up to " .. ULib.backupFile( ULib.UCL_GROUPS ) .. "\n" )
					ucl.saveGroups()
				end
			end
			
			function q:onError(err)
				logPrint('[Ulib-SQL] Query error: ' .. err)
			end
			
			q:start()
			
		end

		function reloadUsers()
			local qs = "SELECT `steamid`, `content` FROM player_permissions"
			local q = db:query(qs)
			
			ucl.users = {}
			
			function q:onSuccess(data)
				if #data > 0 then
					for i = 1, #data do
						ucl.users[data[i].steamid] = ULib.parseKeyValues(data[i].content)
					end
					logPrint('[ULib-SQL] Loaded users!')
				else
					logPrint('[ULib-SQL] Could not get users from database...')
				end
				-- Check to make sure it passes a basic validity test
				if not ucl.users then
					needsBackup = true
					-- Totally messed up! Clear it.
					local f = "addons/ulib/" .. ULib.UCL_USERS
					if not ULib.fileExists( f ) then
						Msg( "ULIB PANIC: users.txt is corrupted and I can't find the default users.txt file!!\n" )
					else
						local err2
						ucl.users, err2 = ULib.parseKeyValues( ULib.removeCommentHeader( ULib.fileRead( f ), "/" ) )
						if not ucl.users then
							Msg( "ULIB PANIC: default users.txt is corrupt!\n" )
							err = err2
						end
					end
					if ULib.fileExists( ULib.UCL_REGISTERED ) then
						ULib.fileDelete( ULib.UCL_REGISTERED ) -- Since we're regnerating we'll need to remove this
					end
					accessStrings = {}

				else
					for id, userInfo in pairs( ucl.users ) do
						if type( id ) ~= "string" then
							needsBackup = true
							ucl.users[ id ] = nil
						else

							if type( userInfo ) ~= "table" then
								needsBackup = true
								userInfo = {}
								ucl.users[ id ] = userInfo
							end

							if type( userInfo.allow ) ~= "table" then
								needsBackup = true
								userInfo.allow = {}
							end

							if type( userInfo.deny ) ~= "table" then
								needsBackup = true
								userInfo.deny = {}
							end

							if userInfo.group and type( userInfo.group ) ~= "string" then
								needsBackup = true
								userInfo.group = nil
							end

							if userInfo.name and type( userInfo.name ) ~= "string" then
								needsBackup = true
								userInfo.name = nil
							end

							if userInfo.group == "" then userInfo.group = nil end -- Clean :)

							-- Lower case'ify
							for k, v in pairs( userInfo.allow ) do
								if type( k ) == "string" and k:lower() ~= k then
									userInfo.allow[ k:lower() ] = v
									userInfo.allow[ k ] = nil
								else
									userInfo.allow[ k ] = v
								end
							end

							for k, v in ipairs( userInfo.deny ) do
								if type( k ) == "string" and type( v ) == "string" then -- This isn't allowed here
									table.insert( userInfo.deny, k )
									userInfo.deny[ k ] = nil
								else
									userInfo.deny[ k ] = v
								end
							end
						end
					end
				end

				if needsBackup then
					Msg( "Users file was not formatted correctly. Attempting to fix and backing up original\n" )
					if err then
						Msg( "Error while reading groups file was: " .. err .. "\n" )
					end
					Msg( "Original file was backed up to " .. ULib.backupFile( ULib.UCL_USERS ) .. "\n" )
					ucl.saveUsers()
				end
			end
			
			function q:onError(err)
				logPrint('[Ulib-SQL] Query error: ' .. err)
			end
			
			q:start()
		end
		
		concommand.Add('libsql_reload_groups', reloadGroups)
		concommand.Add('libsql_reload_users', reloadUsers)
	end
	
	function logPrint(message)
		if ulibsql.log then
			MsgN(message)
		end
	end
end