// --- parser ---

PParse {
    
    *visitEuc { |token|
        // x(k, n, opt(o))
        var openIdx = token.indexOf($(),
            closeIdx = token.indexOf($));
        
        if ((openIdx.notNil)
                .and(closeIdx.notNil)
                .and(closeIdx == (token.size - 1))) {
            var parts = PParse.visitSeqLike(token[openIdx..]);

            if (parts.size >= 2) {
                ^(type: \euc, 
                    val: PParse.visit(token[..openIdx-1]),
                    k: parts[0], 
                    n: parts[1], 
                    o: if (parts.size > 2) { parts[2] } { PParse.visitVal("0") }) 
            };
        };
        
        ^nil
    }

    *isOpen { |ch|
        ^(ch == $().or(ch == $[).or(ch == $<)
    }

    *isClosed { |ch|
        ^(ch == $)).or(ch == $]).or(ch == $>)
    }

    *visitVal { |token|
        // x
        var nonSpecial = token.select { |ch| 
            PParse.isOpen(ch).or(PParse.isClosed(ch)) 
        }.isEmpty;
        if (not(token.isEmpty)
                .and(nonSpecial)
                .and((token.asFloat != 0)
                        .or(token == "0") // hack :P
                        .or(token == "~"))) {
            ^(type: \val, val: token.asFloat)
        };
        ^nil
    }

    *visitSeqLike { |token|
        var items = List.new, 
            depth = 0, 
            start = 0;

        token = token[1..token.size-2];
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
            .collect { |item| PParse.visit(item) };
    }

    *visitSeq { |token|
        // [x y ... z]
        if ((token.first == $[)
                .and(token.last == $])) {
            ^(type: \seq, val: PParse.visitSeqLike(token))
        };
        ^nil
    }

    *visitAlt { |token|
        // <x y ... z>
        if ((token.first == $<)
                .and(token.last == $>)) {
            ^(type: \alt, val: PParse.visitSeqLike(token))
        };
        ^nil
    }

    *visit { |str|
        var result = PParse.visitEuc(str.stripWhiteSpace);
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

    *parse { |str|
        if ((str.first != $[)
                .or(str.last != $])) {
            str = "[" ++ str ++ "]";
        };
        ^PParse.visit(str);
    }
}

// --- demand rate generator ---

Dpat {

    *asDemand { |node, dur|
        var val = node.val, 
            type = node.type;

        ^case
        { type == \val } {
            [val, dur]
        }
        { type == \euc } {
            Error("Euclidean DPat not implemented!").throw;
        }
        { type == \seq } {
            var vals = [];
            var durs = [];
            val.collect { |item| 
                var pair = Dpat.asDemand(item, dur / val.size); 
                vals = vals.add(pair[0]);
                durs = durs.add(pair[1]);
            };
            [Dseq(vals, 1), Dseq(durs, 1)];
        }
        { type == \alt } {
            Error("Alt DPat not implemented!").throw;
        };
    }

    *kr { |str, cycleTime|
        var pat = Dpat.asDemand(PParse.parse(str), cycleTime),
            vals = Dseq([pat[0]], inf),
            durs = Dseq([pat[1]], inf);

        ^TDuty.kr(durs, Impulse.kr(0), vals);
   }
}

// --- mpulse ---

Mpulse {

    *ndef { |key, str, speed=1|
        var bps = 4 / speed,
            currentCycle = TempoClock.default.beats / bps,
            nextCycle = currentCycle.ceil,
            waitTime = (nextCycle - currentCycle) * bps;

        TempoClock.default.sched(waitTime, {
            Ndef(key, {
                var cycleTime = TempoClock.default.beatDur * bps;
                Dpat.kr(str, cycleTime);
            });
            nil;
        });
        
        ^Ndef(key);
    }
}
