import {newLua} from '/js/lua-interop.js';
import {loadPackageAndDeps} from '/js/util.js';

let printBuffer = '';
const printElement = document.getElementById('print');

const printOutAndErr = s => {
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

const lua = await newLua({
	print : printOutAndErr,
	printErr : printOutAndErr,
});
lua.newState();
console.log('lua', lua);
const FS = lua.lib.FS;
window.lua = lua;

let lastCmd = null;

//update if there are any stored input commands
const update = () => {
	if (lastCmd !== null) {
console.log('launcher.update');
		lua.run('launcher.update("'+lastCmd+'")');
		lastCmd = null;
	}
}

const doneLoadingFilesystem = () => {
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
console.log('set packages');
	lua.run(`
package.loaded.ffi = nil	-- pretend we don't know ffi since it's buggy lua-ffi
js = require 'js'			-- set global ... either here or in launch_js.lua, idk
package.path = './?.lua;/?.lua;/?/?.lua'
require 'launch_js'
`);
}

await loadPackageAndDeps(FS, ['stupid-text-rpg']);

FS.chdir('/stupid-text-rpg');

lua.lib.print('initializing...');
setTimeout(doneLoadingFilesystem, 0);
