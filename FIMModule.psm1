
Function CreateObject
 {
    Param($objectType)
    End
    {
       $newObject = New-Object Microsoft.ResourceManagement.Automation.ObjectModel.ImportObject
       $newObject.ObjectType = $objectType
       $newObject.SourceObjectIdentifier = [System.Guid]::NewGuid().ToString()
       return $newObject
    }
 }
 
 Function SetAttribute
 {
    Param($object, $attributeName, $attributeValue, $isMultiValued=$false)
    End
    {
        $importChange = New-Object Microsoft.ResourceManagement.Automation.ObjectModel.ImportChange
        if ($isMultiValued)
		{
			$importChange.Operation = 0
		}
        else
		{
			$importChange.Operation = 1
		}
        $importChange.AttributeName = $attributeName
        $importChange.AttributeValue = $attributeValue
        $importChange.FullyResolved = 1
        $importChange.Locale = "Invariant"
        If ($object.Changes -eq $null) 
		{
			$object.Changes = (,$importChange)
		}
        Else
		{
			$object.Changes += $importChange
		}
    }
}

Function CreateResource
{
    Param([Parameter(Mandatory="true")][String]$ObjectType, [Parameter(Mandatory="true")][HashTable]$Attributes )
    End
    {
        $newObject = CreateObject $ObjectType
        foreach ($attributePair in $attributes.GetEnumerator())
        {
            SetAttribute -object $newObject -attributeName $attributePair.Name -attributeValue $attributePair.Value
        }
        $newObject | Import-FIMConfig -uri http://localhost:5725/ResourceManagementService
		return $newObject.TargetObjectIdentifier.split(":")[2]
    }
}

Function CreateSchemaObject
{
	Param([Parameter(Mandatory="true")][String]$Name, [String]$DisplayName=$Name)
	End
	{
		$existing_obj = GetObjectID -filter "/ObjectTypeDescription[Name='$Name']"
		if ($existing_obj -ne $null)
		{
			return "Skipping... Existing Object Found: $Name"
		}
		
		$objectID = CreateResource -ObjectType "ObjectTypeDescription" -Attributes @{Name="$Name";DisplayName="$DisplayName"}
		return $objectID
	}
}

Function CreateAttribute
{
	Param([Parameter(Mandatory="true")][String]$Name, [String]$DisplayName=$Name, [String]$DataType="String", [Boolean]$Multivalued=$False)
	End
	{
		$existing_attr = GetObjectID -filter "/AttributeTypeDescription[Name='$Name']"
		if ($existing_attr -ne $null)
		{
			return "Skipping... Existing Attribute Found: $Name"
		}
		
		$objectID = CreateResource -ObjectType "AttributeTypeDescription" -Attributes @{Name="$Name";DisplayName="$DisplayName";DataType="$DataType";Multivalued="$($Multivalued.ToString())"}
		return $objectID
	}
}

Function CreateBinding
{
	Param([Parameter(Mandatory="true")][String]$ObjectType, [Parameter(Mandatory="true")][String]$AttributeType, [Boolean]$Required=$False, [String]$DisplayName=$AttributeType, [String]$Validation="")
	End
	{
		$schema_object_oid = GetObjectID -filter "/ObjectTypeDescription[Name='$ObjectType']"
		$schema_attr_oid = GetObjectID -filter "/AttributeTypeDescription[Name='$AttributeType']"
		
		if (($schema_object_oid -ne $null) -and ($schema_attr_oid -ne $null))
		{
			$existing_binding = GetObjectID -filter "/BindingDescription[BoundAttributeType='$schema_attr_oid' and BoundObjectType='$schema_object_oid']"
			if ($existing_binding -ne $null)
			{
				return "Skipping... Existing Binding Found: $AttributeType -> $ObjectType"
			}
		
			$objectID = CreateResource -ObjectType "BindingDescription" -Attributes @{BoundAttributeType="$schema_attr_oid";BoundObjectType="$schema_object_oid";Required="$Required";DisplayName="$DisplayName";StringRegex="$Validation"}
			return $objectID
		}
		else
		{
			return $null
		}
	}
}

