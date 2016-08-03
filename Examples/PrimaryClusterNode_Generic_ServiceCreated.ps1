Configuration PrimaryClusterNode
{
    param([Parameter(Mandatory=$true)] 
          [ValidateNotNullorEmpty()] 
          [PsCredential] $domainAdminCred
          )
          
    Import-DSCResource -ModuleName xFailoverCluster
    node localhost
    {
        xCluster Cluster
        {
            Name = "Cluster_test"
            StaticIPAddress = "10.209.157.200/24"
            DomainAdministratorCredential = $domainAdminCred
        }
        xClusterGroup Ape_svc_Group
        {
            Name = "ape Cluster Role"
            ClusterName = "Cluster_test"
            GroupType = "Unknown"
        }
        xClusterResource ape_svc_res
        {
            Name = "Ape_svc_Resource"
            ClusterName = "Cluster_test"
            ClusterGroupName = "ape Cluster Role"
            ClusterResourceType = "Generic Service"
            State = "Online"
            ClusterResourceParameters = @{
                'ServiceName'         = 'AeLookupSvc'
                'StartupParameters' = '-k netsvcs'
            }
        }
    }
}

$cd = @{
    AllNodes = @(
        @{
            NodeName = "Localhost"
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser = $true
        }
    )
}
$Cred = New-Object PSCredential -ArgumentList "CORP\Administrator",(ConvertTo-SecureString -String "DevAdmin123" -AsPlainText -Force)

PrimaryClusterNode -domainAdminCred $Cred -ConfigurationData $cd -OutputPath C:\tmp\PrimaryClusterNode
Start-DscConfiguration -Path C:\tmp\PrimaryClusterNode -Force -Wait -Verbose


#Clean up
#Get-ClusterGroup -Name 'ape Cluster Role' | Remove-ClusterGroup -RemoveResources -Force -Confirm: $false
#Get-Cluster | Remove-Cluster -CleanupAD -Force