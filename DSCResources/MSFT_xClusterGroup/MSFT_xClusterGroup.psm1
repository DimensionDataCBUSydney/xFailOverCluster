#
# xClusterGroup: DSC Resource that will Create/Remove Cluster Group in certain Cluster
#
# 


#
# The Get-TargetResource cmdlet.
#
function Get-TargetResource
{
    param(
        [parameter(Mandatory)]
        [string]$Name,
        
        [parameter(Mandatory)]
        [string]$ClusterName,
        
        [parameter(Mandatory)]
        [string]$GroupType
    )
    
    #Make sure Failover Cluster Module is imported
    if ((Get-Module -Name FailoverClusters) -eq $null)
    {
        Import-Module -Name FailoverClusters
    }
    #Flush DNS to make sure the updated Cluster Name is able to be contacted
    Clear-DnsClientCache -Verbose

    $failedcount = 0
    $ClusterValid = $false
    Do
    {
        $Cluster = Get-Cluster -Name $ClusterName -ErrorAction SilentlyContinue
        if ($Cluster -eq $null)
        {
            $failedcount += 1
            Start-Sleep -Seconds 5
        }
        else
        {
            $ClusterValid = $true
        }
    }
    While (-not ($ClusterValid -or ($failedcount -eq 3)))

    if ($failedcount -eq 3)
    {
        Write-Verbose -Message "Tried to get Cluster $ClusterName 3 times, but didn't get anything, exit now..."
        exit 1;
    }
    
    $ClusterGroup = Get-ClusterGroup -Name $Name -Cluster $ClusterName -ErrorAction SilentlyContinue
    if ($null -ne $ClusterGroup) 
    {
        $ReturnValue = @{
            Name = $ClusterGroup.Name
            ClusterName = $ClusterGroup.Cluster.Name
            GroupType = $ClusterGroup.GroupType
            Ensure = 'Present'
        }
    }
    else 
    {
        $ReturnValue = @{
            Name = $null
            ClusterName = $null
            GroupType = $null
            Ensure = 'Absent'
        }
    }
    
    $ReturnValue
}
#
# The Set-TargetResource cmdlet.
#
function Set-TargetResource
{
    param(
        [ValidateSet('Present', 'Absent')]
        [String]
        $Ensure = 'Present',
        
        [parameter(Mandatory)]
        [string]$Name,
        
        [parameter(Mandatory)]
        [string]$ClusterName,
        
        [parameter(Mandatory)]
        [string]$GroupType
    )
    
    #Make sure Failover Cluster Module is imported
    if ((Get-Module -Name FailoverClusters) -eq $null)
    {
        Import-Module -Name FailoverClusters
    }
    #Flush DNS to make sure the updated Cluster Name is able to be contacted
    Clear-DnsClientCache -Verbose

    $failedcount = 0
    $ClusterValid = $false
    Do
    {
        $Cluster = Get-Cluster -Name $ClusterName -ErrorAction SilentlyContinue
        if ($Cluster -eq $null)
        {
            $failedcount += 1
            Start-Sleep -Seconds 5
        }
        else
        {
            $ClusterValid = $true
        }
    }
    While (-not ($ClusterValid -or ($failedcount -eq 3)))

    if ($failedcount -eq 3)
    {
        Write-Verbose -Message "Tried to get Cluster $ClusterName 3 times, but didn't get anything, exit now..."
        exit 1;
    }
    
    $ClusterGroup = Get-ClusterGroup -Name $Name -Cluster $ClusterName -ErrorAction SilentlyContinue
    if ($Ensure -eq "Present") 
    {
        if ($ClusterGroup -ne $null)
        {
            if ($ClusterGroup.GroupType -ne $GroupType) 
            {
                #Remove existing Cluster Group
                $ClusterGroup = Remove-ClusterGroup -Name $ClusterGroup.Name -RemoveResources -Force
                #Add Cluster Group with correct Group Type
                $ClusterGroup = Add-ClusterGroup -Name $Name -GroupType $GroupType -Cluster $ClusterName
            }
        }
        else 
        {
            #Cluster Group doesn't exist, creating one
            $ClusterGroup = Add-ClusterGroup -Name $Name -GroupType $GroupType -Cluster $ClusterName
        }
    }
    else
    {
        if ($ClusterGroup -ne $null)
        {
            try 
            {
                $ClusterGroup = Remove-ClusterGroup -Name $ClusterGroup.Name -RemoveResources -Force
            }
            catch [System.Exception]
            {
                Write-Verbose -Message  $_.Exception.Message
            }
        }
    }
}
#
# The Test-TargetResource cmdlet.
#
function Test-TargetResource
{
    param(
        [ValidateSet('Present', 'Absent')]
        [String]
        $Ensure = 'Present',
        
        [parameter(Mandatory)]
        [string]$Name,
        
        [parameter(Mandatory)]
        [string]$ClusterName,
        
        [parameter(Mandatory)]
        [string]$GroupType
    )
    
    #Make sure Failover Cluster Module is imported
    if ((Get-Module -Name FailoverClusters) -eq $null)
    {
        Import-Module -Name FailoverClusters
    }
    #Flush DNS to make sure the updated Cluster Name is able to be contacted
    Clear-DnsClientCache -Verbose

    $failedcount = 0
    $ClusterValid = $false
    Do
    {
        $Cluster = Get-Cluster -Name $ClusterName -ErrorAction SilentlyContinue
        if ($Cluster -eq $null)
        {
            $failedcount += 1
            Start-Sleep -Seconds 5
        }
        else
        {
            $ClusterValid = $true
        }
    }
    While (-not ($ClusterValid -or ($failedcount -eq 3)))

    if ($failedcount -eq 3)
    {
        Write-Verbose -Message "Tried to get Cluster $ClusterName 3 times, but didn't get anything, exit now..."
        exit 1;
    }
    
    $ClusterGroup = Get-ClusterGroup -Name $Name -Cluster $ClusterName -ErrorAction SilentlyContinue
    
    $isDesiredState = $true
    
    if (($Ensure -eq "Present" -and $ClusterGroup -eq $null) -or ($Ensure -eq "Absent" -and $ClusterGroup -ne $null)) 
    {
        $isDesiredState = $false
        Write-Verbose -Message "The Ensure state for Cluster Group `"$($Name)`" does not match the desired state. "
    }
    
    if ($Ensure -eq 'Present' -and $ClusterGroup -ne $null) 
    {
        if ($ClusterGroup.GroupType -ne $GroupType) 
        {
            $isDesiredState = $false
            Write-Verbose -Message "The Group Type state for Cluster Group `"$($ClusterGroup.GroupType)`" does not match the desired state. "
        }
    }
    $isDesiredState
}