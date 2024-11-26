# TCL Requests

Simple wrapper for tcl `http::geturl`

## Usage

```tcl

package require requests

namespace import ::requests::*

set resp [get http://myapp.com/json]

# convert to tcl dict
puts [$resp json]

set resp [post http://myapp.com/json -json {{"x": 1, "y": 2}}]

puts [$resp status]

set req [new-request]
$req uri http://myapp.com
set resp [get -req $req]

get http://app.com -- -header {x y} 

```

Use `--` to pass values to `http::geturl`
