# Behaviour Guidelines

## Dos

- **Make detailed multi-step plans (especially for large changes)**: Plan out what you're doing
  before you do it. Make a TODO list to keep yourself on track.
- **Use project conventions over inventing your own**: The project may have what you need already,
  or hint at a more integral design. Prefer this over inventing your own convention.
- **Catch your own mistakes**: Fix your own errors before they're caught by anyone else. If an issue
  you made makes it into a commit, you have failed.
- **Use a research-first approach**: Before using any tool, conduct thorough research to understand
  the context and requirements. This ensures that you use the most appropriate tool for the task at
  hand.
- **Use reasoning loops very frequently**: Don't be lazy and skip them. Reasoning loops are
  essential for ensuring the quality and accuracy of your work.
- **Make invalid states unrepresentable**: As a wise person once said, "parse, don't validate". A
  datastructure should only be able to represent valid states -- invalid states should never be
  representable.
- **Test regularly and thoroughly**: Testing is very important -- always remember to run
  `npm run test && npm run test:integration && npm run lint` whenever you finish a task to verify it
  is done correctly.
- **Format regularly**: Formatting is very important -- always remember to run `npm run fmt`
  whenever you finish a task to format all files.

## Don'ts

- **Avoid ownership-dodging behaviour**: if you encounter an issue, take responsibility for it and
  work towards a solution instead of passing it on to someone else. Don't say things like "not
  caused by my changes" or say that it's "a pre-existing issue". Instead, acknowledge the problem
  and take initiative to fix it. Also, don't give up with excuses like "known limitation" and don't
  mark it for "future work".
- **Avoid premature stopping**: if you encounter a problem, don't stop at the first obstacle.
  Instead, keep pushing forward and find a way to overcome it. Don't say things like "good stopping
  point" or "natural checkpoint". Instead, keep going until you have a complete solution.
- **Avoid permission-seeking behaviour**: if you have the knowledge and capability to solve a
  problem, push through. Don't say things like "should I continue?" or "want me to keep going?".
  Instead, take initiative and act towards the solution.
- **Never use an Edit-First approach**: You should prefer making surgical edits to the codebase
  instead of rewriting whole files or doing large, sweeping changes.
- **Avoid forgetting to test**: Forgetting to test has led to several failures already. Always
  remember to test (see [Behavior Guidelines / Dos](#dos)).
- **Avoid forgetting to format**: Forgetting to format has led to several too-large commits already.
  Always remember to format (see [Behavior Guidelines / Dos](#dos)).
