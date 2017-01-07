module brainfuck;

import std.range;
import std.traits;

enum EOFType {
    zero,
    minusOne,
    unchanged,
    exception
}

BFInterpreter!(R, P, C) BF(R, P, C)(R input, P program, C cells, EOFType eof = EOFType.zero)
if (isInputRange!R && isSomeString!P && hasAssignableElements!C) {
    return BFInterpreter!(R, P, C)(input, program, cells, eof);
}

struct BFInterpreter(R, P, C) {
    alias Cell = ElementType!C;

    R input;
    P program;
    C cells;
    EOFType eof;

    size_t ip = 0;
    size_t ptr = 0;

    private Cell outputBuffer;
    private bool end;
    private const size_t programLength;
    private const size_t cellsLength;

    this(R input, P program, C cells, EOFType eof) {
        this.input = input;
        this.program = program;
        this.cells = cells;
        this.eof = eof;
        programLength = program.length;
        cellsLength = cells.length;
        popFront();
    }

    bool empty() {
        return end;
    }

    Cell front() {
        return outputBuffer;
    }

    void popFront() {
        const programSize = program.length;
        while (ip < programSize) {
            switch (program[ip]) {
            case '>':
                ptr++;
                if (ptr >= cellsLength) {
                    throw new Exception("out of range");
                }
                break;

            case '<':
                if (ptr <= 0) {
                    throw new Exception("out of range");
                }
                ptr--;

                break;

            case '+':
                cells[ptr]++;
                break;

            case '-':
                cells[ptr]--;
                break;

            case '.':
                outputBuffer = cells[ptr];
                ip++;
                return;

            case ',':
                if (input.empty) {
                    final switch (eof) {
                    case EOFType.zero:
                        cells[ptr] = 0;
                        break;
                    case EOFType.minusOne:
                        cells[ptr] = cast(Cell)-1;
                        break;
                    case EOFType.unchanged:
                        break;
                    case EOFType.exception:
                        throw new Exception("input is empty");
                    }
                } else {
                    cells[ptr] = cast(Cell) input.front;
                    input.popFront;
                }
                break;

            case '[':
                if (cells[ptr] != 0) {
                    break;
                }
                size_t nest = 1;
                while (nest > 0) {
                    if (++ip >= programLength) {
                        throw new Exception("unmatched '['");
                    }
                    const instruction = program[ip];
                    if (instruction == '[') {
                        nest++;
                    } else if (instruction == ']') {
                        nest--;
                    }
                }
                break;

            case ']':
                if (cells[ptr] == 0) {
                    break;
                }
                size_t nest = 1;
                while (nest > 0) {
                    if (ip-- <= 0) {
                        throw new Exception("unmatched ']'");
                    }
                    const instruction = program[ip];
                    if (instruction == '[') {
                        nest--;
                    } else if (instruction == ']') {
                        nest++;
                    }
                }
                break;

            default:
                // ignored
            }
            ip++;
        }
        end = true;
    }
}
