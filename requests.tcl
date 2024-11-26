package require http
package require tls
package require TclOO
package require logger
package require json

http::register https 443 [list ::tls::socket -autoservername true]

namespace eval requests {

    set log [logger::init requests]

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
                    ${::requests::log}::error "propery $name not found"
                    return {}
                }
            }

            method encoding {} {
                my prop encoding
            }

            method status {} {
                my prop ncode
            }

            method status-text {} {
                my prop status
            }

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
                    ${::requests::log}::error "header $name not found"
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
                        ${::requests::log}::error "prop $name not found"
                        return {}
                    }
                } elseif {[llength $args] == 2} {
                    set name [lindex $args 0]
                    set val [lindex $args 1]
                    dict set props $name $val
                    return $val
                } else {
                    ${::requests::log}::error "use prop <name> or prop <name> <value>"
                }
	    }

	    method query {query} {
		my prop -query $query
	    }

            method url {url} {
                my prop -url $url
            }

	    method uri {url} {
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

    proc get {uri {headers {}} {args ""}} {
        request -uri $uri -method GET -headers $headers {*}$args
    }

    proc options {uri {headers {}} {args ""}} {
        request -uri $uri -method OPTIONS -headers $headers {*}$args
    }

    proc head {uri {headers {}} {args ""}} {
        request -uri $uri -method HEAD -headers $headers {*}$args
    }

    proc post {uri payload {{headers}} {args ""}} {
        request -uri $uri -method POST -data $payload -headers $headers {*}$args
    }

    proc put {uri payload {{headers}} {args ""}} {
        request -uri $uri -method PUT -data $payload -headers $headers {*}$args
    }

    proc patch {uri payload {{headers}} {args ""}} {
        request -uri $uri -method PATCH -data $payload -headers $headers {*}$args
    }

    proc delete {uri payload {{headers}} {args ""}} {
        request -uri $uri -method DELETE -data $payload -headers $headers {*}$args
    }

    # Execute a http request
    # @param args keyvaluelist
    proc request {args} {
        variable log
        set queries {}
        set headers {}
        set params {}
        set uri {}
        set data {}
        set debug false
        set req {}

	set reqIdx [lsearch $args -req]
        if {$reqIdx > -1} {
	    incr reqIdx
	    set req [lindex $args $reqIdx]
	    foreach {k v} [$req props] {
		dict set params $k $v
	    }
        }

        foreach {k v} $args {
            switch -regexp -- $k {
                -req {
                    # bypass
                }
                -debug {
                    set debug $v
                }
                -uri|-url {
                    set uri $v
                }
                -protocol {
                    dict set params -protocol $v
                }
                -progress {
                    dict set params -progress $v
                }
                -progress-post {
                    dict set params -queryprogress $v
                }
                -method {
                    dict set params -method $v
                }
                -body {
                    set data $v
                }
                -json {
                    set data $v
                    dict set params -type application/json
                }
                -timeout {
                    dict set params -timeout $v
                }
                -contentType|-content-type {
                    dict set params -type $v
                }
                -query {
                    dict set queries [lindex $v 0] [lindex $v 1]
                }
                -queries {
                    foreach it $v {
                        dict set queries [lindex $it 0] [lindex $it 1]
                    }
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

        dict set params -query [::http::formatQuery {*}$queries]
        dict set params -headers $headers

        if {$debug} {
            ${log}::debug "[dict get $params -method] $uri"
            foreach {k v} $params {                
                ${log}::debug "param: $k=$v"
            }
        }

        set token [http::geturl $uri {*}$params ]
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

    proc new-request {args}{
	Request new {*}$args
    }

    namespace export url-encode new-request get post put patch delete options request
}
