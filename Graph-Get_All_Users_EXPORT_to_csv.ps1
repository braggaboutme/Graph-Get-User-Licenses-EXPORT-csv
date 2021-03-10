# Define AppId, secret and scope, your tenant name and endpoint URL
$AppId = 'XXX-XXX-XXX-XXX-XXX'
$AppSecret = 'XXXXXXXXX'
$Scope = "https://graph.microsoft.com/.default"
$TenantName = "XXXX.onmicrosoft.com"
# Specify authentication URL
$Url = "https://login.microsoftonline.com/$TenantName/oauth2/v2.0/token"

$CSVpath = "C:\temp\LicenseCSVExport.csv"

# Add System.Web for urlencode
Add-Type -AssemblyName System.Web


# Create body
$Body = @{
    client_id = $AppId
	client_secret = $AppSecret
	scope = $Scope
	grant_type = 'client_credentials'
}

# Splat the parameters for Invoke-Restmethod for cleaner code
$PostSplat = @{
    ContentType = 'application/x-www-form-urlencoded'
    Method = 'POST'
    # Create string by joining bodylist with '&'
    Body = $Body
    Uri = $Url
}

# Request the token!
$Request = Invoke-RestMethod @PostSplat

# Create header
$Header = @{
    Authorization = "$($Request.token_type) $($Request.access_token)"
}

#https://docs.microsoft.com/en-us/graph/query-parameters#select-parameter
$ConstructedURL = 'https://graph.microsoft.com/v1.0/users?$filter=AccountEnabled eq true&$select=id,userPrincipalName,assignedLicenses&$top=1'
$Users = Invoke-RestMethod -Method Get -Uri $($ConstructedURL) -Headers $Header -ContentType "application/json"


        $licenseSKUArray = $users.value.assignedLicenses | foreach-Object {$_.SkuId}
        $licenseSKUString = $licenseSKUArray -join ";"
        
        $AllUserLicenses = [pscustomobject][ordered]@{
            userPrincipalName       = $users.value.userPrincipalName
            LicensesSKU             = $licenseSKUString
            ObjectID                = $users.value.id
            }
        
        $AllUserLicenses | Export-CSV -Path $CSVpath -Append -NoTypeInformation   

        Write-host "Added $($users.value.userPrincipalName)" -ForegroundColor Green

        #Handle Paging
        $urlnextpage = $($Users.'@odata.nextlink')

            if ($urlnextpage -ne $null)

            {

                do

                {

                $users = Invoke-RestMethod -uri ($urlnextpage) -Method Get -Headers $Header -ContentType "application/json"

                
                        $licenseSKUArray = $users.value.assignedLicenses | foreach-Object {$_.SkuId}
                        $licenseSKUString = $licenseSKUArray -join ";"
        
                        $AllUserLicenses = [pscustomobject][ordered]@{
                        userPrincipalName = $users.value.userPrincipalName
                        LicensesSKU       = $licenseSKUString
                        id                = $users.value.id
                        }
                        
                        $AllUserLicenses | Export-CSV -Path $CSVpath -Append -NoTypeInformation

                        Write-host "Added $($users.value.userPrincipalName)" -ForegroundColor Green

                $urlnextpage = $($Users.'@odata.nextlink')

                }

                until ($urlnextpage -eq $null)

            }
