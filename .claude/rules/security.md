# Security Constraints

- **Secrets**: Never hardcode API keys, passwords, or tokens. Use environment variables.
- **SQL**: Always use parameterized queries or ORM abstractions. Zero raw string concatenation for SQL.
- **Inputs**: Sanitize all user inputs before rendering them in the DOM to prevent XSS.
