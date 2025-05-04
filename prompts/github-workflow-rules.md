# GitHub Workflow Rules for 6307635.xyz (Hugo Site)
# Last Updated: 2025-05-04

## Overview
This document defines required GitHub Actions workflow standards for the `6307635.xyz` static site project. It includes deployment strategy, DNS and domain integration, branch-based previews, and artifact naming rules. It is inspired by production-grade engineering conventions to ensure high fidelity across environments.

---

## Deployment Structure

### Branch Behavior

| Branch       | Purpose             | Domain                         | Publish Branch       |
|--------------|---------------------|--------------------------------|-----------------------|
| `main`       | Production           | `https://6307635.xyz`          | `gh-pages`            |
| `dev`        | Staging/QA          | `https://dev.6307635.xyz`      | `gh-pages-dev`        |
| `*` (others) | Previews (wildcard) | `https://<branch>.dev.6307635.xyz` | `gh-pages-preview` |

All deploys must be done via GitHub Actions using `peaceiris/actions-gh-pages@v3`.

## Shell Command Rules

- Always prefer block-style `run` steps using `|` for better readability and maintainability.
- The quoting is important. The `"` on _both_ sides of `>>`.

---

## GitHub Actions Rules

- Every workflow must extract the branch name using:

```yaml
- name: Get branch name
  id: vars
  run: echo "branch=${GITHUB_REF##*/}" >> $GITHUB_OUTPUT
```

- Use the branch name to construct dynamic values:
  - `baseURL` for Hugo builds
  - `CNAME` file for custom domains
  - `publish_branch` for deploy target

---

## Hugo Build Rules

- Hugo builds must include `--minify` and the appropriate `--baseURL`
- All deployments must place a `CNAME` file inside `/public`
- Built content must go to `./public` and be deployed to the correct publish branch
- Hugo config must use `relativeURLs: true` and `canonifyURLs: false` to ensure branch-based previews work with wildcard domains.

---

## DNS & Domain Requirements

- Domain: `6307635.xyz`
- DNS is hosted via `lada.websitewelcome.com` (cPanel) with wildcard `*.dev.6307635.xyz` enabled
- A valid `CNAME` must be created for each deploy with the exact domain name used in the baseURL
- Example `CNAME` values:
  - `6307635.xyz`
  - `dev.6307635.xyz`
  - `feature-x.dev.6307635.xyz`

---

## Deployment Workflow Conventions

All GitHub Pages deployments must:

- Use `force_orphan: true` to keep branch history clean
- Generate a user-visible URL at the end of the deploy log:
  ```yaml
  - name: Output live preview URL
    run: echo "🔗 Your site is live at: ${{ steps.vars.outputs.base }}"
  ```
- A `DEPLOYED_URL.txt` file should be created during deployment to include the base URL of the live site for verification or reference.

---

## Versioning and Branch Preview

- Every preview deployment must build Hugo with a unique baseURL derived from the branch:
  ```
  https://<branch>.dev.6307635.xyz/
  ```
- These previews should be published to a shared branch like `gh-pages-preview`, using dynamic CNAMEs to maintain unique domains

---

## Artifact Publishing

This site does not produce compiled artifacts like JARs, but uses the `/public` folder as the deployable output.

- DO NOT upload `public` as an artifact unless explicitly debugging
- DO NOT commit `public` into the repo; it is a build output only
- DO NOT use `gh-pages` as a source branch for user content

---

## CI Behavior & Optimization

- Deploys should happen on `push` events only, never on PRs
- PRs should trigger validation builds (`hugo --minify`) but never publish
- CI should reuse build logic locally and in prod (use a Makefile or shared script)

---

## Example Deploy Flow

```yaml
- uses: peaceiris/actions-hugo@v2
  with:
    hugo-version: latest

- run: hugo --minify --baseURL "${{ steps.vars.outputs.base }}"

- name: Output deployed URL to file
  run: echo "${{ steps.vars.outputs.base }}" > public/DEPLOYED_URL.txt

- run: echo "${{ steps.vars.outputs.cname }}" > public/CNAME

- uses: peaceiris/actions-gh-pages@v3
  with:
    personal_token: ${{ secrets.GH_PAT }}
    publish_dir: ./public
    publish_branch: ${{ steps.vars.outputs.target }}
    force_orphan: true
```

---

## User Visibility Output

Each deployment must include a final workflow step that logs the live URL for user visibility. Add this step at the end of your GitHub Actions job:

```yaml
- name: Output live preview URL
  run: echo "🔗 Your site is live at: ${{ steps.vars.outputs.base }}"
```

This ensures contributors and reviewers can instantly identify where the deployed site is located after a push to any branch.

---

## Maintenance

- All changes to deploy logic must be reflected in this rules file
- If deploy branching logic, naming, or baseURL structure changes, update this file immediately
- Ensure `.github/workflows/deploy.yml` remains consistent with this spec
- The assistant will proactively prompt to update this file whenever changes are made to workflows, branch structures, domain usage, or deployment behavior to ensure documentation fidelity.
- The assistant will proactively prompt to update this file whenever config.yaml changes require build system alignment.

---

## Contact

For questions, issues, or access control around deploy tokens or GitHub secrets, contact:  
📧 contact@6307635.xyz
