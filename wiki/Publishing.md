# Publishing to CurseForge & Wago

This guide explains how to publish **GroundAuraTracker** to CurseForge and Wago using automated GitHub Actions.

---

## Step 1: Create the Project on CurseForge

1. Log into the [CurseForge Author Portal](https://authors.curseforge.com/).
2. Click **Create a Project**.
3. Choose:
   - **Game:** World of Warcraft
   - **Section:** Addons $\rightarrow$ Combat / Class
   - **Name:** `GroundAuraTracker`
   - **Description:** Copy the content from [README.md](../README.md).
   - **License:** MIT License
4. Once created, note your **Project ID** from the *About This Project* box on the right sidebar.
5. In your `GroundAuraTracker.toc`, replace `000000` with your actual CurseForge Project ID:
   ```toc
   ## X-Curse-Project-ID: 123456
   ```

---

## Step 2: Generate CurseForge API Token

1. In CurseForge, click your profile avatar $\rightarrow$ **API Tokens** (or visit `https://authors.curseforge.com/account/api-tokens`).
2. Generate a new API Token with upload permissions.
3. Copy the token.

---

## Step 3: Add the Secret to GitHub

1. In your GitHub repository, go to **Settings** $\rightarrow$ **Secrets and variables** $\rightarrow$ **Actions**.
2. Click **New repository secret**.
3. Name: `CF_API_KEY`
4. Value: Paste your CurseForge API token.
5. *(Optional for Wago)* Add `WAGO_API_TOKEN` for simultaneous Wago publishing.

---

## Step 4: Publish a Release

Whenever you want to publish a new update to CurseForge, create and push a Git tag:

```bash
# Tag a new version
git tag v1.0.0

# Push tag to GitHub
git push origin v1.0.0
```

### What Happens Automatically:
1. GitHub Actions triggers `.github/workflows/release.yml`.
2. All 83 unit tests and syntax checks run locally in the CI runner.
3. `BigWigsMods/packager@v2` packages the addon (excluding tests, docs, and dev scripts via `.pkgmeta`).
4. Injects version tags and uploads the `.zip` release directly to **CurseForge**, **Wago**, and **GitHub Releases** simultaneously!
