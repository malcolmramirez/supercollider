SPToken {
    var <type, <val;

    *new { |type, val|
        ^super.newCopyArgs(type, val)
    }
}

SPTokenStream {
    classvar tokenTable;
    
    var tokens, ptr, readUntil, head;

    *initClass {
        tokenTable = Dictionary[
            $[ -> \lbrack,
            $] -> \rbrack,
            $( -> \lparen,
            $) -> \rparen,
            $< -> \lt,
            $> -> \gt,
            $` -> \tick,
            $~ -> \rest
        ];
    }

    *new { |tokens|
        ^super.newCopyArgs(tokens, 0, nil, nil);
    }

    isTerminal {
        ^((ptr >= tokens.size) and: {isNil(head)});
    }

    curr {
        ^tokens[ptr];
    }

    advance {
        var prev = this.curr;
        ptr = ptr + 1;
        ^prev;
    }

    accumulateWhile { |pred|
        var acc = [];
        while {
            var tok = this.curr;
            not(this.isTerminal) 
                and: {pred.(tok)} 
                and: {not(tokenTable.includesKey(tok))}
        } {
            acc = acc.add(this.advance);
        };
        ^String.newFrom(acc);
    }

    next {
        var tok,
            val,
            isNum = { |t| t.isDecDigit or: {t == $.}},
            isStr = { |t| not(t.isSpace) };
        
        if (notNil(head)) {
            tok = head;
            head = nil;
            ^tok;
        };
        
        // Skip spaces
        while { not(this.isTerminal) and: {this.curr.isSpace} } { 
            this.advance;
        };

        if (this.isTerminal) {
            Error("Unexpected end of statement!").throw;
        };
        tok = this.curr;

        if (tokenTable.includesKey(tok)) {
            val = String.newFrom(this.advance);
            ^SPToken(tokenTable[tok], val);
        };

        if (isNum.(tok)) {
            val = this.accumulateWhile(isNum);
            ^SPToken(\num, val);
        };

        val = this.accumulateWhile(isStr);
        ^SPToken(\sym, val);
    }

    peek {
        if (isNil(head)) {
            head = this.next;
        };
        ^head;
    }

    consume { |tokenType|
        var token = this.next;
        if ((tokenType != \any) and: {token.type != tokenType}) {
            Error("Invalid syntax: " ++ token.val);
        };
        ^token.val;
    }
}

SPSeq {
    var seq;

    *new { |seq|
        ^super.newCopyArgs(seq);
    }

    visit { |depth, visitor|
        seq.do { |elem|
            elem.visit(depth / seq.size, visitor);
        };
    }
}

SPEuc {
    var val, n, k, o;

    *new { |val, k, n, o|
        ^super.newCopyArgs(val, n, k, o);
    }

    visit { |depth, visitor|
        var args = `Dictionary(),
            visitArg = { |n| 
                { |x, d| args.set(args.get.put(n, x.asInteger)) }
            };

        k.visit(depth, visitArg.(\k));
        n.visit(depth, visitArg.(\n));
        o.visit(depth, visitArg.(\o));

        depth = depth / args[\n];

        ((args[\k] / args[\n] * (0..args[\n] - 1))
            .floor
            .differentiate
            .asInteger
            .min(1)[0] = if (args[\k] <= 0) { 0 } { 1 })
        .rotate(args[\o])
        .do { |i| 
            if (i == 0) { 
                visitor.(0, depth)
            } { 
                val.visit(depth, visitor) 
            }
        }
    }
}

SPAlt {
    var alts, ptr;

    *new { |alts|
        ^super.newCopyArgs(alts, 0);
    }

    visit { |depth, visitor|
        var tmp = alts[ptr];
        ptr = (ptr + 1) % alts.size;
        tmp.visit(depth, visitor);
    }
}

SPCode {
    var f;

    *new { |expr|
        ^super.newCopyArgs(expr.compile);
    }
    
    visit { |depth, visitor|
        visitor.(f.value, depth);
    }
}

SPSym {
    var val;

    *new { |val|
        ^super.newCopyArgs(Note.toFreq(val));
    }

    visit { |depth, visitor| 
        visitor.(val, depth);
    }
}

SPNum {
    var val;

    *new { |val|
        if (val == "~") {
            val = 0;
        };
        ^super.newCopyArgs(val.asFloat);
    }

    visit { |depth, visitor| 
        visitor.(val, depth);
    }
}

SPParser {
    var stream; 

    *new { |pat|
        ^super.newCopyArgs(SPTokenStream(pat));
    }

    parseCode { 
        var acc = "";
        stream.consume(\tick);
        while { stream.peek().type != \tick } {
            acc = acc ++ stream.consume(\any);
        };
        stream.consume(\tick);
        ^acc;
    }

    parseList { |start, end| 
        var acc = [];
        stream.consume(start);
        while { stream.peek().type != end } {
            acc = acc.add(this.parseInternal);
        };
        stream.consume(end);
        ^acc;
    }

    parseInternal { 
        var head = stream.peek(),
            sp;
        
        if (head.type == \lbrack) {
            // parse as seq
            var list = this.parseList(\lbrack, \rbrack);
            sp = SPSeq(list);
        };

        if (head.type == \lt) {
            // parse as alt
            var list = this.parseList(\lt, \gt);
            sp = SPAlt(list);
        };

        if (head.type == \tick) {
            // parse as code
            var code = this.parseCode();
            sp = SPCode(code);
        };

        if (head.type == \num or: {head.type == \rest}) {
            var num = stream.consume(head.type);
            sp = SPNum(num);
        };

        if (head.type == \sym) {
            var str = stream.consume(\sym);
            sp = SPSym(str);
        };

        if (stream.isTerminal()) {
            ^sp;
        };

        head = stream.peek();
        
        // parse as euc
        if (head.type == \lparen) {
            var args = this.parseList(\lparen, \rparen);
            if (args.size != 2 and: {args.size != 3}) {
                Error("Wrong number of args for euc: " ++ args).throw;
            };
            sp = SPEuc(sp, args[0], args[1], args[2] ? SPNum(0));
        };
        ^sp;
    }

    parse {
        // TODO: Something about this isn't working quite right...
        //       Patterns defined without an explicit wrapper seq don't sync up correctly to stuff.
        var seq = [];
        while { not(stream.isTerminal) } {
            seq = seq.add(this.parseInternal);
        };
        ^SPSeq(seq);
    }
}

SP {
    var name, >hold, >quant;

    *new { |name|
        ^super.newCopyArgs(name, false, 4);
    }

    get {
        ^Ndef(name);
    }

    pat { |str|
        var parser = SPParser(str),
            seq = parser.parse,
            clock = TempoClock.default,
            cycleBeats = 4,
            cycleTime = clock.beatDur * cycleBeats;
        Tdef(name, {
            loop {
                Ndef(name, {
                    var vals =`[], 
                        durs = `[],
                        visitor = { |val, dur|
                            vals.set(vals.get.add(val));
                            durs.set(durs.get.add(dur));
                        };

                    seq.visit(cycleTime, visitor);
                    
                    vals = Dseq(vals.get, 1);
                    durs = Dseq(durs.get, 1);

                    if (hold) {
                        Duty.kr(durs, Impulse.kr(0), vals);
                    } {
                        TDuty.kr(durs, Impulse.kr(0), vals);
                    }
                });
                cycleBeats.wait;
            }
        })
        .quant_(4)
        .play;

        ^this.get; 
    }
}
