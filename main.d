/+
 + Copyright (c) 2025-2026 Brian Callahan <bcallaha@monmouth.edu>
 +                         Jenna Esposito <jennaesp.ml@gmail.com>
 +                         Aaila Arif <aailaarif03@gmail.com>
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
import std.uni;

import rop.config;

class Rop {
    private string dest, insn, output, sib, src;
    private string xchgq = "\txchgq\t%rbx, %rax\n";

    @safe pure nothrow void ain(string s) {
        this.output ~= s;
    }

    @safe @nogc pure nothrow string aout() {
        return this.output;
    }

    @safe pure nothrow bool parse(string s) {
        ulong i = 1;

        this.insn = "".idup;
        this.src = "".idup;
        this.dest = "".idup;
        this.sib = "".idup;

        while (s[i] != '\t') {
            if (i == s.length - 1)
                return false;
            ++i;
        }
        this.insn = s[1 .. i].idup;

        if (i == s.length - 1)
            return false;

        ++i;

        if (i == s.length - 1)
            return false;

        ulong j = i;
        switch (s[i]) {
        case '%':
            i = this.get_reg(s, j);
            if (i == 0 || i - j == 1)
                return false;
            break;
        case '$':
            i = this.get_immediate(s, j);
            if (i == 0 || i - j == 1)
                return false;
            break;
        case '0':
        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
        case '6':
        case '7':
        case '8':
        case '9':
        case '-':
        case '(':
            i = this.get_sib(s, j);
            if (i == 0 || i - j == 1)
                return false;
            break;
        default:
            return false;
        }
        this.src = s[j .. i].idup;

        if (i == s.length)
            return false;

        if (i == s.length - 1)
            return false;

        while (isWhite(s[i])) {
            if (i == s.length - 1)
                return false;
            ++i;
        }

        if (s[i] != ',')
            return false;

        ++i;

        while (isWhite(s[i])) {
            if (i == s.length - 1)
                return false;
            ++i;
        }

        j = i;
        if (s[i] == '%')
            i = this.get_reg(s, j);
        else
            i = this.get_sib(s, j);
        if (i == 0 || i - j == 1)
            return false;
        this.dest = s[j .. i].idup;

        if (i != s.length)
            return false;

        return true;
    }

    @safe @nogc pure nothrow bool setcc() {
        switch (this.insn) {
        case "seta":
        case "setae":
        case "setb":
        case "setbe":
        case "setc":
        case "sete":
        case "setg":
        case "setge":
        case "setl":
        case "setle":
        case "setna":
        case "setnae":
        case "setnb":
        case "setnbe":
        case "setnc":
        case "setne":
        case "setng":
        case "setnge":
        case "setnl":
        case "setnle":
        case "setno":
        case "setnp":
        case "setns":
        case "setnz":
        case "seto":
        case "setp":
        case "setpe":
        case "setpo":
        case "sets":
        case "setz":
            return true;
        default:
            return false;
        }
    }

    @safe @nogc pure nothrow bool cmovcc() {
        switch (this.insn) {
        case "cmova":
        case "cmovae":
        case "cmovb":
        case "cmovbe":
        case "cmovc":
        case "cmove":
        case "cmovg":
        case "cmovge":
        case "cmovl":
        case "cmovle":
        case "cmovna":
        case "cmovnae":
        case "cmovnb":
        case "cmovnbe":
        case "cmovnc":
        case "cmovne":
        case "cmovng":
        case "cmovnge":
        case "cmovnl":
        case "cmovnle":
        case "cmovno":
        case "cmovnp":
        case "cmovns":
        case "cmovnz":
        case "cmovo":
        case "cmovp":
        case "cmovpe":
        case "cmovpo":
        case "cmovs":
        case "cmovz":
            return true;
        default:
            return false;
        }
    }

    @safe @nogc pure nothrow bool isHex(int c) {
        switch (c) {
        case '0':
        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
        case '6':
        case '7':
        case '8':
        case '9':
        case 'A':
        case 'a':
        case 'B':
        case 'b':
        case 'C':
        case 'c':
        case 'D':
        case 'd':
        case 'E':
        case 'e':
        case 'F':
        case 'f':
            return true;
        default:
            return false;
        }
    }

