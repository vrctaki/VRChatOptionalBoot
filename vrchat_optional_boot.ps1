# * Script Information:
#   - Name: VRChat  Optional Boot
#   - Version: 0.0.9
#   - Licence: MIT
#   - Author: vrctaki

Param(
    [string]$launch_url, 
    [switch]$CreateShortcut
)

Get-Location
Set-Location -Path $PSScriptRoot
Get-Location

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
$script_version = "0.0.9"
$script_title   = "VRChat Optional Boot(v{0})" -f ($script_version)
$script_icon_path = ((Get-Item $PSCommandPath).Basename + ".ico") 

# Initializing Environment

function EntryShortcutToStartmenu($doseCopyToStartMenu) {
    $favicon_path = Join-Path -Path $PSScriptRoot -ChildPath $script_icon_path
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
if (Test-Path $script_icon_path) {
    $window.Icon  = $script_icon_path
}

####################
# Get Controls
####################
$chk_oculusRift  = $window.FindName("OnOculusRift")

$menu_create_shortcut = $window.FindName("Command_Create_Shortcut")

$chk_guiDebug    = $window.FindName("GUIDebug")
$chk_sdk2debug   = $window.FindName("SDK2Debug")
$chk_udonDebug   = $window.FindName("UDONDebug")

$txt_worldID     = $window.FindName("WorldID")
$txt_worldID.Text = $worldID_watermark_text
$txt_worldID.Foreground = $worldID_watermark_fc

$rdi_publicRange = $window.FindName("PublicRange")  # not use
$rdi_friendp     = $window.FindName("FriendP")
$rdi_friend      = $window.FindName("Friend")
$rdi_invitep     = $window.FindName("InviteP")
$rdi_invite      = $window.FindName("Invite")

$chk_profile0    = $window.FindName("UserProfile0")
$chk_profile1    = $window.FindName("UserProfile1")
$chk_profile2    = $window.FindName("UserProfile2")
$chk_profile3    = $window.FindName("UserProfile3")

$chk_nonclosing_mode = $window.FindName("NonClosingMode")

# $btn_boot        = $window.FindName("Boot")
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
        $dammy_user = "usr_00000000-0000-0000-0000-000000000000"
        $world_id   = $txt_worldID.Text

        $room_url = "vrchat://launch/?ref=vrchat.com&id={0}:OptionalBoot" -f ($world_id)

        if ($rdi_friendp.IsChecked) {
            $room_url += ("~hidden({0})" -f $dammy_user)
        }
        if ($rdi_friend.IsChecked) {
            $room_url += ("~friends({0})" -f $dammy_user)
        }
        if ($rdi_invitep.IsChecked) {
            $room_url += ("~private({0})~canRequestInvite" -f $dammy_user)
        }
        if ($rdi_invite.IsChecked) {
            $room_url += ("~private({0})" -f $dammy_user)
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
# Show Window
####################
$window.ShowDialog() > $null
$window = $null