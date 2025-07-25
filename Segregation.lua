local pLocalPlayer = LocalPlayer()
local ScrW, ScrH = ScrW(), ScrH()
local ThirdpersonVal = false
local TargetPriorities = {}
for i = 1, 128 do table.insert( TargetPriorities, 0 ) end

local Configuration = {}

Configuration.Box 									= false
Configuration.Name 									= false
Configuration.Health 								= false
Configuration.Weapon 								= false
Configuration.DLight 								= false
Configuration.ThirdPerson                           = false
Configuration.CircleStrafe 							= false

local ColorF = {}

ColorF.White 			= Color( 255, 255, 255 )
ColorF.Scarlet 			= Color( 255, 35, 0 )
ColorF.Black 			= Color( 0, 0, 0 )
ColorF.BismarckFurioso 	= Color( 165, 38, 10 )
ColorF.Gold 			= Color( 255, 215, 0 )
ColorF.Eggshell			= Color( 240, 234, 214 )
ColorF.LawnGreen 		= Color( 124, 252, 0 )
ColorF.GreyUmber 			= Color( 51, 47, 44, 240 )
ColorF.GreyBlueAlpha 		= Color( 32, 21, 44, 240 )
ColorF.ScarletAlpha 		= Color( 255, 35, 0, 190 )
ColorF.SapphireBlueAlpha 	= Color( 37, 40, 80, 40 )
ColorF.ScarletBadAlpha 		= Color( 255, 35, 0, 60 )

local CSF = {}

surface.CreateFont( "General", { font = "Verdana", size = 13, antialias = false, outline = false } )
surface.CreateFont( "General Outline", { font = "Verdana", size = 13, antialias = false, outline = true } )

function CSF.DrawRect( x, y, w, h, color )
	surface.SetDrawColor( color )
	surface.DrawRect( x, y, w, h )
end

function CSF.DrawLine( x, y, x1, y2, color )
	surface.SetDrawColor( color )
	surface.DrawLine( x, y, x1, y2 )
end

function CSF.DrawOutlinedRect( x, y, w, h, t, color )
	surface.SetDrawColor( color )
	surface.DrawOutlinedRect( x, y, w, h, t )
end

function CSF.DrawText( x, y, str, font, color )
	surface.SetTextColor( color ) 
	surface.SetFont( font )
    surface.SetTextPos( x, y )
    surface.DrawText( str )
end

function CSF.GetTextSize( text, font )
    surface.SetFont( font )
    local width, height = surface.GetTextSize( text )
    return width, height
end

function CSF.DrawTexturedRect( x, y, w, h, color, material )
	surface.SetDrawColor( color ) 
	surface.SetMaterial( material )
	surface.DrawTexturedRect( x, y, w, h ) 
end

local VisualF = {}

function VisualF.GetEntityScreenBounds( entity )
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

    return math.floor( nMinX ), math.floor( nMinY ), math.ceil( nMaxX ), math.ceil( nMaxY )
end

local HookF = {}

HookF.HookFunc = {}

function HookF.Add( event, func )
    hook.Add( event, event .. "_", HookF.HookFunc[ event ] or func )
end

local CursorPos = {}

local function Remember()
    local x, y = input.GetCursorPos()
    if ( x == 0 && y == 0 ) then return end
    CursorPos.x, CursorPos.y = x, y
end

local function Restore()
    if ( !CursorPos.x || !CursorPos.y ) then return end
    input.SetCursorPos( CursorPos.x, CursorPos.y )
end

local DFrame, DFrameX, DFrameY, PrevKeyDown, PanelName, TabPanel, SwitchPerson = nil, nil, nil, false, nil, {}, false

do
    local PANEL = {}

    function PANEL:Init()
        self.Label:SetFont( "General Outline" )
        self.Label:SetTextColor( ColorF.White )

        function self.Button:Paint( w, h )

            CSF.DrawOutlinedRect( 0, 0, w, h, 1, self:GetChecked() and ColorF.Scarlet or ColorF.White )

            if ( self:IsHovered() or self:GetChecked() ) then
                CSF.DrawRect( 3, 3, w - 6, h - 6, ColorF.ScarletBadAlpha )
            end

            if ( self:GetChecked() ) then
                CSF.DrawTexturedRect( 3, 3, w - 6, h - 6, ColorF.BismarckFurioso, Material("icon16/tick.png") )
            end
        end
    end

    function PANEL:PerformLayout()

        self.Button:Dock( LEFT )
        self.Button:SetWide( 15 )
        self.Label:SizeToContents()
        self.Label:SetPos( self.Button:GetWide() + 6, math.floor( ( self:GetTall() - self.Label:GetTall() ) / 2 ) )
    end
    
    vgui.Register( "CustomCheckboxLabel", PANEL, "DCheckBoxLabel" )
end

function DCheckboxLabel( Parent, SetText, Config, Convar )
    local DPanel = Parent:Add( "DPanel" )
    DPanel:Dock( TOP )
    DPanel:SetTall( 15 )
    DPanel:DockMargin( 5, 5, 5, 5 ) 
    DPanel.Paint = nil 

    local DCheckboxLabel = DPanel:Add( "CustomCheckboxLabel" )
    DCheckboxLabel:SetText( SetText )
    DCheckboxLabel:SetPos( 0, 0 )
    if ( Convar ) then
    	DCheckboxLabel:SetConVar( Config )
	else
		DCheckboxLabel:SetValue( Configuration[ Config ] )

		function DCheckboxLabel:OnChange( bVal )
			Configuration[ Config ] = bVal
		end
	end
