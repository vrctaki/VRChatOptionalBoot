# * Script Information:
#   - Name: VRChat  Optional Boot
#   - Version: 0.0.6
#   - Licence: MIT
#   - Author: vrctaki
# * Reference:
#   - XAML: https://qiita.com/Kosen-amai/items/27647f0a1ea5b41a9f5c
#   - VRChat Boot Path: https://kamishirolab.booth.pm/items/1954145
#   - Shortcut: https://teratail.com/questions/57372
#   - Shortcut Icon: http://marazul2015.blog.fc2.com/blog-entry-39.html
#   - Original Icon: https://twitter.com/naqtn/status/1257659359573635075
#   - WaterMark: https://github.com/kunaludapi/Powercli/tree/master/Powershell%20GUI%20Placeholder%20textbox%20example
# * Relation Tweet And Thread:
#   - https://twitter.com/vrctaki/status/1257567286698766336
#  
Param(
    [switch]$CreateShortcut
)

# Const
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

$script_version = "0.0.6"


# Initializing Environment
if ($CreateShortcut) {
    $favicon_path = Join-Path -Path $PSScriptRoot -ChildPath ((Get-Item $PSCommandPath).Basename + ".ico")
    if (-not (Test-Path $favicon_path)) {
      $favicon_path = $vrc_path + ',0';
    }

    $wsh = New-Object -ComObject Wscript.Shell
    $sc = $wsh.CreateShortCut((Get-Item $PSCommandPath).Basename + '.ps1.lnk')
    $sc.TargetPath   = 'powershell.exe'
    $sc.Arguments    = '-ExecutionPolicy RemoteSigned  -WindowStyle Hidden .\vrc_optional_boot.ps1'
    $sc.IconLocation = $favicon_path
    $sc.WorkingDirectory  = $PSScriptRoot
    $sc.HotKey = "CTRL+SHIFT+Return"
    $sc.save()
    return
}

# Import Modules
Add-Type -Assembly System.Windows.Forms
Add-Type -AssemblyName PresentationFramework


# UI
[xml]$xaml = Get-Content ".\main.xaml"


# Create Window 
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

$window.Title = ("VRChat Optional Boot(v{0})" -f ($script_version))


# Get Controls
$chk_desktopMode = $window.FindName("DesktopMode")
$chk_oculusRift  = $window.FindName("OnOculusRift")

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

$btm_boot        = $window.FindName("Boot")

# Set Events
$sb_toggleDesktopMode = {$chk_oculusRift.IsEnabled = -not ($chk_desktopMode.IsChecked)}
$chk_desktopMode.Add_Checked($sb_toggleDesktopMode)
$chk_desktopMode.Add_UnChecked($sb_toggleDesktopMode)

$sb_toggleGUIDebug = {$chk_sdk2debug.IsEnabled = $chk_udonDebug.IsEnabled = ($chk_guiDebug.IsChecked)}
$chk_guiDebug.Add_Checked($sb_toggleGUIDebug)
$chk_guiDebug.Add_UnChecked($sb_toggleGUIDebug)

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

$btm_boot.Add_Click({
    $boot_properties = @()

    if ($chk_desktopMode.IsChecked) {
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

    if ($txt_worldID.Text.Length -and $txt_worldID.Text -match $regex_worldID) {
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

    if ($chk_profile0.IsChecked) {
        Boot-VRChat (($boot_properties + "--profile=0") -join " ")
    }
    if ($chk_profile1.IsChecked) {
        Boot-VRChat (($boot_properties + "--profile=1") -join " ")
    }
    if ($chk_profile2.IsChecked) {
        Boot-VRChat (($boot_properties + "--profile=2") -join " ")
    }
    if ($chk_profile3.IsChecked) {
        Boot-VRChat (($boot_properties + "--profile=3") -join " ")
    }

    $window.close()
})


# shoft hand
$window.Add_KeyDown({
    $press_key = $_.Key

    $short_hands = @{
        'Return'=$btm_boot.Click
    }

    if ($short_hands.ContainsKey($press_key)) {
        &$short_hands[$press_key]
    }
})


# functions
function Boot-VRChat ([string]$parameters){
    Start-Process -FilePath $vrc_path -NoNewWindow -ArgumentList $parameters
}


# Show Window
$window.ShowDialog() > $null
$window = $null
