$API_KEY = "oy2kbma37ahxksmawclqzmrpilznzesedidfdwie6eyoiu"
$PACKAGE_DIR = "E:\Project\Materal\Materal\NugetPackages"
# 自动获取最新版本号
$LatestVersion = ""
$AllVersions = @()
# 从所有nupkg文件中提取版本号
Get-ChildItem -Path $PACKAGE_DIR -Filter *.nupkg | ForEach-Object {
    if ($_.Name -match '\.(\d+\.\d+\.\d+.*)\.nupkg$') {
        $Version = $matches[1]
        $AllVersions += $Version
    }
}
# 如果找到了版本号，则选择最新的一个
if ($AllVersions.Count -gt 0) {
    # 按版本号排序（使用System.Version进行比较）
    $SortedVersions = $AllVersions | ForEach-Object { [System.Version]::new($_.Split('-')[0]) } | Sort-Object -Descending
    $LatestVersion = $SortedVersions[0].ToString()
    Write-Host "找到最新版本: $LatestVersion" -ForegroundColor Cyan
} else {
    Write-Host "未找到任何版本号，请检查文件夹中是否有nupkg文件" -ForegroundColor Yellow
    exit
}

$VERSION = $LatestVersion
$ALLOWED_FILE_LIST = @(
    "Materal.Abstractions",
    #"Materal.COA",
    "Materal.ContextCache",
    "Materal.ContextCache.SqlitePersistence",
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
Write-Host "开始验证包文件..." -ForegroundColor Cyan
$ValidPackages = 0
$InvalidPackages = 0
Get-ChildItem -Path $PACKAGE_DIR -Filter *.nupkg | ForEach-Object {
    $FullFileName = $_.Name    
    # 提取包名称和版本号
    if ($FullFileName -match '(.+?)\.(\d+\.\d+\.\d+.*)\.nupkg$') {
        $PackageName = $matches[1]
        $PackageVersion = $matches[2]        
        # 验证包名称和版本号
        $NameValid = $ALLOWED_FILE_LIST -contains $PackageName
        $VersionValid = $PackageVersion -eq $VERSION        
        # 输出验证结果
        if ($NameValid -and $VersionValid) {
            Write-Host "$PackageName (版本 $PackageVersion) 验证通过，准备发布..." -ForegroundColor Green
            dotnet nuget push $_.FullName --api-key $API_KEY --source https://api.nuget.org/v3/index.json --skip-duplicate
            $ValidPackages++
        }
    } else {
        Write-Host "无法解析文件名: $FullFileName" -ForegroundColor Yellow
        $InvalidPackages++
    }
}

# 输出验证结果统计
Write-Host "`n发布完成! 结果统计:" -ForegroundColor Cyan
Write-Host "成功: $ValidPackages 个包" -ForegroundColor Green
Write-Host "失败: $InvalidPackages 个包" -ForegroundColor $(if ($InvalidPackages -gt 0) { "Red" } else { "Green" })