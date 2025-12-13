SPTokenStreamTest : UnitTest {

    test_simpleValue {
        var stream = SPTokenStream("88912");
        this.assertToken(stream.next(), \val, "88912");
        this.assert(stream.isTerminal(), "stream is terminal");
    }

    test_code {
        var stream = SPTokenStream("`rrand(2, 12)`");
        
        this.assertToken(stream.next(), \tick, "`");
        this.assertToken(stream.next(), \val, "rrand");
        this.assertToken(stream.next(), \lparen, "(");
        this.assertToken(stream.next(), \val, "2,");
        this.assertToken(stream.next(), \val, "12");
        this.assertToken(stream.next(), \rparen, ")");
        this.assertToken(stream.next(), \tick, "`");
        
        this.assert(stream.isTerminal(), "stream is terminal");
    }

    test_complex {
        var stream = SPTokenStream("[ `rrand(2, 12)` abc 1(3 4) [edf 8 12] `exprand(2, 3.43)` ]");
        
        this.assertToken(stream.next(), \lbrack, "[");
        
        this.assertToken(stream.next(), \tick, "`");
        this.assertToken(stream.next(), \val, "rrand");
        this.assertToken(stream.next(), \lparen, "(");
        this.assertToken(stream.next(), \val, "2,");
        this.assertToken(stream.next(), \val, "12");
        this.assertToken(stream.next(), \rparen, ")");
        this.assertToken(stream.next(), \tick, "`");
        
        this.assertToken(stream.next(), \val, "abc");

        this.assertToken(stream.next(), \val, "1");
        this.assertToken(stream.next(), \lparen, "(");
        this.assertToken(stream.next(), \val, "3");
        this.assertToken(stream.next(), \val, "4");
        this.assertToken(stream.next(), \rparen, ")");

        this.assertToken(stream.next(), \lbrack, "[");
        this.assertToken(stream.next(), \val, "edf");
        this.assertToken(stream.next(), \val, "8");
        this.assertToken(stream.next(), \val, "12");
        this.assertToken(stream.next(), \rbrack, "]");

        this.assertToken(stream.next(), \tick, "`");
        this.assertToken(stream.next(), \val, "exprand");
        this.assertToken(stream.next(), \lparen, "(");
        this.assertToken(stream.next(), \val, "2,");
        this.assertToken(stream.next(), \val, "3.43");
        this.assertToken(stream.next(), \rparen, ")");
        this.assertToken(stream.next(), \tick, "`");

        this.assertToken(stream.next(), \rbrack, "]");
        
        this.assert(stream.isTerminal(), "stream is terminal");
    }

    assertToken { |result, type, val|
        this.assertEquals(result.type, type, "token type is " ++ type);
        this.assertEquals(result.val, val, "token val is " ++ val);
    }
}

SPParserTest : UnitTest {

    test_simpleValue {
        var parser = SPParser("88912");
        this.assertEquals(parser.parse().visit(1), [88912, 1]);
    }

    test_code {
        var parser = SPParser("`1 + 3`");
        this.assertEquals(parser.parse().visit(0.25), [4, 0.25]);
    }

    test_alt {
        var parser = SPParser("<1 2 3 4>");
        var alt = parser.parse();
        this.assertEquals(
            8.collect { alt.visit(1) },
            [[1, 1], [2, 1], [3, 1], [4, 1], [1, 1], [2, 1], [3, 1], [4, 1]]);
    }
    
    test_complex {
        var parser = SPParser("[ `(4 + 2)/3` 1.23 `1+2`(2 8) [0 8 12] `1/2` <1 2> ]");
        var seq = parser.parse();
        this.assertEquals(2, seq.visit(1).size);
        /*
        this.assertEquals(
            seq.visit(1),
            [
                Dseq([
                    2, 
                    1.23, 
                    Dseq([3, 0, 0, 0, 3, 0, 0, 0], 1),
                    Dseq([0, 8, 12], 1), 
                    0.5, 
                    1], 
                1),
                Dseq([
                    1/5, 
                    1/5, 
                    Dseq([1/40, 1/40, 1/40, 1/40, 1/40, 1/40, 1/40, 1/40], 1),
                    Dseq([1/15, 1/15, 1/15], 1), 
                    1/5, 
                    1/5], 
                1)
            ]);
        */
    }
}
