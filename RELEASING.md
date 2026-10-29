# Releasing

For maintainers. Releases are cut from `main` after `development` is merged into it. Run it from a separate worktree (`git worktree add ../fuelgauge-release main`) so work in progress can't leak into the build.

```sh
git checkout main && git pull
NOTARY_PROFILE=midnightoil-notary Scripts/release.sh 1.0.0
```

`Scripts/release.sh` then:

1. Archives the app and exports it with Developer ID signing (cloud-managed, so no certificate lives on the machine).
2. Notarizes and staples the app, builds the DMG, and notarizes and staples that.
3. Checks the app inside the DMG with Gatekeeper.
4. Signs the update with Sparkle and writes `appcast.xml`.
5. Packs the Claude Desktop extension (`mcpb/dist/fuelgauge.mcpb`) and publishes a GitHub release `v<version>` with the DMG, an unversioned `FuelGauge.dmg` (what the website links to), `appcast.xml`, and `fuelgauge.mcpb`. The README and website link to `releases/latest/download/fuelgauge.mcpb`, so every release needs it.
6. Bumps the version and checksum in the Homebrew cask.

The build number is the commit count, so it always goes up.

## One-time setup

- **Xcode:** signed in to the team in Settings › Accounts, or `ASC_KEY_PATH`, `ASC_KEY_ID`, and `ASC_ISSUER_ID` for an App Store Connect API key.
- **Notarization:** a notarytool keychain profile (`xcrun notarytool store-credentials <name>`), passed as `NOTARY_PROFILE`. Or `APPLE_ID` and `APPLE_APP_PASSWORD` in the environment.
- **Sparkle key:** the EdDSA private key in the login keychain under the account `fuelgauge`. The script passes `--account fuelgauge`, so another app's key is never used. The public key is `SUPublicEDKey` in `project.yml`. For CI, put the private key in `SPARKLE_KEY_FILE`.
- **Homebrew:** `Casks/fuelgauge.rb` in [coreyhaines31/homebrew-tap](https://github.com/coreyhaines31/homebrew-tap).
- **GitHub CLI:** `gh` signed in with push access to this repo and the tap.
- **Node:** Node 20+ and npm, to pack the Claude Desktop extension.

## The Claude Desktop extension

`mcpb/` is a small Node MCP server that runs the `fuelgauge` CLI (`status` and `history` only, read-only). To check it: `cd mcpb && npm ci && npm run lint && npm test`. To attach it to an existing release without cutting a new one:

```sh
cd mcpb && npm ci && npm run pack
gh release upload v<version> dist/fuelgauge.mcpb --repo coreyhaines31/fuelgauge --clobber
```

Bump `version` in `mcpb/manifest.json`, `mcpb/package.json`, and `mcpb/src/index.ts` when the extension changes.

## Updates

The app checks `https://github.com/coreyhaines31/fuelgauge/releases/latest/download/appcast.xml` (`SUFeedURL` in `project.yml`). Each release's appcast points at that release's DMG.

## The website

The site in `site/` deploys to Vercel (project `fuelgauge`) from `main`:

```sh
python3 site/_build/render.py   # regenerate pages after editing site/_build/*.py
cd site && vercel deploy --prod
```

## When something goes wrong

- **notarytool hangs on "initiating connection":** if no entry shows in `xcrun notarytool history` after about 5 minutes, stop it and run the script again. Nothing is published before notarization finishes.
- **GitHub returns a 500 and leaves a draft:** `gh release edit v<version> --draft=false --latest`, then bump the cask by hand.
- **The cask push is rejected:** another release pushed first. Redo the cask bump in a fresh clone of the tap.
- **Release notes:** the script uses `--generate-notes`. Rewrite them by hand for people, not commits.
