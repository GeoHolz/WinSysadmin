<# 
.Synopsis 
   This script is used to give the list of users with write access to the given path.
.DESCRIPTION 
   This script is used to give the list of users with write access to the given path.
   -Recurse : The Recurse option allows you to browse also the subdirectories
   The variable $ListExclusion allows to give groups to be excluded from the result (Example: Admins Domain)
   Geo Holz https://blog.jolos.fr
.EXAMPLE 
  Access.ps1 - Path "PATH_TO_DIRECTORY" -Recurse
#> 
[CmdletBinding()]
Param (
    [ValidateScript({Test-Path $_ -PathType Container})]
    [Parameter(Mandatory=$true)]
    [string]$Path,
    [switch]$Recurse
)

$ListExclusion = "local.local\domain admins", "local.local\other_group_to_exclude"

Write-Verbose "$(Get-Date): Script begins!"
Write-Verbose "Getting domain name..."
$Domain = (Get-ADDomain).NetBIOSName
Write-Verbose "Getting ACLs for folder $Path"

If ($Recurse)
{   Write-Verbose "...and all sub-folders"
    Write-Verbose "Gathering all folder names, this could take a long time on bigger folder trees..."
    $Folders = Get-ChildItem -Path $Path -Recurse | Where { $_.PSisContainer }
}
Else
{   $Folders = Get-Item -Path $Path
}

Write-Verbose "Gathering ACL's for $($Folders.Count) folders..."
ForEach ($Folder in $Folders)
{   Write-Verbose "Working on $($Folder.FullName)..."
    $ACLs = Get-Acl $Folder.FullName | ForEach-Object { $_.Access }
    ForEach ($ACL in $ACLs)
    {   
       If ($ListExclusion -notcontains $ACL.IdentityReference)
       {
        If ($ACL.IdentityReference -match "\\")
        {   If ($ACL.IdentityReference.Value.Split("\")[0].ToUpper() -eq $Domain.ToUpper())
            {   $Name = $ACL.IdentityReference.Value.Split("\")[1]
                If ((Get-ADObject -Filter 'SamAccountName -eq $Name').ObjectClass -eq "group")
                {   ForEach ($User in (Get-ADGroupMember $Name -Recursive | Select -ExpandProperty Name))
                    {   $Result = New-Object PSObject -Property @{
                            Path = $Folder.Fullname
                            Group = $Name
                            User = $User
                            FileSystemRights = $ACL.FileSystemRights
                            AccessControlType = $ACL.AccessControlType
                            Inherited = $ACL.IsInherited
                        }
                        $Result | Select Path,Group,User,FileSystemRights,AccessControlType,Inherited
                    }
                }
                Else
                {    $Result = New-Object PSObject -Property @{
                        Path = $Folder.Fullname
                        Group = ""
                        User = Get-ADUser $Name | Select -ExpandProperty Name
                        FileSystemRights = $ACL.FileSystemRights
                        AccessControlType = $ACL.AccessControlType
                        Inherited = $ACL.IsInherited
                    }
                    $Result | Select Path,Group,User,FileSystemRights,AccessControlType,Inherited
                }
            }
            Else
            {   $Result = New-Object PSObject -Property @{
                    Path = $Folder.Fullname
                    Group = ""
                    User = $ACL.IdentityReference.Value
                    FileSystemRights = $ACL.FileSystemRights
                    AccessControlType = $ACL.AccessControlType
                    Inherited = $ACL.IsInherited
                }
                $Result | Select Path,Group,User,FileSystemRights,AccessControlType,Inherited
            }
        }
      }
    }
}
Write-Verbose "$(Get-Date): Script completed!"
