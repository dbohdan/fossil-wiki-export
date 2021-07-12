# fossil-wiki-export

Export a Fossil SCM wiki to Git preserving (recreating) the revision history.

This program is the missing exporter for the [wiki feature](https://fossil-scm.org/home/doc/trunk/www/wikitheory.wiki) of Fossil SCM.  It exports every Fossil wiki page to a file in a chosen subdirectory of a new or existing Git repository.  Every wiki page revision becomes a Git commit.  The commits are in correct chronological order (globally, not just by page).  The appropriate author date is set for each commit through `GIT_AUTHOR_DATE`.

## Known bugs and limitations

* Each of the characters `< > : " / \ | ? *` is replaced with `_` in the filename.  This means that the pages `Foo: Bar` and `Foo? Bar` will be exported to the same file.

## Requirements

* Git 2.x.  The program has been tested with version 2.25.1.
* Fossil 2.14.2 or later.  (Earlier versions may work but haven't been tested.)
* Tcl 8.6 or later.

## Usage

```sh
./fossil-wiki-export.tcl /path/to/repo.fossil /path/to/git-repo subdir-for-wiki-files
```

### Environment variable settings

Besides the command line arguments, you can customize the behavior of FWE with environment variables.

* `FWE_AFTER` (string, default `1900-01-01T00:00:00`) — only export modifications after this timestamp (non-inclusive).
* `FWE_INIT` (boolean, default true) — run `git init` in the target Git repository path.
* `FWE_TEMPLATE` (string, default `wiki($page): $action`) — the commit message template.  `$page` is replaced with the Fossil wiki page name (`L` in the card); `$action`, with "create", "update", or "delete".
* `FWE_VERBOSE` (boolean, default false) — be verbose and print debug information.

## License

MIT.
