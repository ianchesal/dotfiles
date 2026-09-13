# Create A Pull Request

Please create a pull request for the current branch with the following information: $ARGUMENTS

Follow these steps:

1. Verify that the branch we're currently on is not named `main` or `master` -- if it is stop
2. Use `git log` to review the commit history
3. Create a pull request using:
  gh pr create --assignee @me --title "[Title]" --body "$(cat <<'EOF'
  ## Summary
  [Brief description of changes]

  ## Changes
  - [Key change 1]
  - [Key change 2]

  ## Test Plan
  [How these changes were tested]
  EOF
  )"

 Ensure the PR title and the body are clear, concise, and follow project conventions. 