    @safe pure nothrow ulong get_sib(string s, ulong begin) {
        switch (s[begin]) {
        case '0':
        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
        case '6':
        case '7':
        case '8':
        case '9':
        case '-':
        case '(':
            break;
        default:
            return 0;
        }

        if (begin == s.length - 1)
            return 0;

        ulong start = begin;
        bool finished;
        while (!finished) {
            switch (s[begin]) {
            case '0':
            case '1':
            case '2':
            case '3':
            case '4':
            case '5':
            case '6':
            case '7':
            case '8':
            case '9':
            case '-':
                if (begin == s.length - 1)
                    return 0;
                ++begin;
                break;
            default:
                finished = true;
            }
        }

        if (begin == s.length - 1)
            return 0;

        if (s[begin] != '(')
            return 0;

        ulong end = begin + 1;

        while (s[end] != ')') {
            if (end == s.length - 1) {
                if (s[begin .. $] == "(%rbx,%rax,8)") {
                    if (start != begin)
                        sib = s[start .. begin] ~ "(%rax,%rbx,8)";
                    return s.length;
                }
                return 0;
            }
            ++end;
        }

        if (end == s.length - 1) {
            if (s[begin .. $] == "(%rbx,%rax,8)") {
                if (start != begin)
                    sib = s[start .. begin] ~ "(%rax,%rbx,8)";
                return s.length;
            }
            return 0;
        }

        ++end;
        if (s[begin .. end] == "(%rbx,%rax,8)") {
            if (start != begin)
                sib = s[start .. begin] ~ "(%rax,%rbx,8)";
            return end;
        }

        return 0;
    }

    @safe @nogc pure nothrow ulong get_immediate(string s, ulong begin) {
        if (s[begin] != '$')
            return 0;

        if (begin == s.length - 1)
            return 0;

        ulong end;

        if (s[begin + 1] == '-') {
            if (begin == s.length - 2)
                return 0;
            end = begin + 2;
        } else {
            end = begin + 1;
        }

        while (this.isHex(s[end])) {
            if (end == s.length - 1)
                return s.length;
            ++end;
        }

        return end;
    }

    @safe @nogc pure nothrow ulong get_reg(string s, ulong begin) {
        if (s[begin] != '%')
            return 0;

        if (begin == s.length - 1)
            return 0;

        ulong end = begin + 1;

        while (isAlphaNum(s[end])) {
            if (end == s.length - 1) {
                if (!this.check_reg(s[begin + 1 .. $]))
                    return 0;
                return s.length;
            }
            ++end;
        }

        if (!this.check_reg(s[begin + 1 .. end]))
            return 0;

        return end;
    }

    @safe @nogc pure nothrow bool check_reg(string s) {
        switch (s) {
        case "rax":
        case "rbx":
        case "rcx":
        case "rdx":
        case "rdi":
        case "rsi":
        case "rbp":
        case "rsp":
        case "r8":
        case "r9":
        case "r10":
        case "r11":
        case "r12":
        case "r13":
        case "r14":
        case "r15":
        case "eax":
        case "ebx":
        case "ecx":
        case "edx":
        case "edi":
        case "esi":
        case "ebp":
        case "esp":
        case "r8d":
        case "r9d":
        case "r10d":
        case "r11d":
        case "r12d":
        case "r13d":
        case "r14d":
        case "r15d":
        case "ax":
        case "bx":
        case "cx":
        case "dx":
        case "di":
        case "si":
        case "bp":
        case "sp":
        case "r8w":
        case "r9w":
        case "r10w":
        case "r11w":
        case "r12w":
        case "r13w":
        case "r14w":
        case "r15w":
        case "al":
        case "bl":
        case "cl":
        case "dl":
        case "r8b":
        case "r9b":
        case "r10b":
        case "r11b":
        case "r12b":
        case "r13b":
        case "r14b":
        case "r15b":
            return true;
        default:
            return false;
        }
    }

    @safe @nogc pure nothrow bool is_basic_64_bit_reg_reg_arithmetic() {
        switch (this.insn) {
        case "adcq":
        case "addq":
        case "andq":
        case "cmpq":
        case "movq":
        case "orq":
        case "sbbq":
        case "subq":
        case "testq":
        case "xorq":
            return true;
        default:
            return false;
        }
    }

    @safe @nogc pure nothrow bool is_basic_32_bit_reg_reg_arithmetic() {
        switch (this.insn) {
        case "adcl":
        case "addl":
        case "andl":
        case "cmpl":
        case "movl":
        case "orl":
        case "sbbl":
        case "subl":
        case "testl":
        case "xorl":
            return true;
        default:
            return false;
        }
    }

    @safe @nogc pure nothrow bool is_basic_16_bit_reg_reg_arithmetic() {
        switch (this.insn) {
        case "adcw":
        case "addw":
        case "andw":
        case "cmpw":
        case "movw":
        case "orw":
        case "sbbw":
        case "subw":
        case "testw":
        case "xorw":
            return true;
        default:
            return false;
        }
    }

