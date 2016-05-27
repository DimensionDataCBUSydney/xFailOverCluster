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
        [string]$ClusterGroupName,
        
        [parameter(Mandatory)]
        [string]$ClusterResourceType
    )
    
    #Make sure Failover Cluster Module is imported
    if ((Get-Module -Name FailoverClusters) -eq $null)
    {
        Import-Module -Name FailoverClusters
    }
    
    $ClusterResource = Get-ClusterResource -Name $Name -Cluster $ClusterName -ErrorAction SilentlyContinue
    if ($null -ne $ClusterResource)
    {
        $ReturnValue = @{
            Name = $ClusterResource.Name
            ClusterName = $ClusterResource.Cluster.Name
            ClusterGroupName = $ClusterResource.OwnerGroup.Name
            ClusterResourceType = $ClusterResource.ResourceType.Name
            Ensure = 'Present'
            State = $ClusterResource.State
        }
    }
    else 
    {
        $ReturnValue = @{
            Name = $null
            ClusterName = $null
            ClusterGroupName = $null
            ClusterResourceType = $null
            Ensure = 'Absent'
            State = $null
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
        [string]$ClusterGroupName,
        
        [parameter(Mandatory)]
        [string]$ClusterResourceType,
        
        [string]$State = "Online",
        
        [string]$Ensure = "Present"
    )
    
    #Make sure Failover Cluster Module is imported
    if ((Get-Module -Name FailoverClusters) -eq $null)
    {
        Import-Module -Name FailoverClusters
    }
    
    $ClusterResource = Get-ClusterResource -Name $Name -Cluster $ClusterName -ErrorAction SilentlyContinue
    if ($Ensure -eq "Present") 
    {
        if ($ClusterResource -ne $null)
        {
            #Check State
            if ($ClusterResource.State -ne $State) 
            {
                if ($State -eq "Online") 
                {
                    Start-ClusterResource -InputObject $ClusterResource
                }
                else 
                {
                    Stop-ClusterResource -InputObject $ClusterResource
                }
            }
            
            if ($ClusterResource.ResourceType.Name -ne $ClusterResourceType) 
            {
                #Remove previous as Cluster Resource cannot have same name in different role
                Remove-ClusterResource -Name $Name -Force
                #Create a new Resource in the target group
                $ClusterResource = Add-ClusterResource -Name $Name -Group $ClusterGroupName -ResourceType $ClusterResourceType -Cluster $ClusterName
                if ($State -eq "Online")
                {
                    Start-ClusterResource -InputObject $ClusterResource
                }
            }
            if ($ClusterResource.OwnerGroup.Name -ne $ClusterGroupName) 
            {
                #Remove previous as Cluster Resource cannot have same name in different role
                Remove-ClusterResource -Name $Name -Force
                #Create a new Resource in the target group
                $ClusterResource = Add-ClusterResource -Name $Name -Group $ClusterGroupName -ResourceType $ClusterResourceType -Cluster $ClusterName
                if ($State -eq "Online")
                {
                    Start-ClusterResource -InputObject $ClusterResource
                }
            }
        }
        else 
        {
            #Create a new Resource in the target group
            $ClusterResourceType = $ClusterResourceType
            $ClusterResource = Add-ClusterResource -Name $Name -Group $ClusterGroupName -ResourceType $ClusterResourceType -Cluster $ClusterName
            if ($State -eq "Online")
            {
                Start-ClusterResource -InputObject $ClusterResource
            }
        }
    }
    else
    {
        if ($ClusterResource -ne $null)
        {
            try 
            {
                $ClusterResource = Remove-ClusterResource -InputObject $ClusterResource -Force
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
        [parameter(Mandatory)]
        [string]$Name,
        
        [parameter(Mandatory)]
        [string]$ClusterName,
        
        [parameter(Mandatory)]
        [string]$ClusterGroupName,
        
        [parameter(Mandatory)]
        [string]$ClusterResourceType,
                
        [string]$State = "Online",
        
        [string]$Ensure = "Present"
    )
    
    #Make sure Failover Cluster Module is imported
    if ((Get-Module -Name FailoverClusters) -eq $null)
    {
        Import-Module -Name FailoverClusters
    }
    
    $ClusterResource = Get-ClusterResource -Name $Name -Cluster $ClusterName -ErrorAction SilentlyContinue
    
    $isDesiredState = $true
    
    if (($Ensure -eq "Present") -and ($ClusterResource -ne $null)) 
    {
        #Check State
        if ($ClusterResource.State -ne $State) 
        {
            $isDesiredState = $false
            Write-Verbose -Message "The State for Cluster Resource `"$($Name)`" does not match the desired state. "
        }
        
        if ($ClusterResource.ResourceType.Name -ne $ClusterResourceType) 
        {
            $isDesiredState = $false
            Write-Verbose -Message "The ClusterResourceType for Cluster Resource `"$($Name)`" does not match the desired state. "
        }
        
        if ($ClusterResource.OwnerGroup.Name -ne $ClusterGroupName) 
        {
            $isDesiredState = $false
            Write-Verbose -Message "The ClusterGroupName for Cluster Resource `"$($Name)`" does not match the desired state. "
        }
    }
    
    if (($Ensure -eq "Present" -and $ClusterResource -eq $null) -or ($Ensure -eq "Absent" -and $ClusterResource -ne $null)) 
    {
        $isDesiredState = $false
        Write-Verbose -Message "The Ensure state for Cluster Resource `"$($Name)`" does not match the desired state. "
    }
    
    $isDesiredState
}