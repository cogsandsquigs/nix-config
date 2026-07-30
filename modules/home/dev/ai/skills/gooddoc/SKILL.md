---
name: gooddoc
description: >-
  Rewrites prose -- docs, READMEs, PR descriptions, error messages, release notes, comments, agent
  instructions -- into ASD-STE100 Simplified Technical English, which removes the padding, hedging,
  and marketing register that read as "AI slop". Never applies to code, identifiers, or command
  syntax. Use when writing or cleaning up documentation in or for a codebase, manuals, technical
  documents, or agent instructions, and when the user asks for text "without AI slop". Two modes:
  strict for procedures, runbooks, and safety text, and STE-flavored for general prose.
argument-hint: "<text or file to rewrite>"
---

# gooddoc -- ASD-STE100 writing

Write prose in ASD-STE100 Simplified Technical English. This applies to documentation, READMEs,
pull-request text, error messages, release notes, comments, and agent instructions. It does not
apply to code, identifiers, or command syntax. It is wrong for marketing copy, essays, and anything
that needs a voice, because STE strips voice on purpose.

Write only the requested text. No preamble, no summary, no closing remarks.

## Modes

- **strict** -- procedures, runbooks, safety text, error messages. Apply every rule and both length
  caps.
- **STE-flavored** -- general prose such as READMEs, PR descriptions, and docs. Apply the sentence,
  paragraph, active-voice, and plain-verb discipline. Relax the ~900-word dictionary so the text
  keeps enough range to read naturally.

## Rules

### Words

- One name for one thing. Do not call the same item by two names.
- Use the short common word: start (not begin, commence, initiate), use (not utilize, leverage),
  help (not facilitate), make sure (not ensure), before (not prior to), after (not subsequent to),
  about (not regarding, concerning), get (not obtain, acquire), show (not demonstrate), also (not
  additionally, furthermore, moreover).
- One meaning per word. "Fall" means to move down, not to decrease.
- No marketing adjectives: seamless, robust, powerful, cutting-edge, effortless, world-class,
  next-generation, revolutionary.
- American spelling.

### Verbs

- Active voice. "The parser reads the file", not "the file is read by the parser".
- A verb for an action. "Analyze the log", not "perform an analysis of the log".
- No stacked auxiliaries. Not "it is important to note that this may help to improve". Write "this
  improves X".
- No "-ing" main verb where a simple tense works.

### Sentences

- One instruction per sentence. Maximum 20 words for an instruction, 25 for description.
- No contractions. Use articles: a, an, the, this, these.

### Punctuation

- No semicolons. Write two sentences. STE does not ban the em dash, only the semicolon. Ask for "no
  em dash" separately if you want it gone.

### Structure

- One topic per paragraph, maximum six sentences.
- For steps, use a numbered vertical list, one action per item, imperative form.
- Put a condition before its command.

### Length and formatting

- Match length to content. Cover the substance and stop. No filler sections, no restated summary, no
  boilerplate.
- Prefer flowing paragraphs to fragments. Use a list only for genuinely discrete items, such as
  steps, options, or fields. A wall of three-word bullets is slop in a different costume.
- Reserve markdown for inline code, code blocks, and simple headings. Bold and italics are rarely
  needed.

## Self-lint

Run this pass over the text before returning it:

1. Any sentence over 20 words? Split it.
2. Any semicolon? Replace it with a period.
3. Any contraction? Expand it.
4. Any passive voice with a known actor? Make it active.
5. Any "-ing" main verb, nominalization ("perform an analysis"), or phrasal verb ("spin up")?
   Replace it with a plain verb.
6. Same thing named two ways? Pick one name.
7. Any section that adds no information the reader lacks? Cut it.

These rules are mechanical, and they are what removes the form of slop. Full STE also needs human
judgment: the right technical noun, and whether a sentence makes good sense. A checker cannot
certify that, and slop is not about that. This skill fixes the FORM of slop. It cannot make a hollow
paragraph true.

The standard is free but copyrighted, so do not paste it in full: https://asd-ste100.org
