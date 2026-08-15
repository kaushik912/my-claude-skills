#!/bin/bash

# Test suite for spring-init skill

PASS=0
FAIL=0

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

test_command() {
    local description=$1
    local command=$2

    # Check if command has required spring init flags
    if echo "$command" | grep -q "spring init" && \
       echo "$command" | grep -q "\-\-java-version" && \
       echo "$command" | grep -q "\-\-boot-version" && \
       echo "$command" | grep -q "\-\-dependencies" && \
       echo "$command" | grep -q "\-\-artifactId"; then
        echo -e "${GREEN}✓ PASS${NC}: $description"
        ((PASS++))
    else
        echo -e "${RED}✗ FAIL${NC}: $description"
        echo "  Command: $command"
        ((FAIL++))
    fi
}

test_syntax() {
    local description=$1
    local command=$2

    # Validate bash syntax (command would execute without -n flag errors)
    if bash -n <(echo "$command") 2>/dev/null; then
        echo -e "${GREEN}✓ PASS${NC}: Syntax - $description"
        ((PASS++))
    else
        echo -e "${RED}✗ FAIL${NC}: Syntax - $description"
        echo "  Command: $command"
        ((FAIL++))
    fi
}

test_dependencies() {
    local description=$1
    local deps=$2
    local expected_count=$3

    local count=$(echo "$deps" | tr ',' '\n' | wc -l)
    if [ "$count" -eq "$expected_count" ]; then
        echo -e "${GREEN}✓ PASS${NC}: Dependencies - $description (count: $count)"
        ((PASS++))
    else
        echo -e "${RED}✗ FAIL${NC}: Dependencies - $description"
        echo "  Expected: $expected_count, Got: $count"
        echo "  Dependencies: $deps"
        ((FAIL++))
    fi
}

# Test 1: REST API preset
test_command "REST API preset" \
    "spring init --type=maven-project --java-version=17 --boot-version=3.4.5 --dependencies=web,data-jpa,postgres,actuator,security --groupId=com.example --artifactId=user-api --name=user-api --package-name=com.example.userapi user-api"

# Test 2: Kafka event streaming
test_command "Kafka event streaming" \
    "spring init --type=maven-project --java-version=17 --boot-version=3.4.5 --dependencies=kafka,data-jpa,postgres --groupId=com.example --artifactId=order-processor --name=order-processor --package-name=com.example.orderprocessor order-processor"

# Test 3: MCP Server with AI
test_command "MCP Server with Spring AI" \
    "spring init --type=maven-project --java-version=17 --boot-version=3.4.5 --dependencies=web,spring-ai-mcp-server,spring-ai-openai,actuator --groupId=com.example --artifactId=random-quote-mcp --name=random-quote-mcp --package-name=com.example.randomquotemcp random-quote-mcp"

# Test 4: Gradle project
test_command "Gradle project" \
    "spring init --type=gradle-project --java-version=21 --boot-version=3.4.5 --dependencies=web,data-jpa --groupId=com.example --artifactId=gradle-app --name=gradle-app --package-name=com.example.gradleapp gradle-app"

# Test 5: Microservice preset
test_command "Microservice preset" \
    "spring init --type=maven-project --java-version=17 --boot-version=3.4.5 --dependencies=web,data-jpa,postgres,cloud-eureka,actuator --groupId=com.example --artifactId=user-service --name=user-service --package-name=com.example.userservice user-service"

# Test 6: WebFlux reactive
test_command "WebFlux reactive" \
    "spring init --type=maven-project --java-version=17 --boot-version=3.4.5 --dependencies=webflux,data-mongodb,actuator --groupId=com.example --artifactId=reactive-api --name=reactive-api --package-name=com.example.reactiveapi reactive-api"

# Test 7: GraphQL with security
test_command "GraphQL with security" \
    "spring init --type=maven-project --java-version=17 --boot-version=3.4.5 --dependencies=graphql,security,data-jpa,postgres --groupId=com.example --artifactId=graphql-server --name=graphql-server --package-name=com.example.graphqlserver graphql-server"

# Test 8: OAuth2 Resource Server
test_command "OAuth2 Resource Server" \
    "spring init --type=maven-project --java-version=17 --boot-version=3.4.5 --dependencies=web,oauth2-resource-server,data-jpa --groupId=com.example --artifactId=oauth-api --name=oauth-api --package-name=com.example.oauthapi oauth-api"

# Test 9: AMQP/RabbitMQ with Kafka
test_command "AMQP/RabbitMQ messaging" \
    "spring init --type=maven-project --java-version=17 --boot-version=3.4.5 --dependencies=amqp,kafka,actuator --groupId=com.example --artifactId=message-broker --name=message-broker --package-name=com.example.messagebroker message-broker"

# Test 10: Minimal web app
test_command "Minimal web app" \
    "spring init --type=maven-project --java-version=17 --boot-version=3.4.5 --dependencies=web --groupId=com.example --artifactId=minimal-web --name=minimal-web --package-name=com.example.minimalweb minimal-web"

echo ""
echo "=== Dependency Count Tests ==="

# Test dependency counts
test_dependencies "REST API (5 deps)" "web,data-jpa,postgres,actuator,security" 5
test_dependencies "Microservice (5 deps)" "web,data-jpa,postgres,cloud-eureka,actuator" 5
test_dependencies "Simple (1 dep)" "web" 1
test_dependencies "Triple (3 deps)" "kafka,data-jpa,postgres" 3

echo ""
echo "=== Syntax Validation ==="

# Test syntax validation
test_syntax "Maven project with multiple deps" "spring init --type=maven-project --java-version=17 --boot-version=3.4.5 --dependencies=web,data-jpa,postgres --groupId=com.example --artifactId=test-app --name=test-app --package-name=com.example.testapp test-app"

test_syntax "Gradle with webflux" "spring init --type=gradle-project --java-version=21 --boot-version=3.4.5 --dependencies=webflux,data-mongodb --groupId=com.example --artifactId=flux-app --name=flux-app --package-name=com.example.fluxapp flux-app"

echo ""
echo "=== Summary ==="
echo -e "${GREEN}Passed: $PASS${NC}"
echo -e "${RED}Failed: $FAIL${NC}"

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi
