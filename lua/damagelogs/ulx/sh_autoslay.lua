
local function CreateCommand()

	if not Damagelog.Enable_Autoslay then return end
	if not ulx then return end

	function ulx.autoslay(calling_ply, target, rounds, reason)
		Damagelog:AddSlays(calling_ply, target:SteamID(), rounds, reason, target)
	end

	function ulx.autoslayid(calling_ply, target, rounds, reason)
		if ULib.isValidSteamID(target) then
			for k,v in pairs(player.GetAll()) do
				if v:SteamID() == target then
					ulx.autoslay(calling_ply, v, rounds, reason)
					return
				end
			end
			Damagelog:AddSlays(calling_ply, target, rounds, reason, false)
		else
			ULib.tsayError(calling_ply, "Invalid steamid.", true)
		end
	end

	function ulx.removeautoslay(calling_ply, target, rounds)
		Damagelog:RemoveSlays(calling_ply, target:SteamID(), rounds, target)
	end

	function ulx.removeautoslayid(calling_ply, target, rounds, reason)
		if ULib.isValidSteamID(target) then
			for k,v in pairs(player.GetAll()) do
				if v:SteamID() == target then
					ulx.removeautoslay(calling_ply, v, rounds, reason)
					return
				end
			end
			Damagelog:RemoveSlays(calling_ply, target, rounds, reason, false)
		else
			ULib.tsayError(calling_ply, "Invalid steamid.", true)
		end
	end

	local autoslay = ulx.command("TTT", "ulx aslay", ulx.autoslay, "!aslay" )
	autoslay:addParam({ type=ULib.cmds.PlayerArg })
	autoslay:addParam({ 
		type=ULib.cmds.NumArg,
		min = 1,
		default = 1, 
		hint= "number of rounds", 
		ULib.cmds.optional, 
		ULib.cmds.round 
	})
	autoslay:addParam({ 
		type=ULib.cmds.StringArg, 
		hint="slay reason", 
		default = Damagelog.Autoslay_DefaultReason,
		ULib.cmds.optional,
		ULib.cmds.takeRestOfLine
	})
	autoslay:defaultAccess(ULib.ACCESS_ADMIN)
	autoslay:help("Slays the target for a specified number of rounds.")

	local autoslayid = ulx.command("TTT", "ulx aslayid", ulx.autoslayid, "!aslayid" )
	autoslayid:addParam({ 
		type=ULib.cmds.StringArg, 
		hint="steamid"
	})
	autoslayid:addParam({ 
		type=ULib.cmds.NumArg,
		min = 1,
		default = 1, 
		hint= "rounds", 
		ULib.cmds.optional, 
		ULib.cmds.round 
	})
	autoslayid:addParam({ 
		type=ULib.cmds.StringArg, 
		hint="slay reason", 
		default = Damagelog.Autoslay_DefaultReason,
		ULib.cmds.optional,
		ULib.cmds.takeRestOfLine
	})
	autoslayid:defaultAccess(ULib.ACCESS_ADMIN)
	autoslayid:help("Slays a steamid for a specified number of rounds.")

	local removeautoslay = ulx.command("TTT", "ulx raslay", ulx.removeautoslay, "!raslay" )
	removeautoslay:addParam({ type=ULib.cmds.PlayerArg })
	removeautoslay:addParam({ 
		type=ULib.cmds.NumArg,
		min = 1,
		default = 1, 
		hint= "number of rounds", 
		ULib.cmds.optional, 
		ULib.cmds.round 
	})
	removeautoslay:defaultAccess(ULib.ACCESS_ADMIN)
	removeautoslay:help("Remove slays from the target.")

	local removeautoslayid = ulx.command("TTT", "ulx raslayid", ulx.removeautoslayid, "!raslayid" )
	removeautoslayid:addParam({ 
		type=ULib.cmds.StringArg, 
		hint="steamid"
	})
	removeautoslayid:addParam({ 
		type=ULib.cmds.NumArg,
		min = 1,
		default = 1, 
		hint= "number of rounds", 
		ULib.cmds.optional, 
		ULib.cmds.round 
	})
	removeautoslayid:defaultAccess(ULib.ACCESS_ADMIN)
	removeautoslayid:help("Remove slays from the steamid.")