end

do
    local PANEL = {}

    function PANEL:Init()

        self.Label:Hide()
        self.TextArea:Hide()

        self.Slider.Knob:SetSize( 1, 1 )
        self.Slider.Knob:SetVisible( false )
        
        self.Slider.Paint = function( s, w, h )
            local Width = self.Slider.Knob:GetPos()
            local Value = self:GetDecimals() == 0 and math.Round( self:GetValue() ) or string.format( "%.2f", self:GetValue() )
            local TextWidth, TextHeight = CSF.GetTextSize( Value, "General" )

            CSF.DrawText(  w - TextWidth , -3, Value, "General", ColorF.White )

            if ( self:IsHovered() or self.Slider.Knob:IsHovered() ) then
                CSF.DrawRect( 0, 12, Width, 10, ColorF.Scarlet )
            else
                CSF.DrawRect( 0, 12, Width, 10, ColorF.Scarlet )
            end

            CSF.DrawOutlinedRect( 0, 12, w, 10, 1, ColorF.White )
        end
	end

    vgui.Register( "CustomDNumSlider", PANEL, "DNumSlider" )
end

local function DNumSlider( Parent, SetText, Config, SetMin, SetMax, SetDecimals )
	local DPanel = Parent:Add( "DPanel" )
    DPanel:Dock( TOP )
    DPanel:SetTall( 25 )
    DPanel:DockMargin( 5, 5, 5, 5 )
    DPanel.Paint = nil 

	local DNumSlider = DPanel:Add( "CustomDNumSlider" )
    DNumSlider:Dock( LEFT )
    DNumSlider:SetWide( 150 )
    DNumSlider:SetMax( SetMax )
    DNumSlider:SetMin( SetMin )
    DNumSlider:SetDecimals( SetDecimals )
    DNumSlider:SetConVar( Config )
	if GetConVar( Config ) then
    	DNumSlider:SetValue( GetConVar( Config ):GetFloat() )
	end

    local DLabel = DPanel:Add( "DLabel" )
    DLabel:SetText( SetText )
    DLabel:Dock( FILL )
    DLabel:DockMargin( 10, 10, 0, 0 )
    DLabel:SetFont( "General Outline" )
    DLabel:SetTextColor( ColorF.White )

end

