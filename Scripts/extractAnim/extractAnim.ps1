function Export-Anims {
    param(
        [Parameter(Mandatory=$true)]
        [string]$blendPath,
        [Parameter(Mandatory=$true)]
        [int]$startFrame,
        [Parameter(Mandatory=$true)]
        [int]$endFrame,
        [Parameter(Mandatory=$true)]
        [string]$meshName,
        [Parameter(Mandatory=$true)]
        [string]$modelsDir,
        [Parameter(Mandatory=$true)]
        [string]$outputDir
    )
	#EXAMPLE: Export-Anims test.blend 1 20 Parasit test out

    $modelsFullPath = (Get-Location).Path + $modelsDir
    
    Write-Output $modelsFullPath
    
    # Confirmation dialog for dir delete
	$title    = $modelsDir
	$question = 'Are you sure you want to remove folder: ' + $modelsFullPath + '?'

	$choices = New-Object Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription]
	$choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&Yes'))
	$choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&No'))

	$decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
	if ($decision -eq 0) {
		Remove-Item $modelsDir -Recurse -ErrorAction Ignore
	} else {
		Return
	}

	# Create new directory for models
	New-Item $modelsDir -ItemType Directory
	
	#Run exporting
	# EXAMPLE: blender test.blend --background --python blenderExportEachFrame.py --start-frame 1 --end-frame 10 --export-file-path "V:/test" --mesh-name "Parasit"
	blender $blendPath --background --python blenderExportEachFrame.py -- --start-frame $startFrame --end-frame $endFrame --export-file-path $modelsFullPath --mesh-name $meshName
	
	# Create obj xmls for OG
	Create-Obj-Xmls $modelsDir $outputDir
}

function Create-Obj-Xmls {
    param(
        [Parameter(Mandatory=$true)]
        [string]$dir,
        [Parameter(Mandatory=$true)]
        [string]$out
    )

	$outputDir = Get-Item $out

	# Confirmation dialog for dir delete
	$title    = $outputDir.FullName
	$question = 'Are you sure you want to remove folder: ' + $outputDir.FullName + '?'

	$choices = New-Object Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription]
	$choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&Yes'))
	$choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&No'))

	$decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
	if ($decision -eq 0) {
		Remove-Item $out -Recurse -ErrorAction Ignore
	} else {
		Return
	}

	# Create new director
	New-Item $out -ItemType Directory

	$animObj = New-Object -TypeName psobject 

	$objectPaths = [System.Collections.ArrayList]@()

	$defaultAnim = New-Object -TypeName psobject 
	$defaultAnim | Add-Member -MemberType NoteProperty -Name animName -Value 'Default'
	$defaultAnim | Add-Member -MemberType NoteProperty -Name repeat -Value $true
	$animFrames = [System.Collections.ArrayList]@()

	$animations = [System.Collections.ArrayList]@()

	$i = 0
	Get-ChildItem $dir -Filter *.obj | 
	Foreach-Object {
		# Generate new xmls
		$newObjXmlName = $_.BaseName + '.xml'
		$regex = $newObjXmlName -match '(\d+)'
		Write-Output $newObjXmlName
		$frameNr = $Matches[0]
		Write-Output $frameNr

		# add xml path to list
		$objectPaths += "Data/Objects/$out/$newObjXmlName"

		# generate animFrame description
		$animframe = New-Object -TypeName psobject 
		$animframe | Add-Member -MemberType NoteProperty -Name frameTime -Value 0
		$animframe | Add-Member -MemberType NoteProperty -Name objectIndex -Value $i
		$animFrames += $animframe


		Copy-Item templateObj.xml $out/$newObjXmlName

		$content = (Get-Content $out/$newObjXmlName) -replace '@obj@', $_.BaseName

		$content = $content -replace '@dir@', $dir

		$content | Set-Content $out/$newObjXmlName
		$i++
	}

	# create anim json 
	$defaultAnim | Add-Member -MemberType NoteProperty -Name animFrames -Value $animFrames
	$animations += $defaultAnim

	# fill objectPaths with xml paths
	$animObj | Add-Member -MemberType NoteProperty -Name objectPaths -Value $objectPaths
	$animObj | Add-Member -MemberType NoteProperty -Name animations -Value $animations
	#$animObj | Add-Member -MemberType NoteProperty -Name animFrames -Value $animFrames

	ConvertTo-Json $animObj -Depth 5 | Set-Content "$out/$out-Anims.json"
}