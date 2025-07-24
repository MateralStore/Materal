$API_KEY = "oy2kbma37ahxksmawclqzmrpilznzesedidfdwie6eyoiu"
$ALLOWED_FILE_LIST = @(
    "Materal.Abstractions",
    #"Materal.COA",
    #"Materal.ContextCache",
    #"Materal.ContextCache.SqlitePersistence",
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
$ValidPackages = 0
foreach ($package in $ALLOWED_FILE_LIST) {
    Write-Host "检查包: $package" -ForegroundColor Cyan
    try {
        $localFile = (Get-ChildItem "../Packages/$package*.nupkg" | Sort-Object CreationTime -Descending)[0]
        $localFileName = $localFile.BaseName
        $localVersion = [System.Version]::Parse($localFileName.Split('.')[-3..-1] -join '.')
        Write-Host "本地最新版本: $localVersion" -ForegroundColor Cyan
        $serverTrueVersion = (Find-Package $package -AllVersions | Sort-Object Version -Descending)[0].Version.ToString()
        $serverVersion = [System.Version]::Parse($serverTrueVersion.Split('+')[0])
        Write-Host "服务器最新版本: $serverVersion" -ForegroundColor Cyan
        if ($localVersion -gt $serverVersion) {
            Write-Host "开始推送包: $package" -ForegroundColor Green
            dotnet nuget push $localFile.FullName --api-key $API_KEY --source https://api.nuget.org/v3/index.json --skip-duplicate
            Write-Host "推送成功: $package" -ForegroundColor Green
            $ValidPackages++
        } else {
            Write-Host "不需推送: $package" -ForegroundColor Cyan
        }
    }
    catch {
        Write-Host "找不到包: $package" -ForegroundColor Red
    }
}
Write-Host "推送成功包数: $ValidPackages" -ForegroundColor Green