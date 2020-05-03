#!/usr/bin/env node


;(function ($global) { "use strict";
var pkg_Packer = function() {
	this.data = new Uint8Array(3);
	this.data[0] = 118;
	this.data[1] = 36;
	this.data[2] = 1;
};
pkg_Packer.writeUInt16 = function(value,buffer,offset) {
	if(value > 65535) {
		buffer[offset] = 255;
		buffer[offset + 1] = 255;
	} else if(value > 0) {
		buffer[offset] = value >>> 8;
		buffer[offset + 1] = value & 255;
	} else {
		buffer[offset] = 0;
		buffer[offset + 1] = 0;
	}
};
pkg_Packer.writeUInt32 = function(value,buffer,offset) {
	if(value > 4294967295) {
		buffer[offset] = 255;
		buffer[offset + 1] = 255;
		buffer[offset + 2] = 255;
		buffer[offset + 3] = 255;
	} else if(value > 2147483647) {
		var str = value.toString(16);
		buffer[offset] = parseInt("0x" + str.substring(0, 2), 16);
		buffer[offset + 1] = parseInt("0x" + str.substring(2, 4), 16);
		buffer[offset + 2] = parseInt("0x" + str.substring(4, 6), 16);
		buffer[offset + 3] = parseInt("0x" + str.substring(6, 8), 16);
	} else if(value > 0) {
		buffer[offset] = value >>> 24;
		buffer[offset + 1] = value >>> 16 & 255;
		buffer[offset + 2] = value >>> 8 & 255;
		buffer[offset + 3] = value & 255;
	} else {
		buffer[offset] = 0;
		buffer[offset + 1] = 0;
		buffer[offset + 2] = 0;
		buffer[offset + 3] = 0;
	}
};
pkg_Packer.writeString = function(str,buffer,offset) {
	var len = str.length;
	while(len-- != 0) buffer[offset + len] = str.charCodeAt(len);
};
pkg_Packer.prototype = {
	add: function(file,name,options) {
		var type = toString.call(file);
		var fileData = null;
		if(type == "[object Uint8Array]") {
			fileData = file;
		} else if(type == "[object ArrayBuffer]") {
			fileData = new Uint8Array(file);
		}
		var nameEnc = encodeURIComponent(name);
		var nameLen = nameEnc.length;
		if(nameLen > 65535) {
			nameEnc = nameEnc.substring(0,65535);
		}
		fileData = pako_Pako.deflateRaw(fileData,options);
		var dataNew = new Uint8Array(this.data.byteLength + fileData.byteLength + 6 + nameLen);
		dataNew.set(this.data);
		var pos = this.data.byteLength;
		pkg_Packer.writeUInt32(fileData.byteLength,dataNew,pos);
		pos += 4;
		pkg_Packer.writeUInt16(nameLen,dataNew,pos);
		pos += 2;
		pkg_Packer.writeString(nameEnc,dataNew,pos);
		pos += nameLen;
		dataNew.set(fileData,pos);
		this.data = dataNew;
	}
};
var Pack = function() { };
Pack.main = function() {
	if(process.argv.length < 3) {
		console.error("Ошибка: Передайте первым аргументом путь до папки, которую вы хотите упаковать");
		process.exitCode = 1;
		return;
	}
	if(process.argv.length < 4) {
		console.error("Ошибка: Передайте вторым аргументом путь для записи архива");
		process.exitCode = 1;
		return;
	}
	var pin = js_node_Path.normalize(process.argv[2] + "");
	var pout = js_node_Path.normalize(process.argv[3] + "");
	var opt = process.argv.length < 4 ? null : { level : Std.parseInt(process.argv[4] + "")};
	console.log("Упаковка папки: \"" + pin + "\", " + "уровень сжатия: " + (opt == null ? "Стандартное" : opt.level == 0 ? "Без сжатия" : opt.level));
	if(js_node_Fs.existsSync(pin) == false) {
		console.error("Ошибка: Каталог не существует: \"" + process.argv[2] + "\"");
		process.exitCode = 1;
		return;
	}
	var sts = js_node_Fs.statSync(pin);
	if(sts.isDirectory() == false) {
		console.error("Ошибка: Указанный путь не является каталогом: \"" + process.argv[2] + "\"");
		process.exitCode = 1;
		return;
	}
	var fd = js_node_Fs.openSync(pout,"w");
	js_node_Fs.writeFileSync(fd,Pack.packer.data.slice(Pack.pos));
	Pack.pos = Pack.packer.data.byteLength;
	Pack.pack(fd,pin,opt);
	console.log("Завершено");
	console.log("Вывод: \"" + pout + "\", размер: " + pkg_Utils.getBytesSize(Pack.packer.data.byteLength) + " (" + Pack.packer.data.byteLength + " bytes)");
};
Pack.pack = function(fd,path,opt,file) {
	if(file == null) {
		file = "";
	}
	var sts = js_node_Fs.statSync(path + file);
	if(sts.isDirectory()) {
		var list = js_node_Fs.readdirSync(path + file);
		var len = list.length;
		var i = 0;
		while(i < len) Pack.pack(fd,path,opt,file + "/" + list[i++]);
		return;
	}
	if(sts.isFile()) {
		console.log("Упаковка: \"" + file.substring(1) + "\"");
		Pack.packer.add(js_node_Fs.readFileSync(path + file),file.substring(1),opt);
		js_node_Fs.writeFileSync(fd,Pack.packer.data.slice(Pack.pos));
		Pack.pos = Pack.packer.data.byteLength;
		return;
	}
};
var Std = function() { };
Std.parseInt = function(x) {
	var v = parseInt(x, x && x[0]=="0" && (x[1]=="x" || x[1]=="X") ? 16 : 10);
	if(isNaN(v)) {
		return null;
	}
	return v;
};
var haxe_io_Bytes = function() { };
var js_node_Fs = require("fs");
var js_node_Path = require("path");
var pako_Pako = require("pako");
var pkg_Utils = function() { };
pkg_Utils.getBytesSize = function(length) {
	if(length < 1e3) {
		return length + " byte";
	}
	if(length < 1e6) {
		return Math.trunc(length / 1e1) / 1e2 + " KB";
	}
	if(length < 1e9) {
		return Math.trunc(length / 1e4) / 1e2 + " MB";
	}
	if(length < 1e12) {
		return Math.trunc(length / 1e7) / 1e2 + " GB";
	}
	if(length < 1e15) {
		return Math.trunc(length / 1e10) / 1e2 + " TB";
	}
	if(length < 1e18) {
		return Math.trunc(length / 1e13) / 1e2 + " PB";
	}
	if(length < 1e21) {
		return Math.trunc(length / 1e16) / 1e2 + " EB";
	}
	if(length < 1e24) {
		return Math.trunc(length / 1e19) / 1e2 + " ZB";
	}
	return Math.trunc(length / 1e22) / 1e2 + " YB";
};
Pack.packer = new pkg_Packer();
Pack.pos = 0;
Pack.main();
})({});
