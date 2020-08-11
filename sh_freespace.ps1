#selfheal - piece - Disk Space

cls
function Install_CleanMGR()
{
    $osver = (Get-WmiObject win32_operatingsystem).version
    switch (-join ($osver.tochararray() | select-object -first 3))
    {
        '6.0'
        {
            #2008/Vista
            write-host "Installing cleanmgr for 2008/Vista" -ForegroundColor Cyan
            #Copy EXE
            copy-item -Path "C:\Windows\winsxs\amd64_microsoft-windows-cleanmgr_31bf3856ad364e35_6.0.6001.18000_none_c962d1e515e94269\cleanmgr.exe" -destination "C:\Windows\System32\"
            #Copy MUI
            copy-item -path "C:\Windows\winsxs\amd64_microsoft-windows-cleanmgr.resources_31bf3856ad364e35_6.0.6001.18000_en-us_b9f50b71510436f2\cleanmgr.exe.mui" -destination "C:\Windows\System32\en-US\"
            Start-Process "c:\windows\system32\cleanmgr.exe /verylowdisk"
        }
        '6.1'
        {
            #2008R2/Win7 - Requires KB2852386 Installed to clean up updates
            write-host "Installing cleanmgr for 2008R2/Win7" -ForegroundColor Cyan
            #Copy EXE
            copy-item -path "C:\Windows\winsxs\amd64_microsoft-windows-cleanmgr_31bf3856ad364e35_6.1.7600.16385_none_c9392808773cd7da\cleanmgr.exe" -destination "C:\Windows\System32\"
            #Copy MUI
            copy-item -Path "C:\Windows\winsxs\amd64_microsoft-windows-cleanmgr.resources_31bf3856ad364e35_6.1.7600.16385_en-us_b9cb6194b257cc63\cleanmgr.exe.mui" -destination "C:\Windows\System32\en-US\"
            Start-Process "c:\windows\system32\cleanmgr.exe /verylowdisk"

        }
        '6.2'
        {
            #2012/Win8
            write-host "Installing cleanmgr for 2012/Win8" -ForegroundColor Cyan
            #Copy EXE
            copy-item -path "C:\Windows\WinSxS\amd64_microsoft-windows-cleanmgr_31bf3856ad364e35_6.2.9200.16384_none_c60dddc5e750072a\cleanmgr.exe" -destination "C:\Windows\System32\"
            #Copy MUI
            copy-item -path "C:\Windows\WinSxS\amd64_microsoft-windows-cleanmgr.resources_31bf3856ad364e35_6.2.9200.16384_en-us_b6a01752226afbb3\cleanmgr.exe.mui" -destination "C:\Windows\System32\en-US\"
            Start-Process "c:\windows\system32\cleanmgr.exe /verylowdisk"
        }
        '6.3'
        {
            #2012r2/Win8.1
            write-host "Unable to install cleanmgr on 2012R2 due to compression and required reboots" -ForegroundColor Cyan
            #To clean up updates, use DISM
            #dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase
        }
    }
}

function CheckFor_cleanmgr()
{
    $exe_exists = (test-path -path 'c:\windows\system32\cleanmgr.exe');
    $mui_exists = (test-path -path 'c:\windows\system32\en-us\cleanmgr.exe.mui');
    if ($exe_exists -and $mui_exists)
    {
        return $true;
    }
    else
    {
        return $false;
    }
}

function cleanmgr_funk()
{
    if(CheckFor_cleanmgr)
    {
        Start-Process "c:\windows\system32\cleanmgr.exe /verylowdisk"
        #cmd /c 'c:\windows\system32\cleanmgr.exe /verylowdisk /autoclean'
    }
    else
    {
        Install_cleanmgr;
    }
}


function CheckFreeSpace()
{
    #if freespace < X, clear logs and run cleanmgr
    $deets = Get-CimInstance -Class Win32_LogicalDisk | Select-Object @{Name="Size(GB)";Expression={$_.size/1gb}}, @{Name="Free Space(GB)";Expression={$_.freespace/1gb}}, @{Name="Free (%)";Expression={"{0,6:P0}" -f(($_.freespace/1gb) / ($_.size/1gb))}}, DeviceID, DriveType | Where-Object DriveType -EQ '3'
    foreach ($drive in $deets)
    {
        write-host "Checking drive " + $drive.DeviceID;
        $free = $drive.'Free Space(GB)' / $drive.'Size(GB)';
        if ($free -le 0.15)
        {
            write-host $drive.DeviceID + " is below 15%, starting cleanup";
            #dism
            #cleanmgr
        }
        else
        {
            write-host $drive.DeviceID + " is above 15% threshold, skipping cleanup"; #give ability to force clean
        }
    }


}

function CleanUpdates()
{
    $winsxs_size = (Get-ChildItem 'c:\windows\winsxs\' | Measure-Object -Property Length -sum).sum / 1GB;
    write-host "WinSXS Folder Size :: " + $winsxs_size + "GB";
    $osver = (Get-WmiObject win32_operatingsystem).version;
    switch (-join ($osver.tochararray() | select-object -first 3))
    {
        '6.0'
        {
            #2008/Vista
            write-host "Clearing WinSXS for Server 2008 (SP2)" -ForegroundColor Cyan
            #For SP1 : vsp1cln.exe
            #For SP2 : compcln.exe
            Start-Process "c:\windows\system32\compcln.exe /y"
            #cmd /c 'c:\windows\system32\compcln.exe /y'
        }
    }



    $winsxs_size = (Get-ChildItem 'c:\windows\winsxs\' | Measure-Object -Property Length -sum).sum / 1GB;
    write-host "WinSXS Folder Size :: " + $winsxs_size + "GB";
}

function CleanMiscFolders()
{
    ##Windows Error Reporting Queue
    write-host "Windowns Report Queue Size :: " + ((Get-ChildItem 'C:\ProgramData\Microsoft\Windows\WER\ReportQueue\' | Measure-Object -Property Length -sum).sum / 1GB) + "GB";
    Remove-Item -Recurse -Force 'C:\ProgramData\Microsoft\Windows\WER\ReportQueue\*'
    write-host "Windowns Report Queue Size :: " + ((Get-ChildItem 'C:\ProgramData\Microsoft\Windows\WER\ReportQueue\' | Measure-Object -Property Length -sum).sum / 1GB) + "GB";
    ##Windows Temp
    write-host "Windowns Temp Size :: " + ((Get-ChildItem 'C:\Windows\Temp\' | Measure-Object -Property Length -sum).sum / 1GB) + "GB";
    Remove-Item -Recurse -Force 'C:\Windows\Temp\*'
    write-host "Windowns Temp Size :: " + ((Get-ChildItem 'C:\Windows\Temp\' | Measure-Object -Property Length -sum).sum / 1GB) + "GB";
    ##
}




function header()
{
    write-host "------Self Healing------`n`n" -ForegroundColor Green

    write-host "---Checking Freespace---`n`n" -ForegroundColor Yellow
    #CheckFreeSpace;
    cleanmgr_funk;
    CleanUpdates;
    CleanMiscFolders;
}








#Start!
header;