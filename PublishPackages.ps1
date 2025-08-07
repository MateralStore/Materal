$API_KEY = "oy2kbma37ahxksmawclqzmrpilznzesedidfdwie6eyoiu"
$ALLOWED_FILE_LIST = @(
    "Materal.Abstractions",
    # "Materal.COA",
    # "Materal.ContextCache",
    # "Materal.ContextCache.SqlitePersistence",
    "Materal.EventBus.Abstraction",
    "Materal.EventBus.Memory",
    "Materal.EventBus.RabbitMQ",
    "Materal.Extensions",
    "Materal.Extensions.DependencyInjection",
    "Materal.Extensions.DependencyInjection.AspNetCore",
    "Materal.Gateway",
    "Materal.Logger",
    "Materal.Logger.Abstractions",
    "Materal.Logger.LoggerTrace",
    "Materal.Logger.MongoLogger",
    "Materal.Logger.MySqlLogger",
    "Materal.Logger.OracleLogger",
    "Materal.Logger.SqliteLogger",
    "Materal.Logger.SqlServerLogger",
    "Materal.Logger.WebSocketLogger",
    "Materal.MergeBlock",
    "Materal.MergeBlock.Abstractions",
    "Materal.MergeBlock.AccessLog",
    "Materal.MergeBlock.Application.Abstractions",
    "Materal.MergeBlock.Authorization",
    "Materal.MergeBlock.Authorization.Abstractions",
    #"Materal.MergeBlock.COA",
    "Materal.MergeBlock.ConfigCenter",
    "Materal.MergeBlock.Consul",
    "Materal.MergeBlock.Consul.Abstractions",
    "Materal.MergeBlock.Cors",
    "Materal.MergeBlock.Domain.Abstractions",
    "Materal.MergeBlock.EventBus",
    "Materal.MergeBlock.ExceptionInterceptor",
    "Materal.MergeBlock.GeneratorCode",
    "Materal.MergeBlock.Logger",
    "Materal.MergeBlock.Oscillator",
    "Materal.MergeBlock.Oscillator.Abstractions",
    "Materal.MergeBlock.Repository.Abstractions",
    "Materal.MergeBlock.ResponseCompression",
    "Materal.MergeBlock.Swagger",
    "Materal.MergeBlock.Swagger.Abstractions",
    "Materal.MergeBlock.Web",
    "Materal.MergeBlock.Web.Abstractions",
    "Materal.MergeBlock.WindowsService",
    "Materal.Oscillator",
    "Materal.Oscillator.Abstractions",
    "Materal.Test.Base",
    "Materal.Tools.Command",
    "Materal.Tools.Core",
    "Materal.TTA.Common",
    "Materal.TTA.EFRepository",
    "Materal.TTA.MySqlEFRepository",
    "Materal.TTA.SqliteEFRepository",
    "Materal.TTA.SqlServerEFRepository",
    "Materal.Utils",
    "Materal.Utils.AutoMapper",
    "Materal.Utils.BarCode",
    "Materal.Utils.CloudStorage.Tencent",
    "Materal.Utils.Consul",
    "Materal.Utils.Excel",
    "Materal.Utils.Image",
    "Materal.Utils.MongoDB",
    "Materal.Utils.Redis",
    "Materal.Utils.Text",
    "Materal.Utils.Wechat",
    "Materal.Utils.Windows",
    "RC.ConfigClient"
)
$LOCAL_PACKAGE_PATH = "../Packages"
$serviceResources = $null
$ValidPackages = 0
# 获取NuGet包的最新版本号
function Get-NuGetPackageServerLatestVersion {
    param (
        [string]$PackageName
    )
    if ($null -eq $serviceResources) {
        $serviceIndex = Invoke-RestMethod "https://api.nuget.org/v3/index.json"
        $serviceResources = $serviceIndex.resources
    }
    $version = Get-NuGetPackageServerLatestVersionFromNugetAPI $PackageName
    if ($null -eq $version) {
        $version = Get-NuGetPackageServerLatestVersionFromAzuresearch $PackageName
    }
    return $version
}
# 从NugetAPI获取Nuget包的最新版本
function Get-NuGetPackageServerLatestVersionFromNugetAPI {
    param (
        [string]$PackageName
    )
    try {
        $registrationUrl = $serviceResources | Where-Object { $_.'@type' -eq "RegistrationsBaseUrl/3.6.0" } | Select-Object -ExpandProperty '@id'
        $packageUrl = "$registrationUrl/$($PackageName.ToLower())/index.json"
        $packageData = Invoke-RestMethod $packageUrl
        if ($packageData.data -and $packageData.data.Count -gt 0) {
            $latestVersion = $packageData.items[-1].upper    
            $version = [System.Version]::Parse($latestVersion)
            return $version
        }
    }
    catch {
        Write-Warning "从NugetAPI获取包版本号失败"
        return $null
    }
}
# 从Azuresearch获取Nuget包的最新版本
function Get-NuGetPackageServerLatestVersionFromAzuresearch {
    param (
        [string]$PackageName
    )
    try {
        $searchUrls = $serviceResources | Where-Object { $_.'@type' -eq "SearchQueryService" } | Select-Object -ExpandProperty '@id'
        if ($searchUrls -is [array]) {
            $searchUrl = $searchUrls[0]
        }
        else {
            $searchUrl = $searchUrls
        }
        $searchUrl += "?q=packageid:$PackageName&prerelease=false&semVerLevel=2.0.0"
        $response = Invoke-RestMethod -Uri $searchUrl -Method Get -ErrorAction Stop
        if ($response.data -and $response.data.Count -gt 0) {
            $package = $response.data | Where-Object { $_.id -eq $PackageName }
            if ($package) {
                $version = $package.version
                $version = [System.Version]::Parse($version.Split('+')[0])
                return $version
            }
        }
        return $null
    }
    catch {
        Write-Warning "从Azuresearch获取包版本号失败"
        return $null
    }
}
# 获取本地最新版本的Nuget包文件
function Get-NugetPackageLocalFileLatestVersion {
    param (
        [string]$PackageName
    )
    $files = Get-ChildItem "$LOCAL_PACKAGE_PATH" -Filter "*.nupkg" | Where-Object { $_.Name -match "^$PackageName(\.\d){3}.nupkg$" }
    $version = $null
    $file = $null
    foreach ($currentFile in $files) {
        $currentVersion = Get-NuGetPackageVersionByFile $currentFile
        if (($null -eq $version) -or ($currentVersion -gt $version)) {
            $version = $currentVersion
            $file = $currentFile
        }
    }
    return $file
}
# 根据文件获取Nuget包版本号
function Get-NuGetPackageVersionByFile {
    param (
        $File
    )
    $versionString = $File.Name.Split('.')[-4..-2] -join '.'
    $version = [System.Version]::Parse($versionString)
    return $version
}

