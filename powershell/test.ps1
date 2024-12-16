$jsonFilePath = $args[0] #reading argument from command line parameters (path to json file)
$jsondata = Get-Content -Raw -Path $jsonFilePath | ConvertFrom-Json # read the contents for json file and pass it to ConvertFrom-Json to create a powershell object
$parameters = $jsondata.parameters # reading parameters from json
$vmlist= $parameters.vmlist # reading vmlist (which is inside parameters)

function getLun($vm){
    # FUction to generate a unique LU
    $max = 0
    foreach ($disk in $vm.StorageProfile.DataDisks) {
        # Iterating through each disk that is attached to the VM
        $diskLun = [int]$disk.Lun
        Write-Host "DiskLUN"
        if($diskLun -ge $max){
            # Comparing LUN number to find the max LUN number
            $max = $diskLun
        }
    }
    # Returning max + 1 to make sure that lun is unique
    return ($max+1)
}

function isDiskAttached{
    param(
        $vm, 
        $diskName
    )
    # Fucntion to check if disk is already attached to VM or not
    Write-Host $vm.StorageProfile.DataDisks
    foreach ($disk in $vm.StorageProfile.DataDisks) {
        # Iterating through each disk that is attached to the VM
        Write-Host $disk.Name $diskName
        if($disk.Name -eq $diskName){
            # if attached disk name matches with given disk name
            return $true
        }
    }
    # if none of attached disk name matches with given disk name, then return false
    return $false
}

function getVMInstalledExtensions{
    # Function to return list of extensions installed in a VM
    param(
        $vm
    )
    $installedExtensions = Get-AzVMExtension -ResourceGroupName $vm.rg -VMName $vm.hostname # Get list of extensions installed in VM
    [System.Collections.ArrayList]$installedExtensionsList = @() # Creating an empty list for storing names of installed extension
    foreach($ext in $installedExtensions){
        # iterating through installed extensions and storing their name in list
        $installedExtensionsList.Add($ext.Name) 
    }
    return $installedExtensionsList
}

function InstallExtension{
    # Function to install extension in a VM
    param(
        $vm,
        $extension
    )

    $cloudExtension = Get-AzVMExtension -ResourceGroupName $vm.rg -VMName $vm.hostname -Name $extension.name -ErrorAction SilentlyContinue # Get details of Extension 
    # check if extension is already installed or not
    if ($null -eq $cloudExtension){
        Write-Host $extension.name
        Write-Host "Extension does not exist, installing extension...."
        # Install the extension to the VM
        Set-AzVMExtension -ResourceGroupName $vm.rg -VMName $vm.hostname -Name $extension.name -Publisher $extension.publisher -ExtensionType $extension.type -TypeHandlerVersion $extension.version
    }
}

function RemoveExtension{
    # Function to uninstall extensions 
    param(
        $vm,
        $jsonExtensions,
        $installedExtensions
    )
    $difference = $installedExtensions | Where-Object {$_ -notin $jsonExtensions} # Performing set difference between vminstalledextension and json extension

    # Uninstalling extensions in difference list 
    foreach($ext in $difference){
        Write-Host "Uninstalling extension..."
        Write-Host $ext
        # Uninstalling extension
        Remove-AzVMExtension -ResourceGroupName $vm.rg -Name $ext -VMName $vm.hostname -Force
    }
}

foreach ($vm in $vmlist.value) {  # iterating through each vm in the list
    Write-Host $vm.hostname
    Write-Host $vm.vmsize
    Write-Host $vm.osDiskType
    $cloudvm = Get-AzVM -ResourceGroupName $vm.rg -Name $vm.hostname # getting the information of virtual machine
    if ($null -eq $cloudvm ) {
        # added null check for absent VMs to avoid runtime error in powershell script
        continue
    }
    if ($cloudvm.HardwareProfile.Vmsize -ne $vm.VmSize) { #cheking if there is difference between json and cloud for vm size
        $cloudvm.HardwareProfile.VmSize = $vm.vmsize # updating the vmsize as mentioned in json
        Update-AzVM -VM $cloudvm -ResourceGroupName $vm.rg # calling azure cli function to commit the updates
    }
    foreach($disk in $vm.datadisks){
        # Iterating through disks in JSON
        $clouddisk = Get-AzDisk -ResourceGroupName $vm.rg -DiskName $disk.name # Fetching disk info from azure cloud
        $diskname = $disk.name
        $attachStatus = isDiskAttached -vm $cloudvm -diskName $diskname # Checking if disk is already attached to the VM or not
        if (($null -eq $clouddisk) -or ($attachStatus -eq $false)) {
            $lun = getLun($vm)
            if($null -eq $clouddisk){
                # if Disk does not exist then create a new disk
                $newdiskConfig = New-AzDiskConfig -Zone $cloudvm.Zones -Location $cloudvm.Location -DiskSizeGB $disk.disksize -SkuName $disk.disktype -CreateOption Empty
                New-AzDisk -ResourceGroupName $vm.rg -DiskName $disk.name -Disk $newdiskConfig
                # Attach the newly created disk to VM
                $newdisk = Get-AzDisk -ResourceGroupName $vm.rg -DiskName $disk.name
                $updatedvm = Add-AzVMDataDisk -VM $cloudvm -Name $disk.name -ManagedDiskId $newdisk.Id -CreateOption Attach -Lun $lun -Caching ReadWrite
            }else{
                # else if the Disk is already created but not yet attached to the VM
                # attaching the existing disk to VM
                $updatedvm = Add-AzVMDataDisk -VM $cloudvm -Name $disk.name -ManagedDiskId $clouddisk.Id -CreateOption Attach -Lun $lun -Caching ReadWrite
            }
            # Updating and commiting changes to VM
            Update-AzVM -ResourceGroupName $vm.rg -VM $updatedvm
            continue
        }
        if(($clouddisk.DiskSizeGB -ne $disk.disksize) -or ($clouddisk.sku -ne $disk.disktype)){
            # Checking for changes in size of already attached disk
            $clouddisk.DiskSizeGB = $disk.disksize # Updating size
            # Committing updated size to azure cloud
            Update-AzDisk -ResourceGroupName $vm.rg -DiskName $disk.name -Disk $clouddisk
        }
    }
    
    [System.Collections.ArrayList]$jsonExtensions = @() # Creating empty list for storing extension names from json 
    $installedExtensions = getVMInstalledExtensions -vm $vm # Getting list of extensions installed in VM
    foreach($extension in $vm.extensions){
        $jsonExtensions.Add($extension.name) # Adding extension name in the list
        InstallExtension -vm $vm -extension $extension # Calling installation of extension
    }
    RemoveExtension -vm $vm -jsonExtensions $jsonExtensions -installedExtensions $installedExtensions # Remove extension (if any to remove)
}
