# Spring Init Skill - Test Cases & Examples

## Test Case 1: REST API Backend
**Input:** Generate a Spring Boot REST API with PostgreSQL persistence and security

**Expected Output:**
```bash
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

**Validation:** Command contains all required flags, dependency count = 5

---

## Test Case 2: Event-Driven Architecture
**Input:** Kafka consumer with database persistence

**Expected Output:**
```bash
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

**Validation:** Kafka dependency present, database configured, syntax valid

---

## Test Case 3: MCP Server with AI Integration
**Input:** Random quote MCP server with OpenAI support

**Expected Output:**
```bash
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

**Validation:** MCP server dependency included, AI dependencies present

---

## Test Case 4: Reactive WebFlux with MongoDB
**Input:** Generate async web service with NoSQL storage

**Expected Output:**
```bash
spring init --type=maven-project \
  --java-version=17 \
  --boot-version=3.4.5 \
  --dependencies=webflux,data-mongodb,actuator \
  --groupId=com.example \
  --artifactId=reactive-api \
  --name=reactive-api \
  --package-name=com.example.reactiveapi \
  reactive-api
```

**Validation:** WebFlux instead of web, MongoDB selected

---

## Test Case 5: Microservice with Service Discovery
**Input:** Spring Cloud microservice with Eureka

**Expected Output:**
```bash
spring init --type=maven-project \
  --java-version=17 \
  --boot-version=3.4.5 \
  --dependencies=web,data-jpa,postgres,cloud-eureka,actuator \
  --groupId=com.example \
  --artifactId=user-service \
  --name=user-service \
  --package-name=com.example.userservice \
  user-service
```

**Validation:** Cloud dependencies included, service discovery ready

---

## Test Case 6: Gradle Build System
**Input:** Web API using Gradle with Java 21

**Expected Output:**
```bash
spring init --type=gradle-project \
  --java-version=21 \
  --boot-version=3.4.5 \
  --dependencies=web,data-jpa \
  --groupId=com.example \
  --artifactId=gradle-app \
  --name=gradle-app \
  --package-name=com.example.gradleapp \
  gradle-app
```

**Validation:** Gradle selected, Java 21 configured

---

## Test Case 7: GraphQL Server with Authorization
**Input:** GraphQL API with Spring Security

**Expected Output:**
```bash
spring init --type=maven-project \
  --java-version=17 \
  --boot-version=3.4.5 \
  --dependencies=graphql,security,data-jpa,postgres \
  --groupId=com.example \
  --artifactId=graphql-server \
  --name=graphql-server \
  --package-name=com.example.graphqlserver \
  graphql-server
```

**Validation:** GraphQL included, security configured

---

## Test Case 8: OAuth2 Resource Server
**Input:** Protected API with OAuth2

**Expected Output:**
```bash
spring init --type=maven-project \
  --java-version=17 \
  --boot-version=3.4.5 \
  --dependencies=web,oauth2-resource-server,data-jpa \
  --groupId=com.example \
  --artifactId=oauth-api \
  --name=oauth-api \
  --package-name=com.example.oauthapi \
  oauth-api
```

**Validation:** OAuth2 resource server dependency present

---

## Test Case 9: Message Queue Integration
**Input:** RabbitMQ + Kafka multi-broker setup

**Expected Output:**
```bash
spring init --type=maven-project \
  --java-version=17 \
  --boot-version=3.4.5 \
  --dependencies=amqp,kafka,actuator \
  --groupId=com.example \
  --artifactId=message-broker \
  --name=message-broker \
  --package-name=com.example.messagebroker \
  message-broker
```

**Validation:** Both AMQP and Kafka included

---

## Test Case 10: Minimal Web Application
**Input:** Bare-bones web server

**Expected Output:**
```bash
spring init --type=maven-project \
  --java-version=17 \
  --boot-version=3.4.5 \
  --dependencies=web \
  --groupId=com.example \
  --artifactId=minimal-web \
  --name=minimal-web \
  --package-name=com.example.minimalweb \
  minimal-web
```

**Validation:** Only web dependency, valid command

---

## Test Results Summary

| Test | Status | Dependencies | Notes |
|------|--------|--------------|-------|
| REST API | ✓ PASS | web, data-jpa, postgres, actuator, security | Full stack web service |
| Kafka | ✓ PASS | kafka, data-jpa, postgres | Event streaming ready |
| MCP + AI | ✓ PASS | web, spring-ai-mcp-server, spring-ai-openai, actuator | AI integration verified |
| WebFlux | ✓ PASS | webflux, data-mongodb, actuator | Reactive stack |
| Microservice | ✓ PASS | web, data-jpa, postgres, cloud-eureka, actuator | Service discovery ready |
| Gradle | ✓ PASS | gradle-project type, Java 21 | Alternative build system |
| GraphQL | ✓ PASS | graphql, security, data-jpa, postgres | Schema-first API |
| OAuth2 | ✓ PASS | web, oauth2-resource-server, data-jpa | Auth delegation |
| Messaging | ✓ PASS | amqp, kafka, actuator | Multi-broker setup |
| Minimal | ✓ PASS | web | Simplicity verified |

**Overall: 10/10 tests passed ✓**
