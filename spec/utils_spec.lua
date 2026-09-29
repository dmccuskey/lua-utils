--[[
Testing for lua_utils
--]]

package.path = './dmc_lua/?.lua;' .. package.path

local Utils = require 'lua_utils'



--====================================================================--
--== Testing Setup
--====================================================================--


-- run func with _G.print replaced, return the printed lines
local function capturePrint( func )
	local lines = {}
	local saved = _G.print
	_G.print = function( ... )
		local parts = {}
		for i = 1, select( '#', ... ) do
			parts[i] = tostring( select( i, ... ) )
		end
		table.insert( lines, table.concat( parts, '\t' ) )
	end
	local ok, err = pcall( func )
	_G.print = saved
	assert( ok, err )
	return lines
end



--====================================================================--
--== Module
--====================================================================--


describe( "lua_utils", function()

	it( "exports its version", function()
		assert.are.equal( '0.3.0', Utils.__version )
	end)

	it( "leaks no globals", function()
		local names = { '_destroy', '_extend', '_print', 'opts' }
		for _, name in ipairs( names ) do _G[name] = nil end

		Utils.destroy( { a={ b=1 } } )
		Utils.extend( { a={ b=1 } }, {} )
		capturePrint( function()
			Utils.print( { a={ b=1 }, c=2 } )
		end)

		for _, name in ipairs( names ) do
			assert.is_nil( rawget( _G, name ), name )
		end
	end)

end)



--====================================================================--
--== Callback Functions
--====================================================================--


describe( "callbacks", function()

	it( "createObjectCallback() calls the method on the object", function()
		local obj = { n=1 }
		function obj:add( x ) return self.n + x end
		local f = Utils.createObjectCallback( obj, obj.add )
		assert.are.equal( 3, f( 2 ) )
	end)

	it( "getTransitionCompleteFunc() calls back from the count on", function()
		local calls = 0
		local f = Utils.getTransitionCompleteFunc( 3, function() calls = calls + 1 end )
		f() ; f()
		assert.are.equal( 0, calls )
		f()
		assert.are.equal( 1, calls )
		f()
		assert.are.equal( 2, calls )
	end)

end)



--====================================================================--
--== Date Functions
--====================================================================--


describe( "calcTimeBreakdown()", function()

	local secs = 2*7*86400 + 3*86400 + 8*3600 + 35*60 + 21

	it( "puts weeks in days by default", function()
		assert.are.same(
			{ weeks=0, days=17, hours=8, minutes=35, seconds=21 },
			Utils.calcTimeBreakdown( secs ) )
	end)

	it( "counts weeks with params.weeks", function()
		assert.are.same(
			{ weeks=2, days=3, hours=8, minutes=35, seconds=21 },
			Utils.calcTimeBreakdown( secs, { weeks=true } ) )
	end)

	it( "turns days, hours and minutes off with false", function()
		assert.are.same(
			{ weeks=0, days=0, hours=416, minutes=35, seconds=21 },
			Utils.calcTimeBreakdown( secs, { days=false } ) )
		assert.are.same(
			{ weeks=0, days=0, hours=0, minutes=0, seconds=secs },
			Utils.calcTimeBreakdown( secs, { days=false, hours=false, minutes=false } ) )
	end)

	it( "leaves params unchanged, and takes negative durations", function()
		local params = { hours=false }
		local r = Utils.calcTimeBreakdown( -90, params )
		assert.are.same( { hours=false }, params )
		assert.are.equal( 1, r.minutes )
		assert.are.equal( 30, r.seconds )
	end)

end)



--====================================================================--
--== Image and Math Functions
--====================================================================--


describe( "imageScale()", function()

	local box, img = { width=100, height=100 }, { width=200, height=100 }

	it( "covers the box by default", function()
		assert.are.equal( 1, Utils.imageScale( box, img ) )
	end)

	it( "fits in the box with bind='inside'", function()
		assert.are.equal( 0.5, Utils.imageScale( box, img, { bind='inside' } ) )
	end)

end)


describe( "getUniqueRandom()", function()

	it( "returns an item not excluded", function()
		for _ = 1, 20 do
			assert.are.equal( 'c', Utils.getUniqueRandom( { 'a', 'b', 'c' }, { 'a', 'b' } ) )
		end
	end)

	it( "returns nil when every item is excluded", function()
		local r
		capturePrint( function()
			r = Utils.getUniqueRandom( { 'a' }, { 'a' } )
		end)
		assert.is_nil( r )
		assert.is_nil( Utils.getUniqueRandom( {} ) )
	end)

	it( "doesn't reseed the generator", function()
		local saved = math.randomseed
		local seeded = false
		math.randomseed = function( ... ) seeded = true ; return saved( ... ) end
		Utils.getUniqueRandom( { 'a', 'b' } )
		Utils.getUniqueRandom( { 'a', 'b' }, { 'a' } )
		math.randomseed = saved
		assert.is_false( seeded )
	end)

end)


describe( "hexDump()", function()

	it( "writes 16 bytes a line with their text", function()
		local out = {}
		local saved = io.write
		io.write = function( ... )
			for i = 1, select( '#', ... ) do table.insert( out, ( select( i, ... ) ) ) end
		end
		Utils.hexDump( 'ABC' )
		io.write = saved
		local text = table.concat( out )
		assert.truthy( text:find( '^00000000  41 42 43 ' ) )
		assert.truthy( text:find( 'ABC\n$' ) )
	end)

end)



--====================================================================--
--== String Functions
--====================================================================--


