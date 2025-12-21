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
            $~ -> \rest,
            $* -> \mul,
            $/ -> \div
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

ValueVisitor {
    var container;

    *new {
        ^this.newCopyArgs(`nil);
    }

    visit { |dur, val|
        container.set(val);
    }

    get {
        ^container.get;
    }
}

SPSeqVisitor {
    var vals, durs;

    *new {
        ^this.newCopyArgs(`[], `[]);
    }

    visit { |dur, val|
        vals.set(vals.get.add(val));
        durs.set(durs.get.add(dur));
    }

    pairs {
        ^[vals.get, durs.get];
    }

    demand { |trig|
        var demandVals = Dseq(vals.get, 1), 
            demandDurs = Dseq(durs.get, 1);

        ^if (trig) {
            TDuty.kr(demandDurs, Impulse.kr(0), demandVals)
        } {
            Duty.kr(demandDurs, Impulse.kr(0), demandVals)
        }
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
        var kVisitor = ValueVisitor(),
            nVisitor = ValueVisitor(),
            oVisitor = ValueVisitor();

        k.visit(depth, kVisitor);
        n.visit(depth, nVisitor);
        o.visit(depth, oVisitor);

        depth = depth / nVisitor.get;

        ((kVisitor.get / nVisitor.get * (0..nVisitor.get - 1))
            .floor
            .differentiate
            .asInteger
            .min(1)[0] = if (kVisitor.get <= 0) { 0 } { 1 })
        .rotate(oVisitor.get.asInteger)
        .do { |i| 
            if (i == 0) { 
                SPNum(0).visit(depth, visitor)
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

SPBinOp {
    var lhs, op, rhs;

    *new { |lhs, op, rhs|

        ^super.newCopyArgs(lhs, op, rhs);
    }

    visit { |depth, visitor|
        var rhsVisitor = ValueVisitor();
        rhs.visit(depth, rhsVisitor);

        if (op == \mul) {
            depth = depth / rhsVisitor.get;
            rhsVisitor.get.do {
                lhs.visit(depth, visitor)
            }
        };

        if (op == \div) {
            Error("div is unimplemented!").throw;
        };
    }
}

SPCode {
    var f;

    *new { |expr|
        ^super.newCopyArgs(expr.compile);
    }
    
    visit { |depth, visitor|
        visitor.visit(depth, f.value);
    }
}

SPSym {
    var val;

    *new { |val|
        ^super.newCopyArgs(Note.toFreq(val));
    }

    visit { |depth, visitor| 
        visitor.visit(depth, val);
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
        visitor.visit(depth, val);
    }
}

SPParser {
    var stream; 

    *new { |pat|
        ^super.newCopyArgs(SPTokenStream(pat));
    }

    parseVal {
        // num | sym | rest
        var head = stream.peek;
        if (head.type == \num or: { head.type == \rest }) {
            ^SPNum(stream.consume(head.type));
        };
        ^SPSym(stream.consume(\sym));
    }

    parseCode { 
        var acc = "";
        stream.consume(\tick);
        while { stream.peek.type != \tick } {
            acc = acc ++ stream.consume(\any);
        };
        stream.consume(\tick);
        ^SPCode(acc);
    }

    parseAlt {
        var acc = [];
        stream.consume(\lt);
        while { stream.peek.type != \gt } {
            acc = acc.add(this.parseExpr);
        };
        stream.consume(\gt);
        ^SPAlt(acc);
    }

    parseAtom {
        // code | alt | val
        var head = stream.peek;
        
        if (head.type == \tick) {
            ^this.parseCode;
        };

        if (head.type == \lt) {
            ^this.parseAlt;
        };

        ^this.parseVal;
    }

    parseSeq { 
        var acc = [];
        stream.consume(\lbrack);
        while { stream.peek.type != \rbrack } {
            acc = acc.add(this.parseExpr);
        };
        stream.consume(\rbrack);
        ^SPSeq(acc);
    }

    parseEuc { |lhs|
        var k, n, o;

        stream.consume(\lparen);
        k = this.parseAtom;
        n = this.parseAtom;
        o = if (stream.peek.type != \rparen) { this.parseAtom } { SPNum(0) };
        stream.consume(\rparen);

        ^SPEuc(lhs, k, n, o);
    }

    parseBinop { |lhs|
        var op, rhs;

        op = stream.peek.type;
        if (op != \mul and: {op != \div}) {
            Error("Invalid binop " ++ op).throw;
        };
        stream.consume(op);

        ^SPBinOp(lhs, op, this.parseAtom);
    }

    parseExpr {
        // elem | seq | binop | euc

        var head = stream.peek;
        var sp = if (head.type == \lbrack) { 
            this.parseSeq 
        } { 
            this.parseAtom 
        };

        if (stream.isTerminal()) {
            ^sp;
        };

        head = stream.peek;

        // euc
        if (head.type == \lparen) {
            sp = this.parseEuc(sp);
        };

        // binop
        if (head.type == \mul or: {head.type == \div}) {
            sp = this.parseBinop(sp);
        };

        ^sp;
    }

    parse {
        var seq = [];
        while { not(stream.isTerminal) } {
            seq = seq.add(this.parseExpr);
        };
        ^SPSeq(seq);
    }
}

// TODO: Compile the mini expression to a pattern object?
// A Pseq?
SPMini {

    *durVals { |pat| 
        var pair, visitor, cycleTime, seq;

        seq = SPParser(pat).parse;
        cycleTime = TempoClock.default.beatDur * 4;
        visitor = SPSeqVisitor();
        seq.visit(cycleTime, visitor);

        ^visitor.pairs;
    }
}

SP {
    var name, >trig, >quant;

    *new { |name|
        ^super.newCopyArgs(name, true, 4);
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
                    var visitor = SPSeqVisitor();
                    seq.visit(cycleTime, visitor);
                    visitor.demand(trig);
                });
                cycleBeats.wait;
            }
        })
        .play;

        ^this.get; 
    }
}