Function UpdateBinding
{
	PARAM([Parameter(Mandatory="true")][String]$ObjectType, [Parameter(Mandatory="true")][String]$AttributeType, [Switch]$Required, [Switch]$NotRequired, [String]$Validation="")
	END
	{
		$schema_object_oid = GetObjectID -filter "/ObjectTypeDescription[Name='$ObjectType']"
		$schema_attr_oid = GetObjectID -filter "/AttributeTypeDescription[Name='$AttributeType']"
		$binding_id = GetObjectID -filter "/BindingDescription[BoundObjectType='$schema_object_oid' and BoundAttributeType='$schema_attr_oid']"
		
		$UpdatedBinding = ModifyImportObject -TargetIdentifier $binding_id -ObjectType "BindingDescription"
		if ($NotRequired)
		{
			SetSingleValue $UpdatedBinding "Required" $false
		}
		elseif  ($Required)
		{
			SetSingleValue $UpdatedBinding "Required" $true
		}
		
		if ($Validation -ne "")
		{
			SetSingleValue $UpdatedBinding "StringRegex" $Validation
		}
		$UpdatedBinding | Import-FIMConfig -Uri "http://localhost:5725/ResourceManagementService"
		return $UpdatedBinding.TargetObjectIdentifier.Replace("urn:uuid:", "")
	}
}

Function UpdatePortalUI
{
	PARAM($LeftImage=$Null, $RightImage=$Null, $Text=$Null)
	END
	{
		$portal_ui_id = GetObjectID -filter "/PortalUIConfiguration"
		
		$UpdatedPortal = ModifyImportObject -TargetIdentifier $portal_ui_id -ObjectType "PortalUIConfiguration"
		if ($LeftImage -ne $null)
		{
			SetSingleValue $UpdatedPortal "BrandingLeftImage" $LeftImage
		}
		
		if ($RightImage -ne $null)
		{
			SetSingleValue $UpdatedPortal "BrandingRightImage" $RightImage
		}
		
		if ($Text -ne $null)
		{
			SetSingleValue $UpdatedPortal "BrandingCenterText" $Text
		}
		
		$UpdatedPortal | Import-FIMConfig -Uri "http://localhost:5725/ResourceManagementService"
		return $UpdatedPortal.TargetObjectIdentifier.Replace("urn:uuid:", "")
	}
}

Function CreateNavBarItem
{

	PARAM([Parameter(Mandatory="true")][String]$DisplayName, [Parameter(Mandatory="true")][String]$NavigationUrl, [String]$ParentOrder="100", [String]$Order="0", [String]$Description="", [Boolean]$IsConfigurationType=$true, [String[]]$UsageKeywords)
	END
	{
		$NewNavBar = CreateImportObject -ObjectType "NavigationBarConfiguration"
		SetSingleValue $NewNavBar "DisplayName" $DisplayName
		SetSingleValue $NewNavBar "NavigationUrl" $NavigationUrl
		SetSingleValue $NewNavBar "ParentOrder" $ParentOrder
		SetSingleValue $NewNavBar "Order" $Order
		SetSingleValue $NewNavBar "Description" $Description
		SetSingleValue $NewNavBar "IsConfigurationType" $IsConfigurationType
		foreach ($keyword in $UsageKeywords)
		{
			AddMultiValue $NewNavBar "UsageKeyword" $keyword
		}
		$NewNavBar | Import-FIMConfig -Uri "http://localhost:5725/ResourceManagementService"
		return $NewNavBar.TargetObjectIdentifier.Replace("urn:uuid:", "")
	}
}

