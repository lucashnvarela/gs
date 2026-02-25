# gss

A small bash script to switch git branches with less friction:
it stashes your work, switches the branch, syncs with the remote, and can re-apply your last stash for that branch.

### Usage

```bash
gss <branch-name>
```

Examples:

```bash
gss main
gss feature/add-login
```

### Installation

Clone the repository and make the script executable:

```bash
chmod +x gss.sh
```

Add it to your `PATH` or create an alias (e.g. `alias gss="/path/to/gss/gss.sh"`).
