//init Module here, for use later in lua.vm.js

var printBuffer = '';
var printElement = undefined;
function printOutAndErr(s) {
	console.log("print: "+s);
	if (printBuffer !== '') printBuffer += '\n';
	printBuffer += s
	printElement.html(printBuffer
		.replace(new RegExp('&', 'g'), '&amp;')
		.replace(new RegExp('<', 'g'), '&lt;')
		.replace(new RegExp('>', 'g'), '&gt;')
		.replace(new RegExp('"', 'g'), '&quot;')
		.replace(new RegExp('\n', 'g'), '<br>')
		.replace(new RegExp(' ', 'g'), '&nbsp;')
	);
	$(document).scrollTop($(document).height()); 
}

function clearOutput() {
	printElement.html(printBuffer = '');
}

var Module = {
	print : printOutAndErr,
	printErr : printOutAndErr,
	stdin : function() {} 
};

var lastCmd = null; 

//update if there are any stored input commands
function update() {
	if (lastCmd !== null) {
		Lua.execute('launcher.update("'+lastCmd+'")');
		lastCmd = null;
	}
}

function doneLoadingFilesystem() {
	//set up input handler
	$(window).keydown(function(e) {
		switch (e.keyCode) {
		case 37:	//left
			lastCmd = 'left';
			break;
		case 38:	//up
			lastCmd = 'up';
			break;
		case 39:	//right
			lastCmd = 'right';
			break;
		case 40:	//down
			lastCmd = 'down';
			break;
		case 32:	//space
			lastCmd = 'space';
			break;
		case 13:	//enter
			lastCmd = 'enter';
			break;
		default:
			var key = String.fromCharCode(e.which).toLowerCase();
			if (key == 'q') key = 'quit';
			lastCmd = key;
			break;
		}
	});
	setInterval(update, 100);

	//launch first file
	Lua.execute([
		"package.path = package.path .. ';./?/init.lua'",
		"require 'launch_js'"
	].join('\n'));
}

$(document).ready(function() {
	printElement = $('#print');

	executeLuaVMFileSet({
		//TODO don't store them here
		//just pull from https://raw.github.com/thenumbernine/stupid-text-rpg/master/
		files : [
			'army.lua',
			'battle.lua',
			'box.lua',
			'client.lua',
			'entity.lua',
			'items.lua',
			'jobs.lua',
			'launch_js.lua',
			'log.lua',
			'map.lua',
			'monster.lua',
			'player.lua',
			'stupid.lua',
			'treasure.lua',
			'unit.lua',
			'util.lua',
			'vec.lua',
			'view.lua'	
		],
		packages : ['ext'],
		onexec : function(url, dest) {
			Module.print('loading '+dest+' ...');
		},
		//wait til all are loaded, then insert them in order
		//this way we run the lua.vm.js before writing to the filesystems (since the filesystem is created by lua.vm.js)
		done : function() { 
			Module.print('initializing...');
			setTimeout(doneLoadingFilesystem, 0);
		}
	});
});

