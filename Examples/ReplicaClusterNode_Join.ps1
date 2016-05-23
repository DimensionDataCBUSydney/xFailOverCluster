Configuration ReplicaClusterNode
{
    param([Parameter(Mandatory=$true)] 
          [ValidateNotNullorEmpty()] 
          [PsCredential] $domainAdminCred)
    Import-DSCResource -ModuleName xFailoverCluster
    node Cluster2
    {
        xWaitForCluster waitForCluster
        {
            Name = "Cluster_test"
            RetryIntervalSec = 10
            RetryCount = 60 
        }

        xCluster joinCluster
        {
            Name = "Cluster_test"
            StaticIPAddress = "10.209.157.200/24"
            DomainAdministratorCredential = $Cred

            DependsOn = "[xWaitForCluster]waitForCluster"
        } 
    }
}

$cd = @{
    AllNodes = @(
        @{
            NodeName = "Cluster2"
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser = $true
        }
    )
}
$Cred = New-Object PSCredential -ArgumentList "CORP\Administrator",(ConvertTo-SecureString -String "password" -AsPlainText -Force)

ReplicaClusterNode -domainAdminCred $Cred -ConfigurationData $cd -OutputPath C:\tmp\ReplicaClusterNode
Start-DscConfiguration -ComputerName Cluster2 -Path C:\tmp\ReplicaClusterNode -Force -Wait -Verbose


#Get-Cluster | Remove-Cluster -CleanupAD -Force