# splandorf-site

The front door of **www.splandorf.com**: the homepage and the web-server (Caddy) routing on the front VM.
Each project keeps its own code and deployment in its own repository; this one only decides which path goes where.

| Path | Goes to | Listed on the homepage |
|---|---|---|
| `/` | `site/index.html` | — |
| `/conlang/` | Conlang Forge, on this same VM (`127.0.0.1:8000`) | yes |
| `/purple/` | Purple, on its own VM `purple-1` (internal address, port 8000) | **no** (private; also sent with `noindex`) |
| `splandorf.com/...` | redirects to `www.splandorf.com/...` | — |

## Publish (on the front VM)
```bash
git clone git@github.com:spland0rf/splandorf-site.git ~/splandorf-site      # private repo: add a read-only deploy key first
sudo bash ~/splandorf-site/install.sh
```
The first run asks for purple-1's internal IP and keeps it in `/etc/splandorf-site/env`. After a change here:
`cd ~/splandorf-site && git pull && sudo bash install.sh`. The script validates the new routing before using it,
so a mistake never takes the site down.

## Moving the routing out of conlang-forge
Until now `conlang-forge/deploy/gce/setup.sh` and `update.sh` copied their own homepage and Caddyfile, and would
overwrite this repository's (dropping `/purple`) on every Conlang update. The conlang-forge change that stops that
must be merged and pulled onto the VM **before** running `install.sh` here, and the VM needs to be tagged
`splandorf-front` for Purple's firewall rule (see purple's `deploy/gce/README.md`).

## Adding a project
* Public: add its route above the final `handle` in `Caddyfile` and an `<li>` in `site/index.html`.
* Private: add only the route. Never mention a private path in `site/` (the page source is public).

**Keep this repository private**: `Caddyfile` and this README name the private paths.
