# JUnit Test Style: BDD (Given/When/Then)

When writing or generating JUnit tests (any Java project), structure the test body
in Given/When/Then sections using comments:

```java
@Test
void givenIdExists_whenGetUser_thenReturnsUser() {
    // Given
    userRepository.save(new User(1L, "alice"));

    // When
    User result = userService.getUser(1L);

    // Then
    assertThat(result.getName()).isEqualTo("alice");
}
```

- Method names: `given<Condition>_when<Action>_then<Outcome>`.
- Use `// Given` / `// When` / `// Then` comments to separate setup, action, assertion.
- Don't pull in Cucumber/JBehave (.feature files) unless the project explicitly needs
  non-technical stakeholders reading/writing scenarios — plain Given/When/Then
  comments on top of JUnit are sufficient otherwise.
- Same applies to mocks: prefer plain Mockito (`when().thenReturn()`); only reach for
  BDDMockito (`given().willReturn()`) if the rest of the test already reads as BDD-style
  and the team wants full consistency.
