# lua-utils

try:
	if not gSTARTED: print( gSTARTED )
except:
	MODULE = "lua-utils"
	include: "../DMC-Lua-Library/snakemake/Snakefile"

module_config = {
	"name": "lua-utils",
	"module": {
		"dir": "dmc_lua",
		"files": [
			"lua_utils.lua"
		],
		"requires": []
	},
	"tests": {
		"dir": "spec",
		"files": [],
		"requires": []
	}
}

register( "lua-utils", module_config )