    @safe @nogc pure nothrow bool is_basic_8_bit_reg_reg_arithmetic() {
        switch (this.insn) {
        case "adcb":
        case "addb":
        case "andb":
        case "cmpb":
        case "movb":
        case "orb":
        case "sbbb":
        case "subb":
        case "testb":
        case "xorb":
            return true;
        default:
            return false;
        }
    }

    @safe @nogc pure nothrow bool is_extend_32_bit_reg_to_64_bit_reg_arithmetic() {
        switch (this.insn) {
        case "movslq":
            return true;
        default:
            return false;
        }
    }

    @safe @nogc pure nothrow bool is_extend_8_bit_reg_to_32_bit_reg_arithmetic() {
        switch (this.insn) {
        case "movzbl":
            return true;
        default:
            return false;
        }
    }

    @safe @nogc pure nothrow bool is_unsafe() {
        if (this.dest == "%rbx" && (this.src == "%rax" || this.src == "%r8")) {
            if (this.is_basic_64_bit_reg_reg_arithmetic())
                return true;
            return false;
        }

        if (this.dest == "%r11" && (this.src == "%rax" || this.src == "%r8")) {
            if (this.is_basic_64_bit_reg_reg_arithmetic())
                return true;
            return false;
        }

        if (this.dest == "%ebx" && (this.src == "%eax" || this.src == "%r8d")) {
            if (this.is_basic_32_bit_reg_reg_arithmetic())
                return true;
            return false;
        }

        if (this.dest == "%r11d" && (this.src == "%eax" || this.src == "%r8d")) {
            if (this.is_basic_32_bit_reg_reg_arithmetic())
                return true;
            return false;
        }

        if (this.dest == "%bx" && (this.src == "%ax" || this.src == "%r8w")) {
            if (this.is_basic_16_bit_reg_reg_arithmetic())
                return true;
            return false;
        }

        if (this.dest == "%bl" && (this.src == "%al" || this.src == "%r8b")) {
            if (this.is_basic_8_bit_reg_reg_arithmetic())
                return true;
            return false;
        }

        if (this.dest == "%rax" && (this.src == "%ebx" || this.src == "%r11d")) {
            if (this.is_extend_32_bit_reg_to_64_bit_reg_arithmetic())
                return true;
            return false;
        }

        if (this.dest == "%eax" && (this.src == "%bl" || this.src == "%r11b")) {
            if (this.is_extend_8_bit_reg_to_32_bit_reg_arithmetic())
                return true;
            return false;
        }

        if (this.dest == "%rax" && this.src == "%rbx") {
            if (this.cmovcc())
                return true;
            return false;
        }

        if (this.dest == "%eax" && this.src == "%ebx") {
            if (this.cmovcc())
                return true;
            return false;
        }

        if (this.src[0] == '$') {
            switch (this.dest) {
            case "%rbx":
            case "%ebx":
            case "%bx":
            case "%bl":
            case "%r11":
            case "%r11d":
            case "%r11w":
            case "%r11b":
                if (this.insn.startsWith("add") || this.insn.startsWith("test"))
                    return true;
                if ((this.dest == "%rbx" || this.dest == "%r11") && this.insn == "movq")
                    return true;
                return false;
            default:
                break;
            }
        }
 
        switch (this.src[0]) {
        case '0':
        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
        case '6':
        case '7':
        case '8':
        case '9':
        case '(':
            return true;
        default:
            break;
        }

        switch (this.dest[0]) {
        case '0':
        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
        case '6':
        case '7':
        case '8':
        case '9':
        case '(':
            return true;
        default:
            break;
        }

        return false;
    }

    @safe pure nothrow void xchg_and_immediate() {
        if (this.dest[2] == '1')
            this.ain("\txchgq\t%r11, %rax\n");
        else
            this.ain(xchgq);
        this.ain("\t" ~ this.insn ~ "\t" ~ this.src ~ ", ");
        switch (this.dest) {
        case "%ebx":
        case "%r11d":
            this.ain("%eax");
            break;
        case "%bx":
        case "%r11w":
            this.ain("%ax");
            break;
        case "%bl":
        case "%r11b":
            this.ain("%al");
            break;
        default:
            this.ain("%rax");
            break;
        }
        this.ain("\n");
        if (this.dest[2] == '1')
            this.ain("\txchgq\t%r11, %rax\n");
        else
            this.ain(xchgq);
    }

