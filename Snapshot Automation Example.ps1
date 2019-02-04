#This is a script made to automate snapshots for the VMs found on hosts attached to any vCenter appliance.
#This script is being referenced from Task Scheduler on this machine alone, if this machine is powered off or disconnected snapshots will not be taken.
#If this script is to be moved or changed please remember to update Task Scheduler accordingly!

$logfolder = "C:\Users\Administrator\Desktop\Script Logs"		#Logs Location
$vms = "Test*"		#Targets VMs.


Start-Transcript -Path "$logfolder\log_$(get-date -format `"yyyyMMdd_hhmmsstt`").txt" 	#This starts logging everything below in the $logfile

Connect-VIServer -Server 192.168.0.1 -User administrator@vsphere.local -Password [PASSWORD WILL GO HERE]		#Login information here, need to get encrypted


get-vm $vms | new-snapshot -Name "Weekly Snapshot" -Description "Snapshot Taken $(Get-Date)" -Quiesce -Memory #-Whatif		#Creates snapshots


$check = get-vm $vms | get-snapshot | 
	select @{
		Label="Age" ; Expression={((Get-Date) - $_.Created).days}
		},VM,@{
		Label="SizeGB";Expression={"{0:N2}" -f ($_.SizeGB)}
		},Created,Name		#Lists snapshots, has an expression to find snapshot age, displays VM, date of creation, and has expression to find size in GB.

$info1 = $check | Select Age,VM,SizeGB,Created,Name | Sort-Object -Property VM | ConvertTo-Html -Fragment		#Gathers snapshot Ages, assiciated VMs, Size, Creation date, and name, then converts to HTML. Sorts by VM property.
$info2 = $check | Measure-Object -Sum SizeGB | select Sum | ConvertTo-Html -Fragment		#This section adds total of all snapshots, then converts to HTML.

$info3 = get-vm $vms | select Name,@{
	Label="Number Of Snapshots";Expression={(Get-Snapshot -VM $_ | Measure-Object).Count}
	},@{
	Label="Total Snapshot Size in MB";Expression={("{0:N0}" -f (Get-Snapshot -VM $_ | Measure-Object -Sum SizeMB).Sum)}
	} | Sort-Object -Property Name |  ConvertTo-Html -Fragment		#Lists VMs and how many snapshots each has and how much space each VM's snapshots take in total. Sorts by Name property.


$Header = @"
<h1>Snapshot Report</h1>
<style>
TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
</style>
"@ 		#This section is entirely HTML formatting

ConvertTo-Html -Body "$info1 $info2 $info3" -Title "Snapshot report" -Head $Header | Out-File $logfolder\report.html		#This section puts together the HTML fragments and produces the HTML document.


get-vm $vms | get-snapshot | Where { $_.Name -NotLike "MASTER" -and $_.Created -lt (Get-Date).AddDays(-14)} | Remove-Snapshot -Confirm:$false #-Whatif		#Checks to see what snapshots are 45 days old or older and deletes them. Excludes the MASTER snapshot.



#–Whatif - check tool, delete for actual task completion
#Simply remove the # sign in front of the -Whatif found in the script for testing without creation or deletion of snapshots.

Stop-Transcript

Start-Sleep -s 10