do
    local PANEL = {}

    function PANEL:Init()
        self:SetTall( 20 )
        self.DropButton.Paint = nil
    end

    function PANEL:Paint( w, h )
        CSF.DrawLine( w - 5, 5, w - 10, 10, ColorF.White)
        CSF.DrawLine( w - 10, 10, w - 15, 5, ColorF.White)

        CSF.DrawOutlinedRect( 0, 0, w, h, 1, ColorF.White )
    end

    function PANEL:OpenMenu( pControlOpener )

        if ( pControlOpener && pControlOpener == self.TextEntry ) then
            return
        end
    
        if ( #self.Choices == 0 ) then return end
    
        if ( IsValid( self.Menu ) ) then
            self.Menu:Remove()
            self.Menu = nil
        end
    
        local parent = self
        while ( IsValid( parent ) && !parent:IsModal() ) do
            parent = parent:GetParent()
        end
        if ( !IsValid( parent ) ) then parent = self end
    
        self.Menu = DermaMenu( false, parent )

        function self.Menu:Paint( w,h )
            CSF.DrawRect( 0, 0, w, h, ColorF.Scarlet )

            CSF.DrawOutlinedRect( 0, 0, w, h, 1, ColorF.White ) 
        end

        for k, v in pairs( self.Choices ) do
            local option = self.Menu:AddOption( v, function() self:ChooseOption( v, k ) end )
            option.txt = option:GetText()
            option:SetText( "" )

            function option:Paint(w,h)
                if ( self:IsHovered() ) then 
                    CSF.DrawRect( 1, 1, w - 2, h - 2, ColorF.Black )
                end

                CSF.DrawText(  10,4, option.txt, "General", ColorF.White )
            end   

            if ( self.Spacers[ k ] ) then
                self.Menu:AddSpacer()
            end
        end

    
        local x, y = self:LocalToScreen( 0, self:GetTall() )
    
        self.Menu:SetMinimumWidth( self:GetWide() )
        self.Menu:Open( x, y, false, self )
    
        self:OnMenuOpened( self.Menu )
    end

    function PANEL:PerformLayout(s)
        self:SetTextColor( ColorF.White )
        self:SetFont( "General" )
    end

    vgui.Register( "CustomDComboBox", PANEL, "DComboBox" )
end

local function DComboBox( Parent, SetText, Config, Choices, Number, Convar )
	local DPanel = Parent:Add( "DPanel" )
    DPanel:Dock( TOP )
    DPanel:SetTall( 15 )
    DPanel:DockMargin( 5, 5, 5, 5 )
    DPanel.Paint = nil 

    local DComboBox = DPanel:Add( "CustomDComboBox" )
    DComboBox:Dock( LEFT )
    DComboBox:SetWide( 120 )
    DComboBox:SetSortItems( false )
	for i = 1, #Choices do
        if Convar then
            DComboBox:AddChoice( Choices[i], Number[i] )
        else
            DComboBox:AddChoice( Choices[i] )
        end
    end

	if Convar then
		DComboBox:SetConVar( Config )
		DComboBox.OnSelect = function( self, index, value, data ) RunConsoleCommand( self.m_strConVar, data ) end
	else
       DComboBox:ChooseOptionID( Configuration[ Config ] )
        
        DComboBox.OnSelect = function( s, index, value, data )
            Configuration[ Config ] = index
        end
	end

    local DLabel = DPanel:Add( "DLabel" )
    DLabel:SetText( SetText )
    DLabel:Dock( FILL )
    DLabel:DockMargin( 10, 0, 0, 0 )
    DLabel:SetFont( "General Outline" )
    DLabel:SetTextColor( ColorF.White )
end

local function StringRequest( strText, strDefaultText, fnEnter, fnCancel, strButtonText, strButtonCancelText )

	local Window = vgui.Create( "DFrame" )
	Window:SetTitle( "" )
	Window:SetDraggable( false )
	Window:ShowCloseButton( false )
	Window:SetBackgroundBlur( true )
	Window:SetDrawOnTop( true )
	Window.Paint = function( s, w, h )
		CSF.DrawRect( 0, 0, w, h, ColorF.Scarlet )
		CSF.DrawOutlinedRect( 0, 0, w, h, 1, ColorF.White )
	end	

	local InnerPanel = vgui.Create( "DPanel", Window )
	InnerPanel:SetPaintBackground( false )

	local Text = vgui.Create( "DLabel", InnerPanel )
	Text:SetText( strText or "Message Text (Second Parameter)" )
	Text:SizeToContents()
	Text:SetContentAlignment( 5 )
	Text:SetFont( "General" )
	Text:SetTextColor( ColorF.White )

	local TextEntry = vgui.Create( "DTextEntry", InnerPanel )
	TextEntry:SetText( strDefaultText or "" )
	TextEntry:SetFont( "General" )
	TextEntry.OnEnter = function() Window:Close() fnEnter( TextEntry:GetValue() ) end

	local ButtonPanel = vgui.Create( "DPanel", Window )
	ButtonPanel:SetTall( 30 )
	ButtonPanel:SetPaintBackground( false )


	local Button = vgui.Create( "DButton", ButtonPanel )
	Button:SetText( "" )
	Button:SizeToContents()
	Button:SetTall( 20 )
	Button:SetWide( Button:GetWide() + 20 )
	Button:SetPos( 5, 5 )
	Button.DoClick = function() Window:Close() fnEnter( TextEntry:GetValue() ) end
	Button.Paint = function( s, w, h )
		local ColorDrawRect 
		if ( s:IsHovered() ) then
			ColorDrawRect = ColorF.GreyUmber
		else
			ColorDrawRect = ColorF.Scarlet
		end
		local TextWidth = CSF.GetTextSize( strButtonText or "OK", "General" )
		CSF.DrawRect( 0, 0, w, h, ColorDrawRect )
		CSF.DrawOutlinedRect(0, 0, w, h, 1, ColorF.White )
		CSF.DrawText( w / 2 - TextWidth / 2 , 1, strButtonText or "OK", "General", ColorF.White )
	end

	local ButtonCancel = vgui.Create( "DButton", ButtonPanel )
	ButtonCancel:SetText( "" )
	ButtonCancel:SizeToContents()
	ButtonCancel:SetTall( 20 )
	ButtonCancel:SetWide( Button:GetWide() + 20 )
	ButtonCancel:SetPos( 5, 5 )
	ButtonCancel.DoClick = function() Window:Close() if ( fnCancel ) then fnCancel( TextEntry:GetValue() ) end end
	ButtonCancel:MoveRightOf( Button, 5 )
	ButtonCancel.Paint = function( s, w, h )
		local ColorDrawRect 
		if ( s:IsHovered() ) then
			ColorDrawRect = ColorF.GreyUmber
		else
			ColorDrawRect = ColorF.Scarlet
		end
		local TextWidth = CSF.GetTextSize( strButtonCancelText or "Cancel", "General" )
		CSF.DrawRect( 0, 0, w, h, ColorDrawRect )
		CSF.DrawOutlinedRect( 0, 0, w, h, 1, ColorF.White )
		CSF.DrawText( w / 2 - TextWidth / 2 , 1, strButtonCancelText or "Cancel", "General", ColorF.White )
	end

	ButtonPanel:SetWide( Button:GetWide() + 5 + ButtonCancel:GetWide() + 10 )

	local w, h = Text:GetSize()
	w = math.max( w, 400 )

	Window:SetSize( w + 50, h + 25 + 75 + 10 )
	Window:Center()

	InnerPanel:StretchToParent( 5, 25, 5, 45 )

	Text:StretchToParent( 5, 0, 5, 35 )

	TextEntry:StretchToParent( 5, nil, 5, nil )
	TextEntry:AlignBottom( 5 )

	TextEntry:RequestFocus()
	TextEntry:SelectAllText( true )

	ButtonPanel:CenterHorizontal()
	ButtonPanel:AlignBottom( 8 )

	Window:MakePopup()
	Window:DoModal()
	
end

local function TabButton( Parent, SetText, TabName )

    local DButton = Parent:Add( "DButton" )
	DButton:Dock( TOP )
    DButton:SetTall( 40 )
	DButton:SetWide( 90 )
	DButton:SetText( "" )
	DButton:SetTooltip(  )

	DButton.Paint = function( s, w, h )

        if ( PanelName == TabName ) then
            CSF.DrawRect(0, 0, w, h, ColorF.ScarletAlpha)
        elseif ( s:IsHovered() ) then
            CSF.DrawRect(0, 0, w, h, ColorF.ScarletBadAlpha)
        end

		local TextWidth, TextHeight = CSF.GetTextSize( SetText, "General" )
		local Y = ( h - TextHeight ) / 2
    	CSF.DrawText( 10, Y, SetText, "General", ColorF.White )
	end

	DButton.DoClick = function()
        PanelName = TabName
        for Name, Panel in pairs( TabPanel ) do
            Panel:SetVisible( Name == TabName )
        end
    end
end

local function SegregationPanel()
 
	DFrame = vgui.Create( "DFrame" )
	DFrame:SetSize( 450, 400 )
	DFrame:SetTitle( "" )
	DFrame:ShowCloseButton( false )
	DFrame:Center()
	DFrame:MakePopup()

	if ( DFrameX == nil or DFrameY == nil ) then
        DFrame:Center()
    else
        DFrame:SetPos( DFrameX, DFrameY )
    end

	DFrame.Paint = function( s, w, h )
		CSF.DrawRect( 0, 20, w, h, ColorF.GreyBlueAlpha )
		CSF.DrawRect( 0, 0, w, 20, ColorF.ScarletAlpha )
        CSF.DrawOutlinedRect( 0, 20, w, h - 20, 1, ColorF.Scarlet )

        local TextWidth, TextHeight = CSF.GetTextSize( "Segregation (64-bit)", "General" )
        CSF.DrawText( 2, ( 20 - TextHeight ) / 2, "Segregation (64-bit)", "General", ColorF.White )
	end

    local DPanel = DFrame:Add( "DPanel" )
    DPanel:Dock( LEFT )
    DPanel:SetTall( 100 )
    DPanel:SetWide( 120 )
    DPanel.Paint = nil

	TabButton(DPanel, "AimBot", "AimBot")
    TabButton(DPanel, "HvH", "HvH")
    TabButton(DPanel, "Visuals", "Visuals")
    TabButton(DPanel, "Misc", "Misc")
    TabButton(DPanel, "PlayerList", "PlayerList")

	local DPanel2 = DFrame:Add( "DPanel" )
    DPanel2:Dock( FILL )
    DPanel2.Paint = nil

    TabPanel.AimBot = DPanel2:Add( "DScrollPanel" )
    TabPanel.AimBot:Dock( FILL )
    TabPanel.AimBot:SetVisible( false )
    TabPanel.AimBot.Paint = function( s, w, h )
        CSF.DrawRect( 0, 0, w, h, ColorF.SapphireBlueAlpha )
    end
    
    DCheckboxLabel( TabPanel.AimBot, "At Teammates", "Aim_Team", true )
	DCheckboxLabel( TabPanel.AimBot, "Extrapolation", "Extrapolation", true )
	DCheckboxLabel( TabPanel.AimBot, "Instant Shot", "Alternative", true )
	DCheckboxLabel( TabPanel.AimBot, "Intersect Hitboxes", "Aim_Intersection", true )
    DNumSlider( TabPanel.AimBot, "Height", "Aim_Height", 0, 1, 2 )
    DComboBox( TabPanel.AimBot, "Hitbox", "Aim_Group", { "Head", "Chest", "Stomach", "Left Arm", "Right Arm", "Left Leg", "Right Leg" }, { "1", "2", "3", "4", "5", "6", "7" }, true )


    TabPanel.HvH = DPanel2:Add( "DScrollPanel" )
    TabPanel.HvH:Dock( FILL )
    TabPanel.HvH:SetVisible( false )
    TabPanel.HvH.Paint = function( s, w, h )
        CSF.DrawRect( 0, 0, w, h, ColorF.SapphireBlueAlpha )
    end

    DNumSlider( TabPanel.HvH, "Pitch", "Angle_X", -180, 180, 0 )
	DNumSlider( TabPanel.HvH, "Fake Yaw", "Angle_Y", -180, 180, 0 )
	DNumSlider( TabPanel.HvH, "Real Yaw First", "First_Choked_Angle_Y", -180, 180, 0 )
	DNumSlider( TabPanel.HvH, "Real Yaw Second", "Second_Choked_Angle_Y", -180, 180, 0 )
	DNumSlider( TabPanel.HvH, "Fake Lag Maximum", "Maximum_Choked_Commands", 0, 21, 0 )
 	DNumSlider( TabPanel.HvH, "Fake Lag Minimum", "Minimum_Choked_Commands", 0, 21, 0 )
	DCheckboxLabel( TabPanel.HvH, "Resolver", "Bruteforce", true )
	DNumSlider( TabPanel.HvH, "Resolver Bullets", "Bruteforce_Tolerance", 0, 30, 0 )
	DNumSlider( TabPanel.HvH, "Resolver Memory Bullets", "Bruteforce_Memory_Tolerance", 0, 30, 0 )
    
    TabPanel.Visuals = DPanel2:Add( "DScrollPanel" )
    TabPanel.Visuals:Dock( FILL )
    TabPanel.Visuals:SetVisible( false )
    TabPanel.Visuals.Paint = function( s, w, h )
        CSF.DrawRect( 0, 0, w, h, ColorF.SapphireBlueAlpha )
    end

    DCheckboxLabel( TabPanel.Visuals, "Box", "Box", false )
	DCheckboxLabel( TabPanel.Visuals, "Name", "Name", false )
	DCheckboxLabel( TabPanel.Visuals, "Health", "Health", false )
	DCheckboxLabel( TabPanel.Visuals, "Weapon", "Weapon", false )
	DNumSlider( TabPanel.Visuals, "Crosshair Scale", "Uber_Alles_Scale", 0, 150, 0 )
	DNumSlider( TabPanel.Visuals, "Crosshair Speed", "Uber_Alles_Speed", 0, 300, 0 )
	DCheckboxLabel( TabPanel.Visuals, "Dynamic Light", "DLight", false )

    TabPanel.Misc = DPanel2:Add( "DScrollPanel" )
    TabPanel.Misc:Dock( FILL )
    TabPanel.Misc:SetVisible( false )
    TabPanel.Misc.Paint = function( s, w, h )
        CSF.DrawRect( 0, 0, w, h, ColorF.SapphireBlueAlpha )
    end

    DCheckboxLabel( TabPanel.Misc, "ThirdPerson", "ThirdPerson", false )
    DCheckboxLabel( TabPanel.Misc, "CircleStrafe", "CircleStrafe", false )
	
    TabPanel.PlayerList = DPanel2:Add( "DListView" )
    TabPanel.PlayerList:Dock( FILL )
    TabPanel.PlayerList:SetVisible( false )
    TabPanel.PlayerList.Paint = function( s, w, h )
        CSF.DrawRect( 0, 0, w, h, ColorF.SapphireBlueAlpha )
    end

	local columns = {
		{ Name = "ID", Width = 30 },
		{ Name = "Name", Width = 100 },
		{ Name = "Friend", Width = 50 },
		{ Name = "Resolve", Width = 70 },
		{ Name = "Priority", Width = 70 }
	}

	for _, col in ipairs( columns ) do
		local column = TabPanel.PlayerList:AddColumn( "" )
		column:SetFixedWidth( col.Width )
		
		column.Header.Paint = function( s, w, h )
			local TextWidth, TextHeight = CSF.GetTextSize( col.Name, "General" )
			CSF.DrawRect( 0, 0, w, h, ColorF.Scarlet )
			CSF.DrawOutlinedRect( 0, 0, w, h, 1, ColorF.White )    
			CSF.DrawText( w / 2 - TextWidth / 2, 0, col.Name, "General", ColorF.White )
		end
	end
	TabPanel.PlayerList.Paint = function( s, w, h )
		CSF.DrawRect( 0, 0, w, h, ColorF.White)
		CSF.DrawOutlinedRect( 0, 0, w, h, 1, ColorF.Scarlet )	
    end

	TabPanel.PlayerList.Think = function( self )
		for id, pl in ipairs( player.GetAll() ) do
 
			if ( IsValid( pl.PlayerListEntry ) ) then continue end
 
			pl.PlayerListEntry = self:AddLine( tostring( pl:EntIndex() ) )
			pl.PlayerListEntry.Player = pl
			pl.PlayerListEntry.PIndex = pl:EntIndex()
			pl.PlayerListEntry.Think = function( self )
 
				if ( !IsValid( self.Player ) ) then
					self:Remove()
					return
				end
 
				if ( self.PName == nil || self.PName != self.Player:Nick() ) then
					self.PName = self.Player:Nick()
					self:SetValue( 2, self.PName )
				end
 
				local priority = TargetPriorities[self.PIndex]
 
				if ( self.Priority == nil || self.Priority != priority ) then
					self.Priority = priority
					self:SetValue( 3, ( self.Priority == -1 ) && "Yes" || "No" )
					self:SetValue( 4, ( self.Priority == -2 ) && "No" || "Yes" )
					self:SetValue( 5, tostring( self.Priority ) )
				end
			end
		end
 
	end
 
	TabPanel.PlayerList.OnRowRightClick = function( parent, id, line )
		local ply_id = line.PIndex
		local Menu = DermaMenu()
		Menu.Paint = function( s, w, h )
			CSF.DrawRect( 0, 0, w, h, ColorF.Scarlet )
			CSF.DrawOutlinedRect( 0, 0, w, h, 1, ColorF.White )	
        end

		local Friend = Menu:AddOption( "Toggle Friend", function() 
			TargetPriorities[ ply_id ] = ( TargetPriorities[ ply_id ] == -1 ) && 0 || -1
			RunConsoleCommand( "Set_Priority", tostring( ply_id ) .. " " .. tostring( TargetPriorities[ ply_id ] ) )
		end )


		Friend:SetIcon( "icon16/user_green.png" )
		Friend:SetFont( "General" )
		Friend:SetTextColor( ColorF.White )
		Friend.Paint = function( s, w, h )
			if ( not s:IsHovered() ) then return end
			CSF.DrawRect( 3, 3, w - 6, h - 6, ColorF.Black )
		end

		local ResolveEnemy = Menu:AddOption( "Toggle Resolve", function() 
			TargetPriorities[ ply_id ] = ( TargetPriorities[ ply_id ] == -2 ) && 0 || -2
			RunConsoleCommand( "Set_Priority", tostring( ply_id ) .. " " .. tostring( TargetPriorities[ ply_id ] ) )
		end )

		ResolveEnemy:SetIcon( "icon16/calculator.png" )
		ResolveEnemy:SetFont( "General" )
		ResolveEnemy:SetTextColor( ColorF.White )
		ResolveEnemy.Paint = function( s, w, h )
			if ( not s:IsHovered() ) then return end
			CSF.DrawRect( 3, 3, w - 6, h - 6, ColorF.Black )
		end

		local Priority = Menu:AddOption( "Change Priority", function() 
			StringRequest("Enter priority:", "", function( text ) 
				local priority = tonumber( text )
				if ( priority != nil ) then
					TargetPriorities[ ply_id ] = priority
					RunConsoleCommand( "Set_Priority", tostring( ply_id ) .. " " .. tostring( TargetPriorities[ ply_id ] ) )
				end
			end )
		end )
		Priority:SetIcon( "icon16/arrow_up.png" )
		Priority:SetFont( "General" )
		Priority:SetTextColor( ColorF.White )
		Priority.Paint = function( s, w, h )
			if ( not s:IsHovered() ) then return end
			CSF.DrawRect( 3, 3, w - 6, h - 6, ColorF.Black )
		end

		Menu:Open()
	end
    

	TabPanel[PanelName]:SetVisible(true)
    
end
 
PanelName = "AimBot"

SegregationPanel()

function HookF.HookFunc.Think()

    if ( SwitchPerson != Configuration.ThirdPerson ) then
        RunConsoleCommand(Configuration.ThirdPerson and "thirdperson" or "firstperson")
        SwitchPerson = Configuration.ThirdPerson
    end

	if ( input.IsKeyDown( KEY_INSERT ) && !PrevKeyDown ) then
		if ( DFrame ) then
			DFrameX, DFrameY = DFrame:GetPos()
			DFrame:Remove()
			DFrame = nil
			Remember()
		else
			SegregationPanel()
			Restore()
		end
	end

	PrevKeyDown = input.IsKeyDown( KEY_INSERT )

    if ( Configuration.DLight ) then
		local hsv = HSVToColor( ( CurTime() * 25 ) % 360, 1, 1 )
		local dlight = DynamicLight( pLocalPlayer:EntIndex() )
		if ( dlight ) then
			dlight.pos = pLocalPlayer:GetShootPos()
			dlight.r = hsv.r 
			dlight.g = hsv.g
			dlight.b = hsv.b
			dlight.brightness = 4
			dlight.Size = 300
			dlight.DieTime = CurTime() + 1
		end
	end
end

function VisualF.DrawPlayerVisual( entity )
    local minX, minY, maxX, maxY = VisualF.GetEntityScreenBounds( entity )

	if ( not entity:Alive() ) then
        return
    end
    
    if (entity == pLocalPlayer) then
        return
    end

    if ( not minX ) then
        return 
    end

    surface.SetAlphaMultiplier( entity:IsDormant() and 0.6 or 1 )

    local width, height = maxX - minX, maxY - minY 

    if ( Configuration.Box ) then
		CSF.DrawOutlinedRect( minX + 1, minY + 1, width, height, 1, ColorF.Black )
		CSF.DrawOutlinedRect( minX, minY, width, height, 1, ColorF.BismarckFurioso )
    end

	if ( Configuration.Name  ) then
        local str = entity:Name()
        local textWidth, textHeight = CSF.GetTextSize( str, "General Outline" )
		CSF.DrawText( minX + ( width - textWidth ) * 0.5, minY - 16, str, "General Outline", ColorF.Eggshell )
    end

	if ( Configuration.Weapon ) then
        local weapon = entity:GetActiveWeapon()

        if ( IsValid( weapon ) ) then
            local str = weapon:GetClass()
			local textWidth, textHeight = CSF.GetTextSize( str, "General Outline" )
			CSF.DrawText( minX + ( width - textWidth ) * 0.5, maxY, str, "General Outline", ColorF.Eggshell )
        end
    end

	if ( Configuration.Health ) then
		local str = entity:Health()
		local textWidth, textHeight = CSF.GetTextSize( str, "General Outline" )
		CSF.DrawText( minX - textWidth - 2, minY, str, "General Outline", ColorF.LawnGreen )
	end

    surface.SetAlphaMultiplier( 1 )
end


function VisualF.DrawOtherVisual()
	
	local progress = math.abs( math.sin( CurTime() * 0.2 ) ) 
	local ColorText = Color( Lerp( progress, 255, 255 ), Lerp( progress, 255, 0 ), Lerp( progress, 255, 0 ) )

	local textWidth, textHeight = CSF.GetTextSize( "Segregation " .. "| " .. pLocalPlayer:Name() .. " | latency:" .. pLocalPlayer:Ping() .. " | fps:" .. math.Round( 1 / FrameTime() ) .. " | " ..  os.date( "%H:%M:%S" , os.time() ), "General Outline" )

	CSF.DrawRect( 3, 5, textWidth + 7, 25, ColorF.GreyBlueAlpha )
	CSF.DrawRect( 3, 5, textWidth + 7, 4, ColorF.Scarlet )
	CSF.DrawText( 8, 10, "Segregation " .. "| " .. pLocalPlayer:Name() .. " | latency:" .. pLocalPlayer:Ping() .. " | fps:" .. math.Round( 1 / FrameTime() ) .. " | " ..  os.date( "%H:%M:%S" , os.time() ), "General Outline", ColorF.White )
	CSF.DrawText( 8, 10, "Segregation ", "General Outline", ColorText )
end

function HookF.HookFunc.HUDPaint()
	local playerlist = player.GetAll()

	for i = 1, #playerlist do
        local player = playerlist[ i ]
       	VisualF.DrawPlayerVisual( player )
    end
	VisualF.DrawOtherVisual()
end

local prev_yaw = 0
local last_ground_pos = 0
local real_ang = Angle()
local cstrafe_predict_ticks = 64
local cstrafe_angle_step = 1
local cstrafe_angle_maxstep = 10
local cstrafe_dir = 0
local cstrafe_ground_diff = 5
 
local function MovementFix( UserCMD, wish_yaw )
 
	local pitch = math.NormalizeAngle( UserCMD:GetViewAngles().x )
	local inverted = -1
 
	if ( pitch > 89 || pitch < -89 ) then
		inverted = 1
	end
 
	local ang_diff = math.rad( math.NormalizeAngle( ( UserCMD:GetViewAngles().y - wish_yaw )*inverted ) )
 
	local forwardmove = UserCMD:GetForwardMove()
	local sidemove = UserCMD:GetSideMove()
 
	local new_forwardmove = forwardmove*-math.cos( ang_diff )*inverted + sidemove*math.sin( ang_diff )
	local new_sidemove = forwardmove*math.sin( ang_diff )*inverted + sidemove*math.cos( ang_diff )
 
	UserCMD:SetForwardMove( new_forwardmove )
	UserCMD:SetSideMove( new_sidemove )
 
end
 
local function PredictVelocity( velocity, viewangles, dir, maxspeed, accel, friction, interval_per_tick )
 
	local forward = viewangles:Forward()
	local right = viewangles:Right()
 
	local fmove = 0
	local smove = ( dir == 1 ) && -10000 || 10000
 
	forward.z = 0
	right.z = 0
 
	forward:Normalize()
	right:Normalize()
 
	local wishdir = Vector( forward.x*fmove + right.x*smove, forward.y*fmove + right.y*smove, 0 )
	local wishspeed = wishdir:Length()
 
	wishdir:Normalize()
 
	if ( wishspeed != 0 && wishspeed > maxspeed ) then
		wishspeed = maxspeed
	end
 
	local wishspd = wishspeed
 
	if ( wishspd > 30 ) then
		wishspd = 30
	end
 
	local currentspeed = velocity:Dot( wishdir )
	local addspeed = wishspd - currentspeed
 
	if ( addspeed <= 0 ) then
		return
	end
 
	local accelspeed = accel * interval_per_tick * wishspeed * friction
 
	if ( accelspeed > addspeed ) then
		accelspeed = addspeed
	end
 
	local new_vel = wishdir * accelspeed
 
	velocity:Add( new_vel )
 
end
 
local sv_airaccelerate = GetConVar( "sv_airaccelerate" )
local sv_gravity = GetConVar( "sv_gravity" )
local sv_sticktoground = GetConVar( "sv_sticktoground" )
 
local function PredictMovement( viewangles, dir, angle )
 
	local pm
 
	local maxspeed = pLocalPlayer:GetMaxSpeed()
	local jump_power = pLocalPlayer:GetJumpPower()
	local interval_per_tick = engine.TickInterval()
	local gravity_per_tick = sv_gravity:GetFloat() * interval_per_tick
	local accel = sv_airaccelerate:GetFloat()
	local stick_to_ground = sv_sticktoground:GetBool()
	local friction = pLocalPlayer:GetInternalVariable( "m_surfaceFriction" )
	local origin = pLocalPlayer:GetNetworkOrigin()
	local velocity = pLocalPlayer:GetAbsVelocity()
	local mins = pLocalPlayer:OBBMins()
	local maxs = pLocalPlayer:OBBMaxs()
	local on_ground = pLocalPlayer:IsFlagSet( FL_ONGROUND )
 
	for i = 1, cstrafe_predict_ticks do
 
		viewangles.y = math.NormalizeAngle( math.deg( math.atan2( velocity.y, velocity.x ) ) + angle )
 
		velocity.z = velocity.z - ( gravity_per_tick * 0.5 )
 
		if ( on_ground ) then
 
			velocity.z = velocity.z + jump_power
			velocity.z = velocity.z - ( gravity_per_tick * 0.5 )
 
		end
 
		PredictVelocity( velocity, viewangles, dir, maxspeed, accel, friction, interval_per_tick )
 
		local endpos = origin + ( velocity * interval_per_tick )
 
		pm = util.TraceHull( {
			start = origin,
			endpos = endpos,
			filter = pLocalPlayer,
			maxs = maxs,
			mins = mins,
			mask = MASK_PLAYERSOLID
		} )
 
		if ( ( pm.Fraction != 1 && pm.HitNormal.z <= 0.9 ) || pm.AllSolid || pm.StartSolid ) then
			return false
		end
 
		if ( pm.Fraction != 1 ) then
 
			local time_left = interval_per_tick
 
			for j = 1, 2 do
 
				time_left = time_left - ( time_left * pm.Fraction )
 
				local dot = velocity:Dot( pm.HitNormal )
 
				velocity = velocity - ( pm.HitNormal * dot )
 
				dot = velocity:Dot( pm.HitNormal )
 
				if ( dot < 0 ) then
					velocity = velocity - ( pm.HitNormal * dot )
				end
 
				endpos = pm.HitPos + ( velocity * time_left )
 
				pm = util.TraceHull( {
					start = pm.HitPos,
					endpos = endpos,
					filter = pLocalPlayer,
					maxs = maxs,
					mins = mins,
					mask = MASK_PLAYERSOLID
				} )
 
				if ( ( pm.Fraction != 1 && pm.HitNormal.z <= 0.9 ) || pm.AllSolid || pm.StartSolid ) then
					return false
				end
 
				if ( pm.Fraction == 1 ) then
					break
				end
 
			end
 
		end
 
		origin = pm.HitPos
 
		if ( ( last_ground_pos - origin.z ) > cstrafe_ground_diff ) then
			return false
		end
 
		friction = 1
 
		if ( velocity.z > 140 && !stick_to_ground ) then
 
			on_ground = false
 
		else
 
			pm = util.TraceHull( {
				start =  Vector( origin.x, origin.y, origin.z + 2 ),
				endpos = Vector( origin.x, origin.y, origin.z - 1 ),
				filter = pLocalPlayer,
				maxs = Vector( maxs.x, maxs.y, maxs.z * 0.5 ),
				mins = mins,
				mask = MASK_PLAYERSOLID
			} )
 
			on_ground = ( ( pm.Fraction < 1 || pm.AllSolid || pm.StartSolid ) && pm.HitNormal.z >= 0.7 )
 
			if ( !on_ground && velocity.z > 0 ) then
 
				friction = 0.25
 
			end
 
		end
 
		velocity.z = velocity.z - ( gravity_per_tick * 0.5 )
 
		if ( on_ground ) then
			velocity.z = 0
		end
 
	end
 
	return true
 
end
 
local function CircleStrafe( UserCMD )
 
	local angle
 
	for i = 1, 2 do
 
		angle = 0
		local path_found = false
		local step = ( cstrafe_dir == 1 ) && cstrafe_angle_step || -cstrafe_angle_step
 
		while ( true ) do
 
			if ( cstrafe_dir == 1 ) then
 
				if ( angle > cstrafe_angle_maxstep ) then
					break
				end
 
			else
 
				if ( angle < -cstrafe_angle_maxstep ) then
					break
				end
 
			end
 
			if ( PredictMovement( UserCMD:GetViewAngles(), cstrafe_dir, angle ) ) then
 
				path_found = true
				break
 
			end
 
			angle = angle + step
 
		end
 
		if ( path_found ) then
			break
		end
 
		if ( cstrafe_dir == 1 ) then
			cstrafe_dir = 0
		else
			cstrafe_dir = 1
		end
 
	end
 
	local velocity = pLocalPlayer:GetAbsVelocity()
	local viewangles = UserCMD:GetViewAngles()
 
	viewangles.y = math.NormalizeAngle( math.deg( math.atan2( velocity.y, velocity.x ) ) + angle )
 
	UserCMD:SetViewAngles( viewangles )
	UserCMD:SetSideMove( ( cstrafe_dir == 1 ) && -10000 || 10000 )
 
end
 
local function AutoStrafe( UserCMD )
 
	if ( input.IsKeyDown( KEY_E ) and Configuration.CircleStrafe) then
 
		CircleStrafe( UserCMD )
 
	else
 
		local ang_diff = math.NormalizeAngle( real_ang.y - prev_yaw )
 
		if ( math.abs( ang_diff ) > 0 ) then
 
			if ( ang_diff > 0 ) then
				UserCMD:SetSideMove( -10000 )
			else
				UserCMD:SetSideMove( 10000 )
			end
 
		else
 
			local vel = pLocalPlayer:GetAbsVelocity()
			local vel_yaw = math.NormalizeAngle( math.deg( math.atan2( vel.y, vel.x ) ) )
			local vel_yaw_diff = math.NormalizeAngle( real_ang.y - vel_yaw )
 
			if ( vel_yaw_diff > 0 ) then
				UserCMD:SetSideMove( -10000 )
			else
				UserCMD:SetSideMove( 10000 )
			end
 
			local viewangles = UserCMD:GetViewAngles()
			viewangles.y = vel_yaw
			UserCMD:SetViewAngles( viewangles )
 
		end
 
		prev_yaw = real_ang.y
 
	end
 
end

function HookF.HookFunc.CreateMove( UserCMD )

	local Weapon = pLocalPlayer:GetActiveWeapon()
	local WeaponClass = IsValid(Weapon) and pLocalPlayer:GetActiveWeapon():GetClass() or false
	if ( IsValid( Weapon ) and WeaponClass:StartWith("m9k_") and UserCMD:KeyDown(IN_SPEED) ) then
		UserCMD:RemoveKey(IN_SPEED)
	end

	real_ang = real_ang + Angle( UserCMD:GetMouseY() * 0.023, -UserCMD:GetMouseX() * 0.023, 0 )
	real_ang.x = math.Clamp( real_ang.x, -89, 89 )
	real_ang:Normalize()
 
	if ( UserCMD:CommandNumber() == 0 ) then
		UserCMD:SetViewAngles( real_ang )
		return
	end
 
	if ( pLocalPlayer:IsFlagSet( FL_ONGROUND ) ) then
		last_ground_pos = pLocalPlayer:GetNetworkOrigin().z
	end
 
	if ( UserCMD:KeyDown( IN_JUMP ) ) then
 
		if ( !pLocalPlayer:IsFlagSet( FL_ONGROUND ) ) then
			UserCMD:RemoveKey( IN_JUMP )
		end
 
		AutoStrafe( UserCMD )
 
	end
 
	local wish_yaw = UserCMD:GetViewAngles().y
 
	local viewangles = UserCMD:GetViewAngles()
	viewangles.y = real_ang.y
	UserCMD:SetViewAngles( viewangles )
 
	MovementFix( UserCMD, wish_yaw )
end

function HookF.HookFunc.CalcView( ply, origin, angles, fov, znear, zfar )
	local view = {
		origin = origin,
		angles = real_ang,
		fov = fov,
		znear = znear,
		zfar = zfar
	}
 
	return view
end

HookF.Add( "Think" )
HookF.Add( "HUDPaint" )
HookF.Add( "CreateMove" )
HookF.Add( "CalcView" )

for k, v in pairs( Entity( 0 ):GetMaterials() ) do
   Material( v ):SetVector( "$color", Vector(1, 1, 1) )
   Material( v ):SetFloat( "$alpha", 1 )
end

RunConsoleCommand( "cl_updaterate", "100" )
RunConsoleCommand( "cl_interp_ratio", "0" )
RunConsoleCommand( "cl_interp", "0" )
