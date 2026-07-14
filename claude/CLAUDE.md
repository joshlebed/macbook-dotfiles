### Local Servers

- Never start background HTTP servers in subagents — they outlive the subagent
  and cause port conflicts. If a subagent needs to verify a web page loads, use
  a quick curl check, not a persistent server.
- When starting a local dev server, always kill any existing process on the port
  first: `lsof -ti:PORT | xargs kill 2>/dev/null`

### Testing Static Web Apps

- For HTML/JS apps in `docs/`, test with:
  `lsof -ti:8000 | xargs kill 2>/dev/null; python3 -m http.server 8000 -d docs &`
  then use browser automation or curl to verify.
