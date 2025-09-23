require("zxcmodule")

if not ded then return end

ded.Write = nil
ded.Read = nil

local pLocalPlayer = LocalPlayer()
local ScrW, ScrH = ScrW(), ScrH()
local TICK_INTERVAL = engine.TickInterval()

ded.SetInterpolation( false )
ded.SetSequenceInterpolation( false )

-- Settings

local Settings = {}

Settings.Aimbot = false
Settings.AimbotBind = 0
Settings.Autofire = false

Settings.Box = true
Settings.Name = true
Settings.Weapon = true
Settings.EyePos = true
Settings.OreStone = false
Settings.Cloth = false

Settings.RemoveSlowDown = true

-- Color

local Theme = {}

Theme.WaterMark     = Color( 155, 162, 255 )
Theme.C_Elements    = Color( 255, 255, 255 )

Theme.Box           = Color( 25, 129, 255 )
Theme.Name          = Color( 255, 255, 255 )
Theme.Weapon        = Color( 255, 255, 255 )
Theme.EyePos        = Color( 55, 155, 55 )

-- Font

surface.CreateFont( "hardluxe.main" , { font = "Verdana", size = 13, antialias = false, outline = true } )

-- Classes

local C_Elements = {}
local C_Visual = {}
local C_Hook = {}

local C_Math = {}

local function TIME_TO_TICKS( time )
    return math.floor( 0.5 + time / TICK_INTERVAL )
end

local Userinterface = {}
Userinterface.bShow = false
Userinterface.bWasDown = false
Userinterface.bIsClicked = false
Userinterface.bWasClicked = false
Userinterface.bIsDown = false

local C_Inputs = { x = 0, y = 0 }

function C_Inputs.InArea( x, y, w, h )
    w = x + w 
    h = y + h 

    return ( C_Inputs.x >= x and C_Inputs.x <= w and C_Inputs.y >= y and C_Inputs.y <= h )
end

function C_Inputs.IsKeysDown( Key )
    if Key >= 107 then
        return input.IsMouseDown( Key )
    end

    return ( input.IsKeyDown( Key ) )
end

local C_Trase = {}
C_Trase.Result = {}
C_Trase.Structure = { filter = pLocalPlayer, output = C_Trase.Result }

function C_Trase.TraceLine( start, endpos, filter, mask )
    C_Trase.Structure.start = start 
    C_Trase.Structure.endpos = endpos 

    if ( filter ) then
        C_Trase.Structure.filter = filter 
    end

    if ( mask ) then
        C_Trase.Structure.mask = mask 
    end

    util.TraceLine( C_Trase.Structure )

    return ( C_Trase.Result )
end
    
function C_Trase.TraceHull( start, endpos, mins, maxs, filter, mask )
    C_Trase.Structure.start = start 
    C_Trase.Structure.endpos = endpos 

    C_Trase.Structure.mins = mins 
    C_Trase.Structure.maxs = maxs 

    if ( filter ) then
        C_Trase.Structure.filter = filter 
    end

    if ( mask ) then
        C_Trase.Structure.mask = mask 
    end

    util.TraceHull( C_Trase.Structure )

    return ( C_Trase.Result )
end

function C_Trase.IsVisible( ply, pos, hitgroup )
    C_Trase.TraceLine( pLocalPlayer:GetShootPos(), pos, pLocalPlayer, MASK_SHOT )

    return ( C_Trase.Result.Entity == ply )
end

local C_Movement = {}
C_Movement.silentAngles = false 

function C_Movement.UpdateSilentAngles( usercmd )
    local mouseX, mouseY = usercmd:GetMouseX(), usercmd:GetMouseY()
    local yawSpeed, pitchSpeed = GetConVar( "m_yaw" ):GetFloat(), GetConVar( "m_pitch" ):GetFloat()

    if ( not C_Movement.silentAngles ) then
        C_Movement.silentAngles = usercmd:GetViewAngles()
    end

    C_Movement.silentAngles.x = math.Clamp( C_Movement.silentAngles.x + mouseY * pitchSpeed, -89, 89 )
    C_Movement.silentAngles.y = math.NormalizeAngle( C_Movement.silentAngles.y + mouseX * -yawSpeed )
    C_Movement.silentAngles.r = 0

    C_Movement.silentAngles:Normalize()

    usercmd:SetViewAngles( C_Movement.silentAngles )
end

