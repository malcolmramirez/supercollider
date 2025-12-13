TestPParse : UnitTest {
    
    test_simpleValue {
        var result = PParse.parse("1");
        var expected = (type: \seq, val: [(type: \val, val: 1)]);
        this.assertEquals(result, expected);
    }
    
    test_multipleValues {
        var result = PParse.parse("1 2 12");
        var expected = (
            type: \seq, 
            val: [
                (type: \val, val: 1),
                (type: \val, val: 2),
                (type: \val, val: 12)]);
        this.assertEquals(result, expected);
    }
    
    test_multipleValuesComplex {
        var result = PParse.parse("1 2 [12 1.2]");
        var expected = (
            type: \seq, 
            val: [
                (type: \val, val: 1),
                (type: \val, val: 2),
                (type: \seq, val: [
                    (type: \val, val: 12),
                    (type: \val, val: 1.2)])]);
        this.assertEquals(result, expected);
    }

    test_tildeShorthand {
        var result = PParse.parse("~ 0");
        var expected = (
            type: \seq, 
            val: [
                (type: \val, val: 0),
                (type: \val, val: 0)]);
        this.assertEquals(result, expected);
    }

    test_alreadyWrapped {
        var result = PParse.parse("[1 2]");
        var expected = (
            type: \seq,
            val: [
                (type: \val, val: 1),
                (type: \val, val: 2)]);
        this.assertEquals(result, expected);
    }
    
    test_euclidean {
        var result = PParse.parse("1(3 8)");
        var expected = (
            type: \seq,
            val: [
                (type: \euc, 
                    val: (type: \val, val: 1), 
                    k: (type: \val, val: 3), 
                    n: (type: \val, val: 8), 
                    o: (type: \val, val: 0))]);
        this.assertEquals(result, expected);
    }
    
    test_euclideanWithOffset {
        var result = PParse.parse("2(5 16 2)");
        var expected = (
            type: \seq,
            val: [
                (type: \euc, 
                    val: (type: \val, val: 2), 
                    k: (type: \val, val: 5), 
                    n: (type: \val, val: 16), 
                    o: (type: \val, val: 2))]);
        this.assertEquals(result, expected);
    }
    
    test_euclideanWithPatterns {
        var result = PParse.parse("2([5 10] <2 16 3> <[2 4] 3>)");
        var expected = (
            type: \seq,
            val: [
                (type: \euc, 
                    val: (type: \val, val: 2), 
                    k: (type: \seq, val: [
                        (type: \val, val: 5),
                        (type: \val, val: 10)]), 
                    n: (type: \alt, val: [
                        (type: \val, val: 2),
                        (type: \val, val: 16),
                        (type: \val, val: 3)]),
                    o: (type: \alt, val: [
                        (type: \seq, val: [
                            (type: \val, val: 2),
                            (type: \val, val: 4)]),
                        (type: \val, val: 3)]))]);
        this.assertEquals(result, expected);
    }

    test_nestedSequence {
        var result = PParse.parse("[1 [2 3] 12]");
        var expected = (
            type: \seq,
            val: [
                (type: \val, val: 1),
                (type: \seq, val: [
                    (type: \val, val: 2),
                    (type: \val, val: 3)
                ]),
                (type: \val, val: 12)
            ]);
        this.assertEquals(result, expected);
    }
    
    test_alternation {
        var result = PParse.parse("<1 2>");
        var expected = (
            type: \seq,
            val: [(
                type: \alt,
                val: [
                    (type: \val, val: 1),
                    (type: \val, val: 2)
                ]
            )]);
        this.assertEquals(result, expected);
    }
    
    test_complexMixed {
        var result = PParse.parse("[1(3 8) <2 3> [12 41982]]");
        var expected = (
            type: \seq,
            val: [
                (type: \euc, 
                    val: (type: \val, val: 1), 
                    k: (type: \val, val: 3), 
                    n: (type: \val, val: 8), 
                    o: (type: \val, val: 0)),
                (type: \alt, val: [
                    (type: \val, val: 2),
                    (type: \val, val: 3)
                ]),
                (type: \seq, val: [
                    (type: \val, val: 12),
                    (type: \val, val: 41982)
                ])
            ]);
        this.assertEquals(result, expected);
    }
}
