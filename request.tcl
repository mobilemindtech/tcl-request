package provide request 1.0

package require http
package require tls
package require TclOO
package require logger
package require json

::http::register https 443 [list ::tls::socket -autoservername true]


namespace eval ::request {

    namespace export request new-request url-encode quote-string config Request Response


    set log [logger::init request]

    catch {
        oo::class create Response {

            constructor {token} {
                my variable props
                set props {}
                dict set props status [::http::status $token]
                dict set props size [::http::size $token]
                dict set props code [::http::code $token]
                dict set props ncode [::http::ncode $token]
                dict set props meta [::http::meta $token]
                dict set props data [::http::data $token]
                dict set props error [::http::error $token]
                dict set props size [::http::size $token]
                dict set props meta [::http::meta $token]
                dict set props encoding [array get $token coding]
                dict set props charset [array get $token charset]
                dict set props currentsize [array get $token currentsize]
                dict set props totalsize [array get $token totalsize]
                dict set props http [array get $token http]
                dict set props type [array get $token type]
                dict set props url [array get $token url]
                dict set props totalsize [array get $token totalsize]

                #The error, if any, that occurred while writing the post query data to the server. 
                dict set props posterror [array get $token posterror]
            }

            method prop {name} {
                my variable log props
                if {[dict exists $props $name]} {
                    dict get $props $name
                } else {
                    ${::request::log}::error "propery $name not found"
                    return {}
                }
            }

            method encoding {} {
                my prop encoding
            }

            # 200
            method status {} {
                my prop ncode
            }

            # ok,eof,error,timeout,reset
            method status-text {} {
                my prop status
            }

            # HTTP/1.1 200
            method status-code {} {
                my prop code
            }

            method text {} {
                my prop data
            }

            method body {} {
                my prop data
            }

            method length {} {
                my prop totalsize
            }

            method content-type {} {
                my header Content-Type
            }

            method url {} {
                my prop url
            }

            method headers {} {
                my prop meta
            }

            method json {} {
                ::json::json2dict [my text]
            }

            method header {name} {
                set hrs [my headers]
                if {[dict exists $hrs $name]} {
                    dict get $hrs $name
                } else {
                    ${::request::log}::error "header $name not found"
                    return {}                    
                }
            }
        }    


        oo::class create Request {
            
            constructor {args} {
                my variable props 
                set props {}
                foreach {k v} $args {
                    my prop $k $v
                }
            }

            method props {} {
                my variable props
                return $props
            }

            method prop {args} {
                my variable props
                if {[llength $args] == 1} {
                    set name [lindex $args 0]
                    if {[dict exists $props $name]} {
                        dict get $props $name]
                    } else {
                        ${::request::log}::error "prop $name not found"
                        return {}
                    }
                } elseif {[llength $args] == 2} {
                    set name [lindex $args 0]
                    set val [lindex $args 1]
                    dict set props $name $val
                    return $val
                } else {
                    ${::request::log}::error "use prop <name> or prop <name> <value>"
                }
	        }


            method url {url} {
                my prop -url $url
            }

            method body {body} {
                my prop -body $body
            }

            method method {method} {
                my prop -method $method
            }

            method json {data} {
                my prop -json $data
            }

            method header {name val} {
                set headers [my prop -headers]
                dict set -headers $name $val
                my prop -headers $headers
            }

            method headers {headers} {
                my prop -headers $headers
            }

            method content-type {type} {
                my header Content-Type $type
            }
        }    
    }

    proc get {url {headers ""} {args ""}} {
        do-request -url $url -method GET -headers $headers {*}$args
    }

    proc options {url {headers ""} {args ""}} {
        do-request -url $url -method OPTIONS -headers $headers {*}$args
    }

    proc head {url {headers ""} {args ""}} {
        do-request -url $url -method HEAD -headers $headers {*}$args
    }

    proc post {url payload {headers ""} {args ""}} {
        do-request -url $url -method POST -body $payload -headers $headers {*}$args
    }

    proc put {url payload {headers ""} {args ""}} {
        do-request -url $url -method PUT -body $payload -headers $headers {*}$args
    }

    proc patch {url payload {headers ""} {args ""}} {
        do-request -url $url -method PATCH -body $payload -headers $headers {*}$args
    }

    proc delete {url payload {headers ""} {args ""}} {
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
            do { do-request {*}$args }
            default {
                return -code error "command $cmd not found, use <get|head|options|post|put|delete|patch>"
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
                    dict set params -method $v
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
                    foreach it $v {
                        dict set headers [lindex $it 0] [lindex $it 1]
                    }
                }
                -header {
                    dict set headers [lindex $v 0] [lindex $v 1]
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

namespace eval ::request::all {
    namespace import ::request::quote-string
    namespace import ::request::config
    namespace import ::request::url-encode
    namespace import ::request::new-request
    namespace import ::request::get
    namespace import ::request::post
    namespace import ::request::put
    namespace import ::request::patch
    namespace import ::request::delete
    namespace import ::request::options
    namespace import ::request::do-request
    namespace import ::request::request
    namespace import ::request::Request
    namespace import ::request::Response
}
