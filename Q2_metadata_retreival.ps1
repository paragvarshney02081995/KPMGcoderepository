<#
INFORMATION:-----------------------------------------------------------------------------------------------------------------------------------------------------
The Azure Instance Metadata provides information about currently running virtual machine instances.
You can use it to manage and configure your virtual machines. This information includes the SKU, storage, network configurations,and upcoming maintenance events.
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
#>

#IPAddress for the Azure Virtual Machine instance to get the metadata inforamtion.
$IPaddress="169.254.169.254"

#REST API url to get the instance details
$MetadataURL="http://$IPaddress/metadata/instance?api-version=2021-02-01"

#Headers to get the details 
$Headers=@{"Metadata"="true"}

#Call rest method to get the results
Invoke-RestMethod -Headers $Headers -Method GET -Proxy $Null -Uri $MetadataURL | ConvertTo-Json -Depth 64


<#--------------------------------------------------------------#>
The response is a JSON string. The following example response is pretty-printed for readability.

{
    "compute": {
        "azEnvironment": "AZUREPUBLICCLOUD",
        "isHostCompatibilityLayerVm": "true",
        "licenseType":  "Windows_Client",
        "location": "westus",
        "name": "paragvirtualmachine",
        "offer": "WindowsServer",
        "osProfile": {
            "adminUsername": "admin",
            "computerName": "paragvirtualmachine",
            "disablePasswordAuthentication": "true"
        },
        "osType": "Windows",
        "placementGroupId": "f67c14ab-e92c-408c-ae2d-da15866ec79a",
        "platformFaultDomain": "36",
        "platformUpdateDomain": "42",
        "publisher": "Microsoft-Windows-Server-Group",
        "resourceGroupName": "parag-RG",
        "resourceId": "/subscriptions/xxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx/resourceGroups/parag-RG/providers/Microsoft.Compute/virtualMachines/paragvirtualmachine",
        "securityProfile": {
            "secureBootEnabled": "true",
            "virtualTpmEnabled": "false"
        },
        "sku": "2019-Datacenter",
        "storageProfile": {
            "dataDisks": [{
                "caching": "None",
                "createOption": "Empty",
                "diskSizeGB": "1024",
                "image": {
                    "uri": ""
                },
                "lun": "0",
                "managedDisk": {
                    "id": "/subscriptions/xxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx/resourceGroups/parag-RG/providers/Microsoft.Compute/disks/paragvirtualmachinedisk",
                    "storageAccountType": "Standard_LRS"
                },
                "name": "exampledatadiskname",
                "vhd": {
                    "uri": ""
                },
                "writeAcceleratorEnabled": "false"
            }],
            "imageReference": {
                "id": "",
                "offer": "WindowsServer",
                "publisher": "MicrosoftWindowsServer",
                "sku": "2019-Datacenter",
                "version": "latest"
            },
            "osDisk": {
                "caching": "ReadWrite",
                "createOption": "FromImage",
                "diskSizeGB": "30",
                "diffDiskSettings": {
                    "option": "Local"
                },
                "encryptionSettings": {
                    "enabled": "false"
                },
                "image": {
                    "uri": ""
                },
                "managedDisk": {
                    "id": "/subscriptions/xxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx/resourceGroups/parag-RG/providers/Microsoft.Compute/disks/paragvirtualmachinedisk",
                    "storageAccountType": "Standard_LRS"
                },
                "name": "paragvirtualmachinedisk",
                "osType": "Windows",
                "vhd": {
                    "uri": ""
                },
                "writeAcceleratorEnabled": "false"
            },
            "resourceDisk": {
                "size": "4096"
            }
        },
        "subscriptionId": "xxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx",
        "tags": "owner:parag;env:POC",
        "userData": "Zm9vYmFy",
        "version": "15.05.22",
        "vmId": "02aab8a4-74ef-476e-8182-f6d2ba4166a6",
        "vmScaleSetName": "paragvmscaleset",
        "vmSize": "Standard_A3",
        "zone": ""
    },
    "network": {
        "interface": [{
            "ipv4": {
               "ipAddress": [{
                    "privateIpAddress": "10.124.133.132",
                    "publicIpAddress": ""
                }],
                "subnet": [{
                    "address": "10.124.133.128",
                    "prefix": "26"
                }]
            },
            "ipv6": {
                "ipAddress": [
                 ]
            },
            "macAddress": "0011AAFFBB22"
        }]
    }
}

