SPTokenStreamTest : UnitTest {

    test_simpleValue {
        var stream = SPTokenStream("88912");
        this.assertToken(stream.next(), \val, "88912");
        this.assert(stream.isTerminal(), "stream is terminal");
    }

    test_code {
        var stream = SPTokenStream("`rrand(2, 12)`");
        
        this.assertToken(stream.next(), \tick, $`);
        this.assertToken(stream.next(), \val, "rrand(2, 12)");
        this.assertToken(stream.next(), \tick, $`);
        
        this.assert(stream.isTerminal(), "stream is terminal");
    }

    test_complex {
        var stream = SPTokenStream("[ `rrand(2, 12)` abc 1(3 4) [edf 8 12] `exprand(2, 3.43)` ]");
        
        this.assertToken(stream.next(), \lbrack, $[);
        
        this.assertToken(stream.next(), \tick, $`);
        this.assertToken(stream.next(), \val, "rrand(2, 12)");
        this.assertToken(stream.next(), \tick, $`);
        
        this.assertToken(stream.next(), \val, "abc");

        this.assertToken(stream.next(), \val, "1");
        this.assertToken(stream.next(), \lparen, $();
        this.assertToken(stream.next(), \val, "3");
        this.assertToken(stream.next(), \val, "4");
        this.assertToken(stream.next(), \rparen, $));

        this.assertToken(stream.next(), \lbrack, $[);
        this.assertToken(stream.next(), \val, "edf");
        this.assertToken(stream.next(), \val, "8");
        this.assertToken(stream.next(), \val, "12");
        this.assertToken(stream.next(), \rbrack, $]);

        this.assertToken(stream.next(), \tick, $`);
        this.assertToken(stream.next(), \val, "exprand(2, 3.43)");
        this.assertToken(stream.next(), \tick, $`);

        this.assertToken(stream.next(), \rbrack, $]);
        
        this.assert(stream.isTerminal(), "stream is terminal");
    }


    assertToken { |result, type, val|
        this.assertEquals(result.type, type, "token type is " ++ type);
        this.assertEquals(result.val, val, "token val is " ++ val);
    }
}
