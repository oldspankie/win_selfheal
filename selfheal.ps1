#self-healing fat script

#c:\windows\system32\cleanmgr /verylowdisk
cls





function header()
{
    write-host "------Self Healing------`n`n" -ForegroundColor Green

    if ($PSVersionTable.PSVersion.Major -lt '3')
    {
        #PSv2 doesn't natively support $PSScriptRoot, so we have to fill it in
        $PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition;
    }

    write-host "---Checking Freespace---`n`n" -ForegroundColor Yellow
    #CheckFreeSpace;
    $scr_FreeSpace = $PSScriptRoot + "\sh_freespace.ps1";
    & $scr_FreeSpace;
}








#Start!
header;