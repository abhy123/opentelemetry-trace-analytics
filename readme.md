# Leveraging AWS OpenSearch for Trace Analytics

### Introduction:

In the ever-evolving landscape of distributed systems and microservices, gaining insights into application performance and tracing transactions across services has become critical for maintaining reliability and improving user experience. In this article, we will explore a comprehensive solution for trace analytics using AWS Opensearch, Data Prepper, Otel Collector, and a Spring Boot application. We will be using JDK 17 and Gradle for our implementation. Let's dive in and unlock the power of trace analytics in your environment!

### 1. Understanding Trace Analytics:
Trace analytics involves capturing and analyzing distributed traces across services to identify performance bottlenecks and diagnose issues. A trace represents a complete end-to-end journey of a request as it flows through various components of a distributed system. It consists of multiple spans, where each span represents an individual operation within the overall request. Spans provide valuable information, such as the duration, latency, and any errors that occurred during the operation.

- Manual Instrumentation for Trace Analytics: In some cases, you may need to manually instrument your code to capture custom spans and enrich trace data. This approach allows you to gain deeper insights into specific operations or to trace external dependencies that may not be automatically instrumented.
- Integrating OpenTelemetry SDKs: OpenTelemetry offers SDKs for various programming languages, enabling manual instrumentation. By adding instrumentation code within your application, you can create custom spans, set attributes, and log events to capture relevant data for trace analysis.
- OpenTelemetry Agent: In our Spring Boot application, we have included the OpenTelemetry agent jar with the name "opentelemetry-javaagent.jar." This agent automatically generates and propagates unique trace IDs and span IDs to each request as it moves through the application, simplifying the tracing process.
### 2. Setting up AWS Opensearch Domain and Endpoint:

To start our journey into trace analytics, create an AWS Opensearch domain through the AWS Management Console.

- Go to the AWS Management Console, navigate to AWS Opensearch, and click "Create domain."
- Choose a name for your domain and select the version and instance type.
- Configure access controls to secure your data by choosing the appropriate access policies.
- Choose the required storage, networking, and monitoring options for your domain.
- Review your settings and create the Opensearch domain.
- Once the domain is created, take note of the endpoint URL, which will be used for exporting trace data.


### 3. Data Prepper:

Data Prepper is an essential component for transforming and sending trace data to AWS Opensearch.

Create a data-prepper-config.yaml file with Data Prepper pipeline configuration, specifying the source and sink for trace data.

```
entry-pipeline:
delay: "100"
source:
otel_trace_source:
ssl: false
sink:
- pipeline:
name: "raw-pipeline"
- pipeline:
name: "service-map-pipeline"


raw-pipeline:
source:
pipeline:
name: "entry-pipeline"
sink:
- opensearch:
hosts: [ "https://opensearchhost:443" ]
username: "username"
password: "password"
index_type: "trace-analytics-raw"


service-map-pipeline:
delay: "100"
source:
pipeline:
name: "entry-pipeline"
sink:
- opensearch:
hosts: [ "https://opensearchhost:443" ]
username: "username"
password: "password"
index_type: "trace-analytics-service-map"
```

- Data Prepper pipelines are customizable and can include multiple sources and sinks. The trace data source should be configured to ingest trace data from the Otel Collector, while the sink should be set to AWS Opensearch for exporting the transformed data.
- Use Docker to build an image for Data Prepper and configure it to read the pipeline configuration.
- Start the Data Prepper container, ensuring it securely connects to AWS Opensearch.
### 4. Otel Collector:

OpenTelemetry Collector acts as a central hub for receiving, processing, and exporting traces. By Dockerizing the Otel Collector, we ensure seamless integration and flexibility in scaling.

- Create an otel-collector-config.yaml file to define the necessary receivers and exporters for trace data.

