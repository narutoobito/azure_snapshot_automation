# az login

# SUBSCRIPTION

$subsList= az account list | ConvertFrom-Json

$subsList | Format-List
Write-Host "Select Subscription"

$subscriptionMap = @{}

for( $i=0; $i -lt $subsList.Length;$i++){
    Write-Host ($i+'1') "- " $subsList[$i].name
    $subscriptionMap.add($subsList[$i].name,$subsList[$i].id)
}

$userSubSelection= Read-Host "Enter name of subscription" 

while(!$subscriptionMap[$userSubSelection]){
    $userSubSelection = Read-Host "No Subscription with that name; Enter name or serial number of subscription" 

}


az account set --subscription $subscriptionMap[$userSubSelection]

Write-Host "Subscription set to - " (az account show | ConvertFrom-Json).name -ForegroundColor Green

#******************************************************************************************************************************
#VM LIST


$activeSubscription = (az account show | ConvertFrom-Json).name

$vmlist = (az vm list | ConvertFrom-Json)




do{
    Write-Host "#######################################################################" -ForegroundColor Blue
    Write-Host "VM List - "
    for( $i=0; $i -lt $vmlist.Length;$i++){
        $vm = $vmlist[$i]
        Write-Host ($i+'1') "-" $vm.name
    }
    $vmNames = $vmlist | ForEach-Object { $_.name }


    
    # Write-Host $vmNames
    
    $userVmSelection = ((Read-Host "Enter VM name for snapshots")  -split ',').trim()

    $VMsNotFound = ($userVmSelection | Where-Object {$_ -notin $vmNames })


    Write-Host "*****************************************************  " -ForegroundColor Blue

    if($VMsNotFound){
        Write-Host "Given Vm names were not found; please check - " $VMsNotFound -ForegroundColor Yellow
    }

    Write-Host "Do you Want to proceed with below VMs -" 
    Write-Host ($vmNames | Where-Object {$_ -in $userVmSelection })
    $userVmSelection = ($vmNames | Where-Object {$_ -in $userVmSelection })
    $userChoice = Read-Host "Y to proceed"
    Write-Host "*****************************************************" -ForegroundColor Blue
    
    
}while($userChoice -ne 'Y')

$vmlist = ($vmlist | Where-Object {$_.name -in $userVmSelection})

# $vmlist = ($vmlist | Write-Host $_.name )


# Write-Host $vmlist[0].id

$changeNumber = Read-Host "Provide Change number"

# $vmlist | Format-List

# # $vms=@()

foreach($vm in $vmlist){

    $cur = az vm show --ids $vm.id -o json | ConvertFrom-Json 
    # Write-Host $cur.storageProfile.osDisk.name
    # Write-Host $cur.resourceGroup

    $snapname = $cur.name+"_OS_Snapshot_"+ $changeNumber

    try{
        $checkName = az snapshot show --name $snapname --resource-group $cur.resourceGroup --subscription $activeSubscription 2>$null | ConvertFrom-Json

        if($checkName){
            Write-Host "Snapshot with name" + $checkName.name + " already exisits!!!" -ForegroundColor Red

        }
        else{
            $snapshot = az snapshot create --name $snapname --resource-group $cur.resourceGroup --source $cur.storageProfile.osDisk.name --incremental false --sku Standard_LRS --location $cur.location | ConvertFrom-Json
            Write-Host $snapshot.name "created Successfully" -ForegroundColor Green
        }
    }
    catch{

    }
    

    
}




# "timeCreated": "2024-09-01T20:59:23.486585+00:00",
# timeCreated": "2024-09-01T20:59:23.486585+00:00",