    @safe pure nothrow void xchg_and_op() {
        if (this.dest == "%rax" && this.src == "%ebx") {
            this.ain(xchgq);
            this.ain("\t" ~ this.insn ~ "\t%eax, %rbx\n");
            this.ain(xchgq);
        } else if (this.dest == "%r11" && this.src == "%rax") {
            this.ain("\txchgq\t%r11, %rax\n");
            this.ain("\t" ~ this.insn ~ "\t%r11, %rax\n");
            this.ain("\txchgq\t%r11, %rax\n");
        } else if (this.dest == "%rax" && this.src == "%r11d") {
            this.ain("\txchgq\t%r11, %rax\n");
            this.ain("\t" ~ this.insn ~ "\t%eax, %r11\n");
            this.ain("\txchgq\t%r11, %rax\n");
        } else if (this.dest == "%eax" && this.src == "%bl") {
            this.ain(xchgq);
            this.ain("\t" ~ this.insn ~ "\t%al, %ebx\n");
            this.ain(xchgq);
        } else if (this.dest == "%eax" && this.src == "%r11b") {
            this.ain("\txchgq\t%r11, %rax\n");
            this.ain("\t" ~ this.insn ~ "\t%al, %r11d\n");
            this.ain("\txchgq\t%r11, %rax\n");
        } else if (this.dest == "%r11d" && this.src == "%r8d") {
            this.ain("\txchgq\t%r11, %r8\n");
            this.ain("\t" ~ this.insn ~ "\t%r11d, %r8d\n");
            this.ain("\txchgq\t%r11, %r8\n");
        } else if (this.dest == "%rbx" && this.src == "%r8") {
            this.ain("\txchgq\t%rbx, %r8\n");
            this.ain("\t" ~ this.insn ~ "\t%rbx, %r8\n");
            this.ain("\txchgq\t%rbx, %r8\n");
        } else if (this.dest == "%r11" && this.src == "%r8") {
            this.ain("\txchgq\t%r8, %r11\n");
            this.ain("\t" ~ this.insn ~ "\t%r11, %r8\n");
            this.ain("\txchgq\t%r8, %r11\n");
        } else if (this.dest == "%r11d" && this.src == "%eax") {
            this.ain("\txchgq\t%r11, %rax\n");
            this.ain("\t" ~ this.insn ~ "\t%r11d, %eax\n");
            this.ain("\txchgq\t%r11, %rax\n");
        } else if (this.dest == "%ebx" && this.src == "%r8d") {
            this.ain("\txchgq\t%rbx, %r8\n");
            this.ain("\t" ~ this.insn ~ "\t%ebx, %r8d\n");
            this.ain("\txchgq\t%rbx, %r8\n");
        } else if (this.dest == "%bx" && this.src == "%r8w") {
            this.ain("\txchgq\t%rbx, %r8\n");
            this.ain("\t" ~ this.insn ~ "\t%bx, %r8w\n");
            this.ain("\txchgq\t%rbx, %r8\n");
        } else if (this.dest == "%bl" && this.src == "%r8b") {
            this.ain("\txchgq\t%rbx, %r8\n");
            this.ain("\t" ~ this.insn ~ "\t%bl, %r8b\n");
            this.ain("\txchgq\t%rbx, %r8\n");
        } else {
            this.ain(xchgq);
            this.ain("\t" ~ this.insn ~ "\t" ~ this.dest ~ ", " ~ this.src ~ "\n");
            this.ain(xchgq);
        }
    }

    @safe pure nothrow void xchg_and_src_sib() {
        if (sib.empty)
            sib = "(%rax,%rbx,8)";
        this.ain(xchgq);
        switch (this.dest) {
        case "%rax":
            this.ain("\t" ~ this.insn ~ "\t" ~ sib ~ ", %rbx\n");
            break;
        case "%rbx":
            this.ain("\t" ~ this.insn ~ "\t" ~ sib ~ ", %rax\n");
            break;
        default:
            this.ain("\t" ~ this.insn ~ "\t" ~ sib ~ ", " ~ this.dest ~ "\n");
        }
        this.ain(xchgq);
    }

    @safe pure nothrow void xchg_and_dest_sib() {
        if (sib.empty)
            sib = "(%rax,%rbx,8)";
        this.ain(xchgq);
        switch (this.src) {
        case "%rax":
            this.ain("\t" ~ this.insn ~ "\t" ~ "%rbx, " ~ sib ~ "\n");
            break;
        case "%rbx":
            this.ain("\t" ~ this.insn ~ "\t" ~ "%rax, " ~ sib ~ "\n");
            break;
        default:
            this.ain("\t" ~ this.insn ~ "\t" ~ this.src ~ ", " ~ sib ~ "\n");
        }
        this.ain(xchgq);
    }