Function UpdateNavBarItem
{
	PARAM([Parameter(Mandatory="true")][String]$ObjectID, [String[]]$AddUsageKeywords, [String[]]$RemoveUsageKeywords)
	END
	{
		$UpdatedNavBar = ModifyImportObject -TargetIdentifier $ObjectID -ObjectType "NavigationBarConfiguration"
		foreach ($RemoveKeyword in $RemoveUsageKeywords)
		{
			RemoveMultiValue $UpdatedNavBar "UsageKeyword" $RemoveKeyword
		}
		foreach ($AddKeyword in $AddUsageKeywords)
		{
			AddMultiValue $UpdatedNavBar "UsageKeyword" $AddKeyword
		}
		$UpdatedNavBar | Import-FIMConfig -Uri "http://localhost:5725/ResourceManagementService"
		return $UpdatedNavBar.TargetObjectIdentifier.Replace("urn:uuid:", "")
	}
}

Function CreateHomepageItem
{
	PARAM([Parameter(Mandatory="true")][String]$DisplayName, [Parameter(Mandatory="true")][String]$NavigationUrl, [Int]$ParentOrder=100, [Int]$Order=0, [String]$Description="", [Boolean]$IsConfigurationType=$true, [Int]$Region=1, [String]$ImageUrl="", [String[]]$UsageKeywords)
	END
	{
		$NewHomepage = CreateImportObject -ObjectType "HomepageConfiguration"
		SetSingleValue $NewHomepage "DisplayName" $DisplayName
		SetSingleValue $NewHomepage "NavigationUrl" $NavigationUrl
		SetSingleValue $NewHomepage "ParentOrder" $ParentOrder
		SetSingleValue $NewHomepage "Order" $Order
		SetSingleValue $NewHomepage "Description" $Description
		SetSingleValue $NewHomepage "IsConfigurationType" $IsConfigurationType
		SetSingleValue $NewHomepage "Region" $Region
		SetSingleValue $NewHomepage "ImageUrl" $ImageUrl
		foreach ($keyword in $UsageKeywords)
		{
			AddMultiValue $NewHomepage "UsageKeyword" $keyword
		}
		$NewHomepage | Import-FIMConfig -Uri "http://localhost:5725/ResourceManagementService"
		return $NewHomepage.TargetObjectIdentifier.Replace("urn:uuid:", "")
	}
}

Function UpdateHomePageItem
{
	PARAM([Parameter(Mandatory="true")][String]$ObjectID, [String[]]$AddUsageKeywords, [String[]]$RemoveUsageKeywords)
	END
	{
		$UpdatedHomePage = ModifyImportObject -TargetIdentifier $ObjectID -ObjectType "HomepageConfiguration"
		foreach ($RemoveKeyword in $RemoveUsageKeywords)
		{
			RemoveMultiValue $UpdatedHomePage "UsageKeyword" $RemoveKeyword
		}
		foreach ($AddKeyword in $AddUsageKeywords)
		{
			AddMultiValue $UpdatedHomePage "UsageKeyword" $AddKeyword
		}
		$UpdatedHomePage | Import-FIMConfig -Uri "http://localhost:5725/ResourceManagementService"
		return $UpdatedHomePage.TargetObjectIdentifier.Replace("urn:uuid:", "")
	}
}

Function CreateSet
{
	PARAM([String]$DisplayName, [String]$Filter="", [String[]]$ManualMembers)
	END
	{
		$NewSet = CreateImportObject -ObjectType "Set"
		SetSingleValue $NewSet "DisplayName" $DisplayName
		if ($Filter -ne "")
		{
			$filter_string = "<Filter xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance"" xmlns:xsd=""http://www.w3.org/2001/XMLSchema"" Dialect=""http://schemas.microsoft.com/2006/11/XPathFilterDialect"" xmlns=""http://schemas.xmlsoap.org/ws/2004/09/enumeration"">[FILTER_GOES_HERE]</Filter>"
			$filter_string = $filter_string.Replace("[FILTER_GOES_HERE]", $Filter)
			SetSingleValue $NewSet "Filter" $filter_string 
		}
		elseif (($Filter -eq "") -and ($ManualMembers.Count -gt 0))
		{
			foreach ($member in $ManualMembers)
			{
				AddMultiValue $NewSet "ExplicitMember" $member
			}
		}
		$NewSet | Import-FIMConfig -Uri "http://localhost:5725/ResourceManagementService"
		return $NewSet.TargetObjectIdentifier.Replace("urn:uuid:", "")
	}
}

