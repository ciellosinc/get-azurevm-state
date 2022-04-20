    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$AzureVMName,
        [string]$AzureTenantId,
        [string]$AzureVMResourceGroup,
        [string]$AzureClientId,
        [string]$AzureClientSecret)

$azurePassword = ConvertTo-SecureString $AzureClientSecret -AsPlainText -Force
$psCred = New-Object System.Management.Automation.PSCredential($AzureClientId , $azurePassword)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# This is requried by Find-Module, by doing it beforehand we remove some warning messages
Write-Host "Installing PowerShell modules d365fo.tools and Az" 
#Check Modules installed
$NuGet = Get-PackageProvider -Name nuget -ErrorAction SilentlyContinue
$Az = Get-InstalledModule -Name Az -ErrorAction SilentlyContinue
$DfoTools = Get-InstalledModule -Name d365fo.tools -ErrorAction SilentlyContinue
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

if([string]::IsNullOrEmpty($NuGet))
{
    Write-Host "NuGet not installed. Installing..." 
    Install-PackageProvider nuget -Scope CurrentUser -Verbose -Force -Confirm:$false
}

if([string]::IsNullOrEmpty($Az))
{
    Write-Host "Az not installed. Installing..." 
    Install-Module -Name Az -AllowClobber -Scope CurrentUser -Verbose -Force -Confirm:$False -SkipPublisherCheck 
}
else
{
    Write-Host "Az already installed. Updating..." 
    Update-Module -Name Az -AllowClobber -Verbose
}
if([string]::IsNullOrEmpty($DfoTools))
{
    Write-Host "d365fo.tools not installed. Installing..." 
    Install-Module -Name d365fo.tools -AllowClobber -Scope CurrentUser -Verbose -Force -Confirm:$false
}
else
{
    Write-Host "d365fo.tools already installed. Updating..."
    Update-Module -Name d365fo.tools -AllowClobber -Verbose
}

Import-Module -Name Az
Import-Module -Name d365fo.tools

$AzureRMAccount = Add-AzAccount -Credential $psCred -ServicePrincipal -TenantId $AzureTenantId -Verbose 

if ($AzureRMAccount) { 
    #Do Logic
    Write-Host "== Logged in == $AzureTenantId "

    Write-Host "Getting Azure VM State $AzureVMName"
    $VMStats = (Get-AzVM -Name "$AzureVMName" -ResourceGroupName "$AzureVMResourceGroup" -Status -Verbose).Statuses
    $PowerState = ($VMStats | Where Code -Like 'PowerState/*')[0].Code.Split("/")[1]
    Write-Host "....state is" $PowerState
    return $PowerState
}
