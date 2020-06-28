# * Script Information:
#   - Name: VRChat  Optional Boot
#   - Version: 0.0.12
#   - Licence: MIT
#   - Author: vrctaki

Param(
    [string]$LaunchURL, 
    [switch]$CreateShortcut
)

Set-Location -Path $PSScriptRoot

####################
# Const
####################
$vrc_install_dir = (Get-ItemProperty -LiteralPath HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam` App` 438100).InstallLocation
$vrc_path = Join-Path $vrc_install_dir "vrchat.exe"

$oculus_install_dir = $null
$oculus_path = $null
if (Test-Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Oculus) {
    $oculus_install_dir = (Get-ItemProperty -LiteralPath HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Oculus -ErrorAction SilentlyContinue).InstallLocation
    $oculus_path = Join-Path $oculus_install_dir "Support\oculus-client\OculusClient.exe"
}

$regex_worldID = "^wrld_[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"
$worldID_watermark_text = "wrld_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
$worldID_watermark_fc   = "DarkGray"

$shortcut_basename = "VRChat optional boot"
$script_version = "0.0.12"
$script_title   = "VRChat Optional Boot(v{0})" -f ($script_version)
$script_icon_path = ((Get-Item $PSCommandPath).Basename + ".ico") 
$favicon_path = Join-Path -Path $PSScriptRoot -ChildPath $script_icon_path

####################
# Vars
####################
$user_id = "usr_00000000-0000-0000-0000-000000000000"
$nonce_id = $null

# Initializing Environment


function EntryShortcutToStartmenu($doseCopyToStartMenu) {
    if (-not (Test-Path $favicon_path)) {
      $favicon_path = $vrc_path + ',0';
    }

    $shortcut_folder = [environment]::getfolderpath("Programs")
    $shortcut_fname = $shortcut_basename + ".lnk"
    $shortcut_path = Join-Path -Path $shortcut_folder -ChildPath $shortcut_fname

    $wsh = New-Object -ComObject Wscript.Shell
    $sc = $wsh.CreateShortCut($shortcut_fname)
    $sc.TargetPath   = 'powershell.exe'
    $sc.Arguments    = '-ExecutionPolicy RemoteSigned  -WindowStyle Hidden .\' + (Split-Path -Leaf $PSCommandPath)
    $sc.IconLocation = $favicon_path
    $sc.WorkingDirectory  = $PSScriptRoot
    # $sc.HotKey = "CTRL+SHIFT+Return"  # if you need hotkey, strip comment symbol.
    $sc.Description = "Boot VRChat with optional arguments"
    $sc.save()

    if ($doseCopyToStartMenu) {
        Write-Host ("Create shortcut file '{0}'" -f $shortcut_path)
        Copy-Item -Path $shortcut_fname -Destination $shortcut_folder
        Start-Process -FilePath "Explorer.exe" -ArgumentList ("/select,`"{0}`"" -f $shortcut_path)
    }
    return
}

if ($CreateShortcut) {
    EntryShortcutToStartmenu($false)
    return
}


####################
# Import Modules
####################
Add-Type -Assembly System.Windows.Forms
Add-Type -AssemblyName PresentationFramework


####################
# UI
####################
[xml]$xaml = (Get-Content ".\main.xaml") -replace "PSScriptRoot", $PSScriptRoot

####################
# Create Window 
####################
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

$window.Title = $script_title
if (Test-Path $favicon_path) {
    $window.Icon  = $favicon_path
}

####################
# Get Controls
####################
$chk_oculusRift  = $window.FindName("OnOculusRift")

$menu_create_shortcut     = $window.FindName("Command_Create_Shortcut")
$menu_add_browser_mode    = $window.FindName("Command_Add_BrowserLaunch")
$menu_remove_browser_mode = $window.FindName("Command_Remove_BrowserLaunch")


$chk_guiDebug    = $window.FindName("GUIDebug")
$chk_sdk2debug   = $window.FindName("SDK2Debug")
$chk_udonDebug   = $window.FindName("UDONDebug")

$txt_worldID     = $window.FindName("WorldID")
$txt_worldID.Text = $worldID_watermark_text
$txt_worldID.Foreground = $worldID_watermark_fc
$txt_roomID      = $window.FindName("RoomID")

$rdi_public      = $window.FindName("Public")
$rdi_friendp     = $window.FindName("FriendP")
$rdi_friend      = $window.FindName("Friend")
$rdi_invitep     = $window.FindName("InviteP")
$rdi_invite      = $window.FindName("Invite")

$chk_profile0    = $window.FindName("UserProfile0")
$chk_profile1    = $window.FindName("UserProfile1")
$chk_profile2    = $window.FindName("UserProfile2")
$chk_profile3    = $window.FindName("UserProfile3")

$chk_nonclosing_mode = $window.FindName("NonClosingMode")

# $btn_boot      = $window.FindName("Boot")
$btn_bootVR      = $window.FindName("BootVR")
$btn_bootDesktop = $window.FindName("BootDesktop")

####################
# Set Events
####################
$sb_toggleGUIDebug = {$chk_sdk2debug.IsEnabled = $chk_udonDebug.IsEnabled = ($chk_guiDebug.IsChecked)}
$chk_guiDebug.Add_Checked($sb_toggleGUIDebug)
$chk_guiDebug.Add_UnChecked($sb_toggleGUIDebug)

$menu_create_shortcut.Add_Click({
    EntryShortcutToStartmenu($true)
})


$menu_add_browser_mode.Add_Click({
    if ((Test-Path 'HKCU:\\Software\Classes\VRChat\shell\open\command') -eq $false) {
        New-Item 'HKCU:\\Software\Classes\VRChat\shell\open\command'
    }

    New-ItemProperty -LiteralPath 'HKCU:\\Software\Classes\VRChat\shell\open\command' -Name '(default)' -PropertyType 'String' -Value (
        'powershell -ExecutionPolicy RemoteSigned -WindowStyle Hidden "' + $PSCommandPath + '" ''"`%1"'''
    )
})


