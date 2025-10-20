Alt {
    var items;
    var ptr;

    *new { |...items|
        ^super.newCopyArgs(items, 0);
    }

    value {
        var tmp = items[ptr];
        ptr = (ptr + 1) % items.size;
        ^tmp.value;
    }
}

Euc {
    var k;
    var n;
    var o;
    var on;
    var off;

    *new { |k, n, o=0, on=1, off=nil|
        ^super.newCopyArgs(k, n, o, on, off);
    }

    value {
        var nVal = n.value;
        var kVal = k.value;
        var items = (
            (kVal / nVal * (0..nVal - 1))
            .floor
            .differentiate
            .asInteger
            .min(1)[0] = if (kVal <= 0) { 0 } { 1 }
        );
        items = items.rotate(o.value);
        items = items.collect({ |i|
            if (i == 0) { off.value } { on.value }
        });
        ^items;
    }
}

Atom {
    var value;

    *new { |value|
        ^super.newCopyArgs(value)
    }

    unwrap {
        ^value;
    }
}