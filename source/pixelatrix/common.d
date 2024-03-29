module pixelatrix.common;

package bool isValidBitmap(size_t size)(const ubyte[8][8] input) {
	foreach (row; input) {
		foreach (pixel; row) {
			if (pixel > (1<<size))  {
				return false;
			}
		}
	}
	return true;
}

package bool isValidBitmap(size_t size)(const ubyte[][] input) {
	foreach (row; input) {
		foreach (pixel; row) {
			if (pixel > (1<<size))  {
				return false;
			}
		}
	}
	return true;
}

enum TileFormat {
	simple1BPP,
	linear2BPP,
	intertwined2BPP,
	intertwined3BPP,
	intertwined4BPP,
	packed4BPP,
	intertwined8BPP,
	packed8BPP,
}

size_t colours(const TileFormat format) @safe pure {
	final switch(format) {
		case TileFormat.simple1BPP:
			return 2^^1;
		case TileFormat.linear2BPP:
		case TileFormat.intertwined2BPP:
			return 2^^2;
		case TileFormat.intertwined3BPP:
			return 2^^3;
		case TileFormat.intertwined4BPP:
		case TileFormat.packed4BPP:
			return 2^^4;
		case TileFormat.intertwined8BPP:
		case TileFormat.packed8BPP:
			return 2^^8;
	}
}

package void setBit(scope ubyte[] bytes, size_t index, bool value) @safe pure {
	const mask = ~(1 << (7 - (index % 8)));
	const newBit = value << (7 - (index % 8));
	bytes[index / 8] = cast(ubyte)((bytes[index / 8] & mask) | newBit);
}
package bool getBit(scope const ubyte[] bytes, size_t index) @safe pure {
	return !!(bytes[index / 8] & (1 << (7 - (index % 8))));
}

align(1) struct Intertwined(size_t inBPP) {
	import std.format : format;
	enum width = 8;
	enum height = 8;
	enum bpp = inBPP;
	align(1):
	ubyte[(width * height * bpp) / 8] raw;
	ubyte opIndex(size_t x, size_t y) const @safe pure
		in(x < width, format!"index [%s, %s] is out of bounds for array of length [%s, %s]"(x, y, width, height))
		in(y < height, format!"index [%s, %s] is out of bounds for array of length [%s, %s]"(x, y, width, height))
	{
		ubyte result;
		static foreach (layer; 0 .. bpp) {
			result |= getBit(raw[], (y * 2 + ((layer & ~1) << 3) + (layer & 1)) * 8 + x) << layer;
		}
		return result;
	}
	ubyte opIndexAssign(ubyte val, size_t x, size_t y) @safe pure
		in(x < width, format!"index [%s, %s] is out of bounds for array of length [%s, %s]"(x, y, width, height))
		in(y < height, format!"index [%s, %s] is out of bounds for array of length [%s, %s]"(x, y, width, height))
		in(val < 1 << bpp, "Value out of range")
	{
		static foreach (layer; 0 .. bpp) {
			setBit(raw[], ((y * 2) + ((layer & ~1) << 3) + (layer & 1)) * 8 + x, (val >> layer) & 1);
		}
		return val;
	}
}

align(1) struct Linear(size_t inBPP) {
	import std.format : format;
	import pixelatrix.bpp1 : Simple1BPP;
	enum width = 8;
	enum height = 8;
	enum bpp = inBPP;
	align(1):
	Simple1BPP[bpp] planes;
	ubyte opIndex(size_t x, size_t y) const @safe pure
		in(x < width, format!"index [%s, %s] is out of bounds for array of length [%s, %s]"(x, y, width, height))
		in(y < height, format!"index [%s, %s] is out of bounds for array of length [%s, %s]"(x, y, width, height))
	{
		ubyte result;
		static foreach (layer; 0 .. bpp) {
			result |= planes[layer][x, y] << layer;
		}
		return result;
	}
	ubyte opIndexAssign(ubyte val, size_t x, size_t y) @safe pure
		in(x < width, format!"index [%s, %s] is out of bounds for array of length [%s, %s]"(x, y, width, height))
		in(y < height, format!"index [%s, %s] is out of bounds for array of length [%s, %s]"(x, y, width, height))
		in(val < 1 << bpp, "Value out of range")
	{
		static foreach (layer; 0 .. bpp) {
			planes[layer][x, y] = (val >> layer) & 1;
		}
		return val;
	}
	package ubyte[8 * bpp] raw() const @safe pure {
		return cast(ubyte[8 * bpp])planes[];
	}
}

align(1) struct Packed(size_t inBPP) {
	import std.format : format;
	enum width = 8;
	enum height = 8;
	enum bpp = inBPP;
	align(1):
	ubyte[(width * height * bpp) / 8] raw;
	ubyte opIndex(size_t x, size_t y) const @safe pure
		in(x < width, format!"index [%s, %s] is out of bounds for array of length [%s, %s]"(x, y, width, height))
		in(y < height, format!"index [%s, %s] is out of bounds for array of length [%s, %s]"(x, y, width, height))
	{
		const pos = (y * width + x) / (8 / bpp);
		const shift = ((x & 1) * bpp) & 7;
		const mask = ((1 << bpp) - 1) << shift;
		return (raw[pos] & mask) >> shift;
	}
	ubyte opIndexAssign(ubyte val, size_t x, size_t y) @safe pure
		in(x < width, format!"index [%s, %s] is out of bounds for array of length [%s, %s]"(x, y, width, height))
		in(y < height, format!"index [%s, %s] is out of bounds for array of length [%s, %s]"(x, y, width, height))
		in(val < 1 << bpp, "Value out of range")
	{
		const pos = (y * width + x) / (8 / bpp);
		const shift = ((x & 1) * bpp) & 7;
		const mask = ((1 << bpp) - 1) << shift;
		raw[pos] = (raw[pos] & ~mask) | cast(ubyte)((val & ((1 << bpp) - 1)) << shift);
		return val;
	}
}

