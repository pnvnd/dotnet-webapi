using OpenTelemetry.Resources;
using OpenTelemetry.Trace;

// Define some important constants and the activity source

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

// Configure important OpenTelemetry settings, the OTEL exporter, and automatic instrumentation
builder.Services.AddOpenTelemetryTracing(b =>
{
    b
    .AddOtlpExporter(options =>
        {
            // options.Endpoint = new Uri("http://localhost:4317");
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

builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();
