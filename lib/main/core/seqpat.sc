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
            $` -> \tick
        ];
    }

    *new { |tokens|
        ^super.newCopyArgs(tokens, 0, nil, nil);
    }

    isTerminal {
        ^(ptr >= tokens.size);
    }

    curr {
        ^tokens[ptr];
    }

    advance {
        var prev = this.curr;
        ptr = ptr + 1;
        ^prev;
    }

    valueToken {
        var acc = [];
        while {
            var tok = this.curr;
            not(this.isTerminal) 
                and: {not(tok.isSpace)} 
                and: {not(tokenTable.includesKey(tok))}
            
        } {
            acc = acc.add(this.advance);
        };
        ^String.newFrom(acc);
    }

    next {
        var tok;
        
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

        ^if (tokenTable.includesKey(tok)) {
            SPToken(tokenTable[tok], String.newFrom(this.advance));
        } {
            SPToken(\val, this.valueToken);
        };
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

    visit { |dur|
        var vals = [],
            durs = [];
        seq.do { |elem|
            var pair = elem.visit(dur / seq.size);
            vals = vals.add(pair[0]);
            durs = durs.add(pair[1]);
        };
        ^[Dseq(vals, 1), Dseq(durs, 1)];
    }
}

SPEuc {
    var val, n, k, o;

    *new { |val, k, n, o|
        ^super.newCopyArgs(val, n, k, o);
    }

    visit { |dur|
        var nVal = n.visit(dur)[0].asInteger,
            kVal = k.visit(dur)[0].asInteger,
            oVal = o.visit(dur)[0].asInteger,
            vVal = val.visit(dur / nVal),
            genPat = { |val|
                ((kVal / nVal * (0..nVal - 1))
                    .floor
                    .differentiate
                    .asInteger
                    .min(1)[0] = if (kVal <= 0) { 0 } { 1 })
                .rotate(oVal)
                .collect { |i| 
                    if (i == 0) { 0 } { val }
                }
            };
        ^[Dseq(genPat.(vVal[0]), 1), Dseq(nVal.collect { vVal[1] }, 1)]
    }
}

SPAlt {
    var alts, ptr;

    *new { |alts|
        ^super.newCopyArgs(alts, 0);
    }

    visit { |dur|
        var tmp = alts[ptr];
        ptr = (ptr + 1) % alts.size;
        ^tmp.visit(dur);
    }
}

SPCode {
    var f;

    *new { |expr|
        ^super.newCopyArgs(expr.compile);
    }
    
    visit { |dur|
        ^[f.value, dur];
    }
}

SPVal {
    var val;

    *new { |val|
        ^super.newCopyArgs(val.asFloat);
    }

    visit { |dur| 
        ^[val, dur];
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
            acc = acc ++ this.parse;
        };
        stream.consume(end);
        ^acc;
    }

    parse { 
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

        if (head.type == \val) {
            sp = SPVal(stream.consume(\val));
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
            sp = SPEuc(sp, args[0], args[1], args[2] ? SPVal("0"));
        };
        ^sp;
    }
}

SP {
    var name, >hold, >speed, >quant;

    *new { |name|
        ^super.newCopyArgs(name, false, 1, 4);
    }

    pat { |str|
        var parser = SPParser(str),
            seq = parser.parse(),
            clock = TempoClock.default,
            scheduleTime = (quant - (clock.beats % quant));

        TempoClock.sched(scheduleTime, {
            var cycleBeats = 4 / speed,
                cycleTime = clock.beatDur * cycleBeats;
            Tdef(name, {
                loop {
                    Ndef(name, {
                        var vals, durs; 
                        #vals, durs = seq.visit(cycleTime);
                        TDuty.kr(Dseq([durs], 1), Impulse.kr(0), Dseq([vals], 1));
                    });
                    cycleBeats.wait;
                }
            }).play;
            nil;
        });

        ^Ndef(name); 
    }
}
