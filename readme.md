# Deploy .NET Core Application to ISS

## Create .NET Core Application

1. Download and install .NET 6.0 (LTS) SDK x64:  
`https://dotnet.microsoft.com/download`

2. Open Command Prompt or PowerShell console

3. Check to make sure dotnet core is installed:  
`dotnet --version`

4. Create dotnet project folder and change directory  
`mkdir dotnet-api`  
`cd dotnet-api`

5. Create new dotnet web API project  
`dotnet new webapi`

6. Build web API project  
`dotnet build .`
![Screenshot 5](/img/dotnet_05.png)

7. Get path from console and go run  
`dotnet .\bin\Debug\net6.0\dotnet-webapi.dll`
![Screenshot 6](/img/dotnet_06.png)

8. Open browser to check if it works/running:  
`https://localhost:5001/WeatherForecast` or  
`http://localhost:5000/WeatherForecast`
![Screenshot 7](/img/dotnet_07.png)

# Hosting Application on IIS

1. Once it works, publish web API application to FolderProfile (Release, not Debug)  
`dotnet publish -c Release -p:PublishProfile=FolderProfile`
![Screenshot 4](/img/dotnet_04.png)

2. Create application folder somewhere convienient and copy everything in the publish folder here  
`mkdir C:\dotnet-webapi`  
`xcopy .\bin\Release\net6.0\publish\ C:\dotnet-webapi\ /y`

## Install Internet Information Services (IIS) Manager
1. Control Panel > Programs and Features > Turn Windows features on or off > Install Internet Information Services
![Screenshot 1](/img/dotnet_00.png)

2. Download and install .NET Core Hosting Bundle  
`https://docs.microsoft.com/en-us/aspnet/core/host-and-deploy/iis/hosting-bundle?view=aspnetcore-6.0`
![Screenshot 2](/img/dotnet_01.png)

