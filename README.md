# gs

A small bash script to switch git branches with less friction:
it stashes your work, switches the branch, syncs with the remote, and can re-apply your last stash for that branch.

### Usage

```bash
gs <branch-name>
```

Examples:

```bash
gs main
gs feature/add-login
```

### Installation

Clone the repository and make the script executable:

```bash
chmod +x gs.sh
```

Add it to your `PATH` or create an alias (e.g. `alias gs='/path/to/gs/gs.sh'`).