function C_Movement.FixMovement( usercmd, wishYaw )
	local yawdiff = math.rad( -math.NormalizeAngle( ( usercmd:GetViewAngles().y - wishYaw ) ) )
	local forwardmove, sidemove = usercmd:GetForwardMove(), usercmd:GetSideMove()

	usercmd:SetForwardMove( forwardmove * math.cos( yawdiff ) + sidemove * math.sin( yawdiff ) )
	usercmd:SetSideMove( forwardmove * -math.sin( yawdiff ) + sidemove * math.cos( yawdiff ) )
end

local C_Aimbot = {}
C_Aimbot.NotPredictileWep = { ["rust_dbarrel"] = true, ["rust_spas12"] = true,["rust_waterpipe"] = true,["rust_pumpshotgun"] = true,["rust_pickaxe"] = true,["rust_hatchet"] = true,["rust_boneclub"] = true,["rust_combatknife"] = true,["rust_woodenspear"] = true,["rust_stonespear"] = true,["rust_stonepickaxe"] = true,["rust_stonehatchet"] = true,["rust_salvagedsword"] = true,["rust_salvagedcleaver"] = true,["rust_rock"] = true}

local C_Priority = {}

function C_Hook.Think()
   
    Userinterface.bIsDown = input.IsKeyDown( KEY_INSERT )

    if ( not Userinterface.bWasDown and Userinterface.bIsDown ) then
        Userinterface.bShow = not Userinterface.bShow
        gui.EnableScreenClicker( Userinterface.bShow )
    end

    Userinterface.bWasDown = Userinterface.bIsDown
    Userinterface.bIsDown = input.IsMouseDown( MOUSE_LEFT )
    Userinterface.bIsClicked = not Userinterface.bWasClicked and Userinterface.bIsDown
    Userinterface.bWasClicked = Userinterface.bIsDown
end

function C_Elements.CheckBox(x, y, vars)
    local state = isbool( Settings[ vars ] ) and ( Settings[ vars ] and "[True]" or "[False]") or Settings[ vars ]
    local str = string.format( "%s: %s", vars, state )  

    surface.SetTextPos( x, y )
    surface.DrawText( str )

    local tw, th = surface.GetTextSize( str )

    if ( C_Inputs.InArea( x, y, tw, th ) and ( Userinterface.bIsClicked ) ) then
        Settings[ vars ] = not Settings[ vars ]
    end
end

function C_Elements.Binder(x, y, vars)
    local key = input.GetKeyName( Settings[ vars ] ) or "None"

    local str = string.format( "%s: [%s]", vars, key )

    surface.SetTextPos( x, y )
    surface.DrawText( str )

    local tw, th = surface.GetTextSize( str )

    if ( C_Inputs.InArea( x, y, tw, th ) ) then
        if ( Userinterface.bIsDown ) then
            for key = 0, 256 do 
                if ( key == 107 ) then
                    continue
                end
                if ( key >= 107 ) then
                    if ( input.IsMouseDown( key ) ) then
                        Settings[ vars ] = key
                    end
                else
                    if ( input.IsKeyDown( key ) ) then
                        Settings[ vars ] = key
                    end
                end
            end
        end
    end
end

function C_Elements.ShowMenu()
    surface.SetTextColor( Theme.WaterMark )
    surface.SetFont( "hardluxe.main" )

    surface.SetTextPos( 8, 8 )
    surface.DrawText( "HardLuxe for GRust" )

    surface.SetTextColor( Theme.C_Elements )

    local y = 30

    C_Elements.CheckBox( 8, y, "Aimbot" )
        y = y + 14
    C_Elements.Binder( 8, y, "AimbotBind" )
        y = y + 14
    C_Elements.CheckBox( 8, y, "Autofire" )
        y = y + 14
    C_Elements.CheckBox( 8, y, "Box" )
        y = y + 14
    C_Elements.CheckBox( 8, y, "Name" )
        y = y + 14
    C_Elements.CheckBox( 8, y, "Weapon" )
        y = y + 14
    C_Elements.CheckBox( 8, y, "EyePos" )
        y = y + 14
    C_Elements.CheckBox( 8, y, "RemoveSlowDown" )
        y = y + 14
    C_Elements.CheckBox( 8, y, "OreStone" )
        y = y + 14
    C_Elements.CheckBox( 8, y, "Cloth" )
end

