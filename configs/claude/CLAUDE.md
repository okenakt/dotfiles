# Claude Code Configuration

## Core Principles

- Think in English for all reasoning and communication
- Break down complex problems into smaller steps and solve them systematically
- Ask for clarification on ambiguous requirements rather than making assumptions
- Write all code comments and documentation in English

## Language Guidelines

### Python

- Use Google-style docstrings
- Follow PEP 8 style guidelines
- Include type hints

### TypeScript

- Use kebab-case for file names
- Use `type` by default instead of `interface`, except when declaration merging or public API extension is required
- Do not use `any`, allow `unknown` only when dealing with unknown data
- Use arrow functions by default, except for utility or library functions
- Include JSDoc comments for all exported functions

## Documentation Requirements

Generate these documentation files in the docs/ directory:

- `design.md`: System architecture and design philosophy
- `features.md`: Feature specifications and requirements
- `decisions.md`: Architecture decision records and technical choices

Use diagrams and examples to create clear and accessible documentation, utilizing Mermaid syntax for visual elements.
