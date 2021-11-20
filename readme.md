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

9. Once it works, publish web API application to FolderProfile (Release, not Debug)  
`dotnet publish -c Release -p:PublishProfile=FolderProfile`
![Screenshot 4](/img/dotnet_04.png)

10. Create application folder somewhere convienient and copy everything in the publish folder here  
`mkdir C:\dotnet-webapi`  
`copy .\bin\Release\net6.0\publish\ C:\dotnet-webapi\`

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