function C_Visual.GetEntityScreenBounds( entity )
    local vOrigin, vMins, vMaxs = entity:GetPos(), entity:OBBMins(), entity:OBBMaxs()
    vMins = vOrigin + vMins
    vMaxs = vOrigin + vMaxs

    local nMinX, nMinY, nMaxX, nMaxY = math.huge, math.huge, -1, -1

    local vectorTable = {
        Vector( vMins.x, vMins.y, vMins.z ),
        Vector( vMaxs.x, vMins.y, vMins.z ),
        Vector( vMins.x, vMaxs.y, vMins.z ),
        Vector( vMaxs.x, vMaxs.y, vMins.z ),
        Vector( vMins.x, vMins.y, vMaxs.z ),
        Vector( vMaxs.x, vMins.y, vMaxs.z ),
        Vector( vMins.x, vMaxs.y, vMaxs.z ),
        Vector( vMaxs.x, vMaxs.y, vMaxs.z )
    }

    for i = 1, 8 do
        local screenPos = vectorTable[ i ]:ToScreen()

        if ( not screenPos.visible ) then
            return false 
        end

        if ( screenPos.x < nMinX ) then
            nMinX = screenPos.x
        end

        if ( screenPos.y < nMinY ) then
            nMinY = screenPos.y
        end

        if ( screenPos.x > nMaxX ) then
            nMaxX = screenPos.x
        end

        if ( screenPos.y > nMaxY ) then
            nMaxY = screenPos.y
        end
    end

    if ( nMinX < 0 or nMaxX > ScrW or nMinY < 0 or nMinY > ScrH ) then
        return false 
    end

    return ( math.floor( nMinX ) ), ( math.floor( nMinY ) ), ( math.ceil( nMaxX ) ), ( math.ceil( nMaxY ) )
end

function C_Visual.PlayerESP( entity )

    local minX, minY, maxX, maxY = C_Visual.GetEntityScreenBounds( entity )

    if ( not minX ) then
        return 
    end

    if ( not entity:Alive() ) then
        return
    end
    
    if (entity == pLocalPlayer) then
        return
    end

    surface.SetAlphaMultiplier( entity:IsDormant() and 0.65 or 1 )

    local width, height = maxX - minX, maxY - minY 

    if ( Settings.Box ) then
        surface.SetDrawColor( 0, 0, 0, 255 )
        surface.DrawOutlinedRect( minX + 1, minY + 1, width, height )
        surface.SetDrawColor( Theme.Box )
        surface.DrawOutlinedRect( minX, minY, width, height )
    end

    surface.SetFont( "hardluxe.main" )

    if ( Settings.Name ) then
        local str = entity:Name()
        local textWidth, textHeight = surface.GetTextSize( str )
        surface.SetTextColor( Theme.Name )
        surface.SetTextPos( minX + ( width - textWidth ) * 0.5, minY - 16 )
        surface.DrawText( str )
    end

    if ( Settings.Weapon ) then
        local weapon = entity:GetActiveWeapon()

        if ( IsValid( weapon ) ) then
            local str = weapon:GetClass()
            local textWidth, textHeight = surface.GetTextSize( str )
            surface.SetTextColor( Theme.Weapon )
            surface.SetTextPos( minX + ( width - textWidth ) * 0.5, maxY )
            surface.DrawText( str )
        end
    end
end

function C_Visual.PlayerESP3D( entity )
    local shootpos = entity:GetShootPos()

    if ( not entity:Alive() ) then
        return
    end

    if (entity == pLocalPlayer) then
        return
    end

    if ( Settings.EyePos ) then
        local EyeTrace = entity:GetEyeTrace()
        local StartPos, HitPos = EyeTrace.StartPos, EyeTrace.HitPos

        render.DrawLine( StartPos, HitPos, Theme.EyePos, true )
    end
end

function C_Visual.EntityESP( entity )

    local class = entity:GetClass()

    if ( class == "rust_ore" and entity:GetSkin() == 0 and Settings.OreStone ) then
        local pos = entity:GetPos():ToScreen()
        surface.SetTextPos( pos.x, pos.y )
        surface.DrawText( "Stone" )
    end

    if ( class == "rust_hemp" and Settings.Cloth ) then
        local pos = entity:GetPos():ToScreen()
        surface.SetTextPos( pos.x, pos.y )
        surface.DrawText( "Cloth" )
    end
end

function C_Hook.DrawOverlay()

    C_Inputs.x, C_Inputs.y = input.GetCursorPos()

    local playerlist = player.GetAll()
    local entities = ents.GetAll()

    cam.Start2D()

        C_Elements.ShowMenu()

        for i = 1, #playerlist do
            local player = playerlist[ i ]
            C_Visual.PlayerESP( player )
        end
            
        for i = 1, #entities do
            local entity = entities[ i ]
            C_Visual.EntityESP( entity )
        end
    cam.End2D()

    cam.Start3D()
        for i = 1, #playerlist do
            local  player = playerlist[ i ]
            C_Visual.PlayerESP3D( player )
        end
    cam.End3D()

