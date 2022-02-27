# This example uses .NET 6.0.  For other versions, see https://hub.docker.com/_/microsoft-dotnet-sdk/
FROM mcr.microsoft.com/dotnet/sdk:6.0-alpine AS base

# Copy repository to base image and publish your application
WORKDIR /src
COPY . .
RUN dotnet publish -c Release -o /app

# Use the correct tagged version for your application's targeted runtime.  See https://hub.docker.com/_/microsoft-dotnet-aspnet/ 
FROM mcr.microsoft.com/dotnet/aspnet:6.0-alpine AS final

# Update latest version frequently, otherwise download link breaks
ARG NewRelicVersion=9.6.0.0
ARG NewRelicHome=/usr/local/newrelic-netcore20-agent

# Enable the agent by setting environment variables
ENV CORECLR_ENABLE_PROFILING=1 \
CORECLR_PROFILER={36032161-FFC0-4B61-B559-F6C5D41BAE5A} \
CORECLR_NEWRELIC_HOME=$NewRelicHome \
CORECLR_PROFILER_PATH=$NewRelicHome/libNewRelicProfiler.so

# Download and extract New Relic Agent
ARG NewRelicFile=newrelic-netcore20-agent_${NewRelicVersion}_amd64.tar.gz
ARG NewRelicUrl=https://download.newrelic.com/dot_net_agent/latest_release/$NewRelicFile
RUN mkdir "${NewRelicHome}" && cd /usr/local && wget -O - "${NewRelicUrl}" | gzip -dc | tar xf -

# Copy published application from base image to final image
WORKDIR /app
COPY --from=base /app .

EXPOSE 80

ENTRYPOINT ["dotnet", "./dotnet-webapi.dll"]
