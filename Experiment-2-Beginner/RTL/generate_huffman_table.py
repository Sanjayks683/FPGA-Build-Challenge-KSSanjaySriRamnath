import heapq
import json
import os

NUM_SYMBOLS = 256
CODE_BITS = 24


CHAR_FREQUENCIES = {
    ' ': 19000, 'e': 13000, 't': 9000, 'a': 8000, 'o': 7500, 'i': 7000,
    'n': 6700, 's': 6300, 'h': 6100, 'r': 6000, 'd': 4300, 'l': 4000,
    'c': 2800, 'u': 2800, 'm': 2400, 'w': 2400, 'f': 2200, 'g': 2000,
    'y': 2000, 'p': 1900, 'b': 1500, 'v': 1000, 'k': 800, 'x': 150,
    'j': 150, 'q': 100, 'z': 74,
    '\n': 2000, ',': 1500, '.': 1500, '"': 1000, "'": 1000, '-': 500,
    '0': 400, '1': 400, '2': 300, '3': 300, '4': 200, '5': 200, '6': 200,
    '7': 200, '8': 200, '9': 200,
}


def build_weights():

    weights = [1] * NUM_SYMBOLS
    for char, freq in CHAR_FREQUENCIES.items():
        weights[ord(char)] = freq
    return weights


def huffman_lengths(weights):


    lengths = [0] * NUM_SYMBOLS
    heap = [(weight, index, [index]) for index, weight in enumerate(weights)]
    heapq.heapify(heap)
    next_id = NUM_SYMBOLS
    while len(heap) > 1:
        weight_a, _, symbols_a = heapq.heappop(heap)
        weight_b, _, symbols_b = heapq.heappop(heap)
        for symbol in symbols_a + symbols_b:
            lengths[symbol] += 1
        heapq.heappush(heap, (weight_a + weight_b, next_id, symbols_a + symbols_b))
        next_id += 1
    return lengths


def canonical_codes(lengths):


    codes = {}
    code = 0
    previous_length = 0
    for symbol in sorted(range(NUM_SYMBOLS), key=lambda s: (lengths[s], s)):
        code <<= lengths[symbol] - previous_length
        codes[symbol] = format(code, "0{}b".format(lengths[symbol]))
        code += 1
        previous_length = lengths[symbol]
    return codes


def check(codes):

    ordered = sorted(codes.values())
    for first, second in zip(ordered, ordered[1:]):
        if second.startswith(first):
            raise SystemExit("code {} is a prefix of {}".format(first, second))
    longest = max(len(c) for c in codes.values())
    if longest > CODE_BITS:
        raise SystemExit("longest code is {} bits, ROM holds {}".format(longest, CODE_BITS))
    return longest


def write_file(path, lines):
    with open(path, "w", newline="\n") as f:
        f.write("\n".join(lines) + "\n")


def write_rom(path, codes):
    lines = [
        "`default_nettype none",
        "module huffman_rom (",
        "    input  wire         clk,",
        "    input  wire  [7:0]  char_in,",
        "    output logic [23:0] code_out,",
        "    output logic [4:0]  code_len_out",
        ");",
        "",
        "    always_ff @(posedge clk) begin",
        "        case (char_in)",
    ]
    for symbol in range(NUM_SYMBOLS):
        code = codes[symbol]

        reversed_code = code[::-1].rjust(CODE_BITS, "0")
        lines.append("            8'd{}: begin code_out <= 24'b{}; code_len_out <= 5'd{}; end".format(
            symbol, reversed_code, len(code)))
    lines += [
        "        endcase",
        "    end",
        "",
        "endmodule",
    ]
    write_file(path, lines)


def write_tb_table(path, codes):
    lines = [
        "initial begin",
    ]
    for symbol in range(NUM_SYMBOLS):
        code = codes[symbol]
        lines.append("    code_tab[{:3d}] = 24'h{:06x}; len_tab[{:3d}] = 5'd{};".format(
            symbol, int(code, 2), symbol, len(code)))
    lines += ["end"]
    write_file(path, lines)


def write_json(path, codes, longest):
    payload = {
        "max_code_len": longest,
        "note": "code is the bit string the hardware sends, first bit first",
        "codes": {str(s): codes[s] for s in range(NUM_SYMBOLS)},
    }
    with open(path, "w", newline="\n") as f:
        json.dump(payload, f, indent=1)
        f.write("\n")


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    weights = build_weights()
    lengths = huffman_lengths(weights)
    codes = canonical_codes(lengths)
    longest = check(codes)

    average = sum(weights[s] * lengths[s] for s in range(NUM_SYMBOLS)) / sum(weights)
    write_rom(os.path.join(here, "huffman_rom.sv"), codes)
    write_tb_table(os.path.join(here, "..", "Testbench", "huffman_codes.svh"), codes)
    write_json(os.path.join(here, "huffman_table.json"), codes, longest)
    print("longest code {} bits, average {:.2f} bits per character of English text".format(longest, average))
    print("wrote RTL/huffman_rom.sv, Testbench/huffman_codes.svh and RTL/huffman_table.json")


if __name__ == "__main__":
    main()
