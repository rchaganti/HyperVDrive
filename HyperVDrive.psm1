using namespace Microsoft.PowerShell.SHiPS

#Load support functions
. "$PSScriptRoot\HyperVDrive.helper.ps1"

[SHiPSProvider()]
class HVRoot : SHiPSDirectory
{
    # static member to keep track of connected Hyper-V hosts
    static [System.Collections.Generic.List``1[Microsoft.HyperV.PowerShell.VMHost]] $connectedHosts
    
    # Default constructor
    HVRoot([string]$name):base($name)
    {
    }

    [object[]] GetChildItem()
    {
        $obj = @()

        if([HVRoot]::connectedHosts)
        {
            [HVRoot]::connectedHosts | ForEach-Object {
                $obj += [HVMachine]::new($_.ComputerName, $_)
            }
        }
        # Else default to localhost
        else{
            try
            {
                $obj += [HVMachine]::new($env:COMPUTERNAME)    
            }
            catch
            {
                Write-Warning 'The local node does not seem to be a Hyper-V host. Use Connect-VMHost to connect to a remote computer.'   
            }
        }
        return $obj
    }
}

[SHiPSProvider()]
class HVMachine : SHiPSDirectory
{
    [Microsoft.HyperV.PowerShell.VMHost]$connectedHost = $null

    HVMachine([string]$name):base($name)
    {
        $this.connectedHost = Get-VMhost -ComputerName $name
        [HVRoot]::connectedHosts += $this.connectedHost
    }

    HVMachine([string]$name, [Microsoft.HyperV.PowerShell.VMHost]$connectedHost):base($name)
    {
        $this.connectedHost = $connectedHost
    }

    [object[]] GetChildItem()
    {
        $obj = @()
        
        $vms = (Get-VM -ComputerName $this.connectedHost.ComputerName).VMName | Sort-Object
        foreach ($vm in $vms)
        {
            $obj = @()
            $obj += [VirtualMachines]::new('VirtualMachines', $this.connectedHost.ComputerName)
            $obj += [VirtualSwitches]::new('VirtualSwitches', $this.connectedHost.ComputerName)
            return $obj

            #$obj += [HVVirtualMachine]::new($vm, $this.connectedHost)
        }
        
        return $obj
    }
}

[ShiPSProvider()]
class VirtualMachines : SHiPSDirectory
{
    [string] $hostname

    VirtualMachines([string]$name, [string] $hostName):base($name)
    {
        $this.hostname = $hostName        
    }
    
    [Object[]] GetChildItem()
    {
        $obj = @()
        
        # Find all VMs
        $vms = (Get-VM -ComputerName $this.hostName).Name | Sort-Object
        foreach ($vm in $vms) {
            $obj += [VirtualMachine]::new($vm, $this.hostName)
        }
        return $obj        
    }
}

[SHiPSProvider()]
class VirtualMachine : SHiPSDirectory
{
    [string] $vmname
    [string] $hostname

    VirtualMachine([string]$name, [string]$hostName):base($name)
    {
        $this.vmname = $name
        $this.hostname = $hostName
    }

    [object[]] GetChildItem()
    {
        return (Get-VM -ComputerName $this.hostname -Name $this.vmname)
    }    
}

[ShiPSProvider()]
class VirtualSwitches : SHiPSDirectory
{
    [string] $hostname

    VirtualSwitches([string]$name, [string] $hostName):base($name)
    {
        $this.hostname = $hostName        
    }
    
    [Object[]] GetChildItem()
    {
        $obj = @()
        
        # Find all VMs
        $vmSwitches = (Get-VMSwitch -ComputerName $this.hostName).Name | Sort-Object
        foreach ($switch in $vmSwitches) {
            $obj += [VirtualSwitch]::new($switch, $this.hostName)
        }
        return $obj        
    }
}

[SHiPSProvider()]
class VirtualSwitch : SHiPSDirectory
{
    [string] $switchname
    [string] $hostname

    VirtualSwitch([string]$name, [string]$hostName):base($name)
    {
        $this.switchname = $name
        $this.hostname = $hostName
    }

    [object[]] GetChildItem()
    {
        return (Get-VMSwitch -ComputerName $this.hostname -Name $this.switchname)
    }    
}

Export-ModuleMember -Function *