```
receivers:
otlp:
protocols:
http:
endpoint: 0.0.0.0:55680


exporters:
otlp/data-prepper:
endpoint: data-prepper:21890
tls:
insecure: true
#logging:


service:
pipelines:
traces:
receivers: [otlp]
exporters: [otlp/data-prepper]
```
- The Otel Collector configuration should include the Otlp receiver to accept trace data from the Otel Agent and the AWS Opensearch exporter to forward the processed trace data to Data Prepper.
- Build an Otel Collector Docker image with the configuration file included.
- Run the Otel Collector container, ensuring it can receive trace data from the Spring Boot application and forward it to AWS Opensearch via Data Prepper.
### 5. Deploying the Spring Boot Application in Docker:

Containerize your Spring Boot application using Docker to ensure consistent and portable deployment.

- Create a Dockerfile for your Spring Boot application that specifies the necessary dependencies and configurations.

```
# Use openjdk 17 as the base image
FROM openjdk:17-jdk


# Set the working directory in the container
WORKDIR /app


# Copy the built Spring Boot JAR to the container
COPY /build/libs/demo-0.0.1-SNAPSHOT.jar /app/demo-0.0.1-SNAPSHOT.jar


COPY opentelemetry-javaagent.jar /app/opentelemetry-javaagent.jar


# Expose the port on which the Spring Boot application runs
EXPOSE 8081


# Start the Spring Boot application with the OpenTelemetry agent
CMD java -javaagent:/app/opentelemetry-javaagent.jar -jar /app/demo-0.0.1-SNAPSHOT.jar
```

Build a Docker image for your Spring Boot application and run it as a container.

- Update your Spring Boot application with a TestController class to send traces to AWS Opensearch.
```
@RestController
@RequestMapping(path = "/test")
public class TestController {

    @GetMapping(path = "/message/{message}")
    public String message(@PathVariable String message) {
        return message;
    }
}
```
- Set environment variables in the container to enable the OpenTelemetry agent for trace instrumentation and export.
- Configure the Otel Agent using environment variables or system properties in your Spring Boot application.
- The Otel Agent automatically generates and propagates unique trace IDs and span IDs to each request as it moves through the application.
- Verify that the Spring Boot application successfully generates and propagates trace IDs and span IDs.

### 6. Visualizing Traces in AWS Opensearch:

With all components connected, trace data from the Spring Boot application is ingested by Data Prepper and forwarded to AWS Opensearch through the Otel Collector.

- Access the AWS Opensearch domain's Kibana endpoint to visualize and analyze trace data.
Analyzing Trace Data:

Explore the powerful querying capabilities of AWS Opensearch to gain valuable insights from your distributed traces. Identify performance patterns, bottlenecks, and opportunities for optimization.

- Use Kibana, the data visualization tool for AWS Opensearch, to create custom dashboards and visualize trace data.
- Create queries to filter and analyze traces based on specific criteria like service name, latency, or error codes.
- Screenshots are added in the images folder.

Architecture :

Architecture diagram image added in images folder.


- OTEL Demo Spring Boot App: The OpenTelemetry Agent is integrated into this spring boot application to automatically instrument and collect trace data.
- OpenTelemetry Collector: The OTel Collector, deployed as a Docker container, acts as the central component to receive, process, and export trace data. It collects data from various sources, including the Spring Boot App and other instrumented services.
- Data Prepper: Data Prepper deployed as a docker container is responsible for processing and preparing the collected telemetry data.
- OTLP Communication: The data collected by the OTel Collector is transported in the OTLP format, ensuring efficient and standardized communication between components.
- AWS OpenSearch: The exported trace data is sent to AWS OpenSearch, where it is stored and visualized for analysis and monitoring purposes.


### Conclusion:

In this article, we explored a comprehensive solution for trace analytics using AWS Opensearch, Data Prepper, Otel Collector, and a Spring Boot application deployed in Docker. We discussed the importance of trace analytics and its role in gaining insights into distributed systems. By leveraging these tools, you can efficiently monitor, diagnose, and optimize the performance of your microservices-based applications.

Remember, trace analytics is a powerful technique for understanding application behavior, identifying performance bottlenecks, and ensuring a seamless user experience. Implementing trace analytics requires a collaborative effort among development, operations, and infrastructure teams to ensure effective instrumentations and a scalable architecture.

By adopting trace analytics, you can elevate your observability game and deliver high-quality, reliable, and performant applications to your end-users. Happy tracing!