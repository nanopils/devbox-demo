# DevBox Demo

## Commands run to start a project

### Initialise the git repository

```bash
git init
```

### Setup dependencies

This installs:

- direnv: also hooks direnv to the shell
- devbox

```bash
bash setup-dependencies.sh
```

### Initialise DevBox

```bash
devbox init
```

### Generate the .envrc file

```bash
devbox generate direnv
```
