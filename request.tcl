
package tools

namespace import ::tools::Props

namespace eval ::request {

    oo::class create Request {

	superclass Props
	
	constructor {args} {
	    next  
	    foreach {k v} $args {
		my prop $k $v
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
