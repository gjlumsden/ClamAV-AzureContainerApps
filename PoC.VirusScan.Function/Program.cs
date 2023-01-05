using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using nClam;

//Add to local.settings.json or user secrets.

string serverName = Environment.GetEnvironmentVariable("AvScanEndpointUrl");

//Update if a different exposed port is used.
int serverPort = 3310;

var host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults()
    .ConfigureServices(services =>
    {
        services.AddSingleton<IClamClient, ClamClient>(factory => new ClamClient(serverName, serverPort));
    })
    .Build();

host.Run();