3. Open Internet Information Services (IIS) Manager (Start Menu)
![Screenshot 8](/img/dotnet_08.png)
4. Right-click Sites > Add Website...
![Screenshot 9](/img/dotnet_09.png)
5. Enter a website name (`dotnet-webapi` in this example  
Note: Name of application pool will be reported to New Relic by default
![Screenshot 10](/img/dotnet_10.png)
6. Physical path: `C:\dotnet-webapi\`
7. Port: `90` (Since Port 80 is in use by the default website)
8. Click OK and go to `http://localhost:90/WeatherForecast`
![Screenshot 11](/img/dotnet_11.png)

## Install New Relic .NET Agent:
1. Go to one.newrelic.com > `Add more data`
2. Guided install > APM (Application Monitoring) > .NET > Begin installation > Windows
3. Copy the command on screen and paste in PowerShell running as Administrator
4. Follow the prompts to complete .NET agent installation
![Screenshot 3](/img/dotnet_02.png)
5. Go to `http://localhost:90/WeatherForecast` a few times to generate traffic
6. Check New Relic APM > DefaultAppPool for APM data
![Screenshot 12](/img/dotnet_12.png)

# Hosting in Docker Container

1. Get a sample `dockerfile` from [New Relic](https://docs.newrelic.com/docs/apm/agents/net-agent/other-installation/install-net-agent-docker-container/) or use the sample below.  Place `dockerfile` in the root of this repository.

```dockerfile
 # Use the correct tagged version for your application's targeted runtime.  See https://hub.docker.com/_/microsoft-dotnet-aspnet/ 
FROM mcr.microsoft.com/dotnet/aspnet:6.0

# Publish your application.
COPY ./bin/Release/net6.0/publish /app

# Install the agent
RUN apt-get update && apt-get install -y wget ca-certificates gnupg \
&& echo 'deb http://apt.newrelic.com/debian/ newrelic non-free' | tee /etc/apt/sources.list.d/newrelic.list \
&& wget https://download.newrelic.com/548C16BF.gpg \
&& apt-key add 548C16BF.gpg \
&& apt-get update \
&& apt-get install -y newrelic-netcore20-agent \
&& rm -rf /var/lib/apt/lists/*

# Enable the agent
ENV CORECLR_ENABLE_PROFILING=1 \
CORECLR_PROFILER={36032161-FFC0-4B61-B559-F6C5D41BAE5A} \
CORECLR_NEWRELIC_HOME=/usr/local/newrelic-netcore20-agent \
CORECLR_PROFILER_PATH=/usr/local/newrelic-netcore20-agent/libNewRelicProfiler.so

WORKDIR /app

EXPOSE 80

ENTRYPOINT ["dotnet", "./dotnet-webapi.dll"]
```

3. Download and [Install Docker Desktop](https://www.docker.com/products/docker-desktop)
4. Open a terminal and navigate to the root of this repository
5. Create a file called `.env` to put in environment variables for your container (the `.env` has been placed in the `.gitignore` file to prevent you from uploading your license key online).

```
NEW_RELIC_LICENSE_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXNRAL
NEW_RELIC_APP_NAME=dotnet-api.docker
```

5. Run this command to build the Docker container: `docker build -t dotnet-webapi:latest .`
6. Run this command to run the container: `docker run -d --env-file .env -p 80:80 dotnet-webapi:latest`
6. Alternatively, run `docker run -d -e NEW_RELIC_LICENSE_KEY="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXNRAL" -e NEW_RELIC_APP_NAME="dotnet-api.docker" -p 80:80 dotnet-webapi:latest`
7. Access the webapi at: `http:/127.0.0.1/WeatherForecast`
8. Check New Relic One > APM to see transactions

![Screenshot 13](/img/dotnet_13.png)

# Custom Attributes
1. In your project folder containing `.csproj` by entering the following in the terminal:
```
dotnet add package NewRelic.Agent.Api --version 9.5.0
```

2. Edit `WeatherForecastController.cs` and add the following on the first line: `using NewRelic.Api.Agent;`

3. Also, add the following just before the `return` statement on line 25
```cs
[HttpGet(Name = "GetWeatherForecast")]
public IEnumerable<WeatherForecast> Get()
{
    IAgent agent = NewRelic.Api.Agent.NewRelic.GetAgent();
    ITransaction transaction = agent.CurrentTransaction;
    transaction.AddCustomAttribute("dockerVersion", "4.4.4");
    return Enumerable.Range(1, 5).Select(index => new WeatherForecast
    {
        Date = DateTime.Now.AddDays(index),
        TemperatureC = Random.Shared.Next(-20, 55),
        Summary = Summaries[Random.Shared.Next(Summaries.Length)]
    })
    .ToArray();
}
```

4. Rebuild the application and docker image, and run to test
```
dotnet build .
dotnet publish -c Release -p:PublishProfile=FolderProfile
xcopy .\bin\Release\net6.0\publish\ C:\dotnet-webapi\ 
docker build -t dotnet-webapi:latest .
docker run -d --env-file .env -p 80:80 dotnet-webapi:latest
```
5. In New Relic, try this NRQL query to see your newly added custom attribute:
```nrql
SELECT * FROM Transaction WHERE appName='dotnet-api.docker' SINCE 1 hour ago
```
![Screenshot 14](/img/dotnet_14.png)

# Deploy to Kubernetes via Minikiube (Hyper-V)
1. Get download `minikube` and `kubectl`, and set path to the folder containing these.
2. Enable Hyper-V  
![Screenshot 15](/img/dotnet_15.png)

3. Open Hyper-V Manager and create a new external virtual switch called `New Virtual Switch`
![Screenshot 16](/img/dotnet_16.png)

2. Open terminal as Administrator and create a new minikube (kubernetes) cluster 
```
minikube start --driver=hyperv --hyperv-virtual-switch='New Virtual Switch' --cni=flannel --cpus=4 --memory=4096 -p dotnet-webapi
```
3. We need to re-build the Docker image so it appears in the minikube Docker repository instead of your localhost Docker image repository.  Run this command to switch Docker repository to minikiube:  
```
minikube -p dotnet-webapi docker-env | Invoke-Expression
```
4. Check `docker images` to see the images in your minikube image repository instead of your local Docker image repository.  
![Screenshot 17](/img/dotnet_17.png)

5. Before you re-build the docker image, update the `dockerfile` to include the environment variables for `NEW_RELIC_LICENSE_KEY` and `NEW_RELIC_APP_NAME`.  This was left out previously to prevent uploading keys online.  
```
# Enable the agent
ENV CORECLR_ENABLE_PROFILING=1 \
CORECLR_PROFILER={36032161-FFC0-4B61-B559-F6C5D41BAE5A} \
CORECLR_NEWRELIC_HOME=/usr/local/newrelic-netcore20-agent \
CORECLR_PROFILER_PATH=/usr/local/newrelic-netcore20-agent/libNewRelicProfiler.so \
NEW_RELIC_LICENSE_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXNRAL \
NEW_RELIC_APP_NAME=dotnet-api.docker
```
6. Build the Docker image with the new `dockerfile` using `docker build -t dotnet-webapi:test .`
7. Run this with 
```
kubectl apply -f dotnet-webapi.yaml
```
8. In a different terminal, expose the service to an external IP in minikube:  
```
minikube tunnel -p dotnet-webapi
```
9. Check `kubectl get pods` to make sure the pod is running.
10. Get the external IP using `kubectl get services`  
![Screenshot 18](/img/dotnet_18.png)
11. Check out the service `http://<EXTERNAL-IP>/WeatherForecast`
12. If the new Docker image was built correctly with the environment variables added in, you should now be able to see this data in New Relic as well under Kubernetes Cluster Explorer  
![Screenshot 19](/img/dotnet_19.png)

## Monitor Kubernetes Cluster with Pixie
1. Download `helm` and set PATH to its containing folder.
2. Go to New Relic to add more data and select "Kubernetes"
![Screenshot 20](/img/dotnet_20.png)
3. Enter a namespace for the Kubernetes instrumentation and click next.
4. Copy and paste the code to a notepad and replace `&&` with `;` and replace `\` with `` ` `` to run in PowerShell.  It should look something like this for PowerShell:
```
kubectl apply -f https://download.newrelic.com/install/kubernetes/pixie/latest/px.dev_viziers.yaml; 
kubectl apply -f https://download.newrelic.com/install/kubernetes/pixie/latest/olm_crd.yaml; 
helm repo add newrelic https://helm-charts.newrelic.com;
helm repo update; 
kubectl create namespace newrelic;

helm upgrade --install newrelic-bundle newrelic/nri-bundle `
 --set global.licenseKey=a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8NRAL `
 --set global.cluster=tiny-hat `
 --namespace=newrelic `
 --set newrelic-infrastructure.privileged=true `
 --set global.lowDataMode=true `
 --set ksm.enabled=true `
 --set prometheus.enabled=true `
 --set kubeEvents.enabled=true `
 --set logging.enabled=true `
 --set newrelic-pixie.enabled=true `
 --set newrelic-pixie.apiKey=px-api-a1b2c3d4-e5f6-g7h8-i9j0-k1l2m3n4o0p5 `
 --set pixie-chart.enabled=true `
 --set pixie-chart.deployKey=px-dep-d4c3b2a1-f6e5-h8g7-j0i9-p5o0n4m3l2k1 `
 --set pixie-chart.clusterName=tiny-hat
```
![Screenshot 21](/img/dotnet_21.png)

5. New pods will be created under the `newrelic`, `olm`, and `px-operator` namespace within 5 minutes.
![Screenshot 22](/img/dotnet_22.png)

6. Go back to the Kubernetes Cluster Explorer to see your minikube cluster.
![Screenshot 23](/img/dotnet_23.png)

7. Check out the `Control Plane` and `Events` to get a feel for what kind of data is coming in, and compare it to what you see in APM.  Then, check out `Live debugging with Pixie`.
![Screenshot 24](/img/dotnet_24.png)

8. In `Live debugging with Pixie` click on the dropdown for `script` and select `px/perf_flamegraph` and filter as needed to see performance data,.
![Screenshot 25](/img/dotnet_25.png)

# OpenTelemetry

1. Install the following.  Notice it will add to your `.csproj` file.
```
dotnet add package OpenTelemetry --prerelease
dotnet add package OpenTelemetry.Exporter.OpenTelemetryProtocol --prerelease
dotnet add package OpenTelemetry.Instrumentation.AspNetCore --prerelease
dotnet add package OpenTelemetry.Instrumentation.Http --prerelease
dotnet add package OpenTelemetry.Extensions.Hosting --prerelease
```

2. In the `program.cs` file, add the following at the top of the code:
```cs
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;
```

3. Finally, just before `builder.Services.AddControllers();` add the following:
```cs
builder.Services.AddOpenTelemetryTracing(b =>
{
    b
    .AddOtlpExporter(options =>
        {
            options.Endpoint = new Uri($"{Environment.GetEnvironmentVariable("OTEL_EXPORTER_OTLP_ENDPOINT")}");
            options.Headers = Environment.GetEnvironmentVariable("OTEL_EXPORTER_OTLP_HEADERS");
        })
    .SetResourceBuilder(
        ResourceBuilder
            .CreateDefault()
            .AddService("dotnet-webapi.otel")
            .AddAttributes(new Dictionary<string, object> { {"environment", "production"} })
    )
    .AddHttpClientInstrumentation()
    .AddAspNetCoreInstrumentation();
});
```

4. Build the application with `dotnet build .` 

5. Before running with `dotnet bin/Debug/net6.0/dotnet-webapi.dll` set the following environment variables:
```
OTEL_EXPORTER_OTLP_ENDPOINT=https://otlp.nr-data.net:4317
OTEL_EXPORTER_OTLP_HEADERS=api-key=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXNRAL
```

6. Check New Relic One > Services - OpenTelemetry to see the data.

## Jaeger
1. To see OpenTelemetry data in Jaeger UI instead, change the endpoint and spin up a jaeger container
    ```powershell
    $env:OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4317"
    docker run --name jaeger -p 13133:13133 -p 16686:16686 -p 4317:55680 -d --restart=unless-stopped jaegertracing/opentelemetry-all-in-one
    ```
2. Run the application generate some traffic

3. Go to http://localhost:16686 to see Jaeger UI.

4. Notice no change was done to the code, only environment variables were changed to specify which endpoint to export traces.