$menu_remove_browser_mode.Add_Click({
    if ((Test-Path -LiteralPath "HKCU:\\Software\Classes\VRChat\shell\open\command")) {
        Remove-Item 'HKCU:\\Software\Classes\VRChat\shell\open\command'
    }
})


$txt_worldID.Add_KeyUp({
    if ($txt_worldID.Text.Length -eq 0 -or $txt_worldID.Text -match $regex_worldID) {
        $txt_worldID.Background = "White";        
    }
    else {
        $txt_worldID.Background = "Yellow";
    }
})

$txt_worldID.Add_GotFocus({
    if ($txt_worldID.Text -eq $worldID_watermark_text) {
        $txt_worldID.Text = ""
        $txt_worldID.Foreground = "Black"
    }
})

$txt_worldID.Add_LostFocus({
    if ($txt_worldID.Text.Length -eq 0) {
        $txt_worldID.Text = $worldID_watermark_text
        $txt_worldID.Foreground =$worldID_watermark_fc
    }
})

$btn_bootVR.Add_Click({
    Boot-VRChat -isDesktopMode $false
})

$btn_bootDesktop.Add_Click({
    Boot-VRChat -isDesktopMode $true
})

function Boot-VRChat{
    param(
        $isDesktopMode=$true
    )

    $sb_launch = {
        param([string]$parameters)
        Start-Process -FilePath $vrc_path -NoNewWindow -ArgumentList $parameters
    }

    $boot_properties = @()

    if ($isDesktopMode) {
        $boot_properties += "--no-vr"
    }
    else {
        if ($chk_oculusRift.IsChecked -and $oculus_path) {
            Start-Process -FilePath $oculus_path -NoNewWindow
            Start-Sleep -Seconds 2
            Start-Process -FilePath "cmd.exe" "/c start steam://rungameid/250820" -NoNewWindow
            Start-Sleep -Seconds 15
        }
    }

    if ($chk_guiDebug.IsChecked) {
        $boot_properties += "--enable-debug-gui"
        
        if ($chk_sdk2debug.IsChecked) {
            $boot_properties += "--enable-sdk-log-levels"
        }
        if ($chk_udonDebug.IsChecked) {
            $boot_properties += "--enable-udon-debug-logging"
        }
    }

    if ($launch_url -ne $null) {
        $room_url = $launch_url
        $boot_properties += $room_url
    }
    elseif ($txt_worldID.Text.Length -and $txt_worldID.Text -match $regex_worldID) {
        $world_id   = $txt_worldID.Text
        $room_id    = $txt_roomID.Text

        $room_url = "vrchat://launch/?ref=vrchat.com&id={0}:{1}" -f ($world_id, $room_id)

        if ($rdi_friendp.IsChecked) {
            $room_url += ("~hidden({0})" -f $user_id)
        }
        elseif ($rdi_friend.IsChecked) {
            $room_url += ("~friends({0})" -f $user_id)
        }
        elseif ($rdi_invitep.IsChecked -or $rdi_invite.IsChecked) {
            $room_url += ("~private({0})" -f $user_id)
        }

        if ($nonce_id -ne $null) {
            $room_url += ("~nonce({0})" -f $nonce_id)
        }

        if ($rdi_invitep.IsChecked) {
            $room_url += "~canRequestInvite"
        }

        $boot_properties += $room_url
    }

    # 
    if ($chk_profile0.IsChecked) {
        &$sb_launch (($boot_properties + "--profile=0") -join " ")
    }
    if ($chk_profile1.IsChecked) {
        &$sb_launch (($boot_properties + "--profile=1") -join " ")
    }
    if ($chk_profile2.IsChecked) {
        &$sb_launch (($boot_properties + "--profile=2") -join " ")
    }
    if ($chk_profile3.IsChecked) {
        &$sb_launch (($boot_properties + "--profile=3") -join " ")
    }

    if ($chk_nonclosing_mode.IsChecked -eq $false) {
        $window.close()
    }
}



