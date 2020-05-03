#!/usr/bin/env node


;(function ($global) { "use strict";
var Unpack = function() { };
Unpack.main = function() {
	if(process.argv.length < 3) {
		console.error("Ошибка: Передайте первым аргументом путь до файла, который будет распакован");
		process.exitCode = 1;
		return;
	}
	if(process.argv.length < 4) {
		console.error("Ошибка: Передайте вторым аргументом путь до папки, в которую будет распаковано содержимое архива");
		process.exitCode = 1;
		return;
	}
	var pin = js_node_Path.normalize(process.argv[2] + "");
	var pout = js_node_Path.normalize(process.argv[3] + "");
	console.log("Распаковка архива: \"" + pin + "\"");
	if(js_node_Fs.existsSync(pin) == false) {
		console.error("Ошибка: Архив не найден: \"" + process.argv[2] + "\"");
		process.exitCode = 1;
		return;
	}
	var sts = js_node_Fs.statSync(pin);
	if(sts.isFile() == false) {
		console.error("Ошибка: Указанный путь ссылается не на файл: \"" + process.argv[2] + "\"");
		process.exitCode = 1;
		return;
	}
	if(js_node_Fs.existsSync(pout) == false) {
		js_node_Fs.mkdirSync(pout);
	} else if(js_node_Fs.statSync(pout).isDirectory() == false) {
		console.error("Ошибка: Указанный путь вывода уже занят: \"" + process.argv[3] + "\"");
		process.exitCode = 1;
		return;
	}
	Unpack.unpacker = new pkg_Unpacker(new Uint8Array(js_node_Fs.readFileSync(pin)));
	while(true) {
		var file = Unpack.unpacker.get();
		if(file == null) {
			break;
		}
		console.log("Распаковка: \"" + file.name + "\"");
		Unpack.buildPath(pout,js_node_Path.normalize(file.name));
		js_node_Fs.writeFileSync(js_node_Path.normalize(pout + js_node_Path.sep + file.name),file.data);
		Unpack.files++;
	}
	console.log("Завершено");
	console.log("Вывод: \"" + pout + "\", файлов: " + Unpack.files);
};
Unpack.buildPath = function(pout,file) {
	var folders = js_node_Path.dirname(file).split(js_node_Path.sep);
	if(folders.length == 0 || folders[0] == ".") {
		return;
	}
	var i = 0;
	while(i < folders.length) {
		pout += js_node_Path.sep + folders[i++];
		if(js_node_Fs.existsSync(pout) == false) {
			js_node_Fs.mkdirSync(pout);
		}
	}
};
var haxe_io_Bytes = function() { };
var js_node_Fs = require("fs");
var js_node_Path = require("path");
var pako_Pako = require("pako");
var pkg_Unpacker = function(data) {
	this.position = 0;
	this.data = null;
	var type = toString.call(data);
	if(type == "[object Uint8Array]") {
		this.data = data;
	} else if(type == "[object ArrayBuffer]") {
		this.data = new Uint8Array(data);
	}
	this.position = 3;
};
pkg_Unpacker.readUInt16 = function(buffer,offset) {
	return (buffer[offset] << 8) + buffer[offset + 1];
};
pkg_Unpacker.readUInt32 = function(buffer,offset) {
	if(buffer[offset] < 127) {
		return (buffer[offset] << 24) + (buffer[offset + 1] << 16) + (buffer[offset + 2] << 8) + buffer[offset + 3];
	} else {
		return parseInt("0x" + buffer[offset].toString(16) + "000000", 16) + (buffer[offset + 1] << 16) + (buffer[offset + 2] << 8) + buffer[offset + 3];
	}
};
pkg_Unpacker.readString = function(buffer,offset,length) {
	var arr = new Array(length);
	while(length-- != 0) arr[length] = String.fromCodePoint(buffer[offset + length]);
	return arr.join("");
};
pkg_Unpacker.prototype = {
	get: function() {
		if(this.position == this.data.byteLength) {
			return null;
		}
		var file = { data : null, name : null};
		var dataLength = pkg_Unpacker.readUInt32(this.data,this.position);
		this.position += 4;
		var nameLength = pkg_Unpacker.readUInt16(this.data,this.position);
		this.position += 2;
		var s = pkg_Unpacker.readString(this.data,this.position,nameLength);
		file.name = decodeURIComponent(s.split("+").join(" "));
		this.position += nameLength;
		file.data = pako_Pako.inflateRaw(this.data.slice(this.position,this.position + dataLength));
		this.position += dataLength;
		return file;
	}
};
if( String.fromCodePoint == null ) String.fromCodePoint = function(c) { return c < 0x10000 ? String.fromCharCode(c) : String.fromCharCode((c>>10)+0xD7C0)+String.fromCharCode((c&0x3FF)+0xDC00); }
Unpack.files = 0;
Unpack.main();
})({});
