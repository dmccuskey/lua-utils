# lua-utils

A grab bag of small helper functions for Lua: tables, strings, URLs and queries, callbacks, time and image scaling.

lua-utils is one module, `lua_utils`, a table of plain functions with no state and no dependencies. It was written for the DMC Solar2D (formerly Corona SDK) libraries, but it's plain Lua 5.1 and runs anywhere:

```lua
local Utils = require 'lua_utils'

local parts = Utils.split( 'red,green,blue', ',' )  --> { 'red', 'green', 'blue' }
local copy = Utils.extend( defaults, {} )            -- deep copy
```

## Features

- Tables: deep copy and merge, slice, count, list the values, find and remove an item, shuffle, print a nested table
- Strings and the web: split, Python-style formatting, URL encoding and decoding, query strings
- Callbacks: bind a method to its object; call something once `n` transitions have finished
- Time and images: split seconds into days, hours, minutes; the scale that fits an image in, or over, a box
- Pure Lua 5.1, one file, no dependencies; MIT licensed

## Quick Start

The following steps will get you up and running in about 5 minutes with Lua 5.1 on macOS or Linux. You will load the module and try a few of its functions.

Prerequisites: Lua 5.1 (`lua -v` shows `Lua 5.1.x`) and git.

### 1. Get the Code

In an empty folder:

```sh
git clone https://github.com/dmccuskey/lua-utils.git
```

The module is `lua-utils/dmc_lua/lua_utils.lua`.

### 2. Use It

Create `main.lua` in the same folder:

```lua
package.path = './lua-utils/dmc_lua/?.lua;' .. package.path
local Utils = require 'lua_utils'

local parts = Utils.split( 'red,green,blue', ',' )
print( #parts, parts[2] )

local defaults = { size=12, font={ name='Helvetica', bold=false } }
local style = Utils.extend( { font={ bold=true } }, Utils.extend( defaults, {} ) )
print( style.size, style.font.name, style.font.bold, defaults.font.bold )

print( table.concat( Utils.tableSlice( { 10, 20, 30, 40, 50 }, 2, -2 ), ' ' ) )

print( Utils.createQuery( { q='lua utils' } ) )
print( Utils.parseQuery( 'page=2&sort=name' ).sort )

local t = Utils.calcTimeBreakdown( 93784 )
print( t.days, t.hours, t.minutes, t.seconds )
```

Run it:

```sh
lua main.lua
```

```text
3	green
12	Helvetica	true	false
20 30 40
q=lua+utils
name
1	2	3	4
```

The second line shows the usual way to merge settings: copy the defaults (`extend( defaults, {} )`), then copy the changes over the copy, which leaves the defaults untouched. If it shows `module 'lua_utils' not found`, run it from the folder that holds `lua-utils/`.

To update, pull the repository again (`git -C lua-utils pull`).

## Functions

All are called on the module, `Utils.name( ... )`. "Array" means a table with keys `1..n`. The module's version is `Utils.__version` (`0.3.1`).

### Tables

| function | does |
|---|---|
| `extend( from, to )` | Copies every key of `from` into `to` and returns `to`. Nested tables are copied, not shared, and merged into a table already at that key in `to`. `extend( t, {} )` is a deep copy (without metatables). Errors when either is `nil`. |
| `destroy( t )` | Sets every key of `t`, and of every table in it, to `nil`. For plain data, not objects. |
| `tableSlice( array, i1, i2 )` | A new array of `array[i1..i2]`. `i1` defaults to 1, `i2` to the end; a negative `i2` counts from the end (`-1` is the last). |
| `tableLength( t )`, `tableSize( t )` | The number of keys in `t`, of any kind (the two are the same). |
| `tableList( t )` | A new array of the values of `t`, in `pairs()` order. |
| `propertyIn( array, value )` | `true` if `value` is in `array`. |
| `removeFromTable( array, value )` | Removes the last occurrence of `value` from `array` and returns it, or `nil`. |
| `shuffle( array )` | Shuffles `array` in place and returns it. |
| `hasOwnProperty( t, key )` | `true` if `t` itself holds `key`, ignoring its metatable's `__index`. |
| `print( t, include, exclude, params )` | Prints the keys of `t` and of the tables in it, indented, down to `params.limit` levels (default 10). Skips functions and keys that start with `_`, unless named in the `include` array; skips keys named in `exclude`. |

