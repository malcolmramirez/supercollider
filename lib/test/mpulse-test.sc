TestPParse : UnitTest {
    
    test_simpleValue {
        var result = PParse("1");
        var expected = (type: \seq, val: [(type: \val, val: 1)]);
        this.assertEquals(result, expected);
    }
    
    test_multipleValues {
        var result = PParse("1 2 12");
        var expected = (
            type: \seq, 
            val: [
                (type: \val, val: 1),
                (type: \val, val: 2),
                (type: \val, val: 12)
            ]);
        this.assertEquals(result, expected);
    }
    
    test_alreadyWrapped {
        var result = PParse("[1 2]");
        var expected = (
            type: \seq,
            val: [
                (type: \val, val: 1),
                (type: \val, val: 2)
            ]);
        this.assertEquals(result, expected);
    }
    
    test_euclidean {
        var result = PParse("1(3, 8)");
        var expected = (
            type: \seq,
            val: [(type: \euc, val: 1, k: 3, n: 8, o: 0)]);
        this.assertEquals(result, expected);
    }
    
    test_euclideanWithOffset {
        var result = PParse("2(5, 16, 2)");
        var expected = (
            type: \seq,
            val: [(type: \euc, val: 2, k: 5, n: 16, o: 2)]);
        this.assertEquals(result, expected);
    }
    
    test_nestedSequence {
        var result = PParse("[1 [2 3] 12]");
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
        var result = PParse("<1 2>");
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
        var result = PParse("[1(3, 8) <2 3> [12 41982]]");
        var expected = (
            type: \seq,
            val: [
                (type: \euc, val: 1, k: 3, n: 8, o: 0),
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
