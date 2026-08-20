---
name: spring-init
description: Generate and validate Spring Boot project initialization commands with configurable dependencies
invocation: explicit
subagent_type: general-purpose
---

# Spring Boot Project Initializer

Generate `spring init` commands for various project types, Java versions, Boot versions, and dependency combinations. Each invocation produces a shell-ready command that can be copy-pasted or executed directly.

> Tip: run `spring help` to see all available Spring CLI commands; `spring help init` shows flags/options for `init` specifically.

## Steps

### 1. Parse requirements
Extract from the prompt: project name, build system (maven/gradle), Java version, Spring Boot version, desired dependencies. Default to maven, Java 17, latest stable Boot version if not specified.

**Done when:** all five parameters are clear (missing ones have defaults).

### 2. Build dependency string
Map human-readable dependency names to Spring Boot starter names. Join with commas. See [Dependency Map](#dependency-map) below for the complete list.

**Done when:** a single comma-separated string is ready for the `--dependencies` flag.

### 3. Generate command
Assemble the `spring init` command using this template:

```
spring init --type=<build>-project \
  --java-version=<java> \
  --boot-version=<boot> \
  --dependencies=<deps> \
  --groupId=com.example \
  --artifactId=<project-name> \
  --name=<project-name> \
  --package-name=com.example.<project-name> \
  <project-name>
```

Use hyphens in artifactId and package suffix; convert to camelCase for package names. Example: `random-quote-mcp` → `randomquoteMcp`.

**Done when:** the full command is ready to execute.

### 4. Output command and validate
Print the command in a code block. Verify:
- All flags are spelled correctly
- Dependency names exist in Spring Boot (or note if custom)
- The command is shell-ready (no syntax errors)

**Done when:** the command is validated and ready to run.

## Dependency Map

### Web & REST
| Name | Starter | Notes |
|------|---------|-------|
| web | spring-boot-starter-web | REST APIs, embedded Tomcat |
| webflux | spring-boot-starter-webflux | Reactive web, Netty |
| websocket | spring-boot-starter-websocket | WebSocket support |
| graphql | spring-boot-starter-graphql | GraphQL server |

### Data & Persistence
| Name | Starter | Notes |
|------|---------|-------|
| data-jpa | spring-boot-starter-data-jpa | JPA/Hibernate ORM |
| data-mongodb | spring-boot-starter-data-mongodb | MongoDB driver |
| data-redis | spring-boot-starter-data-redis | Redis caching |
| h2 | com.h2database:h2 | H2 in-memory database |
| postgres | org.postgresql:postgresql | PostgreSQL driver |
| mysql | mysql:mysql-connector-java | MySQL driver |

### Security & Auth
| Name | Starter | Notes |
|------|---------|-------|
| security | spring-boot-starter-security | Spring Security |
| oauth2-client | spring-boot-starter-oauth2-client | OAuth2 client |
| oauth2-resource-server | spring-boot-starter-oauth2-resource-server | OAuth2 resource server |

### Messaging & Events
| Name | Starter | Notes |
|------|---------|-------|
| amqp | spring-boot-starter-amqp | RabbitMQ, AMQP |
| kafka | spring-boot-starter-kafka | Apache Kafka |
| jms | spring-boot-starter-activemq | ActiveMQ, JMS |

### Cloud & AI
| Name | Starter | Notes |
|------|---------|-------|
| spring-ai-mcp-server | spring-ai-mcp-server | MCP server support |
| spring-ai-openai | spring-ai-openai | OpenAI integration |
| cloud-config | spring-cloud-config-server | Config server |
| cloud-eureka | spring-cloud-eureka-server | Service discovery |

### Observability
| Name | Starter | Notes |
|------|---------|-------|
| actuator | spring-boot-starter-actuator | Metrics, health checks |
| micrometer | spring-boot-starter-micrometer-core | Micrometer metrics |
| logging | spring-boot-starter-logging | SLF4J + Logback |

### Testing
| Name | Starter | Notes |
|------|---------|-------|
| test | spring-boot-starter-test | JUnit, Mockito, etc. |
| testcontainers | org.testcontainers:testcontainers | Test containers |

## Common Presets

Use these as shortcuts for typical project archetypes:

| Preset | Dependencies |
|--------|--------------|
| **REST API** | web, data-jpa, postgres, actuator, security |
| **Event Streaming** | kafka, data-jpa, actuator |
| **AI Assistant** | web, spring-ai-openai, security, data-jpa |
| **MCP Server** | web, spring-ai-mcp-server, actuator |
| **Microservice** | web, data-jpa, postgres, cloud-eureka, actuator |

## Examples

### REST API with PostgreSQL
```
spring init --type=maven-project \
  --java-version=17 \
  --boot-version=3.4.5 \
  --dependencies=web,data-jpa,postgres,actuator,security \
  --groupId=com.example \
  --artifactId=user-api \
  --name=user-api \
  --package-name=com.example.userapi \
  user-api
```

### Kafka Event Consumer
```
spring init --type=maven-project \
  --java-version=17 \
  --boot-version=3.4.5 \
  --dependencies=kafka,data-jpa,postgres \
  --groupId=com.example \
  --artifactId=order-processor \
  --name=order-processor \
  --package-name=com.example.orderprocessor \
  order-processor
```

### MCP Server with AI
```
spring init --type=maven-project \
  --java-version=17 \
  --boot-version=3.4.5 \
  --dependencies=web,spring-ai-mcp-server,spring-ai-openai,actuator \
  --groupId=com.example \
  --artifactId=random-quote-mcp \
  --name=random-quote-mcp \
  --package-name=com.example.randomquotemcp \
  random-quote-mcp
```
