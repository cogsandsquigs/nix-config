# Documentation

Documentation comes in some forms: **inline** (doc comments) and **external** (anything under
external docs, e.g. `docs/`). Documentation is different from comments in several ways:

- It is **end-user facing**
- It decribes **relevant behavior** to end-users

Documentation is required ONLY when one of these conditions is met:

- The object/function/type/thing is exported **and** will be seen by the end-user
- The code in question has hidden behavior end-users would need to know
- If there was no documentation for something, end-users would get confused about it

Documentation should follow these guidelines:

- **Do the least amount necessary**: Fewer words are better.
- **Describe any inputs and outputs**: For functions, this means using e.g. in JS: `@param` and
  `@return` TSDoc. For types, this means e.g. in TS: `@typeParam` for TSDoc.
- **Explain any error conditions, common questions, or pitfalls**: Users should be warned to avoid
  these. Only explain if there is any to explain -- a lack of warning implies this is generally safe
  to use.

Remember to update both external- and inline-documentation as you work. Note inline documentation
may become "external" auto-generated documentation -- don't touch that.
