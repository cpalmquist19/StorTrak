# Seed data generator

Generates `db/seed.sql`, the fictional dataset for Piedmont Stor-All. The output is
byte-for-byte reproducible: the same code, seed and Faker version always produce the
same file. `db/seed.sql` is committed so a fresh `make up` has data without running the
generator first.

## Running it

```sh
make seed     # regenerate db/seed.sql only
make reset    # regenerate, then drop/recreate the database and load schema + seed
```

`make seed` runs the generator in Docker (`docker/seed/Dockerfile`: Python 3.12.7 with
Faker installed from `requirements.txt`). The image only contains the dependencies;
`seed/` is mounted read-only at run time, so code changes don't need a rebuild.

Without Docker, use a virtualenv (Python 3.12 or newer):

```sh
python -m venv .venv
.venv/bin/pip install -r seed/requirements.txt      # Windows: .venv\Scripts\pip
.venv/bin/python -m seed --out db/seed.sql
```

Options: `--out PATH` (default `db/seed.sql`) and `--seed N` (default in `config.py`).