### Strings and the Web

| function | does |
|---|---|
| `split( str, sep )` | An array of the pieces of `str` between separators. `sep` is a set of characters, as in a Lua pattern's `[...]` (default: whitespace); empty pieces are dropped (`'a,,b'` gives two). |
| `stringFormatting( fmt, values )` | `string.format( fmt, ... )` with `values` as one value or an array of them (a `nil` in the array is passed on, not the end of it). The same function is lua-patch's `%` operator for strings. |
| `urlEncode( str )`, `urlDecode( str )` | Form encoding: spaces become `+`, other characters except letters, digits and `-_.~` become `%XX`, a newline `%0D%0A`. Decoding reverses it. |
| `createQuery( t )` | `k1=v1&k2=v2` from a table, keys and values URL-encoded, in `pairs()` order. |
| `parseQuery( str )` | A table from `k1=v1&k2=v2`, keys and values URL-decoded; pairs with an empty key or value are dropped. `parseQuery( createQuery( t ) )` gives back `t` (as strings). |
| `normalizeHeaders( headers, params )` | A copy of the table with every key in lower case, or with `params.case='camel'` each word capitalized (`Content-Type`). |
| `createHttpRequest( params )` | The text of an HTTP request: `params.method`, `params.path` (default `/`), `params.host`, and the optional `params.http_params.headers` and `.body`. |
| `hexDump( str )` | Writes `str` to standard output as a hex dump, 16 bytes a line with their text. |

### Callbacks

| function | does |
|---|---|
| `createObjectCallback( object, method )` | A function that calls `method( object, ... )`: a method as a listener. |
| `getTransitionCompleteFunc( count, callback )` | A function that calls `callback` once it has been called `count` times (and on every call after): one callback for several transitions. |

### Time, Images, Random

| function | does |
|---|---|
| `calcTimeBreakdown( seconds, params )` | A table `{ weeks, days, hours, minutes, seconds }` for a duration. Weeks only with `params.weeks=true`; otherwise days hold them. `params.days`, `.hours` or `.minutes` set to `false` leave that unit at 0 and its time in the next smaller one. |
| `imageScale( box, image, params )` | The scale for an image (`width`, `height`) against a box (the same). `params.bind='outside'` (default) covers the box, cropping; `'inside'` fits the image in it. |
| `getUniqueRandom( include, exclude )` | A random item of the array `include` that isn't in the array `exclude`; `nil` (with a warning) when none is left. Uses `math.random()`: seed it once in your program (`math.randomseed()`) for different picks on each run. |

## In Solar2D

[dmc-utils](https://github.com/dmccuskey/dmc-utils) builds on this module, adding functions for Solar2D (audio channels, device checks, the status bar). The DMC Solar2D libraries load lua-utils itself as `lib.dmc_lua.lua_utils` from their `dmc_corona/lib/dmc_lua/` folder, part of [DMC-Lua-Library](https://github.com/dmccuskey/DMC-Lua-Library).

## Development

Only `dmc_lua/lua_utils.lua` is written here. [DMC-Lua-Library](https://github.com/dmccuskey/DMC-Lua-Library) copies it into its `dmc_lua/` with its Snakemake build (the `Snakefile` here registers it; lua-files lists it as a requirement), and the DMC Solar2D libraries copy it from there into `dmc_corona/lib/dmc_lua/`.

Some modules keep a copy of a function from here, between `--== Start: copy from lua_utils ==--` and `--== End: copy from lua_utils ==--`, so they load without lua-utils. A fix to one of these functions goes into the copies too:

- `createObjectCallback()`: lua-events-mixin (`lua_events_mix.lua`)
- `stringFormatting()`: lua-patch (`lua_patch.lua`)
- `extend()`: the Solar2D modules of dmc-autostore, dmc-bytearray, dmc-dragdrop, dmc-e4x, dmc-error, dmc-events-mixin, dmc-megaphone, dmc-objects, dmc-patch, dmc-path, dmc-performance, dmc-promise and dmc-states-mixin

The tests are in `spec/utils_spec.lua`, for [busted](https://lunarmodules.github.io/busted/) under Lua 5.1. From the repository's root folder:

```sh
busted spec
```

## License

lua-utils is released under the [MIT License](LICENSE).
