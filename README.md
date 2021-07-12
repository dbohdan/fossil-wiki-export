# fossil-wiki-export

Export a Fossil SCM wiki to Git preserving (recreating) the revision history.

This program is the missing exporter for the [wiki feature](https://fossil-scm.org/home/doc/trunk/www/wikitheory.wiki) of Fossil SCM.  It exports every Fossil wiki page to a file in a chosen subdirectory of a new or existing Git repository.  Every wiki page revision becomes a Git commit.  The commits are in correct chronological order (globally, not just by page).  The appropriate author date is set for each commit through `GIT_AUTHOR_DATE`.

## Requirements

* Git v2.x.  The program was tested with v2.25.1.
* Fossil 2.16 or later.  (Earlier versions may work but haven't been tested.)
* Tcl 8.6 or later.

## Usage

```sh
./fossil-wiki-export.tcl /path/to/repo.fossil /path/to/git-repo subdir-for-wiki-files
```

### Environment variable settings

Besides the command line arguments, you can customize the behavior of FWE with environment variables.

* `FWE_INIT` (boolean, default true) — run `git init` in the target Git repository path.
* `FWE_DEBUG` (boolean, default false) — be verbose and print debug information.
* `FWE_DEFAULT_MIME_TYPE` (string, default `text/x-markdown`) — the MIME type for pages without one in the [card](https://fossil-scm.org/home/doc/trunk/www/fileformat.wiki).  Determines the file extension.
* `FWE_TEMPLATE` (string, default `wiki($page): $action`) — the commit message template.  `$page` is replaced with the Fossil wiki page name (`L` in the card); `$action`, with "create", "update", or "delete".


## License

MIT.
