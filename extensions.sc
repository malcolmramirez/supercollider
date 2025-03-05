Peseq : Pattern {

    var <>k, <>n, <>on, <>off, <>repeats, <>offset;

    *new { arg k, n, on=1, off=0, repeats=1, offset=0;
        ^super.newCopyArgs(k, n, on, off, repeats, offset)
    }

    embedInStream {  arg inval;
        var list, item, offsetValue;
        list = (
            (k / n * (0..n - 1))
            .floor
            .differentiate
            .asInteger
            .min(1)[0] = if (k <= 0) { 0 } { 1 }
        );
        offsetValue = offset.value(inval);
        if (inval.eventAt('reverse') == true, {
            repeats.value(inval).do({ arg j;
                list.size.reverseDo({ arg i;
                    item = list.wrapAt(i + offsetValue);
                    item = if (item == 1, on.value(inval), off.value(inval));
                    inval = item.embedInStream(inval);
                });
            });
        },{
            repeats.value(inval).do({ arg j;
                list.size.do({ arg i;
                    item = list.wrapAt(i + offsetValue);
                    item = if (item == 1, on.value(inval), off.value(inval));
                    inval = item.embedInStream(inval);
                });
            });
        });
        ^inval;
    }

    storeArgs { ^[ k, n, on, off, repeats, offset ] }
}