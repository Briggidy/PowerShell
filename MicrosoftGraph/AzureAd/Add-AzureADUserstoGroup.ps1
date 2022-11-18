<#
.SYNOPSIS
    Add AzureAD Users to M365 Group utilizing GraphAPI
.DESCRIPTION
    Users need to be provided in a CSV file with single headers 'UPN'.
    Output will be logged to the output\Add-AzureADUsertoGroup_$TimeStamp.csv by default

    
.NOTES
    File Name  : Add-AzureADUsertoGroup.ps1
    Author     : Brad Owen
    Version    : 1.0

    -v 1.0 (11 18 2022) : Initial Version
    
    
    
.EXAMPLE
   .\Add-AzureADUsertoGroup.ps1

#>

$error.Clear()

# define variables
$TimeStamp = get-date -Format MMddyyyyTHHmm
$ImportFile = "C:\scripts\input\group_of_users.csv"
$GroupObjectID = "replace_with_objectid_of_group"
$ErrorLog = "C:\scripts\output\Add-AzureADUsertoGroup_$TimeStamp.csv"

# define error log
$ErrorDataTable = New-Object System.Data.DataTable
[void]$ErrorDataTable.Columns.Add("UserName")
[void]$ErrorDataTable.Columns.Add("Reason")
[void]$ErrorDataTable.Columns.Add("ManualRetryCmd")

Import-Module Microsoft.Graph.Groups
Import-Module Microsoft.Graph.Users

<#
    App Principal Permissions Required, must have any one permission for each of the three cmdlets.
    
    Get-MgGroup       == GroupMember.Read.All, Group.Read.All, Directory.Read.All, Group.ReadWrite.All, Directory.ReadWrite.All
    Get-MgUser        == User.Read, User.ReadWrite, User.ReadBasic.All, User.Read.All, User.ReadWrite.All, Directory.Read.All, Directory.ReadWrite.All
    New-MgGroupMember == GroupMember.ReadWrite.All, Group.ReadWrite.All, Directory.ReadWrite.All
    
#>

# connect to graph
Connect-MgGraph -Scopes "User.Read.All","GroupMember.ReadWrite.All"

$Group = (Get-MgGroup -GroupId $GroupObjectID | Select-Object -Property ID,DisplayName)

    # define counter for progress bar
    $i = 1

    # import csv
    $Users = Import-csv -Path $ImportFile

    # Look for UPN
    $Users = $Users.upn
    
    # loop through the input file to get each user object id and add to specified group
    foreach ($User in $Users){
    
        # get user object id from UPN   
        $userid = (Get-MgUser -UserId $User | Select-Object -Property ID).id
            
   
            try
            {
            # progress bar used in case many users are being added
            Write-Progress -Activity "Adding User: $User to Group: $($Group.DisplayName)" -CurrentOperation "$i of $($Users.Count)"
            New-MgGroupMember -GroupId $Group.id -DirectoryObjectId $userid -ErrorAction Stop
            }
      
            catch
            {
            [void]$ErrorDataTable.Rows.Add($user,$error[0].errordetails.message,"New-MgGroupMember -GroupId $($Group.id) -DirectoryObjectId $($userid)")
            }
            # increment counter
            $i++
   
    }
    
    If($ErrorDataTable.Rows.Count -gt 0)
    {
        Write-Host ""
        Write-Host ""
        $ErrorDataTable | Export-Csv -Path $ErrorLog -NoTypeInformation
        Write-Host "Major Errors Encountered During Processing - See $ErrorLog"
    }



