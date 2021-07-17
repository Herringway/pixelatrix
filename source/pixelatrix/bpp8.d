module pixelatrix.bpp8;

import pixelatrix.common;
import siryul;

/++
+ 8 bit per pixel tile format with palette. Each row has its bitplanes stored
+ adjacent to one another. Commonly used by the SNES.
+/
align(1) struct Linear8BPP {
	align(1):
	ubyte[8 * 8] raw;
	@SerializationMethod
	string toBase64() const @safe {
		import std.base64 : Base64;
		return Base64.encode(raw[]);
	}
	ubyte[8][8] pixelMatrix() const @safe pure
		out(result; result.isValidBitmap!8)
	{
		ubyte[8][8] output;
		foreach (x; 0..8) {
			output[x] = raw[x * 8 .. (x * 8) + 8];
		}
		return output;
	}
}
///
@safe pure unittest {
	//import std.string : representation;
	//const data = Intertwined4BPP(import("bpp4-sample1.bin").representation[0 .. 8 * 4]);
	//const ubyte[8][8] finaldata = [
	//	[0x0, 0xF, 0x2, 0xE, 0xE, 0xE, 0xF, 0xA],
	//	[0x0, 0x0, 0xF, 0x6, 0xE, 0xE, 0xE, 0xE],
	//	[0x0, 0x0, 0xF, 0xF, 0xF, 0x8, 0xF, 0xF],
	//	[0x0, 0xF, 0xF, 0xF, 0x8, 0x8, 0x8, 0xF],
	//	[0x0, 0xF, 0x8, 0xF, 0x7, 0x7, 0xF, 0x7],
	//	[0x0, 0xF, 0x8, 0x7, 0x7, 0x7, 0xF, 0x7],
	//	[0x0, 0x0, 0xF, 0x8, 0x9, 0x9, 0x7, 0x7],
	//	[0x0, 0x0, 0x0, 0xF, 0x9, 0x9, 0xF, 0xA]
	//];
	//assert(data.pixelMatrix() == finaldata);
}
/++
+ 8 bit per pixel tile format with palette. Each row has its bitplanes stored
+ adjacent to one another. Commonly used by the SNES.
+/
align(1) struct Intertwined8BPP {
	align(1):
	ubyte[8 * 8] raw;
	@SerializationMethod
	string toBase64() const @safe {
		import std.base64 : Base64;
		return Base64.encode(raw[]);
	}
	ubyte[8][8] pixelMatrix() const @safe pure
		out(result; result.isValidBitmap!8)
	{
		ubyte[8][8] output;
		foreach (x; 0..8) {
			foreach (y; 0..8) {
				output[x][7-y] = cast(ubyte)
					(((raw[(8 * 0) + x*2]&(1<<y))>>y) +
					(((raw[(8 * 0) + x*2+1]&(1<<y))>>y)<<1) +
					(((raw[(8 * 2) + x*2]&(1<<y))>>y)<<2) +
					(((raw[(8 * 2) + x*2 + 1]&(1<<y))>>y)<<3) +
					(((raw[(8 * 4) + x*2]&(1<<y))>>y)<<4) +
					(((raw[(8 * 4) + x*2 + 1]&(1<<y))>>y)<<5) +
					(((raw[(8 * 6) + x*2]&(1<<y))>>y)<<6) +
					(((raw[(8 * 6) + x*2 + 1]&(1<<y))>>y)<<7)
				);
			}
		}
		return output;
	}
}
///
@safe pure unittest {
	//import std.string : representation;
	//const data = Intertwined4BPP(import("bpp4-sample1.bin").representation[0 .. 8 * 4]);
	//const ubyte[8][8] finaldata = [
	//	[0x0, 0xF, 0x2, 0xE, 0xE, 0xE, 0xF, 0xA],
	//	[0x0, 0x0, 0xF, 0x6, 0xE, 0xE, 0xE, 0xE],
	//	[0x0, 0x0, 0xF, 0xF, 0xF, 0x8, 0xF, 0xF],
	//	[0x0, 0xF, 0xF, 0xF, 0x8, 0x8, 0x8, 0xF],
	//	[0x0, 0xF, 0x8, 0xF, 0x7, 0x7, 0xF, 0x7],
	//	[0x0, 0xF, 0x8, 0x7, 0x7, 0x7, 0xF, 0x7],
	//	[0x0, 0x0, 0xF, 0x8, 0x9, 0x9, 0x7, 0x7],
	//	[0x0, 0x0, 0x0, 0xF, 0x9, 0x9, 0xF, 0xA]
	//];
	//assert(data.pixelMatrix() == finaldata);
}