Function CreateSyncRule
{
	PARAM([Parameter(Mandatory="true")][String]$FileName, [Parameter(Mandatory="true")][String]$ManagementAgentID="")
	END
	{
		$sr = Import-Clixml $FileName
		$NewSyncRule = CreateImportObject -ObjectType "SynchronizationRule"

		$rma = $sr.ResourceManagementAttributes
		foreach ($attr in $rma)
		{
			if (($attr.AttributeName -ne "CreatedTime") -and ($attr.AttributeName -ne "ObjectType") -and ($attr.AttributeName -ne "ObjectID") -and ($attr.AttributeName -ne "ConnectedSystem"))
			{
				if ($attr.AttributeName -eq "ManagementAgentID")
				{
					$attr.Value = $ManagementAgentID
				}
				
				if ($attr.isMultiValue -eq $false)
				{
					SetSingleValue $NewSyncRule $attr.AttributeName $attr.Value
				}
				else
				{
					foreach ($attrvalue in $attr.Values)
					{
						AddMultiValue $NewSyncRule $attr.AttributeName $attrvalue
					}
				}
			}
		}
		$NewSyncRule | Import-FIMConfig -Uri "http://localhost:5725/ResourceManagementService"
		return $NewSyncRule.TargetObjectIdentifier.Replace("urn:uuid:", "")
	}
}

Function ImportWorkflow
{
	PARAM([Parameter(Mandatory="true")][String]$FileName, [HashTable]$WorkflowIDs)
	END
	{
		$wf = Import-Clixml $FileName
		$NewWorkflow = CreateImportObject -ObjectType "WorkflowDefinition"

		$rma = $wf.ResourceManagementAttributes
		foreach ($attr in $rma)
		{
			if (($attr.AttributeName -ne "CreatedTime") -and ($attr.AttributeName -ne "ObjectType") -and ($attr.AttributeName -ne "ObjectID") -and ($attr.AttributeName -ne "Creator"))
			{
				if ($attr.isMultiValue -eq $false)
				{
					SetSingleValue $NewWorkflow $attr.AttributeName $attr.Value
				}
				else
				{
					foreach ($attrvalue in $attr.Values)
					{
						AddMultiValue $NewWorkflow $attr.AttributeName $attrvalue
					}
				}
			}
		}
		$NewWorkflow | Import-FIMConfig -Uri "http://localhost:5725/ResourceManagementService"
		return $NewWorkflow.TargetObjectIdentifier.Replace("urn:uuid:", "")
	}
}

Function ImportMPR
{
	PARAM([Parameter(Mandatory="true")][String]$FileName, [String]$RequestorID, [String]$TargetBeforeID, [String]$TargetAfterID, [String]$ActionWF)
	END
	{
		$mpr = Import-Clixml $FileName
		$NewMPR = CreateImportObject -ObjectType "ManagementPolicyRule"

		$rma = $mpr.ResourceManagementAttributes
		foreach ($attr in $rma)
		{
			if (($attr.AttributeName -ne "CreatedTime") -and ($attr.AttributeName -ne "ObjectType") -and ($attr.AttributeName -ne "ObjectID") -and ($attr.AttributeName -ne "Creator"))
			{
				if ($attr.AttributeName -eq "PrincipalSet")
				{
					$attr.Value = $RequestorID
				}
				elseif ($attr.AttributeName -eq "ResourceCurrentSet")
				{
					$attr.Value = $TargetBeforeID
				}
				elseif ($attr.AttributeName -eq "ResourceFinalSet")
				{
					$attr.Value = $TargetAfterID
				}
				elseif ($attr.AttributeName -eq "ActionWorkflowDefinition")
				{
					$attr.Values = @($ActionWF)
				}				
				
				if ($attr.isMultiValue -eq $false)
				{
					SetSingleValue $NewMPR $attr.AttributeName $attr.Value
				}
				else
				{
					foreach ($attrvalue in $attr.Values)
					{
						AddMultiValue $NewMPR $attr.AttributeName $attrvalue
					}
				}
			}
		}
		$NewMPR | Import-FIMConfig -Uri "http://localhost:5725/ResourceManagementService"
		return $NewMPR.TargetObjectIdentifier.Replace("urn:uuid:", "")
	}
}

