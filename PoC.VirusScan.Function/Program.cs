using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using nClam;

IConfigurationRoot configuration = new ConfigurationBuilder()
               .SetBasePath(Environment.CurrentDirectory)
               .AddEnvironmentVariables()
               .AddUserSecrets<Program>()
               .Build();

var host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults()
    .ConfigureServices(services =>
    {
        services.AddSingleton<IClamClient, ClamClient>(factory =>
        {
            //Add to local.settings.json or user secrets.
            string? serverName = configuration["AvScanEndpointUrl"];
            
            if(serverName == null)
            {
                throw new Exception("AvScanEndpointUrl setting is not set.");
            }
            //Update if a different exposed port is used.
            int serverPort = 3310;
            
            return new ClamClient(serverName, serverPort);
        });
    })
    .Build();

host.Run();
