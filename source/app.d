module app;

import brainfuck;

import std.stdio;
import std.algorithm;
import std.array;
import std.conv;
import std.getopt;

void main(string[] args) {
    try {
        size_t cells = 30000;
        int bits = 8;
        EOFType eofType = EOFType.zero;

        dchar[] program;

        // dfmt off
        auto helpInformation = getopt(args,
            "cells|c", "specify number of cells (default: 30000)", &cells,
            "bits|b", "specify number of cell size [8, 16, 32, 64] (default: 8)", &bits,
            "eof", "specify the way to handle EOF [zero, minusOne, unchanged] (default: zero)", &eofType);
        // dfmt on

        if (!(bits == 8 || bits == 16 || bits == 32 || bits == 64)) {
            throw new Exception("Not allowed to set value '" ~ bits.to!string ~ "' to cell size");
        }

        if (helpInformation.helpWanted || args.length == 1) {
            defaultGetoptPrinter("usage: brainfuck-d [<options...>] inputfile",
                    helpInformation.options);
            return;
        }

        if (args.length == 1) {
            throw new Exception("No input file given");
        }
        if (args.length > 2) {
            throw new Exception("Unrecognized option " ~ args[2]);
        }
        assert(args.length == 2);

        program = File(args[1]).byLine.joiner.array;

        alias run(T) = () => StdinByChar().BF(program, new T[cells], eofType)
            .each!(a => stdout.rawWrite([cast(char) a]));

        if (bits == 8) {
            run!ubyte();
        } else if (bits == 16) {
            run!ushort();
        } else if (bits == 32) {
            run!uint();
        } else if (bits == 64) {
            run!ulong();
        } else {
            assert(0);
        }
    }
    catch (Exception e) {
        writeln("Error: ", e.msg);
        return;
    }
}

struct StdinByChar {
    import core.stdc.stdio : getchar, EOF;

    private enum INIT = -2;

    private int buffer = INIT;

    bool empty() {
        if (buffer == INIT) {
            popFront();
        }
        return buffer == EOF;
    }

    char front() {
        if (buffer == INIT) {
            popFront();
        }
        return cast(char) buffer;
    }

    void popFront() {
        buffer = getchar();
    }
}
