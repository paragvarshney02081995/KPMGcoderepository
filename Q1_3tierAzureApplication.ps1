<#------------------------------------------------------------------------------------------------------------------
This PowerShell Script creates a virtual network with front-end and back-end subnets.
Traffic to the front-end subnet is limited to HTTP and SSH, while traffic to the back-end subnet is limited to MySQL, 
port 3306. After running the script, you will have two virtual machines, 
one in each subnet that you can deploy web server for front end application and MySQL software to have backend data retreival.
-------------------------------------------------------------------------------------------------------------------#>


[CmdletBinding()]
param(
[string][Parameter(Mandatory)][Helpermessage("Name of ResourceGroup to be provisioned")]$rgName,
[string][Parameter(Mandatory)][Helpermessage("Location of ResourceGroup to be provisioned")]$location,
[string][Parameter(Mandatory)][Helpermessage("Subscription for Resources to be provisioned")]$subscriptionID

)

#Check for Az Module availality and install if not available
$AzModule=Get-Module -Name Az -ListAvailable
if($null -eq $AzModule.Version)
{
   Install-Module Az -RequiredVersion 3.1.6 -Force 
   Import-Module Az -RequiredVersion 3.1.6 -Force -Global
}

#Login to Azure to provision the Resources
Connect-AzAccount

#Select the subscription ID to provision the resources
Select-Subscription -SubscriptionID $subscriptionID

# Create user object
$VMcredentials = Get-Credential -Message "Enter a username and password for the virtual machine."

# Create a resource group.
New-AzResourceGroup -Name $rgName -Location $location

# Create=ion of a virtual network with a front-end subnet and back-end subnet.
$FrontendSubnet = New-AzVirtualNetworkSubnetConfig -Name 'MySubnet-FrontEnd' -AddressPrefix '10.0.1.0/24'
$BackendSubnet = New-AzVirtualNetworkSubnetConfig -Name 'MySubnet-BackEnd' -AddressPrefix '10.0.2.0/24'
$vnet = New-AzVirtualNetwork -ResourceGroupName $rgName -Name 'MyVnet' -AddressPrefix '10.0.0.0/16' `
  -Location $location -Subnet $FrontendSubnet, $BackendSubnet

# Creation of a NSG rule to allow HTTP traffic in from the Internet to the front-end subnet.
$rule1 = New-AzNetworkSecurityRuleConfig -Name 'Allow-HTTP-All' -Description 'Allow HTTP' `
  -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 `
  -SourceAddressPrefix Internet -SourcePortRange * `
  -DestinationAddressPrefix * -DestinationPortRange 80

# Creation a NSG rule to allow RDP traffic from the Internet to the front-end subnet.
$rule2 = New-AzNetworkSecurityRuleConfig -Name 'Allow-RDP-All' -Description "Allow RDP" `
  -Access Allow -Protocol Tcp -Direction Inbound -Priority 200 `
  -SourceAddressPrefix Internet -SourcePortRange * `
  -DestinationAddressPrefix * -DestinationPortRange 3389


# Creation of a network security group for the front-end subnet.
$NSGfrontend = New-AzNetworkSecurityGroup -ResourceGroupName $RgName -Location $location `
  -Name 'MyNsg-FrontEnd' -SecurityRules $rule1,$rule2

# Associate the front-end NSG to the front-end subnet.
Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name 'MySubnet-FrontEnd' `
  -AddressPrefix '10.0.1.0/24' -NetworkSecurityGroup $NSGfrontend

# Creation of a NSG rule to allow SQL traffic from the front-end subnet to the back-end subnet.
$rule1 = New-AzNetworkSecurityRuleConfig -Name 'Allow-SQL-FrontEnd' -Description "Allow SQL" `
  -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 `
  -SourceAddressPrefix '10.0.1.0/24' -SourcePortRange * `
  -DestinationAddressPrefix * -DestinationPortRange 1433

# Creation of a NSG rule to allow RDP traffic from the Internet to the back-end subnet.
$rule2 = New-AzNetworkSecurityRuleConfig -Name 'Allow-RDP-All' -Description "Allow RDP" `
  -Access Allow -Protocol Tcp -Direction Inbound -Priority 200 `
  -SourceAddressPrefix Internet -SourcePortRange * `
  -DestinationAddressPrefix * -DestinationPortRange 3389

# Creation of a network security group for back-end subnet.
$NSGbackend = New-AzNetworkSecurityGroup -ResourceGroupName $RgName -Location $location `
  -Name "MyNsg-BackEnd" -SecurityRules $rule1,$rule2

# Associate the back-end NSG to the back-end subnet
Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name 'MySubnet-BackEnd' `
  -AddressPrefix '10.0.2.0/24' -NetworkSecurityGroup $NSGbackend

# Creation of a public IP address for the web server VM.
$publicipvm1 = New-AzPublicIpAddress -ResourceGroupName $rgName -Name 'MyPublicIp-Web' `
  -location $location -AllocationMethod Dynamic

# Creation of a NIC for the web server VM.
$nicVMweb = New-AzNetworkInterface -ResourceGroupName $rgName -Location $location `
  -Name 'MyNic-Web' -PublicIpAddress $publicipvm1 -NetworkSecurityGroup $NSGfrontend -Subnet $vnet.Subnets[0]

# Creation of a Web Server VM in the front-end subnet
$vmConfig = New-AzVMConfig -VMName 'MyVm-Web' -VMSize 'Standard_DS2' | `
  Set-AzVMOperatingSystem -Windows -ComputerName 'MyVm-Web' -Credential $VMcredentials | `
  Set-AzVMSourceImage -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' `
  -Skus '2016-Datacenter' -Version latest | Add-AzVMNetworkInterface -Id $nicVMweb.Id

$vmweb = New-AzVM -ResourceGroupName $rgName -Location $location -VM $vmConfig

# Creation of a public IP address for the SQL VM.
$publicipvm2 = New-AzPublicIpAddress -ResourceGroupName $rgName -Name MyPublicIP-Sql `
  -location $location -AllocationMethod Dynamic

# Creation of a NIC for the SQL VM.
$nicVMsql = New-AzNetworkInterface -ResourceGroupName $rgName -Location $location `
  -Name MyNic-Sql -PublicIpAddress $publicipvm2 -NetworkSecurityGroup $NSGbackend -Subnet $vnet.Subnets[1] 

# Creation of a SQL VM in the back-end subnet.
$vmConfig = New-AzVMConfig -VMName 'MyVm-Sql' -VMSize 'Standard_DS2' | `
  Set-AzVMOperatingSystem -Windows -ComputerName 'MyVm-Sql' -Credential $VMcredentials | `
  Set-AzVMSourceImage -PublisherName 'MicrosoftSQLServer' -Offer 'SQL2016-WS2016' `
  -Skus 'Web' -Version latest | Add-AzVMNetworkInterface -Id $nicVMsql.Id

$vmsql = New-AzVM -ResourceGroupName $rgName -Location $location -VM $vmConfig

# Creation of a NSG rule to block all outbound traffic from the back-end subnet to the Internet (must be done after VM creation)
$rule3 = New-AzNetworkSecurityRuleConfig -Name 'Deny-Internet-All' -Description "Deny Internet All" `
  -Access Deny -Protocol Tcp -Direction Outbound -Priority 300 `
  -SourceAddressPrefix * -SourcePortRange * `
  -DestinationAddressPrefix Internet -DestinationPortRange *

# Add NSG rule to Back-end NSG
$NSGbackend.SecurityRules.add($rule3)

Set-AzNetworkSecurityGroup -NetworkSecurityGroup $NSGbackend