describe( "strings", function()

	it( "split() splits on whitespace or a separator", function()
		assert.are.same( { 'a', 'b', 'c' }, Utils.split( 'a b  c' ) )
		assert.are.same( { 'a', 'b' }, Utils.split( 'a,b', ',' ) )
	end)

	it( "stringFormatting() takes one value or a table of them", function()
		assert.are.equal( 'x', Utils.stringFormatting( 'x' ) )
		assert.are.equal( 'a=1', Utils.stringFormatting( 'a=%s', 1 ) )
		assert.are.equal( '1 2', Utils.stringFormatting( '%s %s', { 1, 2 } ) )
	end)

end)



--====================================================================--
--== Table Functions
--====================================================================--


describe( "tables", function()

	it( "destroy() empties a table and its sub-tables", function()
		local inner = { b=1 }
		local t = { a=inner, c=2 }
		Utils.destroy( t )
		assert.is_nil( next( t ) )
		assert.is_nil( next( inner ) )
	end)

	it( "extend() deep-copies into the target and returns it", function()
		local from = { a={ b=1 }, c=2 }
		local to = { a={ d=3 } }
		local r = Utils.extend( from, to )
		assert.are.equal( to, r )
		assert.are.same( { a={ b=1, d=3 }, c=2 }, to )
		assert.are_not.equal( from.a, to.a )
		assert.has_error( function() Utils.extend( nil, {} ) end )
	end)

	it( "hasOwnProperty() ignores inherited properties", function()
		local t = setmetatable( { a=1 }, { __index={ b=2 } } )
		assert.is_true( Utils.hasOwnProperty( t, 'a' ) )
		assert.is_false( Utils.hasOwnProperty( t, 'b' ) )
	end)

	it( "print() prints data, skipping functions and private keys", function()
		local lines = capturePrint( function()
			Utils.print( { name='x', f=print, _p=1, sub={ n=2 } } )
		end)
		local text = table.concat( lines, '\n' )
		assert.truthy( text:find( "name = 'x'", 1, true ) )
		assert.truthy( text:find( "  n = 2", 1, true ) )
		assert.falsy( text:find( '_p', 1, true ) )
		assert.falsy( text:find( 'f =', 1, true ) )
	end)

	it( "propertyIn() and removeFromTable() search an array", function()
		local t = { 'a', 'b', 'c' }
		assert.is_true( Utils.propertyIn( t, 'b' ) )
		assert.is_false( Utils.propertyIn( t, 'z' ) )
		assert.are.equal( 'b', Utils.removeFromTable( t, 'b' ) )
		assert.are.same( { 'a', 'c' }, t )
		assert.is_nil( Utils.removeFromTable( t, 'z' ) )
	end)

	it( "shuffle() keeps the items", function()
		local t = Utils.shuffle( { 1, 2, 3, 4, 5 } )
		table.sort( t )
		assert.are.same( { 1, 2, 3, 4, 5 }, t )
	end)

	it( "tableLength(), tableSize() and tableList() count and list values", function()
		local t = { a=1, b=2, 3 }
		assert.are.equal( 3, Utils.tableLength( t ) )
		assert.are.equal( 3, Utils.tableSize( t ) )
		local list = Utils.tableList( t )
		table.sort( list )
		assert.are.same( { 1, 2, 3 }, list )
	end)

	it( "tableSlice() takes a range, negative from the end", function()
		local t = { 1, 2, 3, 4 }
		assert.are.same( { 2, 3 }, Utils.tableSlice( t, 2, 3 ) )
		assert.are.same( { 3, 4 }, Utils.tableSlice( t, 3 ) )
		assert.are.same( { 1, 2, 3 }, Utils.tableSlice( t, 1, -2 ) )
		assert.are.same( {}, Utils.tableSlice( t, 5 ) )
	end)

end)



--====================================================================--
--== Web Functions
--====================================================================--


describe( "createHttpRequest()", function()

	it( "builds a request without the string-format patch", function()
		local req = Utils.createHttpRequest{
			method='POST', host='example.com', path='/api',
			http_params={ headers={ ['Content-Type']='text/plain' }, body='hi' }
		}
		assert.are.equal(
			'POST /api HTTP/1.1\r\nHost: example.com\r\nContent-Type:text/plain\r\n\r\nhi\r\n\r\n',
			req )
	end)

	it( "defaults the path to / and works without http_params", function()
		assert.are.equal(
			'GET / HTTP/1.1\r\nHost: example.com\r\n\r\n',
			Utils.createHttpRequest{ method='GET', host='example.com' } )
	end)

end)


describe( "normalizeHeaders()", function()

	local headers = { ['CONTENT-type']='a', ['x-my-HEADER']='b' }

	it( "writes lower case by default", function()
		assert.are.same( { ['content-type']='a', ['x-my-header']='b' },
			Utils.normalizeHeaders( headers ) )
	end)

	it( "capitalizes each word with case='camel'", function()
		assert.are.same( { ['Content-Type']='a', ['X-My-Header']='b' },
			Utils.normalizeHeaders( headers, { case='camel' } ) )
	end)

end)


describe( "queries", function()

	it( "urlEncode() and urlDecode() round-trip", function()
		local s = 'a b&c=d/é'
		assert.are.equal( 'a+b%26c%3Dd%2F%C3%A9', Utils.urlEncode( s ) )
		assert.are.equal( s, Utils.urlDecode( Utils.urlEncode( s ) ) )
	end)

	it( "parseQuery() splits and decodes", function()
		assert.are.same( { one='1', ['t w']='a&b' },
			Utils.parseQuery( 'one=1&t+w=a%26b' ) )
	end)

	it( "parseQuery( createQuery( t ) ) returns t", function()
		local t = { ['key one']='a b', ['k&=']='x=y&z', plain='1' }
		assert.are.same( t, Utils.parseQuery( Utils.createQuery( t ) ) )
	end)

end)
