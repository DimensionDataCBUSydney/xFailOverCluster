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
        [string]$ClusterResourceName
    )
    
    #Make sure Failover Cluster Module is imported
    if ((Get-Module -Name FailoverClusters) -eq $null)
    {
        Import-Module -Name FailoverClusters
    }
    
    $ClusterResource = Get-ClusterResource -Name $ClusterResourceName -Cluster $ClusterName -ErrorAction SilentlyContinue
    $ClusterParameter = Get-ClusterParameter -Name $Name -InputObject $ClusterResource -Cluster $ClusterName -ErrorAction SilentlyContinue
    if ($null -ne $ClusterParameter)
    {
        $ReturnValue = @{
            Name = $Name
            ClusterName = $ClusterResource.Cluster.Name
            ClusterResourceName = $ClusterResource.Name
            Value = $ClusterParameter.Value
        }
    }
    else 
    {
        $ReturnValue = @{
            Name = $null
            ClusterName = $null
            ClusterResourceName = $null
            Value = $null
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
        [parameter(Mandatory)]
        [string]$Name,
        
        [parameter(Mandatory)]
        [string]$ClusterName,
        
        [parameter(Mandatory)]
        [string]$ClusterResourceName,
        
        [parameter(Mandatory)]
        [string]$Value
    )
    
    #Make sure Failover Cluster Module is imported
    if ((Get-Module -Name FailoverClusters) -eq $null)
    {
        Import-Module -Name FailoverClusters
    }
    
    $ClusterResource = Get-ClusterResource -Name $ClusterResourceName -Cluster $ClusterName -ErrorAction SilentlyContinue
    $ClusterParameter = Get-ClusterParameter -Name $Name -InputObject $ClusterResource -Cluster $ClusterName -ErrorAction SilentlyContinue
    if ($null -ne $ClusterParameter)
    {
        if ($ClusterParameter.Value -ne $Value)
        {
            Set-ClusterParameter -InputObject $ClusterResource -Name $Name -Value $Value
        }
    }
}
#
# The Test-TargetResource cmdlet.
#
function Test-TargetResource
{
    param(
        [parameter(Mandatory)]
        [string]$Name,
        
        [parameter(Mandatory)]
        [string]$ClusterName,
        
        [parameter(Mandatory)]
        [string]$ClusterResourceName,
        
        [parameter(Mandatory)]
        [string]$Value
    )
    
    #Make sure Failover Cluster Module is imported
    if ((Get-Module -Name FailoverClusters) -eq $null)
    {
        Import-Module -Name FailoverClusters
    }
    
    $isDesiredState = $true
    
    $ClusterResource = Get-ClusterResource -Name $ClusterResourceName -Cluster $ClusterName -ErrorAction SilentlyContinue
    $ClusterParameter = Get-ClusterParameter -Name $Name -InputObject $ClusterResource -Cluster $ClusterName -ErrorAction SilentlyContinue
    if ($null -ne $ClusterParameter)
    {
        if ($ClusterParameter.Value -ne $Value)
        {
            $isDesiredState = $false
            Write-Verbose -Message "The Cluster Parameter `"$Name`" for Cluster Resource `"$($ClusterResourceName)`" does not match the desired state. "
        }
    }
    else
    {
        $isDesiredState = $false
        Write-Verbose -Message "The Cluster Parameter `"$Name`" is not existed for Cluster Resource `"$($ClusterResourceName)`". "
    }
    
    $isDesiredState
}