# WinSysadmin
Script for Windows Sysadmin

## Access.ps1

Access.ps1 vous permet d'auditer vos répertoires afin d'obtenir la liste compléte des utilisateurs et leurs droits.

Utilisation :

.\Get-FolderACL.ps1 -Path CheminLocal_OuReseau | ConvertTo-HTML | Out-File c:\resultat.html

La variable $ListExclusion à la ligne 9 vous permet d'exclure certains groupes du résultat ( ex: domain admins )
