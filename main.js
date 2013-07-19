var printBuffer = '';
var printElement = undefined;
//init Module here, for use later in lua.vm.js
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

function setOutput(str) {
	printElement.text(
		str
		//.replace(new RegExp('&', 'g'), '&amp;')
		.replace(new RegExp('<', 'g'), '&lt;')
		.replace(new RegExp('>', 'g'), '&gt;')
		.replace(new RegExp('"', 'g'), '&quot;')
	);
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

var FileSetLoader = makeClass({
	
	/*
	args:
		files : array of string
		onload(filename) : (optional) once one file is done
		done : (optional) once they're all done
	*/
	init : function(args) {
		var thiz = this;
		
		this.files = args.files.clone();
		
		this.div = $('<div>', {
			css : {
				margin : 'auto'
			}
		}).prependTo(document.body);
		var loading = $('<span>', {text:'Loading...'}).appendTo(this.div);
		$('<br>').appendTo(this.div);
		this.progress = $('<progress>').attr('max', '0').attr('value', '0').appendTo(this.div);

		this.results = [];
		var totals = [];
		var loadeds = [];
		var dones = [];
		for (var i = 0; i < this.files.length; ++i) {
			totals[i] = 0;
			loadeds[i] = 0;
			dones[i] = false;
			this.results[i] = null;
		}
		var updateProgress = function() {
			var loaded = 0;
			var total = 0;
			for (var i = 0; i < thiz.files.length; ++i) {
				loaded += loadeds[i];
				total += totals[i];
			}
			thiz.progress.attr('max', total);
			thiz.progress.attr('value', loaded);
		};
		var updateDones = function() {
			for (var i = 0; i < thiz.files.length; ++i) {
				if (!dones[i]) return;
			}
			thiz.div.remove();
			if (args.done) args.done.call(thiz);
		};
		$.each(this.files, function(i,file) {
			var xhr = new XMLHttpRequest();
			
			xhr.open('GET', file, true);
			
			xhr.onprogress = function(e) {
				if (e.total) {
					totals[i] = e.total;
					loadeds[i] = e.loaded;
				} else {
					totals[i] = 0;
					loadeds[i] = 0;
				}
				updateProgress();
			};
			
			xhr.onload = function(e) {
				console.log('file '+file);
				console.log('size '+this.responseText.length);
				console.log('contents');
				console.log(this.responseText);
				loadeds[i] = totals[i];
				thiz.results[i] = this.responseText;
				updateProgress();
				dones[i] = true;
				if (args.onload) args.onload.call(thiz, file, this.responseText);
				updateDones();
			};

			xhr.send();
		});
	}
});

$(document).ready(function() {
	printElement = $('#print');
	var doneCount = 0;
	
	// remotely add lua.vm.js here

	var fsl = new FileSetLoader({
		//TODO don't store them here
		//just pull from https://raw.github.com/thenumbernine/stupid-text-rpg/master/
		files : [
			'/js/lua.vm.js',
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
			'view.lua',
			'ext/class.lua',
			'ext/init.lua',
			'ext/io.lua',
			'ext/math.lua',
			'ext/serialize.lua',
			'ext/string.lua',
			'ext/table.lua'
		],
		//wait til all are loaded, then insert them in order
		//this way we run the lua.vm.js before writing to the filesystems (since the filesystem is created by lua.vm.js)
		done : function() {	
			var thiz = this;
			asyncfor({
				map	: this.results,
				callback : function(i,result) {
					var filename = thiz.files[i];
				
					Module.print('executing '+filename+' ...');
					//first load the vm...
					if (filename.substring(filename.length-3) == '.js') {
						//this will run in-place.  I always thought it sucked that Lua loadstring() didn't run in place, now I see why it's a good idea.  consistency of scope.
						//eval(result);
						var s = document.createElement("script");
						s.type = "text/javascript";
						s.innerHTML = result;
						$("head").append(s);
					} else if (filename.substring(filename.length-4) == '.lua') {
						//pull apart filename and directory path 
						var lastSlash = filename.lastIndexOf('/');
						if (lastSlash != -1) {
							var dir = filename.substring(0, lastSlash);
							try { 	//how do you detect if a path is already created?
								FS.createPath('/', dir, true, true);
							} catch (e) {
							}
							filename = filename.substring(lastSlash+1);
						}
						
						FS.createDataFile(dir, filename, result, true, false);
					} else {
						throw "don't know what to do with "+filename;
					}
				},
				done : function() {
					Module.print('initializing...');
					doneLoadingFilesystem();
				}
			});
		}
	});
});

