#! /usr/bin/env tclsh
# Export a Fossil SCM wiki to Git preserving the revision history.
# Copyright (c) 2021 D. Bohdan and contributors.
# License: MIT.

package require Tcl 8.6-10

namespace eval fossil-wiki-export {
    variable debug false
    variable query {
        SELECT uuid
        FROM blob
        WHERE regexp('D[^\n]+\nL ', content(uuid));
    }
    variable version 0.1.0

    proc main {repo dest subdir} {
        variable debug
        set debug [env FWE_VERBOSE false]

        set uuids [uuids $repo]
        debug [llength $uuids] UUIDs
        set cardsNoOrder [wiki-cards $repo $uuids]

        set cards {}
        foreach D [lsort [dict keys $cardsNoOrder]] {
            dict set cards $D [dict get $cardsNoOrder $D]
        }
        unset cardsNoOrder

        set dir [file join $dest $subdir]
        file mkdir $dir
        cd $dest

        if {[env FWE_INIT true]} {
            run git init
        }

        set after [env FWE_AFTER 1900-01-01T00:00:00]
        set seen {}
        set template [env FWE_TEMPLATE {wiki($page): $action}]
        dict for {D card} $cards {
            set L [dict get $card L]

            if {[dict exists $seen $L]} {
                set action update
            } else {
                set action create
                dict set seen $L {}
            }

            if {$D <= $after} continue

            # Filename logic.
            set N [env FWE_DEFAULT_MIME_TYPE text/x-markdown]
            if {[dict exists $card N]} {
                set N [dict get $card N]
            }

            switch -- $N {
                text/x-fossil-wiki {
                    set ext .wiki
                }
                text/x-markdown {
                    set ext .md
                }
            }

            set path $dir/[safe-filename $L]$ext
            set ch [open $path wb]
            puts -nonewline $ch [dict get $card text]
            close $ch

            # Determine if this is a deletion (blanking).
            if {[regexp {^\s*$} [dict get $card text]]} {
                try {
                    set action delete
                    run git rm --force $path
                } on error {e opts} {
                    # Skip repeated wiki page deletions (blankings).
                    if {[regexp {pathspec '.*' did not match any files} $e]} {
                        continue
                    }
                    return -options $opts $e
                }
            } else {
                run git add $path
            }

            set ::env(GIT_AUTHOR_DATE) [dict get $card D]
            set message [string map [list \
                {$action} $action \
                {$page} $L \
            ] $template]

            try {
                run git commit \
                    --message $message \
                    $path \
            } on error {e opts} {
                if {![regexp {nothing (to commit|added to commit but\
                              untracked)} $e]} {
                    return -options $opts $e
                }
            }
        }

        return 0
    }

    proc env {varName default} {
        if {[info exists ::env($varName)]} {
            return $::env($varName)
        }

        return $default
    }

    proc debug args {
        variable debug

        if {$debug} {
            puts stderr $args
        }
    }

    proc uuids repo {
        variable query

        set output [exec \
            fossil sql \
                --readonly \
                --repository $repo \
            << $query \
        ]
        string map [list ' {} \n { }] $output
    }

    proc wiki-cards {repo uuids} {
        set cards {}

        try {
            set ch [file tempfile temp]
            fconfigure $ch -translation binary

            set i 0
            lmap uuid $uuids {
                exec fossil artifact --repository $repo $uuid $temp
                seek $ch 0

                set card [parse-wiki-card [read $ch]]
                set D [dict get $card D]
                if {[dict exists $cards $D]} {
                    error [list two cards with date $D]
                }

                incr i
                if {$i % 100 == 0} {
                    debug card $i
                }

                dict set cards $D $card
            }
        } finally {
            close $ch
            file delete $temp
        }

        return $cards
    }

    proc safe-filename filename {
        regsub -all {[<>:"/\\|?*]} $filename _
    }

    proc run args {
        set command [list {*}$args]
        debug running {*}$command
        exec {*}$command
    }

    proc parse-wiki-card card {
        set parsed {}
        set i 0

        set len [string length $card]
        while {$i < $len} {
            if {![regexp \
                    -indices \
                    -start $i \
                    {([A-Z]) ([^\n]+)\n} \
                    $card _ _ valueIndex]} {
                error [list can't parse card at index $i \
                    [string range $card $i $i+10]... of $len]
            }

            lassign $valueIndex valueStart valueEnd
            set format [string index $card $i]
            set value [string range $card $valueStart $valueEnd]

            if {$format eq {W}} {
                set text \
                    [string range $card \
                        [expr { $valueEnd + 2 }] \
                        [expr { $valueEnd + 2 + $value }]]
                dict set parsed text $text
                set i [expr { $valueEnd + 3 + $value }]
            } else {
                set i [expr { $valueEnd + 2 }]
            }

            dict set parsed $format $value
        }

        dict set parsed L [string map [list \\s { }] [dict get $parsed L]]

        return $parsed
    }
}

# If this is the main script...
if {[info exists argv0] && ([file tail [info script]] eq [file tail $argv0])} {
    exit [fossil-wiki-export::main {*}$argv]
}

package provide fossil-wiki-export 0