    @safe pure nothrow void xchg_and_setcc() {
        if (this.src == "%r11b")
            this.ain("\txchgq\t%r11, %rax\n");
        else
            this.ain(xchgq);
        this.ain("\t" ~ this.insn ~ "\t%al\n");
        if (this.src == "%r11b")
            this.ain("\txchgq\t%r11, %rax\n");
        else
            this.ain(xchgq);
    }

    @safe pure nothrow void process(string line) {
        if (line.empty) {
            this.ain("\n");
            return;
        }

        if (line.length == 1)
            goto done;

        if (line[0] != '\t')
            goto done;

        if (line[1] == '.')
            goto done;

        if (this.parse(line)) {
            if (this.is_unsafe()) {
                switch (this.src[0]) {
                case '$':
                    switch (this.dest[0]) {
                    case '0':
                    case '1':
                    case '2':
                    case '3':
                    case '4':
                    case '5':
                    case '6':
                    case '7':
                    case '8':
                    case '9':
                    case '-':
                    case '(':
                        this.xchg_and_dest_sib();
                        break;
                    default:
                        this.xchg_and_immediate();
                    }
                    break;
                case '0':
                case '1':
                case '2':
                case '3':
                case '4':
                case '5':
                case '6':
                case '7':
                case '8':
                case '9':
                case '-':
                case '(':
                    this.xchg_and_src_sib();
                    break;
                default:
                    switch (this.dest[0]) {
                    case '0':
                    case '1':
                    case '2':
                    case '3':
                    case '4':
                    case '5':
                    case '6':
                    case '7':
                    case '8':
                    case '9':
                    case '-':
                    case '(':
                        this.xchg_and_dest_sib();
                        break;
                    default:
                        this.xchg_and_op();
                    }
                }
                return;
            }
        }

        if (this.src == "%bl" || this.src == "%r11b") {
            if (this.setcc()) {
                this.xchg_and_setcc();
                return;
            }
        }

done:
        this.ain(line ~ "\n");
    }
}

int main(string[] args) {
    int usage() {
        stderr.writeln("usage: rop [-h] [-v] [-o out.s] [in.s ...]");
        return 1;
    }

    int v_and_exit() {
        stderr.writeln(v());
        stderr.writeln("\nCopyright (c) 2025-2026 Brian Callahan <bcallaha@monmouth.edu>");
        stderr.writeln("                        Jenna Esposito <jennaesp.ml@gmail.com>");
        stderr.writeln("                        Aaila Arif <aailaarif03@gmail.com>\n");
        stderr.writeln("Permission to use, copy, modify, and distribute this software for any");
        stderr.writeln("purpose with or without fee is hereby granted, provided that the above");
        stderr.writeln("copyright notice and this permission notice appear in all copies.\n");
        stderr.writeln("THE SOFTWARE IS PROVIDED \"AS IS\" AND THE AUTHOR DISCLAIMS ALL WARRANTIES");
        stderr.writeln("WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF");
        stderr.writeln("MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR");
        stderr.writeln("ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES");
        stderr.writeln("WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN");
        stderr.writeln("ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF");
        stderr.writeln("OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.\n");
        stderr.writeln("This optimizer was configured for a target of `" ~ target() ~ "'.");
        return 0;
    }

    Rop rop = new Rop();

    string[] infiles;
    string input, outfile;

    int saw_output;
    foreach (arg; args[1 .. $]) {
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

        if (arg == "-v") {
            stderr.writeln(v());
            continue;
        }

        if (arg == "-h" || arg == "--help")
            return usage();

        if (arg == "--version")
            return v_and_exit();

        if (arg[0] == '-' && arg != "-") {
            stderr.writeln("unknown option: " ~ arg);
            return usage();
        }

        infiles ~= arg.idup;
    }

    if (saw_output == 1)
        return usage();

    if (outfile == "-")
        saw_output = 0;

    if (infiles.empty) {
        foreach (string line; lines(stdin))
            input ~= line;
    } else {
        foreach (infile; infiles) {
            if (infile == "-") {
                foreach (string line; lines(stdin))
                    input ~= line;
            } else {
                input ~= cast(string)std.file.read(infile);
            }
        }
    }

    string[] assembly = input.splitLines;
    foreach (line; assembly)
        rop.process(line);

    if (saw_output == 0)
        stdout.write(rop.aout);
    else
        std.file.write(outfile, rop.aout);

    return 0;
}