Function UpdateMPR
{
	PARAM([Parameter(Mandatory="true")][String]$ObjectID, [Switch]$Enable, [Switch]$Disable, [String[]]$RemoveActionParameters, [String[]]$AddActionParameters)
	END
	{
		$UpdatedMPR = ModifyImportObject -TargetIdentifier $ObjectID -ObjectType "ManagementPolicyRule"
		if ($Enable)
		{
			SetSingleValue $UpdatedMPR "Disabled" $false
		}
		elseif ($Disable)
		{
			SetSingleValue $UpdatedMPR "Disabled" $true
		}
		
		foreach ($remove_param in $RemoveActionParameters)
		{
			RemoveMultiValue $UpdatedMPR "ActionParameter" $remove_param
		}
		foreach ($add_param in $AddActionParameters)
		{
			AddMultiValue $UpdatedMPR "ActionParameter" $add_param
		}
		
		$UpdatedMPR | Import-FIMConfig -Uri "http://localhost:5725/ResourceManagementService"
		return $UpdatedMPR.TargetObjectIdentifier.Replace("urn:uuid:", "")
	}
}

Function CreateRCDC
{
	PARAM([Parameter(Mandatory="true")][String]$FileName, [Parameter(Mandatory="true")][String]$TargetResource, [String]$DisplayName, [Boolean]$Create=$false, [Boolean]$Edit=$false, [Boolean]$View=$false)
	END
	{
		$ConfigurationData = Get-Content $FileName
	
		$NewRCDC = CreateImportObject -ObjectType "ObjectVisualizationConfiguration"
		SetSingleValue $NewRCDC "ConfigurationData" $ConfigurationData
		SetSingleValue $NewRCDC "TargetObjectType" $TargetResource
		SetSingleValue $NewRCDC "DisplayName" $DisplayName
		SetSingleValue $NewRCDC "AppliesToCreate" $Create
		SetSingleValue $NewRCDC "AppliesToEdit" $Edit
		SetSingleValue $NewRCDC "AppliesToView" $View
		
		$NewRCDC | Import-FIMConfig -Uri "http://localhost:5725/ResourceManagementService"
		return $NewRCDC.TargetObjectIdentifier.Replace("urn:uuid:", "")
	}
}

Function UpdateRCDC
{
	PARAM([Parameter(Mandatory="true")][String]$DisplayName, [Parameter(Mandatory="true")][String]$FileName)
	END
	{
		$ConfigurationData = Get-Content $FileName
		$rcdc_id = GetObjectID -filter "/ObjectVisualizationConfiguration[DisplayName='$DisplayName']"
		
		$UpdatedRCDC = ModifyImportObject -TargetIdentifier $rcdc_id -ObjectType "ObjectVisualizationConfiguration"
		SetSingleValue $UpdatedRCDC "ConfigurationData" $ConfigurationData
        #$ImportObjects += (,$UpdatedRCDC)
		
		$UpdatedRCDC | Import-FIMConfig -Uri "http://localhost:5725/ResourceManagementService"
		return $UpdatedRCDC.TargetObjectIdentifier.Replace("urn:uuid:", "")
	}
}

Function DeleteObject
{
    Param([Parameter(Mandatory="true")][String]$ObjectID)
    Process
    {
		$target_object = GetObject($ObjectID)
		if ($target_object -ne $null)
		{
			$DeleteObject = New-Object Microsoft.ResourceManagement.Automation.ObjectModel.ImportObject
			$DeleteObject.ObjectType = $target_object.ObjectType
			$DeleteObject.TargetObjectIdentifier = $ObjectID
			$DeleteObject.SourceObjectIdentifier = $ObjectID
			$DeleteObject.State = 'Delete'
			$DeleteObject | Import-FIMConfig -uri http://localhost:5725/ResourceManagementService
		}
	}
}

