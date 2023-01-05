using System;
using System.IO;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using nClam;

namespace PoC.VirusScan.Function
{
    public class ScanBlobFunctions
    {
        private readonly ILogger _logger;
        private readonly IClamClient _clam;

        public ScanBlobFunctions(ILoggerFactory loggerFactory, IClamClient clam)
        {
            _logger = loggerFactory.CreateLogger<ScanBlobFunctions>();
            this._clam = clam;
        }

        //ScanFilesConnectionString is in User Secrets instead of local.settings.json. Its value locally is UseDevelopmentStorage=true
        [Function(nameof(ScanBlob))]
        public async Task ScanBlob([BlobTrigger("upload/{name}", Connection = "ScanFilesConnectionString")] byte[] myBlob, string name)
        {
            // Scanning for viruses...
            var scanResult = await _clam.SendAndScanFileAsync(myBlob);

            switch (scanResult.Result)
            {
                case ClamScanResults.Clean:
                    _logger.LogInformation($"The file \"{name}\" is clean");
                    break;
                case ClamScanResults.VirusDetected:
                    _logger.LogInformation($"Virus Found in \"{name}\"");
                    _logger.LogInformation($"Virus: {scanResult.InfectedFiles?.First()?.VirusName}");
                    break;
                case ClamScanResults.Error:
                    _logger.LogInformation($"Error scanning \"{name}\": {scanResult.RawResult}");
                    break;
                default:
                    _logger.LogInformation($"Unknown scan result for \"{name}\": {scanResult.RawResult}");
                    break;
            }
        }
    }
}
