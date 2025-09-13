/+
 + Copyright (c) 2025 Brian Callahan <bcallah@openbsd.org>
 +
 + Permission to use, copy, modify, and distribute this software for any
 + purpose with or without fee is hereby granted, provided that the above
 + copyright notice and this permission notice appear in all copies.
 +
 + THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 + WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 + MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 + ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 + WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 + ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 + OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 +/

import std.file;
import std.stdio;
import std.string;

import rop.v;

class Rop {
    string output;

    string xchgq_rbx_rax = "\txchgq\t%rbx, %rax\n";
    string xchgq_r11_rax = "\txchgq\t%r11, %rax\n";
    string xchgq_r8_rbx = "\txchgq\t%r8, %rbx\n";
    string xchgq_r8_r11 = "\txchgq\t%r8, %r11\n";

    string xchgl_ebx_eax = "\txchgl\t%ebx, %eax\n";
    string xchgl_r11d_eax = "\txchgl\t%r11d, %eax\n";
    string xchgl_r8d_ebx = "\txchgl\t%r8d, %ebx\n";
    string xchgl_r8d_r11d = "\txchgl\t%r8d, %r11d\n";
}

void xchg_and_op(Rop rop, string xchg, string op) {
    rop.output ~= xchg;
    rop.output ~= op;
    rop.output ~= xchg;
}

bool endsWith(string s, string t) {
    if (s.length < t.length)
        return false;

    return s[s.length - t.length .. $] == t;
}

string get_immediate(string s) {
    ulong begin, end;

    while (s[begin] != '$')
        ++begin;

    end = begin;

    while (s[end] != ',')
        ++end;

    return s[begin .. end];
}

void process(Rop rop, string line) {
    if (line.empty) {
        rop.output ~= "\n";
        return;
    }

    if (line[0] != '\t') {
        rop.output ~= (line ~ "\n");
        return;
    }

    switch (line) {
    case "\taddq\t%rax, %rbx":
        xchg_and_op(rop, rop.xchgq_rbx_rax, "\taddq\t%rbx, %rax\n");
        break;
    case "\taddq\t%rax, %r11":
        xchg_and_op(rop, rop.xchgq_r11_rax, "\taddq\t%r11, %rax\n");
        break;
    case "\taddl\t%eax, %ebx":
        xchg_and_op(rop, rop.xchgl_ebx_eax, "\taddl\t%ebx, %eax\n");
        break;
    case "\tcmpq\t%rax, %rbx":
        xchg_and_op(rop, rop.xchgq_rbx_rax, "\tcmpq\t%rbx, %rax\n");
        break;
    case "\tincq\t%rbx":
        xchg_and_op(rop, rop.xchgq_rbx_rax, "\tincq\t%rax\n");
        break;
    case "\tincl\t%ebx":
        xchg_and_op(rop, rop.xchgl_ebx_eax, "\tincl\t%eax\n");
        break;
    case "\tmovq\t%rax, %rbx":
        xchg_and_op(rop, rop.xchgq_rbx_rax, "\tmovq\t%rbx, %rax\n");
        break;
    case "\tmovq\t%rax, %r11":
        xchg_and_op(rop, rop.xchgq_r11_rax, "\tmovq\t%r11, %rax\n");
        break;
    case "\tmovl\t%eax, %ebx":
        xchg_and_op(rop, rop.xchgl_ebx_eax, "\tmovl\t%ebx, %eax\n");
        break;
    case "\torq\t%rax, %rbx":
        xchg_and_op(rop, rop.xchgq_rbx_rax, "\torq\t%rbx, %rax\n");
        break;
    case "\torl\t%eax, %ebx":
        xchg_and_op(rop, rop.xchgl_ebx_eax, "\torl\t%ebx, %eax\n");
        break;
    case "\tsubq\t%rax, %rbx":
        xchg_and_op(rop, rop.xchgq_rbx_rax, "\tsubq\t%rbx, %rax\n");
        break;
    case "\tsubl\t%eax, %ebx":
        xchg_and_op(rop, rop.xchgl_ebx_eax, "\tsubl\t%ebx, %eax\n");
        break;
    case "\txorq\t%rax, %rbx":
        xchg_and_op(rop, rop.xchgq_rbx_rax, "\txorq\t%rbx, %rax\n");
        break;
    case "\txorl\t%eax, %ebx":
        xchg_and_op(rop, rop.xchgl_ebx_eax, "\txorl\t%ebx, %eax\n");
        break;
    default:
        if (line.startsWith("\taddq\t$")) {
            if (line.endsWith(", %rbx")) {
                string immediate = line.get_immediate;
                xchg_and_op(rop, rop.xchgq_rbx_rax, "\taddq\t" ~ immediate ~ ", %rax\n");
                return;
            }
        }

        if (line.startsWith("\taddl\t$")) {
            if (line.endsWith(", %ebx")) {
                string immediate = line.get_immediate;
                xchg_and_op(rop, rop.xchgl_ebx_eax, "\taddl\t" ~ immediate ~ ", %eax\n");
                return;
            }
        }

        rop.output ~= (line ~ "\n");
    }
}

int main(string[] args) {
    int usage() {
        stderr.writeln("usage: rop [-o out.s] [in.s]");
        return 1;
    }

    Rop rop = new Rop();

    string infile, input, outfile;

    bool first = true, saw_input;
    int saw_output;
    foreach (arg; args) {
        if (first) {
            first = false;
            continue;
        }

        if (saw_output == 1) {
            outfile = arg.idup;
            saw_output = 2;
            continue;
        }

        if (arg == "-o") {
            if (saw_output == 0) {
                saw_output = 1;
                continue;
            }
            return usage();
        }

        if (arg == "-h" || arg == "--help")
            return usage();

        if (arg == "-v" || arg == "--version") {
            v();
            continue;
        }

        if (!saw_input) {
            infile = arg.idup;
            saw_input = 1;
            continue;
        }

        return usage();
    }

    if (saw_output == 1)
        return usage();

    if (saw_input) {
        input = cast(string)std.file.read(infile);
    } else {
        foreach (string line; lines(stdin))
            input ~= line;
    }

    string[] assembly = input.splitLines;
    foreach (line; assembly)
        process(rop, line);

    if (saw_output == 0)
        write(rop.output);
    else
        std.file.write(outfile, rop.output);

    return 0;
}
