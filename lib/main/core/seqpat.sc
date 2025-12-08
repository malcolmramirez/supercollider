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
        var prev = this.curr();
        ptr = ptr + 1;
        ^prev;
    }

    skip {
        while { not(this.isTerminal()) and: {this.curr().isSpace} } { 
            this.advance();
        };
    }

    valueToken {
        var acc = [];
        while {
            var tok = this.curr();
            not(this.isTerminal()) 
                and: {(isNil(readUntil) 
                            and: {not(tok.isSpace)} 
                            and: {not(tokenTable.includesKey(tok))}) 
                        or: {(notNil(readUntil) and: {tok != readUntil})}}
            
        } {
            acc = acc.add(this.advance());
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
        
        if (this.isTerminal()) {
            Error("Unexpected end of statement!").throw;
        };

        this.skip();
        
        tok = this.curr();

        ^if (tokenTable.includesKey(tok)) {
            if (readUntil != $` and: {tok == $`}) {
                readUntil = $`;
            } {
                readUntil = nil;
            };
            SPToken(tokenTable[tok], this.advance());
        } {
            SPToken(\val, this.valueToken());
        };
    }

    peek {
        if (isNil(head)) {
            head = this.next();
        };
        ^head;
    }

    consume { |tokenType|
        var token = this.next();
        if (token.type != tokenType) {
            Error("Invalid syntax: " ++ token.val);
        };
        ^token;
    }
}