auto pixelMatrix(Tile)(const Tile tile)
	out(result; result.isValidBitmap!(Tile.bpp))
{
	static if (__traits(compiles, Tile.width + 0) && __traits(compiles, Tile.height + 0)) {
		ubyte[Tile.width][Tile.height] output;
	} else {
		auto output = new ubyte[][](tile.width, tile.height);
	}
	foreach (x; 0 .. tile.width) {
		foreach (y; 0 .. tile.height) {
			output[y][x] = tile[x, y];
		}
	}
	return output;
}

interface Tile {
	ubyte bpp() const @safe pure;
	size_t size() const @safe pure;
	uint opIndex(size_t x, size_t y) const @safe pure;
	uint opIndexAssign(uint val, size_t x, size_t y) @safe pure;
	const(ubyte)[] raw() const @safe pure;
}

class TileClass(T) : Tile {
	T[1] tile;
	this(const ubyte[T.sizeof] data) @safe pure {
		tile = (cast(const(T)[])(data[]))[0];
	}
	ubyte bpp() const @safe pure {
		return T.bpp;
	}
	size_t size() const @safe pure {
		return T.sizeof;
	}
	uint opIndex(size_t x, size_t y) const @safe pure {
		return tile[0][x, y];
	}
	uint opIndexAssign(uint val, size_t x, size_t y) @safe pure {
		return tile[0][x, y] = cast(ubyte)val;
	}
	const(ubyte)[] raw() const @safe pure {
		return cast(const(ubyte)[])tile;
	}
}

Tile getTile(const ubyte[] data, TileFormat format) @safe pure {
	import pixelatrix.bpp1 : Simple1BPP;
	import pixelatrix.bpp2 : Linear2BPP, Intertwined2BPP;
	import pixelatrix.bpp3 : Intertwined3BPP;
	import pixelatrix.bpp4 : Intertwined4BPP, Packed4BPP;
	import pixelatrix.bpp8 : Intertwined8BPP, Packed8BPP;
	static Tile getType(T)(const ubyte[] data) {
		return new TileClass!T(data[0 .. T.sizeof]);
	}
	final switch (format) {
		case TileFormat.simple1BPP:
			return getType!Simple1BPP(data);
		case TileFormat.linear2BPP:
			return getType!Linear2BPP(data);
		case TileFormat.intertwined2BPP:
			return getType!Intertwined2BPP(data);
		case TileFormat.intertwined3BPP:
			return getType!Intertwined3BPP(data);
		case TileFormat.intertwined4BPP:
			return getType!Intertwined4BPP(data);
		case TileFormat.packed4BPP:
			return getType!Packed4BPP(data);
		case TileFormat.intertwined8BPP:
			return getType!Intertwined8BPP(data);
		case TileFormat.packed8BPP:
			return getType!Packed8BPP(data);
	}
}

Tile[] getTiles(const ubyte[] data, TileFormat format) @safe pure {
	import pixelatrix.bpp1 : Simple1BPP;
	import pixelatrix.bpp2 : Linear2BPP, Intertwined2BPP;
	import pixelatrix.bpp3 : Intertwined3BPP;
	import pixelatrix.bpp4 : Intertwined4BPP, Packed4BPP;
	import pixelatrix.bpp8 : Intertwined8BPP, Packed8BPP;
	static Tile[] getType(T)(const ubyte[] data)
		in((data.length % T.sizeof) == 0, "Provided data is not an even multiple of the tile size")
	{
		Tile[] tiles;
		tiles.reserve(data.length / T.sizeof);
		foreach (i; 0 .. data.length / T.sizeof) {
			tiles ~= new TileClass!T(data[i * T.sizeof .. (i + 1) * T.sizeof][0 .. T.sizeof]);
		}
		return tiles;
	}
	final switch (format) {
		case TileFormat.simple1BPP:
			return getType!Simple1BPP(data);
		case TileFormat.linear2BPP:
			return getType!Linear2BPP(data);
		case TileFormat.intertwined2BPP:
			return getType!Intertwined2BPP(data);
		case TileFormat.intertwined3BPP:
			return getType!Intertwined3BPP(data);
		case TileFormat.intertwined4BPP:
			return getType!Intertwined4BPP(data);
		case TileFormat.packed4BPP:
			return getType!Packed4BPP(data);
		case TileFormat.intertwined8BPP:
			return getType!Intertwined8BPP(data);
		case TileFormat.packed8BPP:
			return getType!Packed8BPP(data);
	}
}

void getBytes(const Tile tile, scope void delegate(scope const(ubyte)[]) @safe pure sink) @safe pure {
	sink(tile.raw);
}

void getBytes(const Tile[] tiles, scope void delegate(scope const(ubyte)[]) @safe pure sink) @safe pure {
	foreach (tile; tiles) {
		sink(tile.raw);
	}
}

ubyte[] getBytes(const Tile tile) @safe pure {
	ubyte[] result;
	getBytes(tile, (data) { result ~= data; });
	return result;
}

ubyte[] getBytes(const Tile[] tiles) @safe pure {
	ubyte[] result;
	getBytes(tiles, (data) { result ~= data; });
	return result;
}

@safe pure unittest {
	ubyte[] data = new ubyte[](128);
	assert(getBytes(getTiles(data, TileFormat.packed4BPP)) == data);
}
