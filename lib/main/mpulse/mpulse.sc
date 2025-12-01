// grammar
// - x(k, n, o) 
// - x
// - [x y ... z]
// - <x y ... z>

PParse {
    
    *visitEuc { |token|
        // x(k, n, opt(o))
        var openIdx, closeIdx, parts;
        
        openIdx = token.indexOf($();
        closeIdx = token.indexOf($));
        
        if ((openIdx.notNil)
                .and(closeIdx.notNil)
                .and(closeIdx == (token.size - 1))) {
            parts = token[openIdx+1..closeIdx-1]
                .split($ )
                .collect(_.stripWhiteSpace);
            
            if (parts.size >= 2) {
                ^(type: \euc, 
                    val: PParse.from(token[..openIdx-1]),
                    k: parts[0].asInteger, 
                    n: parts[1].asInteger, 
                    o: if (parts.size > 2) { parts[2].asInteger } { 0 }) 
            };
        };
        
        ^nil
    }

    *isOpen { |ch|
        ^(ch == $()
            .or(ch == $[)
            .or(ch == $<)
    }

    *isClosed { |ch|
        ^(ch == $))
            .or(ch == $])
            .or(ch == $>)
    }

    *visitVal { |token|
        // x
        var nonSpecial = token.select { |ch| 
            PParse.isOpen(ch).or(PParse.isClosed(ch)) 
        }.isEmpty;
        if (not(token.isEmpty).and(nonSpecial)) {
            ^(type: \val, 
                val: token.asInteger)
        };
        ^nil
    }

    *visitSeqLike { |token|
        var items, depth, start;

        token = token[1..token.size-2];
        items = List.new;
        depth = 0;
        start = 0;
        
        token.size.do { |i|
            var curr = token[i];
            case 
            { PParse.isOpen(curr) } { 
                depth = depth + 1;
            }
            { PParse.isClosed(curr) } {
                depth = depth - 1;
            }  
            { (curr.isSpace).and(depth == 0) } {
                if (i > start) {
                    items.add(token[start..i-1].stripWhiteSpace);
                };
                start = i + 1;
            };
        };

        if (depth != 0) {
            Error("Unclosed form in seq-like expression:" + token[start..]).throw;
        };
        
        if (start < token.size) {
            items.add(token[start..].stripWhiteSpace);
        };
        
        ^items 
            .select { |x| x.size > 0 } 
            .collect { |item| PParse.from(item) };
    }

    *visitSeq { |token|
        // [x y ... z]
        if ((token.first == $[)
                .and(token.last == $])) {
            ^(type: \seq, 
                val: PParse.visitSeqLike(token))
        };
        ^nil
    }

    *visitAlt { |token|
        // <x y ... z>
        if ((token.first == $<)
                .and(token.last == $>)) {
            ^(type: \alt, 
                val: PParse.visitSeqLike(token))
        };
        ^nil
    }

    *from { |str|
        var result;
        
        str = str.stripWhiteSpace;
        
        result = PParse.visitEuc(str);
        if (result.notNil) { 
            ^result 
        };
        
        result = PParse.visitSeq(str);
        if (result.notNil) { 
            ^result 
        };
        
        result = PParse.visitAlt(str);
        if (result.notNil) { 
            ^result 
        };
        
        result = PParse.visitVal(str);
        if (result.notNil) { 
            ^result 
        };

        Error("Invalid pattern:" + str).throw;    
    }

    *new { |str|
        if ((str.first != $[)
                .and(str.last != $])) {
            str = "[" ++ str ++ "]";
        };
        ^PParse.from(str);
    }
}