Function GetObject
{
	Param([Parameter(Mandatory="true")][String]$ObjectID)
	Process
	{
		$FimObject = export-fimconfig -uri http://localhost:5725/ResourceManagementService –onlyBaseResources -customconfig "/*[ObjectID='$ObjectID']"
		if ($FimObject -ne $null)
		{
			return $FimObject.ResourceManagementObject
		}
		else
		{
			return $null
		}
	}
}
		
Function GetObjectID
{
    Param([String]$filter)
    Process
    {
		$FimObject = QueryResource -Filter $filter
		
		if (($FimObject -ne $null) -and ($FimObject.Count -lt 2))
		{
			$objectID = (($FimObject.ResourceManagementObject.ObjectIdentifier).split(":"))[2]
			return $objectID
		}
		elseif ($FimObject.Count -gt 1)
		{
			throw "ERROR: More than one object is returned from the filter" 
		}
		else
		{
			return $null
		}
    }
}

function CreateImportObject
{
    PARAM([string]$ObjectType)
    END
    {
        $importObject = New-Object Microsoft.ResourceManagement.Automation.ObjectModel.ImportObject
        $importObject.SourceObjectIdentifier = [System.Guid]::NewGuid().ToString()
        $importObject.ObjectType = $ObjectType
        $importObject
    }
}

function SetSingleValue
{
    PARAM($ImportObject, $AttributeName, $NewAttributeValue, $FullyResolved=1)
    END
    {
        $ImportChange = CreateImportChange -AttributeName $AttributeName -AttributeValue $NewAttributeValue -Operation 1
        $ImportChange.FullyResolved = $FullyResolved
        AddImportChangeToImportObject $ImportChange $ImportObject
    }
}

function ModifyImportObject
{
    PARAM([string]$TargetIdentifier, $ObjectType = "Resource")
    END
    {
        $importObject = New-Object Microsoft.ResourceManagement.Automation.ObjectModel.ImportObject
        $importObject.ObjectType = $ObjectType
        $importObject.TargetObjectIdentifier = $TargetIdentifier
        $importObject.SourceObjectIdentifier = $TargetIdentifier
        $importObject.State = 1 # Put
        $importObject
    }
}


Function UpdateFilterScope
{
	Param([Parameter(Mandatory="true")][String]$Name, [String[]]$AddAllowedAttributes=$null)
	Process
	{
		$not_added_list = $null
		$filter_id = GetObjectID -filter "/FilterScope[DisplayName='$Name']"
		$mod_obj = ModifyImportObject -TargetIdentifier $filter_id -ObjectType "FilterScope"
		
		foreach ($attribute in $AddAllowedAttributes)
		{
			$attr_id = GetObjectID -filter "/AttributeTypeDescription[Name='$attribute']"
			if ($attr_id -ne $null)
			{
				AddMultiValue -ImportObject $mod_obj -AttributeName "AllowedAttributes" -NewAttributeValue $attr_id -FullyResolved 0
			}
			else
			{
				$not_added_list += $attribute
			}
		}
		
		$mod_obj | Import-FIMConfig -uri http://localhost:5725/ResourceManagementService
		
		if ($not_added_list -ne $null)
		{
			return $not_added_list
		}
	}
}

function QueryResource
{
    PARAM($Filter, $Uri = "http://localhost:5725/ResourceManagementService")
    END
    {
        $resources = Export-FIMConfig -CustomConfig $Filter -Uri $Uri –onlyBaseResources
        $resources
    }
}

