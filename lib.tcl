package provide request 1.0


source [file join [file dirname [file normalize [info script]]] request.tcl]
source [file join [file dirname [file normalize [info script]]] response.tcl]

package require http
package require tls
package require TclOO
package require logger
package require json
package require tools

::http::register https 443 [list ::tls::socket -autoservername true]


namespace eval ::request {

    namespace export request new-request url-encode quote-string config Request Response


    set log [logger::init request]


    proc get {url {headers ""} {args ""}} {
        do-request -url $url -method GET -headers $headers {*}$args
    }

    proc options {url {headers ""} {args ""}} {
        do-request -url $url -method OPTIONS -headers $headers {*}$args
    }

    proc head {url {headers ""} {args ""}} {
        do-request -url $url -method HEAD -headers $headers {*}$args
    }

    proc post {url {payload ""} {headers ""} {args ""}} {
        do-request -url $url -method POST -body $payload -headers $headers {*}$args
    }

    proc put {url {payload ""} {headers ""} {args ""}} {
        do-request -url $url -method PUT -body $payload -headers $headers {*}$args
    }

    proc patch {url {payload ""} {headers ""} {args ""}} {
        do-request -url $url -method PATCH -body $payload -headers $headers {*}$args
    }

    proc delete {url {payload} {headers ""} {args ""}} {
        do-request -url $url -method DELETE -body $payload -headers $headers {*}$args
    }

    # @param cmd <get|head|options|post|put|delete|patch>
    proc request {cmd args} {

        switch $cmd {
            get { get {*}$args }
            head { head {*}$args }
            options { options {*}$args }
            post { post {*}$args }
            put { put {*}$args }
            delete { delete {*}$args }
            patch { patch {*}$args }
            default {
		do-request $cmd {*}$args
            }
        }
    }

    # Execute a http request
    # @param args keyvaluelist
    proc do-request {args} {
        variable log
        set headers {}
        set params {}
        set url {}
        set query {}
        set debug false
        set req {}

	set reqIdx [lsearch $args -req]
        if {$reqIdx > -1} {
	       incr reqIdx
	       set req [lindex $args $reqIdx]
	       foreach {k v} [$req props] {
		      dict set args $k $v
	       }
        }

        foreach {k v} $args {
            switch $k {
                -req {
                    # bypass
                }
                -debug {
                    set debug $v
                }
                -url {
                    set url $v
                }
                -method {
                    dict set params -method [string toupper $v]
                }
                -body {
                    set query $v
                }
                -json {
                    set query $v                    
                    dict set params -type application/json
                }
                -timeout {
                    dict set params -timeout $v
                }
                -content-type {
                    dict set params -type $v
                }
                -headers {
                    foreach {k v} $v {
                        dict set headers $k $v
                    }
                }
                -header {
                    foreach {k v} $v {
                        dict set headers $k $v
                    }
                }
            }
        }

        set i [lsearch $args --]        
        if {$i > 0} {
            incr i
            foreach {k v} [lrange $args $i end] {
                dict set params $k $v
            }
        }

	dict set params -query $query
        dict set params -headers $headers

        if {$debug} {
            ${log}::debug "[dict get $params -method] $url"
            foreach {k v} $params {                
                ${log}::debug "param: $k=$v"
            }
	}

        set token [::http::geturl $url {*}$params ]
        set resp [Response new $token]
        ::http::cleanup $token
        return $resp
    }

    #
    # URL encode
    # @param keyvaluelist
    proc url-encode {data} {
        ::http::formatQuery {*}$data
    }

    # @param keyvaluelist
    proc new-request {args} {
	   Request new {*}$args
    }

    # @param keyvaluelist
    proc config {args} {
        ::http::config {*}$args
    }

    proc quote-string {value} {
        ::http::quoteString $value
    }    
}
