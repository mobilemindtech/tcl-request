# TCL Request

Simple wrapper for tcl `http::geturl`


https://www.tcl.tk/man/tcl8.6.13/TclCmd/http.htm


### Install with `tclp`

Ref https://github.com/mobilemindtech/tclp

```
tclp pkg install https://github.com/mobilemindtech/tcl-request
```


## Usage

```tcl
package require request
namespace import ::request::* 

set req [Request new] ;# or [Request new]
$req url http://myapp.com
set resp [request do -req $req]

# use http with cmd
request get http://app.com -- -header {x y}

request post http://app.com {x=1}

# file dowload

set fd [open my_file.jpg w+]
set page [quote-string "my file name.jpg"]
set url "https://site.com/images/$page"
request get $url -- -channel $fd -binary 1

```

Use `--` to pass values to `http::geturl`


### Doc


* `::request::new-request {args}` Create new `::request::Request`
* `::request::url-encode {keyvallist}`  wrapper for `::http::formatQuery`
* `::request::quote-string {string}`  wrapper for `::http::quoteString`
* `::request::config {args}` wrapper for `::http::config`

* `::request::request get {url {headers keyvallist} args}` 
* `::request::request options {url {headers keyvallist} args}`
* `::request::request post {url payload {headers keyvallist} args}`
* `::request::request put {url payload {headers keyvallist} args}`
* `::request::request patch {url payload {headers keyvallist} args}`
* `::request::request delete {url payload {headers keyvallist} args}`
* `::request::request {args}`

Gereral args

* `-debug` default false
* `-url` url
* `-progress` callback request progress
* `-method` http method
* `-body` body 
* `-json` body as json, set content-type to application/json
* `-timeout` timeout milliseconds
* `-content-type` set content-type
* `-header` keyval `{k v}`
* `-headers` keyvallist `{k v x y}`
* `-req` accepts a `::request::Request`
* `--` send args directly to `::http::geturl`


### ::request::Request

Methods:

* `prop {args}` get or ser prop
* `url {string}` set url
* `body {string}` set body
* `method {string}` set verb method
* `json {json data}` set body with json data
* `header {keyval}` set header
* `headers {keyvallist}` set headers
* `content-type {string}` set content-type

The `::request::Request new` accept all args of session `Request args`. You can use `::request::new-request` too.

### ::request::Response

* `prop {string}` get prop by name
* `encoding` get encoding
* `status` get http status (eg. 200, 404)
* `status-text` ok,eof,error,timeout,reset
* `status-code` get http status (eg. HTTP/1.1 200)
* `text` get bodys tring
* `body` get bodys tring
* `length` get body size
* `content-type` get content-type
* `url` get url
* `headers` get headers keyvallist
* `json` get body as json (dict)
* `header {string}` get header by name