function ResolveObject
{
    PARAM([string] $ObjectType, [string]$AttributeName, [string]$AttributeValue)
    END
    {
        $importObject = New-Object Microsoft.ResourceManagement.Automation.ObjectModel.ImportObject
        $importObject.TargetObjectIdentifier = $TargetIdentifier
        $importObject.ObjectType = $ObjectType
        $importObject.State = 3 # Resolve
        $importObject.SourceObjectIdentifier = [System.String]::Format("urn:uuid:{0}", [System.Guid]::NewGuid().ToString())
        $importObject.AnchorPairs = New-Object Microsoft.ResourceManagement.Automation.ObjectModel.JoinPair
        $importObject.AnchorPairs[0].AttributeName = $AttributeName
        $importObject.AnchorPairs[0].AttributeValue = $AttributeValue
        $importObject
    }
}

function CreateImportChange
{
    PARAM($AttributeName, $AttributeValue, $Operation)
    END
    {
        $importChange = New-Object Microsoft.ResourceManagement.Automation.ObjectModel.ImportChange
        $importChange.Operation = $Operation
        $importChange.AttributeName = $AttributeName
        $importChange.AttributeValue = $AttributeValue
        $importChange.FullyResolved = 1
        $importChange.Locale = "Invariant"
        $importChange
    }
}

function AddImportChangeToImportObject
{
    PARAM($ImportChange, $ImportObject)
    END
    {
        if ($ImportObject.Changes -eq $null)
        {
            $ImportObject.Changes = (,$ImportChange)
        }
        else
        {
            $ImportObject.Changes += $ImportChange
        }
    }
}


### FIM HELPER FUNCTIONS ###
function AddMultiValue
{
    PARAM($ImportObject, $AttributeName, $NewAttributeValue, $FullyResolved=1)
    END
    {
        $ImportChange = CreateImportChange -AttributeName $AttributeName -AttributeValue $NewAttributeValue -Operation 0
        $ImportChange.FullyResolved = $FullyResolved
        AddImportChangeToImportObject $ImportChange $ImportObject
    }
}

function RemoveMultiValue
{
    PARAM($ImportObject, $AttributeName, $NewAttributeValue, $FullyResolved=1)
    END
    {
        $ImportChange = CreateImportChange -AttributeName $AttributeName -AttributeValue $NewAttributeValue -Operation 2
        $ImportChange.FullyResolved = $FullyResolved
        AddImportChangeToImportObject $ImportChange $ImportObject
    }
}


Function CreateSearchScope
{
	PARAM([Parameter(Mandatory="true")][String]$DisplayName, [Parameter(Mandatory="true")][String]$ResourceType, [Int]$Order=100, [String]$SearchAttribute="DisplayName", [Parameter(Mandatory="true")][String]$Filter, [Parameter(Mandatory="true")][String[]]$UsageKeywords, [String]$SearchScopeColumn)
	END
	{
		$NewSearchScope = CreateImportObject -ObjectType "SearchScopeConfiguration"
		SetSingleValue $NewSearchScope "DisplayName" $DisplayName
		SetSingleValue $NewSearchScope "SearchScopeContext" $SearchAttribute
		SetSingleValue $NewSearchScope "Order" $Order
		SetSingleValue $NewSearchScope "SearchScopeResultObjectType" $ResourceType
		SetSingleValue $NewSearchScope "SearchScope" $Filter
		SetSingleValue $NewSearchScope "SearchScopeColumn" $SearchScopeColumn
		SetSingleValue $NewSearchScope "IsConfigurationType" $true
		foreach ($keyword in $UsageKeywords)
		{
			AddMultiValue $NewSearchScope "UsageKeyword" $keyword
		}
		$NewSearchScope | Import-FIMConfig -Uri "http://localhost:5725/ResourceManagementService"
		return $NewSearchScope.TargetObjectIdentifier.Replace("urn:uuid:", "")
	}
}

Function RunMA($ma_name, $run_profile_name)
{
	$filter = "name = '$($ma_name)'"
	$ma_obj = gwmi -Class "MIIS_ManagementAgent" -Namespace "root\MicrosoftIdentityIntegrationServer" -Filter $filter

	$ma_result = $ma_obj.Execute($run_profile_name)
	
	return $ma_result.ReturnValue
}