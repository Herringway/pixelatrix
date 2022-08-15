module pixelatrix.bpp2;

import pixelatrix.common;

/++
+ 2 bit per pixel tile format with palette. Consists of two bitplanes stored
+ one after the other. Commonly used by the NES.
+
+ Params: data = a 16 byte array
+ Returns: a decoded 8x8 tile.
+/
align(1) struct Linear2BPP {
	align(1):
	ubyte[16] raw;
	this(in ubyte[16] tile) @safe pure {
		raw = tile;
	}
	this(in ubyte[8][8] tile) @safe pure {
		foreach (rowID, row; tile) {
			foreach (colID, col; row) {
				this[rowID, colID] = col;
			}
		}
	}
	ubyte[8][8] pixelMatrix() const @safe pure
		out(result; result.isValidBitmap!2)
	{
		ubyte[8][8] output;
		foreach (x; 0..8) {
			foreach (y; 0..8) {
				output[x][y] = this[x, y];
			}
		}
		return output;
	}
	ubyte opIndex(size_t x, size_t y) const @safe pure {
		return getBit(raw[], x * 8 + y) | (getBit(raw[], (x + 8) * 8 + y) << 1);
	}
	ubyte opIndexAssign(ubyte val, size_t x, size_t y) @safe pure {
		setBit(raw[], x * 8 + y, val & 1);
		setBit(raw[], (x + 8) * 8 + y, (val >> 1) & 1);
		return val;
	}
}
///
@safe pure unittest {
	import std.string : representation;
	const data = Linear2BPP(import("bpp2-sample1.bin").representation[0 .. 8 * 2]);
	const ubyte[][] finaldata = [
		[0, 3, 2, 2, 2, 2, 3, 2],
		[0, 0, 3, 2, 2, 2, 2, 2],
		[0, 0, 3, 3, 3, 0, 3, 3],
		[0, 3, 3, 3, 0, 0, 0, 3],
		[0, 3, 0, 3, 3, 3, 3, 3],
		[0, 3, 0, 3, 3, 3, 3, 3],
		[0, 0, 3, 0, 1, 1, 3, 3],
		[0, 0, 0, 3, 1, 1, 3, 2]];
	assert(data[0, 1] == 3);
	assert(data.pixelMatrix() == finaldata);
	assert(Linear2BPP(data.pixelMatrix()) == data);
	Linear2BPP data2 = data;
	data2[0, 1] = 2;
	assert(data2[0, 1] == 2);
}

/++
+ 2 bit per pixel tile format with palette. Each row has its bitplanes stored
+ adjacent to one another. Commonly used by SNES and Gameboy.
+
+ Params: data = a 16 byte array
+ Returns: a decoded 8x8 tile.
+/
align(1) struct Intertwined2BPP {
	align(1):
	ubyte[16] raw;
	this(in ubyte[16] tile) @safe pure {
		raw = tile;
	}
	this(in ubyte[8][8] tile) @safe pure {
		foreach (rowID, row; tile) {
			foreach (colID, col; row) {
				this[rowID, colID] = col;
			}
		}
	}
	ubyte[8][8] pixelMatrix() const @safe pure
		out(result; result.isValidBitmap!2)
	{
		ubyte[8][8] output;
		foreach (x; 0..8) {
			foreach (y; 0..8) {
				output[x][y] = this[x, y];
			}
		}
		return output;
	}
	ubyte opIndex(size_t x, size_t y) const @safe pure {
		return getBit(raw[], (x * 2) * 8 + y) | (getBit(raw[], (x * 2 + 1) * 8 + y) << 1);
	}
	ubyte opIndexAssign(ubyte val, size_t x, size_t y) @safe pure {
		setBit(raw[], (x * 2) * 8 + y, val & 1);
		setBit(raw[], ((x * 2) + 1) * 8 + y, (val >> 1) & 1);
		return val;
	}
}
///
@safe pure unittest {
	import std.string : representation;
	const data = Intertwined2BPP(import("bpp2-sample2.bin").representation[0 .. 8 * 2]);
	const ubyte[][] finaldata = [
		[0, 3, 2, 2, 2, 2, 3, 2],
		[0, 0, 3, 2, 2, 2, 2, 2],
		[0, 0, 3, 3, 3, 0, 3, 3],
		[0, 3, 3, 3, 0, 0, 0, 3],
		[0, 3, 0, 3, 3, 3, 3, 3],
		[0, 3, 0, 3, 3, 3, 3, 3],
		[0, 0, 3, 0, 1, 1, 3, 3],
		[0, 0, 0, 3, 1, 1, 3, 2]];
	assert(data.pixelMatrix() == finaldata);
	assert(Intertwined2BPP(data.pixelMatrix()) == data);
}
