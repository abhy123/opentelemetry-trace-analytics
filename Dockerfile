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
