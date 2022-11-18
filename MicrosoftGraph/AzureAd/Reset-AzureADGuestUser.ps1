<#
.SYNOPSIS
    Reset AzureAD Guest User Redemption Status
.DESCRIPTION
    Programmaticly reseting an Azure AD Guest User via Microsoft Graph (GraphAPI)
    The From on the System Generated E-mail message will be whichever account used to authenticate to MS Graph

    
.NOTES
    File Name  : Reset-AzureADGuestUser.ps1
    Author     : Brad Owen
    Version    : 1.0

    -v 1.0 (11 18 2022) : Initial Version
    
    
    
.EXAMPLE
   .\Reset-AzureADGuestUser.ps1

#>

$error.Clear()

# define variables


Import-Module Microsoft.Graph.Identity.SignIns

<#
    App Principal Permissions Required, must have any one permission for each of the two cmdlets.
    
    
    Get-MgUser        == User.Read, User.ReadWrite, User.ReadBasic.All, User.Read.All, User.ReadWrite.All, Directory.Read.All, Directory.ReadWrite.All
    New-MgInvitation  == User.Invite.All, User.ReadWrite.All, Directory.ReadWrite.All
    
#>

# connect to graph
Connect-MgGraph -Scopes "User.ReadWrite.All"

# change profile needed for reset
Select-MgProfile -Name beta

# get TenantId from graph
$Tenant = (Get-MgContext).TenantId

# get user that needs to be reset
$User = read-host "enter the user email address to be reset"

# get userid from input
$userid = (Get-MgUser -Filter "proxyAddresses/any(p:startswith(p,'smtp:$user'))" |Select-Object mail,id)

$params = @{
	InvitedUserEmailAddress = $userid.mail
	SendInvitationMessage = $true
	InvitedUserMessageInfo = @{
		MessageLanguage = "en-US"
		CcRecipients = @(
			@{
				EmailAddress = @{
					Name = "Full Name"
					Address = "first.last@domain.com"
				}
			}
		)
		CustomizedMessageBody = "Please click the link to reset your guest access with Company X"
	}
	InviteRedirectUrl = "https://myapps.microsoft.com?tenantId=$Tenant"
	InvitedUser = @{
		Id = $userid.id
	}
	ResetRedemption = $true
}

New-MgInvitation -BodyParameter $params