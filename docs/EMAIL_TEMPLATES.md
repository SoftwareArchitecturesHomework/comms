# Email Templates

Location: `lib/comms_web/templates/email/`

Colors follow Nuxt UI scheme:

- Background: `#0f172b`
- Primary: `#05df72`
- Text: white
- Muted: `#767e8e`

A shared layout `layout.html.eex` wraps each template. Render with assigns including `:view_module` and `:view_template` pointing to the desired template.

## Templates and Assigns

- `user_added_to_project.html.eex`

  - `project`: `%{id, name}`
  - `manager`: `%{id, name, email}`
  - `member`: `%{id, name, email}`
  - Optional: `project_url`, `manager_url`, `member_url`, `action_url`

- `user_removed_from_project.html.eex`

  - `project`: `%{id, name}`
  - `manager`: `%{id, name, email}`
  - `member`: `%{id, name, email}`
  - Optional: `action_url`

- `project_completion.html.eex`

  - `project`: `%{id, name}`
  - `manager`: `%{id, name, email}`
  - `member`: `%{id, name, email}`
  - Optional: `summary`, `action_url`

- `task_assignment.html.eex`

  - `task`: `%{id, details: %{start, end, name, description}}` (UNIX seconds for `start`/`end`)
  - `assigner`: `%{id, name, email}`
  - `assignees`: `[%{id, name, email}]`
  - Optional: `action_url`, `accept_url`

- `task_completion.html.eex`

  - `task`: `%{id, details: %{name, description}}`
  - `assigner`: `%{id, name, email}`
  - `assignees`: `[%{id, name, email}]`
  - Optional: `action_url`

- `task_permission_request.html.eex`
  - `task`: `%{id, details: %{name, description}}`
  - `assigner`: `%{id, name, email}`
  - `assignees`: `[%{id, name, email}]`
  - Optional: `action_url`, `approve_url`, `deny_url`

## Rendering Example (Swoosh)

```elixir
new()
|> to(member.email)
|> from({"Comms", manager.email})
|> subject("You were added to #{project.name}")
|> render_body("lib/comms_web/templates/email/layout.html.eex", Map.merge(assigns, %{
  title: "Added to Project",
  view_module: CommsWeb.EmailView,
  view_template: "user_added_to_project.html.eex"
}))
```

Note: Prefer inline CSS for better email client support. Dates in `task_assignment` use `DateTime.from_unix!`.