end
hook.Add("Initialize", "AutoSlay", CreateCommand)

if CLIENT then

	function Damagelog.SlayMessage()
		chat.AddText(Color(255,128,0), "[Autoslay] ", Color(255,128,64), net.ReadString())
	end
	net.Receive("DL_SlayMessage", Damagelog.SlayMessage)

	net.Receive("DL_AutoSlay", function()
		local ply = net.ReadEntity()
		local list = net.ReadString()
		local reason = net.ReadString()
		local _time = net.ReadString()
		local slays_left = net.ReadInt(32)
		if not IsValid(ply) or not list or not reason or not _time and not slays_left then return end
		local remaining = ""
		if slays_left == 1 then remaining = " One slay remaining." end
		if slays_left > 1 then remaining = " "..slays_left.." slays remaining." end
		chat.AddText(Color(255, 62, 62), ply:Nick(), color_white, " has been autoslain by ",  Color(98, 176, 255), list.." ", color_white, _time.." ago with the reason: '"..reason.."'."..remaining)

		if ply == LocalPlayer() then
			local frame = vgui.Create("DFrame")
			frame:SetSize(275, 170)
			frame:SetTitle(LocalPlayer():Nick().." is dead!"..remaining)
			frame:ShowCloseButton(false)
			frame:SetBackgroundBlur(true)
			frame:Center()

			local admin = vgui.Create("DLabel", frame)
			admin:SetText(list.." issued this slay ".._time.." ago:")
			-- admin:SetFGColor( Color(0,0,0) )
			admin:SizeToContents()
			admin:SetPos(10, 28)

			local reasonlabel = vgui.Create("DLabel", frame)
			reasonlabel:SetText(reason)
			-- reasonlabel:SetFGColor( Color(255,0,0) )
			reasonlabel:SetFGColor( Color(255,132,0) )
			reasonlabel:SetWidth(255)
			reasonlabel:SetWrap(true)
			reasonlabel:SetAutoStretchVertical(true)
			-- reasonlabel:SizeToContents()
			reasonlabel:SetPos(10, 44)

			local rulesbutton = vgui.Create("DButton", frame)
			rulesbutton:SetPos(5, 110)
			rulesbutton:SetSize(265, 25)	
			rulesbutton:SetText("Show me the rules.")
			rulesbutton.DoClick = function()
				MODERN.OpenMOTD( {} )
			end

			local rules_icon = vgui.Create("DImageButton", rulesbutton)
			rules_icon:SetPos(2, 5)
			rules_icon:SetMaterial("materials/icon16/book.png")
			rules_icon:SizeToContents()

			local closebutton = vgui.Create("DButton", frame)
			closebutton:SetPos(5, 140)
			closebutton:SetSize(265, 25)	
			closebutton:SetText("Please wait...")
			closebutton:SetDisabled(true)
			closebutton.DoClick = function()
				frame:Close()
			end

			local unlock = os.time() + 10
			closebutton.Think = function(self)
				if (self.NoWaitTime and LocalPlayer():CheckGroup( self.NoWaitTime )) or unlock <= os.time() then
					closebutton:SetText("I am sorry and I will obey the rules now.")
					closebutton:SetDisabled(false)
				else
					closebutton:SetText("Time to read: "..(unlock - os.time()))
					closebutton:SetDisabled(true)
				end
			end

			local close_icon = vgui.Create("DImageButton", closebutton)
			close_icon:SetPos(2, 5)
			close_icon:SetMaterial("materials/icon16/accept.png")
			close_icon:SizeToContents()

			frame:MakePopup()
		end
	end)
	
	net.Receive("DL_AutoSlaysLeft", function()
		local ply = net.ReadEntity()
		local slays = net.ReadUInt(32)
		if not IsValid(ply) or not slays then return end
		ply.AutoslaysLeft = slays
	end)
	
	net.Receive("DL_PlayerLeft", function()
		local nick = net.ReadString()
		local steamid = net.ReadString()
		local slays = net.ReadUInt(32)
		if not nick or not steamid or not slays then return end
		chat.AddText(Color(255,62,62), nick.."("..steamid..") has disconnected with "..slays.." autoslay"..(slays > 1 and "s" or "").." left!")
	end)
end
