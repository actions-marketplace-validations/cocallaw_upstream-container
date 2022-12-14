#!/usr/bin/pwsh

#region parameters
param(
    [Parameter(mandatory = $true)]
    [string]$un,
    [Parameter(mandatory = $true)]
    [string]$pat,
    [Parameter(mandatory = $true)]
    [string]$si,
    [Parameter(mandatory = $true)]
    [string]$ct,
    [Parameter(mandatory = $true)]
    [string]$tfrgx
)
#endregion
#region variables
$token_URI = "https://hub.docker.com/v2/users/login"
$repolist_URI = "https://hub.docker.com/v2/namespaces/##namespace##/repositories/##repository##/tags"
$latest_tag_result = $null
$current_tag_result = $null
$rslt = $null
$tag_filterregex = $tfrgx
#endregion
#region functions
function Split-SourceImage {
    param(
        [Parameter(mandatory = $true)]
        [string]$simg
    )
    $split = $simg.Split("/")
    $s = @{}
    $s.add( "namespace" , $split[0] )
    $s.add( "repository" , $split[1] )
    return $s
}
function Get-GHAuthToken {
    param(
        [Parameter(mandatory = $true)]
        [string]$username,
        [Parameter(mandatory = $true)]
        [string]$Docker_PAT
    )
    $json_authBody = @{username = "$username"; password = "$Docker_PAT" } | ConvertTo-Json
    $token = (Invoke-RestMethod -Uri $token_URI -Method Post -ContentType "application/json" -Body $json_authBody).token
    return $token
}
function Build-ImageURI {
    param(
        [Parameter(mandatory = $true)]
        [string]$namespace,
        [Parameter(mandatory = $true)]
        [string]$repository
    )
    $uri = $repolist_URI.Replace("##namespace##", $namespace).Replace("##repository##", $repository)
    $uri += "?page_size=100"
    return $uri
}
function Get-ImageTags {
    param(
        [Parameter(mandatory = $true)]
        [string]$uri,
        [Parameter(mandatory = $true)]
        [string]$token
    )
    $tags = (Invoke-RestMethod -Uri $uri -Method Get -Body $json_GetBody -Headers @{Authorization = "Bearer " + $token }).results
    return $tags
}
function Start-TagFiltering {
    param(
        [Parameter(mandatory = $true)]
        [string]$tag_filterregex,
        [Parameter(mandatory = $true)]
        [Object[]]$tags
    )
    $err = 0
    $filtered_tags = $tags | Where-Object { $_.name -match $tag_filterregex }
    if ($filtered_tags -eq $null) {
        Write-Host "No tags found that match the regex $tag_filterregex"
        $err = 1
    }
    else {
        $sorted_tags = $filtered_tags | Sort-Object { $_.last_updated } -Descending
        $ltr = ($sorted_tags | Select-Object -First 1)
        Set-Variable -Name latest_tag_result -Value $ltr -Scope Global
        $ctr = $sorted_tags | Where-Object { $_.name -eq $ct }
        if ($ctr -eq $null) {
            set-variable -Name current_tag_result -Value $ltr -Scope Global
            $err = 2
        }
        else {
            Set-Variable -Name current_tag_result -Value $ctr -Scope Global
        }
    }
    return $err
}
function Start-TagComparison {
    param(
        [Parameter(mandatory = $true)]
        [PSCustomObject]$latest_tag_result,
        [Parameter(mandatory = $true)]
        [PSCustomObject]$current_tag_result
    )
    if ($latest_tag_result.last_updated -gt $current_tag_result.last_updated) {
        $chg = "true"
        $tag = $latest_tag_result.name
    }
    else {
        $chg = "false"
        $tag = $current_tag_result.name
    }
    $r = $chg + "|" + $tag
    return $r
}
#endregion
#region main
$ssi = Split-SourceImage -simg $si
$ght = Get-GHAuthToken -username $un -Docker_PAT $pat
$uri = Build-ImageURI -namespace $ssi['namespace'] -repository $ssi['repository']
$tags = Get-ImageTags -uri $uri -token $ght
$errcode = Start-TagFiltering -tag_filterregex $tfrgx -tags $tags

if ($errcode -eq 0) {
    $rslt = Start-TagComparison -latest_tag_result $latest_tag_result -current_tag_result $current_tag_result
    Set-Variable -Name rslt -Value $rslt -Scope Global
}
elseif ($errcode -eq 1) {
    $rslt = "false|regexfiltererror"
    Set-Variable -Name rslt -Value $rslt -Scope Global
}
elseif ($errcode -eq 2) {
    $rslt = "true|" + $latest_tag_result.name
    Set-Variable -Name rslt -Value $rslt -Scope Global
}

return $rslt
#endregion