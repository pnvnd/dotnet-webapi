# This example uses .NET 6.0.  For other versions, see https://hub.docker.com/_/microsoft-dotnet-sdk/
FROM mcr.microsoft.com/dotnet/sdk:6.0-alpine AS base

# Copy repository to base image and publish your application
WORKDIR /src
COPY . .
RUN dotnet publish -c Release -o /app

# Use the correct tagged version for your application's targeted runtime.  See https://hub.docker.com/_/microsoft-dotnet-aspnet/ 
FROM mcr.microsoft.com/dotnet/aspnet:6.0-alpine AS final

# # Update latest version as needed
# ARG NewRelicVersion=9.6.0.0
# ARG NEW_RELIC_HOME=/usr/local/newrelic-netcore20-agent

ARG NEW_RELIC_AGENT=newrelic-netcore20-agent
ARG NEW_RELIC_FILE_REGEX=dot_net_agent/latest_release/${NEW_RELIC_AGENT}_\\d*\\.\\d*\\.\\d*\\.\\d*_amd64\\.tar\\.gz
ARG NEW_RELIC_S3_BUCKET=https://nr-downloads-main.s3.amazonaws.com/
ARG NEW_RELIC_ROOT=/usr/local
ARG NEW_RELIC_HOME=${NEW_RELIC_ROOT}/${NEW_RELIC_AGENT}

# Enable the agent by setting environment variables
ENV CORECLR_ENABLE_PROFILING=1 \
CORECLR_PROFILER={36032161-FFC0-4B61-B559-F6C5D41BAE5A} \
CORECLR_NEWRELIC_HOME=$NEW_RELIC_HOME \
CORECLR_PROFILER_PATH=$NEW_RELIC_HOME/libNewRelicProfiler.so

# # Download and extract New Relic Agent, may need to modify URL or previous_releases
# ARG NewRelicFile=newrelic-netcore20-agent_${NewRelicVersion}_amd64.tar.gz
# ARG NewRelicUrl=https://download.newrelic.com/dot_net_agent/latest_release/$NewRelicFile
# RUN mkdir "${NewRelicHome}" && cd /usr/local && wget -O - "${NewRelicUrl}" | gzip -dc | tar xf -

# Download latest New Relic .NET Agent based on regex and extract
RUN mkdir "${NEW_RELIC_HOME}" && \
    cd "${NEW_RELIC_ROOT}" && \
    export NEW_RELIC_DOWNLOAD_URI=${NEW_RELIC_S3_BUCKET}$(wget -O - "${NEW_RELIC_S3_BUCKET}?delimiter=/&prefix=dot_net_agent/latest_release/${NEW_RELIC_AGENT}" | grep -o "${NEW_RELIC_FILE_REGEX}") && \
    wget -O - "$NEW_RELIC_DOWNLOAD_URI" | tar -xvzf -

# Copy published application from base image to final image
WORKDIR /app
COPY --from=base /app .

EXPOSE 80

ENTRYPOINT ["dotnet", "./dotnet-webapi.dll"]
