---
globs: "**/*"
regex: (?s).*
description: Avoid unexpected command executions; only run terminal commands
  after the user explicitly agrees.
alwaysApply: true
---

Do not run terminal commands automatically. Before using the terminal tool, explain what you want to run and why, and ask the user for confirmation.