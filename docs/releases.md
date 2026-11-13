# Publishing releases

1. Add a `CHANGELOG.md` section matching the new tag, such as `## [v1.2.3] - YYYY-MM-DD`.
2. Commit and push the changes to `main`.
3. Push the version tag:

   ```sh
   git tag -a v1.2.3 -m "v1.2.3"
   git push origin v1.2.3
   ```

Tags such as `v1`, `v1.2`, and `v1.2.3` trigger the release workflow. It builds the
amd64 image, provisions the tools, and runs the regression and offline smoke tests
before publishing to `ghcr.io/ricardoboss/t3-code-container` and creating a GitHub
release from the matching changelog section. No registry secret needs configuring;
the workflow uses its repository-scoped `GITHUB_TOKEN`.

Images receive the exact version tag and `latest`. Dotted versions also update the
major image alias, so `v1.2.3` publishes `:v1.2.3`, `:v1`, and `:latest`.
`latest` tracks the most recently published release. Git version tags are not moved.

If a workflow fails, fix the cause and rerun it before publishing another tag.
The GitHub release is created only after the image has been published successfully.
