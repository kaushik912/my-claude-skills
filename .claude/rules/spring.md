# Spring

Use the `spring` CLI (Spring Boot CLI) for project init/scaffolding when available — check with `command -v spring`. Fall back to Spring Initializr (start.spring.io) only if the CLI isn't installed. See the `spring-init` skill for dependency mapping and command generation.

When adding any new API, always attempt to add Swagger (springdoc-openapi) support — dependency, config, and annotations — unless already present:
- Dependency: `org.springdoc:springdoc-openapi-starter-webmvc-ui` (e.g. `2.8.6`, latest at time of writing)
- Default endpoints: Swagger UI `/swagger-ui.html`, OpenAPI spec `/v3/api-docs` — no custom `springdoc:` config needed unless overriding paths
- Annotate controllers with `@Tag` (class) and `@Operation` (method)
