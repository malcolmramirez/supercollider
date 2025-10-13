Cycle {
    var <>synth;
    var bindings;
    var clock;
    var s;
    var <>stopped;

    *new { |synth, clock=(TempoClock.default), s=(Server.default)|
        ^super.newCopyArgs(synth, Dictionary[], clock, s, false);
    }

    add { |assoc|
        if (assoc.key == \def) {
            this.synth = Synth(assoc.value);
            ^this;
        };

        if (assoc.key == \synth) {
            this.synth = assoc.value;
            ^this;
        };

        if (assoc.value.isKindOf(SequenceableCollection)) {
            var flattened = [];
            var flattenHelper = { |seq, acc, stepSize|
                seq.do { |item|
                    if (item.isKindOf(SequenceableCollection)) {
                        flattenHelper.(item, acc, stepSize * item.size.reciprocal);
                    } {
                        flattened = flattened.add((val: item, sched: acc.get));
                        acc.value = acc.value + stepSize;
                    };
                }
            };
            var list = assoc.value;
            flattenHelper.(list, `0, list.size.reciprocal);
            flattened.postln;
            bindings[assoc.key] = flattened;
            ^this;
        };

        bindings[assoc.key] = assoc.value;
    }

    run { |length=8|
        var timeline = Dictionary[];
        var putInTimeline = { |time, param, val|
            if (val != \) {
                var timelineEntry = timeline.atFail(time, []);
                timelineEntry = timelineEntry.add(param);
                timelineEntry = timelineEntry.add(val);
                timeline[time] = timelineEntry;
            };
        };

        this.stopped = false;

        bindings.pairsDo { |param, binding|
            if (binding.isKindOf(SequenceableCollection)) {
                binding.do { |item|
                    putInTimeline.(item[\sched] * length, param, item.val);
                };
            } {
                "hellp".postln;
                putInTimeline.(0, param, binding);
            };
        };

        // construct a timeline and run the cycles
        fork {
            timeline.pairsDo { |time, values|
                clock.sched(time, {
                    s.bind {
                        s.listSendMsg(
                            ["/n_set", this.synth.nodeID] ++
                            values.collect{|v| v.value;});
                    };
                    if (not(this.stopped)) {
                        length;
                    };
                });
            };
        }
    }

    stop {
        this.stopped = true;
    }
}

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
    var items;
    var ptr;
    var o;

    *new { |k, n, o=0, on=1, off=\|
        var items = (
            (k / n * (0..n - 1))
            .floor
            .differentiate
            .asInteger
            .min(1)[0] = if (k <= 0) { off } { on }
        );
        ^super.newCopyArgs(items, o);
    }

    value {
        var tmp = items[ptr];
        ptr = (ptr + 1) % items.size;
        ^tmp.value;
    }
}