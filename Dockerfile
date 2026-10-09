# Multi-stage Dockerfile for Java Web Application on Apache Tomcat
# Stage 1: Build stage using Maven
FROM maven:3.8.6-openjdk-11 AS buildstage
RUN mkdir /opt/java-application
WORKDIR /opt/java-application
COPY . .
RUN mvn clean install

# Stage 2: Runtime stage using Apache Tomcat
FROM tomcat:9.0-jre11-openjdk-slim
WORKDIR webapps
COPY --from=buildstage /opt/java-application/target/*.war .
RUN rm -rf ROOT && \
    mv *.war ROOT.war
EXPOSE 8080
CMD ["catalina.sh", "run"]