end

function C_Aimbot.GetSortedPlayers()
    local sorted = {}

    local playerlist = player.GetAll()

    for i = 1, #playerlist do
        local ply = playerlist[ i ]

        if ( ply == pLocalPlayer ) then
            continue 
        end

        if ( not ply:Alive() ) then
            continue 
        end 

        if ( ply:IsDormant() ) then
            continue  
        end

        if ( C_Priority[ply:UserID()] == "ignore" ) then 
            continue
        end

        sorted[ #sorted + 1 ] = ply 
    end

    return sorted
end

function C_Aimbot.GetAimPos(ply, visibleCheck)
    local hitboxCount = ply:GetHitBoxCount( 0 )

    for hitboxIndex = 0, hitboxCount - 1 do
        local hitboxHitgroup = ply:GetHitBoxHitGroup( hitboxIndex, 0 )
        local hitgroupIndex = hitboxHitgroup

        if ( hitgroupIndex ~= 2 ) then
            continue
        end
        
        local hitboxBone = ply:GetHitBoxBone( hitboxIndex, 0 )

        if ( not hitboxBone ) then
            continue
        end

        local boneMatrix = ply:GetBoneMatrix( hitboxBone )

        if ( not boneMatrix ) then
            continue
        end

        local bonePos, boneAng = boneMatrix:GetTranslation(), boneMatrix:GetAngles()
 
        if ( visibleCheck ) then
            if ( C_Trase.IsVisible( ply, bonePos, hitboxHitgroup ) ) then
                return ( bonePos ), ( boneAng )
            end
            continue
        end

        return ( bonePos ), ( boneAng )
    end
end

function C_Aimbot.GetBestTarget()
    local bestPosition
    local bestTarget = false 
    local playerlist = C_Aimbot.GetSortedPlayers()
    local dist
    for i = 1, #playerlist do
        local ply = playerlist[i] 
        local pos, ang = C_Aimbot.GetAimPos(ply, true)

        if ( not pos ) then
            continue 
        end

        local scrPos = pos:ToScreen()  
        
        do
            local dx = ScrW / 2 - scrPos.x
            local dy = ScrH / 2 - scrPos.y
            dist = dx * dx + dy * dy
        end

        if ( not bestTarget or dist < bestDist ) then
            bestTarget = ply
            bestPosition = pos
            bestDist = dist  
        end
    end

    return ( bestTarget ), ( bestPosition )
end

function C_Aimbot.RecoilControle( ang )
    ang = ang - pLocalPlayer:GetViewPunchAngles() 
	return ang
end

function C_Aimbot.RunAimbot( usercmd )
    local activeWeapon = pLocalPlayer:GetActiveWeapon()
    if ( not IsValid( activeWeapon ) ) then
        return 
    end

    if ( not Settings.Aimbot ) then 
        return 
    end

    if ( Settings.AimbotBind ~= 0 and not C_Inputs.IsKeysDown( Settings.AimbotBind ) ) then 
        return 
    end

    local aimTarget, aimPos = C_Aimbot.GetBestTarget()
    local aimAngle

    if ( IsValid( aimTarget ) ) then

        ded.NetSetConVar( "cl_interp", "0" )
        ded.NetSetConVar( "cl_interpolate", "0" )
        ded.SetCommandTick( usercmd, TIME_TO_TICKS( ded.GetSimulationTime( aimTarget:EntIndex() ) ) )


        if ( C_Aimbot.NotPredictileWep[ activeWeapon:GetClass() ] ) then 
            aimPos = aimPos
        else
            local Velocity = 5000
            local Distance = pLocalPlayer:GetShootPos():Distance( aimPos )
            if ( string.StartsWith( activeWeapon:GetClass(), "rust_huntingbow") ) then
                Velocity = 4000 - ( 0.65 * Distance ) -- $_$
            elseif ( string.StartsWith( activeWeapon:GetClass(), "rust_assaultrifle" ) or string.StartsWith( activeWeapon:GetClass(), "rust_boltrifle" ) ) then
                Velocity = 10000
            elseif ( string.StartsWith( activeWeapon:GetClass(), "rust_revolver" ) ) then
                Velocity = 4000 
            elseif ( string.StartsWith( activeWeapon:GetClass(), "rust_nailgun" ) ) then 
                Velocity = 2500
            end

            if ( Distance < 80 ) then return end

            local TravelTime = Distance / Velocity
            local PredTime = ( ded.GetLatency( 0 ) + ded.GetLatency( 1 ) ) + TravelTime 

            if PredTime > 1 then return end

            ded.StartSimulation( aimTarget:EntIndex() )
                for i = 1, TIME_TO_TICKS( PredTime ) do
                    ded.SimulateTick()
                end
                local ModuleData = ded.GetSimulationData()
                aimPos = ModuleData.m_vecAbsOrigin + ( aimPos  - aimTarget:GetPos() )
            ded.FinishSimulation()

            Distance = pLocalPlayer:GetShootPos():Distance( aimPos )
            TravelTime = Distance / Velocity

            local Gravity =  (9.81 * 51.4285714 ) * (TravelTime^2) / 2
            aimPos.z = aimPos.z + Gravity

            C_Trase.Structure.start = pLocalPlayer:GetShootPos() 
            C_Trase.Structure.endpos = aimPos
            C_Trase.Structure.filter = pLocalPlayer 
            C_Trase.Structure.mask = MASK_SHOT 
        
            local Trace = util.TraceLine( C_Trase.Structure )

            if ( Trace.Hit and not Trace.Entity:IsPlayer() ) then return end
        end

        debugoverlay.Cross( aimPos, 3, 0.1, color_white, true )

        aimAngle = ( Vector( aimPos )  - pLocalPlayer:GetShootPos() ):Angle()
        aimAngle = C_Aimbot.RecoilControle( aimAngle )

        aimAngle:Normalize()
        
        if ( Settings.Autofire ) then
            usercmd:AddKey( IN_ATTACK )
        end
   
        usercmd:SetViewAngles( aimAngle )
    end
end

function C_Movement.RunMovement( usercmd )
    local moveType = pLocalPlayer:GetMoveType()

    if ( moveType ~= MOVETYPE_WALK ) then
        return 
    end

    if ( Settings.RemoveSlowDown ) then
        usercmd:RemoveKey( bit.bor( IN_MOVELEFT, IN_MOVERIGHT, IN_FORWARD, IN_BACK ) )
    end
end


function C_Hook.CreateMove( usercmd )
    C_Movement.UpdateSilentAngles( usercmd )

    if Userinterface.bShow then
        usercmd:ClearMovement()
        usercmd:ClearButtons()
    end

    if usercmd:CommandNumber() == 0 then return end 

    if ( pLocalPlayer:Alive() ) then

        C_Movement.RunMovement( usercmd )

	    ded.StartPrediction( usercmd )
            C_Aimbot.RunAimbot( usercmd )
            C_Movement.FixMovement( usercmd, C_Movement.silentAngles.y )
        ded.FinishPrediction() 
    end
end

local cameraOrigin, cameraAngles
function C_Hook.CalcView( ply, origin, angles, fov, znear, zfar )
    local camera = {
        origin = origin,
        angles = angles,
        angles = C_Movement.silentAngles
    }

    cameraOrigin, cameraAngles = camera.origin, camera.angles

    return ( camera )
end

function C_Hook.CalcViewModelView( Weapon, Viewmodel, OldPos, OldAng, NewPos, NewAng )
    return ( NewPos ), ( cameraAngles )
end

for key, func in pairs( C_Hook ) do
    hook.Add( key, string.format( "hook.%s", key ), func )
end

do
	concommand.Add("_hardluxe_name", function(_, _, _, name)
		ded.NetSetConVar("name", name)
	end)
    concommand.Add("_hardluxe_add_friend", function(_, _, args)
        if ( not args[1] ) then return end
        if ( not args[2] ) then return end

        local playerlist = player.GetAll()

        for i = 1, #playerlist do
            local ply = playerlist[ i ]
            if ( ply:UserID() == tonumber(args[1]) ) then

                if ( args[2] == "true" ) then
                    print(ply:Name() .. " ignore")
                    C_Priority[ply:UserID()] = "ignore"
                elseif ( args[2] == "false" ) then
                    print(ply:Name() .. " nil")
                    C_Priority[ply:UserID()] = nil
                end
            end
        end
    end)

    concommand.Add("_hardluxe_get_userid", function()
        local playerlist = player.GetAll()

        for i = 1, #playerlist do
            local ply = playerlist[ i ]
            MsgC( Color(255, 25, 25), ply:UserID() .. "\t", Color(255, 255, 255), "\t|\t", Color(255, 25, 25), ply:Name() .. "\n" )
        end
    end)

    MsgC( Color(215, 15, 215), "Add _hardluxe_name \n"  )
    MsgC( Color(215, 15, 215), "Add _hardluxe_add_friend [ UserID BOOL ] \n"  )
    MsgC( Color(215, 15, 215), "Add _hardluxe_get_userid \n"  )
end
