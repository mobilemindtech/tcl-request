

package require json
package require tools

namespace import ::tools:props

namespace eval request {
    oo::class create Response {

	superclass Props
	
	constructor {token} {
	    next
	    
	    my prop status [::http::status $token]
	    my prop size [::http::size $token]
	    my prop code [::http::code $token]
	    my prop ncode [::http::ncode $token]
	    my prop meta [::http::meta $token]
	    my prop data [::http::data $token]
	    my prop error [::http::error $token]
	    my prop size [::http::size $token]
	    my prop meta [::http::meta $token]
	    my prop encoding [array get $token coding]
	    my prop charset [array get $token charset]
	    my prop currentsize [array get $token currentsize]
	    my prop totalsize [array get $token totalsize]
	    my prop http [array get $token http]
	    my prop type [array get $token type]
	    my prop url [array get $token url]
	    my prop totalsize [array get $token totalsize]

	    #The error, if any, that occurred while writing the post query data to the server. 
	    my prop posterror [array get $token posterror]
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
}
