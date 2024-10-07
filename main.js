import {require} from '/js/util.js';
import {executeLuaVMFileSet} from '/js/lua.vm-util.js';

let printBuffer = '';
const printElement = document.getElementById('print');

printOutAndErr = s => {
	console.log("print: "+s);
	if (printBuffer !== '') printBuffer += '\n';
	printBuffer += s
	printElement.innerHTML = printBuffer
		.replace(new RegExp('&', 'g'), '&amp;')
		.replace(new RegExp('<', 'g'), '&lt;')
		.replace(new RegExp('>', 'g'), '&gt;')
		.replace(new RegExp('"', 'g'), '&quot;')
		.replace(new RegExp('\n', 'g'), '<br>')
		.replace(new RegExp(' ', 'g'), '&nbsp;');
	//document.scrollTop(document.offsetHeight);
}

// exported for the lua vm which the lua code to call via its js global
window.clearOutput = () => {
	printElement.innerHTML = printBuffer = '';
};


//exported for the LuaModule require
window.LuaModule = {
	print : printOutAndErr,
	printErr : printOutAndErr,
	stdin : () => {},
};
let LuaModule = await require('/js/lua.vm.js');
window.LuaModule = undefined;
window.LuaModule = LuaModule;

let lastCmd = null;

//update if there are any stored input commands
update = () => {
	if (lastCmd !== null) {
		LuaModule.Lua.execute('launcher.update("'+lastCmd+'")');
		lastCmd = null;
	}
}

doneLoadingFilesystem = () => {
	//set up input handler
	window.addEventListener('keydown', e => {
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
			let key = String.fromCharCode(e.which).toLowerCase();
			if (key == 'q') key = 'quit';
			lastCmd = key;
			break;
		}
	});
	setInterval(update, 100);

	//launch first file
	LuaModule.Lua.execute([
		"package.path = package.path .. ';./?/?.lua'",
		"require 'launch_js'"
	].join('\n'));
}

executeLuaVMFileSet({
	FS : LuaModule.FS,
	//TODO just pull from https://raw.github.com/thenumbernine/stupid-text-rpg/master/
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
	packages : ['ext', 'template'],
	onexec : (url, dest) => {
		LuaModule.print('loading '+dest+' ...');
	},
	//wait til all are loaded, then insert them in order
	//this way we run the lua.vm.js before writing to the filesystems (since the filesystem is created by lua.vm.js)
	done : () => {
		LuaModule.print('initializing...');
		setTimeout(doneLoadingFilesystem, 0);
	},
});
