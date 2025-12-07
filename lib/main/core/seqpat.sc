SPToken {
    var <type, <val;

    *new { |type, val|
        ^super.newCopyArgs(type: type, val: val)
    }
}

SPTokenStream {
    classvar tokenTable;
    
    var <tokens, ptr, readUntil, head;

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
        ^super.newCopyArgs(
            tokens, 
            0, 
            nil,
            nil);
    }

    skip {
        while { ptr < tokens.size and: {this.curr().isSpace} } { 
            ptr = ptr + 1;
        };
    }

    valueToken {
        var acc = [];
        while {
            var tok = this.curr();
            (ptr < tokens.size) and: {}
            (isNil(readUntil) and: {not(tok.isSpace)} and: {not(tokenTable.includesKey(tok))}) or:
            (notNil(readUntil) and: {tok != readUntil})
        } {
            acc = acc.add(curr);
            ptr = ptr + 1;
        };
        ^String.newFrom(acc);
    }

    curr {
        if (ptr >= tokens.size) {
            Error("Unexpected end of statement!").throw;
        };
        ^this.tokens[ptr];
    }

    next {
        var tok;
        
        if (notNil(head)) {
            var tmp = head;
            head = nil;
            ^head;
        };
        
        this.skip();
        tok = this.curr();

        ^if (tokenTable.includesKey(tok)) {
            if (readUntil != $` and: {tok == $`}) {
                readUntil = $`
            } {
                readUntil = nil;
            };
            SPToken(tokenTable[tok], tok);
        } {
            SPToken(\val, this.valueToken())
        }
    }

    peek {
        if (isNil(head)) {
            head = this.next();
        };
        ^head;
    }

    consume { |tokenType|
        var token = this.peek();
        if (token.type != tokenType) {
            Error("Invalid syntax: " ++ token.val);
        };
        ^token;
    }
}

SPTokenizer {
    classvar tokenTable;

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

    *tokenize { |pat|
        var acc = [],
            resetAcc = {
                if (acc.isEmpty.not) {
                    var token = SPToken(\val, String.newFrom(acc));
                    tokens = tokens.add(token);
                    acc = [];
                };
                tokens;
            },
            ticks = 0,
            tokens = [];

        pat.do { |tok|
            case
                { ticks.odd } {
                    if (tokenTable[tok] == \tick) {
                        tokens = resetAcc.();
                        tokens = tokens.add(SPToken(\tick, $`));
                        ticks = ticks + 1;
                    } {
                        acc = acc.add(tok);
                    }
                }
                { tokenTable.includesKey(tok) } {
                    tokens = resetAcc.();
                    if (tokenTable[tok] == \tick) {
                        ticks = ticks + 1;
                    };
                    tokens = tokens.add(SPToken(tokenTable[tok], tok));
                }
                { tok.isSpace } {
                    tokens = resetAcc.();
                }
                { true } {
                    acc = acc.add(tok);
                };
        };
        ^resetAcc.();
    }
}
