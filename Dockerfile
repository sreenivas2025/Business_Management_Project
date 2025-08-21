# Use a lightweight JDK runtime
FROM eclipse-temurin:17-jdk

# Set working directory
WORKDIR /app

# Copy your already built JAR into the container
COPY target/BusinessProject-0.0.1-SNAPSHOT.jar app.jar

# Expose the Spring Boot app port
EXPOSE 2330

# Run the JAR
ENTRYPOINT ["java", "-jar", "app.jar"]
