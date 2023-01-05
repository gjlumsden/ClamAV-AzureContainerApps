# ClamAV Scanning using Azure Functions and Azure Container Apps

This repository contains a sample to run ClamAV official container in Azure Container Apps and an Azure Function to invoke the on-demand scan of files in an Azure Storage Blob Container.

The Function App code for this solution is based upon this blog post by Peter Rombouts [Scanning Blob storage for viruses with Azure Functions and Docker](https://peterrombouts.nl/2019/04/15/scanning-blob-storage-for-viruses-with-azure-functions-and-docker/). The key differences are this sample uses the official ClamAV image and uses the latest version of the nClam package in a .NET 7 Isolated Function App.

## Summary

This solution comprises the following:

* Bicep template to deploy:
  * A Virtual Network with a single subnet
  * An NSG to allow TCP traffic to a specified port
  * Azure Container Apps Environment
  * Azure Container App with a single container running ClamAV (official image). The container app exposes port 3310 for on-demand scanning
* A sample Function App (.NET 7 Isolated) with a single Blob Trigger Function
  * The blob trigger calls the containerised ClamAV endpoint to perform an on-demand scan
* A sample file that will raise a positive "virus detected" result.

    > ‼️ Warning  
    > This sample file will trigger a realtime virus scan detection. The file is a benign EICAR test file and is designed to test detection. More information can be found in the documentation section below.  
    > Either disable realtime protection for the directory into which the repo is cloned (e.g., Add an exclusion in Virus & thread protection on Windows), or clone the repo on an isolated Virtual Machine.

## Getting Started

The following instructions apply to getting started locally with Azure Functions and using a deployed Azure Container App.

1. Create a [Resource Group](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal#create-resource-groups)
1. Deploy main.bicep using one of the following methods:
   1. [Azure CLI](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-cli#deploy-local-bicep-file)
   1. [Azure PowerShell](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-powershell#deploy-local-bicep-file)
   1. [VS Code](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-vscode)

    > Note: The bicep file can accept two parameters to hook the Container App up to an existing Log Analytics workspace. These parameters are `logAnalyticsWorkspaceId` in guid format and `logAnalyticsSharedKey`. These can be retrieved from an existing Log Analytics workspace if you wish to use this. If `logAnalyticsWorkspaceId` is not specified, Log Analytics integration will not be applied. If `logAnalyticsWorkspaceId` is specified, ensure the key is also supplied.

1. Add a `local.settings.json` file to the Azure Functions project with the following contents:

    ```json
    {
        "IsEncrypted": false,
        "Values": {
            "AzureWebJobsStorage": "UseDevelopmentStorage=true",
            "FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated"
        }
    }
    ```

1. The output of the bicep deployment includes the FQDN of the container app that can be called from the Function App to perform an on-demand scan. Add a user secret with the key `AvScanEndpointUrl` and the value of the `fqdn` output from the Bicep deployment. You may add this to local.settings.json instead of user secrets if you wish. This should have the following format:

    ```json
    "AvScanEndpointUrl": "[unqiue-value].azurecontainerapps.io"
    ```

1. Add the following to either user secrets or local.settings.json:

   ```json
   "ScanFilesConnectionString": "UseDevelopmentStorage=true",
   "ScanFilesConnectionString:blob": "UseDevelopmentStorage=true",
   "ScanFilesConnectionString:queue": "UseDevelopmentStorage=true"
   ```

1. In the emulated local storage account, add a blob container called "upload".

Once these steps have been successfully completed, drop files in to the "upload" container to perform an on-demand scan. You can use the `clamav-testfile.txt` to test that a virus detected result is returned.

## Documentation

* [ClamAV in Containers](https://docs.clamav.net/manual/Installing/Docker.html)
* [ClamAV on Dockerhub](https://hub.docker.com/r/clamav/clamav)
* [User Secrets](https://learn.microsoft.com/en-us/aspnet/core/security/app-secrets?view=aspnetcore-7.0&tabs=windows)
* [EICAR test file](https://en.wikipedia.org/wiki/EICAR_test_file)
* [Azure Container Apps](https://learn.microsoft.com/en-us/azure/container-apps/overview)
* [Azure Functions](https://learn.microsoft.com/en-us/azure/azure-functions/functions-overview)
* [Scanning Blob storage for viruses with Azure Functions and Docker](https://peterrombouts.nl/2019/04/15/scanning-blob-storage-for-viruses-with-azure-functions-and-docker/)
