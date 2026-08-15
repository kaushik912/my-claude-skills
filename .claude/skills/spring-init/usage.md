# Spring Init Skill - Usage Guide

## Overview

The `spring-init` skill generates production-ready `spring init` commands for various project configurations. It handles dependency mapping, Java versions, Spring Boot versions, and build system selection.

## How to Use

### Basic Invocation

Tell the skill what you need:

```
Generate a Spring Boot REST API with PostgreSQL, actuator, and security using Maven and Java 17
```

### Common Requests

#### 1. REST API Service
```
REST API with PostgreSQL, security, and monitoring
```
→ Returns web + data-jpa + postgres + actuator + security

#### 2. Kafka Event Processor
```
Kafka consumer with database storage
```
→ Returns kafka + data-jpa + postgres

#### 3. AI-Powered MCP Server
```
MCP server with OpenAI integration and metrics
```
→ Returns web + spring-ai-mcp-server + spring-ai-openai + actuator

#### 4. Reactive WebFlux API
```
Async web service with MongoDB
```
→ Returns webflux + data-mongodb + actuator

#### 5. Cloud Microservice
```
Microservice with service discovery and persistence
```
→ Returns web + data-jpa + postgres + cloud-eureka + actuator

## Dependency Reference

### Quick Lookup

| Use Case | Dependencies |
|----------|--------------|
| REST API | web, data-jpa, postgres, actuator, security |
| Kafka Streaming | kafka, data-jpa, postgres |
| GraphQL Server | graphql, security, data-jpa, postgres |
| WebFlux Reactive | webflux, data-mongodb, actuator |
| RabbitMQ AMQP | amqp, kafka, actuator |
| OAuth2 Protected | web, oauth2-resource-server, data-jpa |
| AI Integration | web, spring-ai-openai, spring-ai-mcp-server |
| Minimal Web | web |

### Starter Names

**Web & APIs**
- `web` – REST APIs, Tomcat
- `webflux` – Reactive, Netty
- `graphql` – GraphQL server
- `websocket` – WebSocket support

**Data**
- `data-jpa` – JPA/Hibernate
- `data-mongodb` – MongoDB
- `data-redis` – Redis caching
- `postgres` – PostgreSQL JDBC
- `mysql` – MySQL JDBC
- `h2` – H2 in-memory DB

**Security**
- `security` – Spring Security
- `oauth2-client` – OAuth2 client
- `oauth2-resource-server` – OAuth2 server

**Messaging**
- `kafka` – Apache Kafka
- `amqp` – RabbitMQ/AMQP
- `jms` – ActiveMQ/JMS

**Cloud & AI**
- `spring-ai-openai` – OpenAI integration
- `spring-ai-mcp-server` – MCP server
- `cloud-eureka` – Service discovery
- `cloud-config` – Config server

**Observability**
- `actuator` – Health, metrics
- `micrometer` – Metrics core
- `logging` – SLF4J + Logback

## Parameters

### Default Behavior
- **Build System:** Maven (override with `gradle`)
- **Java Version:** 17 (can specify 17, 21, etc.)
- **Boot Version:** 3.4.5 (latest stable)
- **GroupId:** com.example (auto-generated)
- **PackageName:** com.example.{projectname} (auto-converted to camelCase)

### Override Examples

```
Java 21 Gradle project with WebFlux and MongoDB
```
→ Generates Gradle with Java 21

```
Boot 3.3.0 with Kafka and Redis
```
→ Uses Spring Boot 3.3.0 instead

## Output Format

The skill returns a ready-to-execute bash command:

```bash
spring init --type=maven-project \
  --java-version=17 \
  --boot-version=3.4.5 \
  --dependencies=web,data-jpa,postgres,actuator \
  --groupId=com.example \
  --artifactId=my-api \
  --name=my-api \
  --package-name=com.example.myapi \
  my-api
```

**Copy-paste ready!** Execute directly in your terminal.

## Execution

After getting the command, run it:

```bash
# Copy the generated command and run
spring init --type=maven-project \
  --java-version=17 \
  --boot-version=3.4.5 \
  --dependencies=web,data-jpa,postgres \
  --groupId=com.example \
  --artifactId=user-api \
  --name=user-api \
  --package-name=com.example.userapi \
  user-api

# Navigate to project
cd user-api

# Build
./mvnw clean package
```

## Advanced Usage

### Custom Package Names
Request with explicit package structure:
```
REST API for enterprise-auth with package io.corp.auth.backend
```

### Multiple Configurations
Request variations at once:
```
Generate 3 commands:
1. REST API with PostgreSQL
2. Kafka consumer version
3. Reactive WebFlux version
```

### Java Version Compatibility
- Java 17: All features, LTS, recommended
- Java 21: Latest LTS, latest features
- Java 11: Legacy support, limited features

## Troubleshooting

### Command Not Found
Ensure Spring Boot CLI is installed:
```bash
brew install spring-boot
```

### Dependency Not Found
Common typos to watch:
- `datasource-jpa` ❌ → `data-jpa` ✓
- `spring-web` ❌ → `web` ✓
- `postgres-sql` ❌ → `postgres` ✓

### Boot Version Mismatch
Use available versions: 3.4.5, 3.3.0, 3.2.x, etc.

## Examples in Real Projects

See `spring-init-test-cases.md` for 10 complete examples with validation results.

## Testing

The skill is tested with:
- ✓ 10 preset configurations
- ✓ 4 dependency count validations
- ✓ 2 syntax validations
- ✓ All major dependency combinations

Run test suite:
```bash
./test-spring-init.sh
```

Result: **16/16 tests passing**