####################
# short hand
####################
$window.Add_KeyDown({
    $press_key = $_.Key.toString()

    $short_hands = @{
        # 'Return'=$btn_boot.Click  # not to use
        'Escape'={ $window.close() }
    }

    if ($short_hands.ContainsKey($press_key)) {
        &$short_hands[$press_key]
    }
})

####################
# Parameter Switch
####################
if ($LaunchURL) {
    $LaunchURL -match "(?<=id=)(wrld_[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}):(\d+)" | Out-Null

    $txt_worldID.Text = $Matches[1]
    $txt_worldID.Foreground = "Black"
    $txt_roomID.Text   = $Matches[2]

    $result = $LaunchURL -match "~(hidden|friends|private)\((usr_[^)]+)\)~nonce\(([^)]+)\).*(~canRequestInvite)?"
    $user_id = $Matches[2]
    $nonce_id = $Matches[3]

    if ($result -eq $false) {
        # Public
        $rdi_public.IsChecked = $true
    }
    else {
        if ($Matches[1] -eq "hidden") {
            # Friends+
            $rdi_friendp.IsChecked = $true
        }
        elseif ($Matches[1] -eq "friends") {
            # Friends
            $rdi_friend.IsChecked = $true
        }
        elseif ($Matches[1] -eq "private" -and $Matches[4].Length) {
            # Invite+
            $rdi_invitep.IsChecked = $true
        }
        elseif ($Matches[1] -eq "private") {
            #Invite
            $rdi_invite.IsChecked = $true
        }
    }

    $txt_worldID.IsEnabled = 
    $txt_roomID.IsEnabled  = 
    $rdi_public.IsEnabled  =
    $rdi_friendp.IsEnabled =
    $rdi_friend.IsEnabled  =
    $rdi_invitep.IsEnabled =
    $rdi_invite.IsEnabled  = $false

}

####################
# Show Window
####################
$window.ShowDialog() > $null
$window = $null

