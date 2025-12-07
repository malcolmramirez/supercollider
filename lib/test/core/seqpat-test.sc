SPTokenStreamTest : UnitTest {

    test_number {
        var result = SPTokenStream("1").next();
        var expected = SPToken(\val, "1");
        this.assertEquals(result, expected);
    }
}

SPTokenizerTest : UnitTest {

    test_number {
        var result = SPTokenizer.tokenize("1");
        var expected = ["1"];
        this.assertEquals(result, expected);
    }
    
    test_complexExpression {
        var result = SPTokenizer.tokenize(
            "[a b(2 3 4) [5 j errr] `rrand(2, 4)` <3 effe 4>]");
        var expected = [
            \lbrack, "a", 
                    "b", 
                    \lparen, "2", "3", "4", \rparen,
                    \lbrack, "5", "j", "errr", \rbrack, 
                    \tick, "rrand(2, 4)", \tick,
                    \lt, "3", "effe", "4", \gt,
            \rbrack
        ];
        this.assertEquals(result, expected);
    }
}
