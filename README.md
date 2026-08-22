# danwah.me

Ett utbildningsprojekt för att lära sig en modern utvecklingsprocess med FastAPI, Docker, GitHub Actions och tre separata miljöer.

## Miljöer

| Miljö | Branch/release | URL |
|---|---|---|
| Dev | `develop` | https://dev.danwah.me |
| Test | `test` | https://test.danwah.me |
| Prod | `main` efter godkännande i GitHub Environment `production` | https://prod.danwah.me |

## Deployflöde

```text
feature-branch → Pull Request → develop → dev
                                   ↓
                                  test → test
                                   ↓
                                  main → prod (manuellt godkännande)
```

Varje lyckad branch-push bygger en immutable image i GHCR. Deployen verifierar sedan både `/health` och `/version` mot rätt miljö och commit-SHA. Produktion använder GitHub Environment `production`, som kräver ett manuellt godkännande innan containern uppdateras.

## Lokal utveckling

```bash
uv sync --dev
uv run uvicorn app.main:app --reload
```

Öppna sedan http://127.0.0.1:8000.

## Kvalitetskontroller

```bash
uv run python -m pytest -q
uv run ruff check .
```

## API

- `GET /` – applikationens namn, miljö och version
- `GET /health` – healthcheck för Docker och reverse proxy
- `GET /version` – miljö, applikationsversion och Git-commit

Runtime konfigureras med `APP_ENV`, `APP_VERSION` och `COMMIT_SHA`.
