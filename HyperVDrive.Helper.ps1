function Connect-HVHost
{
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName
    )
    
    ([HVRoot]::connectedHosts).Add((Get-VMHost -ComputerName $ComputerName))
}