foreach ($packageName in $ALLOWED_FILE_LIST) {
    Write-Host "检查包: $packageName" -ForegroundColor Cyan
    $localFile = Get-NugetPackageLocalFileLatestVersion $packageName
    if ($null -eq $localFile) {
        Write-Warning "没有在本地找到包: $packageName"
        continue
    }
    $localVersion = Get-NuGetPackageVersionByFile $localFile
    if ($null -eq $localVersion) {
        Write-Warning "获取本地包$($packageName)版本失败:$($localFile.FullName)"
        continue
    }
    Write-Host "本地版本: $localVersion" -ForegroundColor Cyan
    $serverVersion = Get-NuGetPackageServerLatestVersion $packageName
    if ($null -eq $serverVersion) {
        Write-Warning "获取远端包$($packageName)版本失败"
        continue
    }
    Write-Host "远端版本: $serverVersion" -ForegroundColor Cyan
    if ($localVersion -gt $serverVersion) {
        Write-Host "开始推送包: $packageName" -ForegroundColor Green
        dotnet nuget push $localFile.FullName --api-key $API_KEY --source https://api.nuget.org/v3/index.json --skip-duplicate
        Write-Host "推送成功: $packageName" -ForegroundColor Green
        $ValidPackages++
    }
    else {
        Write-Host "不需推送: $packageName" -ForegroundColor Cyan
    }
}
Write-Host "推送成功包数: $ValidPackages" -ForegroundColor Green